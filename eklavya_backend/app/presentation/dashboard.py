"""
Dashboard API router — unified view of user stats, active goal, and pending tasks.

Endpoints:
- GET  /api/v1/dashboard/summary — Full dashboard data in one call
- POST /api/v1/dashboard/claim-task/{task_id} — Complete a task and earn XP
"""

import logging
import uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import CurrentUser, get_current_user, get_current_user_id
from app.core.database import get_db
from app.core import repositories as repo
from app.core.cache import DashboardCache
from app.domain.enums import GoalStatus, MilestoneStatus, TaskStatus
from app.domain.models import RewardSignalLog

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/dashboard", tags=["Dashboard"])


# ─── Response schemas ───────────────────────────────

class TaskSummary(BaseModel):
    id: str
    title: str
    task_type: str
    xp_reward: int
    status: str
    estimated_minutes: int = 30


class MilestoneSummary(BaseModel):
    id: str
    title: str
    order_index: int
    status: str
    total_tasks: int
    completed_tasks: int


class GoalSummary(BaseModel):
    id: str
    title: str
    domain: str
    status: str
    total_milestones: int
    completed_milestones: int
    resources: list[dict] = []


class UserStats(BaseModel):
    display_name: str
    total_xp: int
    current_streak: int


class DashboardResponse(BaseModel):
    user: UserStats
    active_goal: GoalSummary | None = None
    current_milestone: MilestoneSummary | None = None
    pending_tasks: list[TaskSummary] = []


class ClaimTaskResponse(BaseModel):
    task_id: str
    xp_earned: int
    new_total_xp: int
    message: str
    bonus_xp: int = 0
    level_up: bool = False
    new_level: int = 0
    badges_awarded: list[str] = []


# ─── Endpoints ──────────────────────────────────────

@router.get("/summary", response_model=DashboardResponse)
async def get_dashboard_summary(
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(get_current_user),
):
    """Get unified dashboard data: user stats, active goal, milestone, tasks."""
    current_user_id = current_user.id
    cache_key = str(current_user_id)

    # ── Cache hit: serve from memory (30s TTL) ────────────────────────────────
    cached = DashboardCache.get(cache_key)
    if cached is not None:
        return cached

    # 1. Get user profile
    user = await repo.get_user_profile(db, current_user_id)
    if user is None:
        user = await repo.upsert_user_profile(db, current_user_id, display_name=current_user.display_name)
    else:
        user = await repo.ensure_user_display_name(db, current_user_id, current_user.display_name) or user

    user_stats = UserStats(
        display_name=user.display_name,
        total_xp=user.total_xp,
        current_streak=user.current_streak,
    )

    # 2. Get the most recent ACTIVE goal with eager loaded relations
    active_goal = await repo.get_dashboard_active_goal(db, current_user_id)

    if active_goal is None:
        return DashboardResponse(user=user_stats)

    # 3. Process eagerly loaded milestones
    milestones = active_goal.milestones

    completed_milestones = sum(1 for m in milestones if m.status == MilestoneStatus.COMPLETED)
    goal_summary = GoalSummary(
        id=str(active_goal.id),
        title=active_goal.title,
        domain=active_goal.domain.value,
        status=active_goal.status.value,
        total_milestones=len(milestones),
        completed_milestones=completed_milestones,
        resources=active_goal.metadata_.get("resources", []) if active_goal.metadata_ else [],
    )

    # 4. Find the current milestone (first non-completed by order)
    current_ms = next(
        (m for m in sorted(milestones, key=lambda x: x.order_index) if m.status in (MilestoneStatus.LOCKED, MilestoneStatus.ACTIVE)),
        None,
    )

    if current_ms is None:
        return DashboardResponse(user=user_stats, active_goal=goal_summary)

    # 5. Get tasks for the current milestone
    tasks = current_ms.tasks
    completed_tasks = sum(1 for t in tasks if t.status == TaskStatus.COMPLETED)

    milestone_summary = MilestoneSummary(
        id=str(current_ms.id),
        title=current_ms.title,
        order_index=current_ms.order_index,
        status=current_ms.status.value,
        total_tasks=len(tasks),
        completed_tasks=completed_tasks,
    )

    # 6. Get pending tasks (up to 5)
    pending = [
        TaskSummary(
            id=str(t.id),
            title=t.title,
            task_type=t.task_type.value,
            xp_reward=t.xp_reward,
            status=t.status.value,
            estimated_minutes=t.metadata_.get("estimated_minutes", 30) if t.metadata_ else 30,
        )
        for t in tasks
        if t.status in (TaskStatus.PENDING, TaskStatus.IN_PROGRESS)
    ][:5]

    response = DashboardResponse(
        user=user_stats,
        active_goal=goal_summary,
        current_milestone=milestone_summary,
        pending_tasks=pending,
    )
    DashboardCache.set(cache_key, response)
    return response


@router.post("/claim-task/{task_id}", response_model=ClaimTaskResponse)
async def claim_task(
    task_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(get_current_user),
):
    """Mark a task as completed and award XP to the user."""
    current_user_id = current_user.id

    # ── Invalidate dashboard cache so next load is fresh ──────────────────────
    DashboardCache.invalidate(str(current_user_id))

    # SQLAlchemy async sessions don't allow concurrent ops on the same session.
    task = await repo.get_task_by_id(db, task_id)
    previous_completion = await repo.get_latest_task_completion_for_user(db, current_user_id)
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.status == TaskStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Task already completed")

    task_milestone_id = task.milestone_id
    task_xp_reward = task.xp_reward
    await repo.update_task_status(db, task_id, TaskStatus.COMPLETED)

    # 6. Advance milestone / goal state when all nested tasks are complete.
    bonus_xp_from_milestone = 0
    bonus_xp_from_goal = 0
    try:
        milestone = await repo.get_milestone_by_id(db, task_milestone_id)
        if milestone:
            milestone_tasks = await repo.get_tasks_for_milestone(db, milestone.id)
            if milestone_tasks and all(t.status == TaskStatus.COMPLETED for t in milestone_tasks):
                await repo.update_milestone_status(db, milestone.id, MilestoneStatus.COMPLETED)
                bonus_xp_from_milestone = 50

                milestones = await repo.get_milestones_for_goal(db, milestone.goal_id)
                remaining = [m for m in milestones if m.status != MilestoneStatus.COMPLETED]
                if remaining:
                    next_milestone = sorted(remaining, key=lambda item: item.order_index)[0]
                    if next_milestone.status == MilestoneStatus.LOCKED:
                        await repo.update_milestone_status(db, next_milestone.id, MilestoneStatus.ACTIVE)

                goal = await repo.get_goal_by_id(db, milestone.goal_id)
                if goal:
                    refreshed = await repo.get_milestones_for_goal(db, goal.id)
                    if refreshed and all(m.status == MilestoneStatus.COMPLETED for m in refreshed):
                        await repo.update_goal(db, goal.id, status=GoalStatus.COMPLETED)
                        bonus_xp_from_goal = 200
    except Exception as e:
        logger.error("Milestone/goal advancement failed (task already completed in DB): %s", e)
        try:
            await db.rollback()
        except Exception:
            pass

    # 6. Award XP, update streak, check level and badges.
    user = await repo.get_user_profile(db, current_user_id)
    bonus_xp_total = 0
    level_up = False
    new_level = 0
    badges_awarded = []

    if user:
        old_xp = user.total_xp or 0
        old_level = old_xp // 100

        streak = user.current_streak or 0
        multiplier = 1.0
        if streak >= 7:
            multiplier = 1.5
        elif streak >= 3:
            multiplier = 1.2

        streak_bonus = int(task_xp_reward * (multiplier - 1.0))
        bonus_xp_total = streak_bonus + bonus_xp_from_milestone + bonus_xp_from_goal

        user.total_xp = old_xp + task_xp_reward + bonus_xp_total
        new_level = user.total_xp // 100
        level_up = new_level > old_level

        today = datetime.now(timezone.utc).date()
        prev_date = previous_completion.date() if previous_completion else None
        if prev_date is None:
            user.current_streak = 1
        elif prev_date == today:
            user.current_streak = max(user.current_streak or 0, 1)
        elif prev_date == today - timedelta(days=1):
            user.current_streak = (user.current_streak or 0) + 1
        else:
            user.current_streak = 1
        user.updated_at = datetime.now(timezone.utc)
        # Merge reward signal log into same commit to save a round-trip.
        try:
            db.add(RewardSignalLog(
                user_id=current_user_id,
                action_type="task_complete",
                reward_value=1.0,
            ))
        except Exception:
            pass
        try:
            await db.commit()
        except Exception as e:
            logger.error("Failed to commit user XP/streak update: %s", e)
            try:
                await db.rollback()
            except Exception:
                pass

        # 7. Evaluate badge triggers — optional, must not fail the request
        try:
            badge_checks = []
            if previous_completion is None:
                badge_checks.append(repo.award_badge_if_not_earned(db, current_user_id, "First Steps"))
            if user.total_xp >= 100:
                badge_checks.append(repo.award_badge_if_not_earned(db, current_user_id, "Novice"))
            if user.total_xp >= 500:
                badge_checks.append(repo.award_badge_if_not_earned(db, current_user_id, "Centurion"))
            if user.current_streak >= 7:
                badge_checks.append(repo.award_badge_if_not_earned(db, current_user_id, "Consistency"))
            if bonus_xp_from_milestone > 0:
                badge_checks.append(repo.award_badge_if_not_earned(db, current_user_id, "Milestone Master"))
            if bonus_xp_from_goal > 0:
                badge_checks.append(repo.award_badge_if_not_earned(db, current_user_id, "Goal Crusher"))

            for check in badge_checks:
                try:
                    result = await check
                    if isinstance(result, str):
                        badges_awarded.append(result)
                except Exception as badge_err:
                    logger.warning("Badge check failed: %s", badge_err)
        except Exception as e:
            logger.warning("Badge evaluation skipped: %s", e)
            try:
                await db.rollback()
            except Exception:
                pass

    return ClaimTaskResponse(
        task_id=str(task_id),
        xp_earned=task_xp_reward,
        new_total_xp=user.total_xp if user else 0,
        message=(
            f"+{task_xp_reward + bonus_xp_total} XP earned!"
            if bonus_xp_total
            else f"+{task_xp_reward} XP earned!"
        ),
        bonus_xp=bonus_xp_total,
        level_up=level_up,
        new_level=new_level,
        badges_awarded=badges_awarded,
    )
