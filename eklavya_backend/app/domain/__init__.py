"""Domain package — enums, SQLAlchemy models, and Pydantic schemas."""

from app.domain.enums import (
    Domain,
    GoalStatus,
    MilestoneStatus,
    TaskStatus,
    TaskType,
)
from app.domain.models import Goal, Milestone, Task, User
from app.domain.schemas import (
    GoalCreate,
    GoalResponse,
    GoalUpdate,
    MilestoneCreate,
    MilestoneResponse,
    TaskCreate,
    TaskResponse,
    TaskStatusUpdate,
    UserResponse,
    UserUpdate,
)

__all__ = [
    # Enums
    "Domain",
    "GoalStatus",
    "MilestoneStatus",
    "TaskStatus",
    "TaskType",
    # Models
    "Goal",
    "Milestone",
    "Task",
    "User",
    # Schemas
    "GoalCreate",
    "GoalResponse",
    "GoalUpdate",
    "MilestoneCreate",
    "MilestoneResponse",
    "TaskCreate",
    "TaskResponse",
    "TaskStatusUpdate",
    "UserResponse",
    "UserUpdate",
]
