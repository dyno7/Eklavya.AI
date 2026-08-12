"""
Tasks API router — CRUD operations for tasks within milestones.
"""

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import get_current_user_id
from app.core.database import get_db
from app.core import repositories as repo
from app.domain.schemas import TaskCreate, TaskResponse, TaskStatusUpdate, TaskTimerStart, TaskTimerStop
from app.domain.models import Task
from sqlalchemy import update

router = APIRouter(prefix="/api/v1/tasks", tags=["Tasks"])


async def _require_task_owner(
    db: AsyncSession,
    task_id: uuid.UUID,
    current_user_id: uuid.UUID,
):
    owner_id = await repo.get_task_owner_id(db, task_id)
    if owner_id is None or owner_id != current_user_id:
        raise HTTPException(status_code=404, detail="Task not found")


async def _require_milestone_owner(
    db: AsyncSession,
    milestone_id: uuid.UUID,
    current_user_id: uuid.UUID,
):
    milestone = await repo.get_milestone_by_id(db, milestone_id)
    if milestone is None:
        raise HTTPException(status_code=404, detail="Milestone not found")
    goal = await repo.get_goal_by_id(db, milestone.goal_id)
    if goal is None or goal.user_id != current_user_id:
        raise HTTPException(status_code=404, detail="Milestone not found")


@router.post("/", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_task(
    body: TaskCreate,
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Create a new task under a milestone."""
    await _require_milestone_owner(db, body.milestone_id, current_user_id)
    task = await repo.create_task(
        db,
        milestone_id=body.milestone_id,
        title=body.title,
        description=body.description,
        task_type=body.task_type,
        xp_reward=body.xp_reward,
        metadata_=body.metadata,
        due_date=body.due_date,
    )
    return task


@router.get("/milestone/{milestone_id}", response_model=list[TaskResponse])
async def list_tasks_for_milestone(
    milestone_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """List all tasks for a milestone, ordered by index."""
    await _require_milestone_owner(db, milestone_id, current_user_id)
    return await repo.get_tasks_for_milestone(db, milestone_id)


@router.get("/{task_id}", response_model=TaskResponse)
async def get_task(
    task_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Get a single task by ID."""
    await _require_task_owner(db, task_id, current_user_id)
    task = await repo.get_task_by_id(db, task_id)
    return task


@router.patch("/{task_id}/status", response_model=TaskResponse)
async def update_task_status(
    task_id: uuid.UUID,
    body: TaskStatusUpdate,
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Update a task's status. Auto-sets completed_at when completed."""
    await _require_task_owner(db, task_id, current_user_id)

    updated = await repo.update_task_status(db, task_id, body.status)
    return updated


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(
    task_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Permanently remove a task from its roadmap."""
    owner_id = await repo.get_task_owner_id(db, task_id)
    if owner_id is None or owner_id != current_user_id:
        raise HTTPException(status_code=404, detail="Task not found")

    await repo.delete_task(db, task_id)


@router.post("/{task_id}/timer/start", response_model=TaskResponse)
async def start_task_timer(
    task_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Start the timer for a task."""
    await _require_task_owner(db, task_id, current_user_id)
    task = await repo.get_task_by_id(db, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.timer_running:
        raise HTTPException(status_code=400, detail="Timer already running")
    if task.status == TaskStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="Cannot start timer for completed task")

    from datetime import datetime, timezone
    task.started_at = datetime.now(timezone.utc)
    task.timer_running = True
    task.actual_minutes = None  # Reset actual minutes when starting fresh
    await db.commit()
    await db.refresh(task)
    return task


@router.post("/{task_id}/timer/stop", response_model=TaskResponse)
async def stop_task_timer(
    task_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Stop the timer for a task and record actual time spent."""
    await _require_task_owner(db, task_id, current_user_id)
    task = await repo.get_task_by_id(db, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    if not task.timer_running:
        raise HTTPException(status_code=400, detail="Timer not running")
    if task.started_at is None:
        raise HTTPException(status_code=400, detail="Timer start time not recorded")

    from datetime import datetime, timezone
    now = datetime.now(timezone.utc)
    elapsed_seconds = (now - task.started_at).total_seconds()
    actual_minutes = max(1, int(elapsed_seconds / 60))

    task.timer_running = False
    task.actual_minutes = actual_minutes
    task.started_at = None
    await db.commit()
    await db.refresh(task)

    # Trigger roadmap adjustment based on actual vs estimated time
    await _adjust_roadmap_for_task(db, task)

    return task


async def _adjust_roadmap_for_task(db: AsyncSession, task: Task) -> None:
    """Adjust future tasks in the roadmap based on actual vs estimated time."""
    from app.core import repositories as repo
    from app.domain.enums import TaskStatus

    # Get the milestone and goal
    milestone = await repo.get_milestone_by_id(db, task.milestone_id)
    if not milestone:
        return

    goal = await repo.get_goal_by_id(db, milestone.goal_id)
    if not goal:
        return

    estimated = task.metadata_.get("estimated_minutes", 30) if task.metadata_ else 30
    actual = task.actual_minutes or estimated

    # Calculate ratio: actual / estimated
    # < 0.7 = user is fast -> optimize (reduce future estimates)
    # > 1.5 = user is slow -> break down (increase granularity)
    ratio = actual / estimated if estimated > 0 else 1.0

    if ratio < 0.7:
        # User is faster than expected - optimize remaining tasks
        await _optimize_remaining_tasks(db, milestone, goal, ratio)
    elif ratio > 1.5:
        # User is slower than expected - break down future tasks
        await _breakdown_remaining_tasks(db, milestone, goal, ratio)


async def _optimize_remaining_tasks(db: AsyncSession, milestone, goal, ratio: float) -> None:
    """Reduce estimated time for remaining tasks when user is fast."""
    from app.core import repositories as repo
    from app.domain.enums import TaskStatus

    milestones = await repo.get_milestones_for_goal(db, goal.id)
    for ms in milestones:
        if ms.order_index < milestone.order_index:
            continue
        tasks = await repo.get_tasks_for_milestone(db, ms.id)
        for t in tasks:
            if t.status in (TaskStatus.PENDING, TaskStatus.IN_PROGRESS):
                est = t.metadata_.get("estimated_minutes", 30) if t.metadata_ else 30
                # Reduce by ratio but not below 10 minutes
                new_est = max(10, int(est * ratio))
                if new_est < est:
                    meta = dict(t.metadata_) if t.metadata_ else {}
                    meta["estimated_minutes"] = new_est
                    meta["auto_adjusted"] = True
                    meta["adjustment_reason"] = "user_fast"
                    await db.execute(
                        update(Task).where(Task.id == t.id).values(metadata_=meta)
                    )
    await db.commit()


async def _breakdown_remaining_tasks(db: AsyncSession, milestone, goal, ratio: float) -> None:
    """Break down remaining tasks into smaller chunks when user is slow."""
    from app.core import repositories as repo
    from app.domain.enums import TaskStatus

    milestones = await repo.get_milestones_for_goal(db, goal.id)
    for ms in milestones:
        if ms.order_index < milestone.order_index:
            continue
        tasks = await repo.get_tasks_for_milestone(db, ms.id)
        for t in tasks:
            if t.status in (TaskStatus.PENDING, TaskStatus.IN_PROGRESS):
                est = t.metadata_.get("estimated_minutes", 30) if t.metadata_ else 30
                # If task is long (>45 min), split it
                if est > 45:
                    # Create a subtask with half the time
                    meta = dict(t.metadata_) if t.metadata_ else {}
                    meta["estimated_minutes"] = max(15, est // 2)
                    meta["parent_task_id"] = str(t.id)
                    meta["auto_split"] = True

                    await repo.create_task(
                        db,
                        milestone_id=ms.id,
                        title=f"{t.title} (Part 2)",
                        description=t.description,
                        task_type=t.task_type.value,
                        xp_reward=t.xp_reward,
                        metadata_=meta,
                        order_index=t.order_index + 1,
                    )
                    # Reduce original task estimate
                    meta_orig = dict(t.metadata_) if t.metadata_ else {}
                    meta_orig["estimated_minutes"] = max(15, est // 2)
                    meta_orig["auto_split"] = True
                    meta_orig["adjustment_reason"] = "user_slow"
                    await db.execute(
                        update(Task).where(Task.id == t.id).values(metadata_=meta_orig)
                    )
    await db.commit()
