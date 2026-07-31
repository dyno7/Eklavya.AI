"""
Tasks API router — CRUD operations for tasks within milestones.
"""

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import get_current_user_id
from app.core.database import get_db
from app.core import repositories as repo
from app.domain.schemas import TaskCreate, TaskResponse, TaskStatusUpdate

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
