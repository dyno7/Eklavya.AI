"""
Repository layer — async data access functions using SQLAlchemy.
Each function takes an AsyncSession and returns SA model instances.
Pydantic conversion happens in the router layer via from_attributes=True.
"""

import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import select, update, outerjoin, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.enums import TaskStatus
from app.domain.models import Badge, Goal, Milestone, Notification, Task, User, UserBadge


# ─── Users ─────────────────────────────────────────────────────

async def get_user_profile(db: AsyncSession, user_id: uuid.UUID) -> Optional[User]:
    """Get a user profile by ID. Returns None if not found."""
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()


async def upsert_user_profile(
    db: AsyncSession,
    user_id: uuid.UUID,
    display_name: str,
    avatar_url: Optional[str] = None,
) -> User:
    """Create or update a user profile. Used on first login / profile update."""
    user = await get_user_profile(db, user_id)
    if user is None:
        user = User(id=user_id, display_name=display_name, avatar_url=avatar_url)
        db.add(user)
    else:
        user.display_name = display_name
        if avatar_url is not None:
            user.avatar_url = avatar_url
        user.updated_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(user)
    return user


# ─── Goals ─────────────────────────────────────────────────────

async def create_goal(
    db: AsyncSession,
    user_id: uuid.UUID,
    title: str,
    description: str,
    domain: str,
    target_date=None,
    metadata_: Optional[dict] = None,
) -> Goal:
    """Create a new goal for a user."""
    goal = Goal(
        user_id=user_id,
        title=title,
        description=description,
        domain=domain,
        target_date=target_date,
        metadata_=metadata_ or {},
    )
    db.add(goal)
    await db.commit()
    await db.refresh(goal)
    return goal


async def get_goals_for_user(db: AsyncSession, user_id: uuid.UUID) -> list[Goal]:
    """List all goals for a user, ordered by creation date (newest first)."""
    result = await db.execute(
        select(Goal)
        .where(Goal.user_id == user_id)
        .order_by(Goal.created_at.desc())
    )
    return list(result.scalars().all())


async def get_goal_by_id(db: AsyncSession, goal_id: uuid.UUID) -> Optional[Goal]:
    """Get a single goal by ID."""
    result = await db.execute(select(Goal).where(Goal.id == goal_id))
    return result.scalar_one_or_none()


async def update_goal(
    db: AsyncSession,
    goal_id: uuid.UUID,
    **kwargs,
) -> Optional[Goal]:
    """Update goal fields. Only updates provided non-None fields."""
    update_data = {k: v for k, v in kwargs.items() if v is not None}
    if not update_data:
        return await get_goal_by_id(db, goal_id)

    update_data["updated_at"] = datetime.now(timezone.utc)
    await db.execute(
        update(Goal).where(Goal.id == goal_id).values(**update_data)
    )
    await db.commit()
    return await get_goal_by_id(db, goal_id)


# ─── Milestones ────────────────────────────────────────────────

async def create_milestone(
    db: AsyncSession,
    goal_id: uuid.UUID,
    title: str,
    description: str = "",
    order_index: int = 0,
) -> Milestone:
    """Create a new milestone under a goal."""
    milestone = Milestone(
        goal_id=goal_id,
        title=title,
        description=description,
        order_index=order_index,
    )
    db.add(milestone)
    await db.commit()
    await db.refresh(milestone)
    return milestone


async def get_milestones_for_goal(
    db: AsyncSession, goal_id: uuid.UUID
) -> list[Milestone]:
    """List milestones for a goal, ordered by order_index."""
    result = await db.execute(
        select(Milestone)
        .where(Milestone.goal_id == goal_id)
        .order_by(Milestone.order_index)
    )
    return list(result.scalars().all())


# ─── Tasks ─────────────────────────────────────────────────────

async def create_task(
    db: AsyncSession,
    milestone_id: uuid.UUID,
    title: str,
    description: str = "",
    task_type: str = "custom",
    xp_reward: int = 10,
    metadata_: Optional[dict] = None,
    due_date=None,
    order_index: int = 0,
) -> Task:
    """Create a new task under a milestone."""
    task = Task(
        milestone_id=milestone_id,
        title=title,
        description=description,
        task_type=task_type,
        xp_reward=xp_reward,
        metadata_=metadata_ or {},
        due_date=due_date,
        order_index=order_index,
    )
    db.add(task)
    await db.commit()
    await db.refresh(task)
    return task


async def get_tasks_for_milestone(
    db: AsyncSession, milestone_id: uuid.UUID
) -> list[Task]:
    """List tasks for a milestone, ordered by order_index."""
    result = await db.execute(
        select(Task)
        .where(Task.milestone_id == milestone_id)
        .order_by(Task.order_index)
    )
    return list(result.scalars().all())


async def get_task_by_id(db: AsyncSession, task_id: uuid.UUID) -> Optional[Task]:
    """Get a single task by ID."""
    result = await db.execute(select(Task).where(Task.id == task_id))
    return result.scalar_one_or_none()


async def update_task_status(
    db: AsyncSession,
    task_id: uuid.UUID,
    status: TaskStatus,
) -> Optional[Task]:
    """Update task status. Auto-sets completed_at when status is COMPLETED."""
    update_data: dict = {"status": status}
    if status == TaskStatus.COMPLETED:
        update_data["completed_at"] = datetime.now(timezone.utc)
    elif status != TaskStatus.COMPLETED:
        update_data["completed_at"] = None

    await db.execute(
        update(Task).where(Task.id == task_id).values(**update_data)
    )
    await db.commit()
    return await get_task_by_id(db, task_id)


# ─── Badges ───────────────────────────────────────────────────

async def get_user_badges_status(db: AsyncSession, user_id: uuid.UUID) -> list[dict]:
    """
    Get all available badges from the system, along with a boolean indicating
    if the specified user has earned them, and when.
    Returns a list of dicts matching the BadgeResponse schema.
    """
    # Query: SELECT b.*, ub.earned_at FROM badges b LEFT JOIN user_badges ub ON b.id = ub.badge_id AND ub.user_id = :user_id
    stmt = (
        select(Badge, UserBadge.earned_at)
        .outerjoin(
            UserBadge,
            (Badge.id == UserBadge.badge_id) & (UserBadge.user_id == user_id)
        )
        .order_by(Badge.required_xp.asc())
    )
    result = await db.execute(stmt)
    rows = result.all()
    
    response_list = []
    for badge, earned_at in rows:
        response_list.append({
            "id": badge.id,
            "name": badge.name,
            "description": badge.description,
            "icon_url": badge.icon_url,
            "required_xp": badge.required_xp,
            "is_earned": earned_at is not None,
            "earned_at": earned_at
        })
    return response_list


# ─── Notifications ────────────────────────────────────────────

async def get_notifications_for_user(db: AsyncSession, user_id: uuid.UUID, limit: int = 50) -> list[Notification]:
    """Get recent notifications for a user, newest first."""
    result = await db.execute(
        select(Notification)
        .where(Notification.user_id == user_id)
        .order_by(Notification.created_at.desc())
        .limit(limit)
    )
    return list(result.scalars().all())

async def mark_notification_read(db: AsyncSession, notification_id: uuid.UUID, user_id: uuid.UUID) -> Optional[Notification]:
    """Mark a specific notification as read. Validates user ownership."""
    stmt = (
        update(Notification)
        .where((Notification.id == notification_id) & (Notification.user_id == user_id))
        .values(read_status=True)
        .returning(Notification)
    )
    result = await db.execute(stmt)
    await db.commit()
    return result.scalar_one_or_none()
