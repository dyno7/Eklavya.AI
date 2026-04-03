"""
Notifications API router — system alerts for the authenticated user.
"""

import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import get_current_user_id
from app.core.database import get_db
from app.core import repositories as repo
from app.domain.schemas import NotificationResponse

router = APIRouter(prefix="/api/v1/notifications", tags=["Notifications"])


@router.get("/", response_model=list[NotificationResponse])
async def get_my_notifications(
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Get recent notifications for the authenticated user."""
    notifications = await repo.get_notifications_for_user(db, current_user_id)
    return notifications


@router.post("/{notification_id}/read", response_model=NotificationResponse)
async def mark_notification_as_read(
    notification_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user_id: uuid.UUID = Depends(get_current_user_id),
):
    """Mark a specific notification as read."""
    notification = await repo.mark_notification_read(db, notification_id, current_user_id)
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found or unauthorized")
    return notification
