"""
Dashboard API router — unified view of user stats, active goal, and pending tasks.

Endpoints:
- GET  /api/v1/dashboard/summary — Full dashboard data in one call
- POST /api/v1/dashboard/claim-task/{task_id} — Complete a task and earn XP
"""

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import get_current_user_id
from app.core.database import get_db
from app.core import repositories as repo
from app.domain.enums import GoalStatus, MilestoneStatus, TaskStatus

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


# ─── Endpoints ──────────────────────────────────────

@router.get("/summary", response_model=DashboardResponse)
async def get_dashboard_summary(
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Get unified dashboard data: user stats, active goal, milestone, tasks."""
    # 1. Get user profile
    user = await repo.get_user_profile(db, current_user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User profile not found")

    user_stats = UserStats(
        display_name=user.display_name,
        total_xp=user.total_xp,
        current_streak=user.current_streak,
    )

    # 2. Get the most recent ACTIVE goal
    goals = await repo.get_goals_for_user(db, current_user_id)
    active_goal = next((g for g in goals if g.status == GoalStatus.ACTIVE), None)

    if active_goal is None:
        return DashboardResponse(user=user_stats)

    # 3. Get milestones for that goal
    milestones = await repo.get_milestones_for_goal(db, active_goal.id)

    completed_milestones = sum(1 for m in milestones if m.status == MilestoneStatus.COMPLETED)
    goal_summary = GoalSummary(
        id=str(active_goal.id),
        title=active_goal.title,
        domain=active_goal.domain.value,
        status=active_goal.status.value,
        total_milestones=len(milestones),
        completed_milestones=completed_milestones,
    )

    # 4. Find the current milestone (first non-completed)
    current_ms = next(
        (m for m in milestones if m.status in (MilestoneStatus.LOCKED, MilestoneStatus.ACTIVE)),
        None,
    )

    if current_ms is None:
        return DashboardResponse(user=user_stats, active_goal=goal_summary)

    # 5. Get tasks for the current milestone
    tasks = await repo.get_tasks_for_milestone(db, current_ms.id)
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

    return DashboardResponse(
        user=user_stats,
        active_goal=goal_summary,
        current_milestone=milestone_summary,
        pending_tasks=pending,
    )


@router.post("/claim-task/{task_id}", response_model=ClaimTaskResponse)
async def claim_task(
    task_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Mark a task as completed and award XP to the user."""
    # 1. Get task
    task = await repo.get_task_by_id(db, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")

    if task.status == TaskStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Task already completed")

    # 2. Complete the task
    await repo.update_task_status(db, task_id, TaskStatus.COMPLETED)

    # 3. Award XP
    user = await repo.get_user_profile(db, current_user_id)
    if user:
        user.total_xp = (user.total_xp or 0) + task.xp_reward
        user.updated_at = datetime.now(timezone.utc)
        await db.commit()
        await db.refresh(user)

    return ClaimTaskResponse(
        task_id=str(task_id),
        xp_earned=task.xp_reward,
        new_total_xp=user.total_xp if user else 0,
        message=f"+{task.xp_reward} XP earned!",
    )
