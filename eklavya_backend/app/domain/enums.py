"""
Python enums mirroring PostgreSQL enum types.
All enums use (str, Enum) mixin for JSON serialization as strings.
"""

from enum import Enum


class Domain(str, Enum):
    """Goal domains — determines AI prompt templates and task types."""
    LEARNING = "learning"
    FITNESS = "fitness"
    STARTUP = "startup"
    FINANCE = "finance"
    WRITING = "writing"


class GoalStatus(str, Enum):
    """Lifecycle status of a goal."""
    ACTIVE = "active"
    PAUSED = "paused"
    COMPLETED = "completed"
    ABANDONED = "abandoned"


class MilestoneStatus(str, Enum):
    """Progression status of a milestone within a goal."""
    LOCKED = "locked"
    ACTIVE = "active"
    COMPLETED = "completed"


class TaskStatus(str, Enum):
    """Completion status of an individual task."""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    SKIPPED = "skipped"


class TaskType(str, Enum):
    """Type of task — determines how the task is presented in the UI."""
    READ = "read"
    WATCH = "watch"
    PRACTICE = "practice"
    QUIZ = "quiz"
    WRITE = "write"
    EXERCISE = "exercise"
    CUSTOM = "custom"
