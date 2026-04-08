"""
Users API router — profile management for the authenticated user.
"""

import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import CurrentUser, get_current_user, get_current_user_id
from app.core.database import get_db
from app.core import repositories as repo
from app.domain.schemas import BadgeResponse, UserResponse, UserUpdate

router = APIRouter(prefix="/api/v1/users", tags=["Users"])


@router.get("/me", response_model=UserResponse)
async def get_my_profile(
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(get_current_user),
):
    """Get the authenticated user's profile. Creates profile on first access."""
    current_user_id = current_user.id
    user = await repo.get_user_profile(db, current_user_id)
    if user is None:
        # Auto-create profile on first access
        user = await repo.upsert_user_profile(db, current_user_id, display_name=current_user.display_name)
    else:
        user = await repo.ensure_user_display_name(db, current_user_id, current_user.display_name) or user
    return user


@router.patch("/me", response_model=UserResponse)
async def update_my_profile(
    body: UserUpdate,
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Update the authenticated user's profile."""
    user = await repo.upsert_user_profile(
        db,
        current_user_id,
        display_name=body.display_name or "",
        avatar_url=body.avatar_url,
    )
    return user


@router.get("/me/badges", response_model=list[BadgeResponse])
async def get_my_badges(
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Get the authenticated user's badges (both earned and unearned)."""
    badges = await repo.get_user_badges_status(db, current_user_id)
    return badges
