"""
Pydantic v2 schemas for API request/response validation.
Separate from SQLAlchemy models — schemas are the API contract,
models are the database mapping.

Pattern: {Entity}Create (input), {Entity}Response (output), {Entity}Update (patch).
"""

from datetime import date, datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.domain.enums import (
    Domain,
    GoalStatus,
    MilestoneStatus,
    TaskStatus,
    TaskType,
)


# ─── User ─────────────────────────────────────────────────────

class UserResponse(BaseModel):
    """User profile returned from API."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    display_name: str
    avatar_url: Optional[str] = None
    total_xp: int = 0
    current_streak: int = 0
    created_at: datetime


class UserUpdate(BaseModel):
    """Fields the user can update on their own profile."""
    display_name: Optional[str] = Field(None, max_length=255)
    avatar_url: Optional[str] = None


# ─── Goal ─────────────────────────────────────────────────────

class GoalCreate(BaseModel):
    """Create a new goal."""
    title: str = Field(..., max_length=500)
    description: str = Field(default="", max_length=5000)
    domain: Domain
    target_date: Optional[date] = None
    metadata: dict = Field(default_factory=dict, alias="metadata_")

    model_config = ConfigDict(populate_by_name=True)


class GoalResponse(BaseModel):
    """Goal returned from API."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    domain: Domain
    title: str
    description: str
    target_date: Optional[date] = None
    metadata_: dict = Field(default_factory=dict)
    status: GoalStatus
    created_at: datetime
    updated_at: datetime


class GoalUpdate(BaseModel):
    """Partial update for a goal."""
    title: Optional[str] = Field(None, max_length=500)
    description: Optional[str] = Field(None, max_length=5000)
    status: Optional[GoalStatus] = None
    target_date: Optional[date] = None


# ─── Milestone ────────────────────────────────────────────────

class MilestoneCreate(BaseModel):
    """Create a new milestone under a goal."""
    goal_id: UUID
    title: str = Field(..., max_length=500)
    description: str = Field(default="", max_length=5000)
    order_index: int = Field(default=0, ge=0)


class MilestoneResponse(BaseModel):
    """Milestone returned from API."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    goal_id: UUID
    title: str
    description: str
    order_index: int
    status: MilestoneStatus
    created_at: datetime


# ─── Task ─────────────────────────────────────────────────────

class TaskCreate(BaseModel):
    """Create a new task under a milestone."""
    milestone_id: UUID
    title: str = Field(..., max_length=500)
    description: str = Field(default="", max_length=5000)
    task_type: TaskType = TaskType.CUSTOM
    xp_reward: int = Field(default=10, ge=0)
    metadata: dict = Field(default_factory=dict, alias="metadata_")
    due_date: Optional[date] = None

    model_config = ConfigDict(populate_by_name=True)


class TaskResponse(BaseModel):
    """Task returned from API."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    milestone_id: UUID
    title: str
    description: str
    task_type: TaskType
    metadata_: dict = Field(default_factory=dict)
    xp_reward: int
    order_index: int
    status: TaskStatus
    due_date: Optional[date] = None
    completed_at: Optional[datetime] = None
    created_at: datetime


class TaskStatusUpdate(BaseModel):
    """Update only the status of a task."""
    status: TaskStatus


# ─── Badges ───────────────────────────────────────────────────

class BadgeResponse(BaseModel):
    """A badge with user-specific earned status."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    description: str
    icon_url: Optional[str] = None
    required_xp: int
    is_earned: bool = False
    earned_at: Optional[datetime] = None


# ─── Notifications ────────────────────────────────────────────

class NotificationResponse(BaseModel):
    """System notification for a user."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    title: str
    message: str
    type: str # 'level_up', 'badge_earned', 'reminder'
    read_status: bool
    created_at: datetime

