"""
Goals API router — CRUD operations for goals and milestones.
"""

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import get_current_user_id
from app.core.database import get_db
from app.core import repositories as repo
from app.domain.schemas import (
    GoalCreate,
    GoalResponse,
    GoalUpdate,
    MilestoneCreate,
    MilestoneResponse,
)

router = APIRouter(prefix="/api/v1/goals", tags=["Goals"])


@router.post("/", response_model=GoalResponse, status_code=status.HTTP_201_CREATED)
async def create_goal(
    body: GoalCreate,
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Create a new goal for the authenticated user."""
    # Ensure user profile exists (auto-create on first goal)
    user = await repo.get_user_profile(db, current_user_id)
    if user is None:
        await repo.upsert_user_profile(db, current_user_id, display_name="")

    goal = await repo.create_goal(
        db,
        user_id=current_user_id,
        title=body.title,
        description=body.description,
        domain=body.domain,
        target_date=body.target_date,
        metadata_=body.metadata,
    )
    return goal


@router.get("/", response_model=list[GoalResponse])
async def list_goals(
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """List all goals for the authenticated user."""
    return await repo.get_goals_for_user(db, current_user_id)


@router.get("/{goal_id}", response_model=GoalResponse)
async def get_goal(
    goal_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Get a specific goal by ID."""
    goal = await repo.get_goal_by_id(db, goal_id)
    if goal is None or goal.user_id != current_user_id:
        raise HTTPException(status_code=404, detail="Goal not found")
    return goal


@router.patch("/{goal_id}", response_model=GoalResponse)
async def update_goal(
    goal_id: uuid.UUID,
    body: GoalUpdate,
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Update a goal (partial update)."""
    goal = await repo.get_goal_by_id(db, goal_id)
    if goal is None or goal.user_id != current_user_id:
        raise HTTPException(status_code=404, detail="Goal not found")

    updated = await repo.update_goal(
        db,
        goal_id,
        title=body.title,
        description=body.description,
        status=body.status,
        target_date=body.target_date,
    )
    return updated


# ─── Milestones (nested under goals) ──────────────────────────

@router.post(
    "/{goal_id}/milestones",
    response_model=MilestoneResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_milestone(
    goal_id: uuid.UUID,
    body: MilestoneCreate,
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Create a milestone under a goal."""
    goal = await repo.get_goal_by_id(db, goal_id)
    if goal is None or goal.user_id != current_user_id:
        raise HTTPException(status_code=404, detail="Goal not found")

    milestone = await repo.create_milestone(
        db,
        goal_id=goal_id,
        title=body.title,
        description=body.description,
        order_index=body.order_index,
    )
    return milestone


@router.get("/{goal_id}/milestones", response_model=list[MilestoneResponse])
async def list_milestones(
    goal_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """List milestones for a goal, ordered by index."""
    goal = await repo.get_goal_by_id(db, goal_id)
    if goal is None or goal.user_id != current_user_id:
        raise HTTPException(status_code=404, detail="Goal not found")
    return await repo.get_milestones_for_goal(db, goal_id)
