"""
SQLAlchemy 2.0 ORM models for the Eklavya.AI core schema.
Maps to the 4 core tables: users, goals, milestones, tasks.
"""

import uuid
from datetime import date, datetime
from typing import Optional

from sqlalchemy import (
    Date,
    DateTime,
    Enum as SAEnum,
    ForeignKey,
    Integer,
    String,
    Text,
    text,
)
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.domain.enums import (
    Domain,
    GoalStatus,
    MilestoneStatus,
    TaskStatus,
    TaskType,
)


class User(Base):
    """Application user profile linked to Supabase Auth."""

    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True
    )
    display_name: Mapped[str] = mapped_column(
        String(255), default="", server_default=text("''")
    )
    avatar_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    total_xp: Mapped[int] = mapped_column(
        Integer, default=0, server_default=text("0")
    )
    current_streak: Mapped[int] = mapped_column(
        Integer, default=0, server_default=text("0")
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )

    # Relationships
    goals: Mapped[list["Goal"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<User {self.id} '{self.display_name}'>"


class Goal(Base):
    """A user's high-level objective in a specific domain."""

    __tablename__ = "goals"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()")
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    domain: Mapped[Domain] = mapped_column(
        SAEnum(Domain, name="domain_type", create_type=False)
    )
    title: Mapped[str] = mapped_column(String(500))
    description: Mapped[str] = mapped_column(Text, default="", server_default=text("''"))
    target_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    metadata_: Mapped[dict] = mapped_column(
        "metadata", JSON, default=dict, server_default=text("'{}'::jsonb")
    )
    status: Mapped[GoalStatus] = mapped_column(
        SAEnum(GoalStatus, name="goal_status", create_type=False),
        default=GoalStatus.ACTIVE,
        server_default=text("'active'"),
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )

    # Relationships
    user: Mapped["User"] = relationship(back_populates="goals")
    milestones: Mapped[list["Milestone"]] = relationship(
        back_populates="goal", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<Goal {self.id} '{self.title}' [{self.domain.value}]>"


class Milestone(Base):
    """An ordered checkpoint within a goal."""

    __tablename__ = "milestones"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()")
    )
    goal_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("goals.id", ondelete="CASCADE"), index=True
    )
    title: Mapped[str] = mapped_column(String(500))
    description: Mapped[str] = mapped_column(Text, default="", server_default=text("''"))
    order_index: Mapped[int] = mapped_column(Integer, default=0, server_default=text("0"))
    status: Mapped[MilestoneStatus] = mapped_column(
        SAEnum(MilestoneStatus, name="milestone_status", create_type=False),
        default=MilestoneStatus.LOCKED,
        server_default=text("'locked'"),
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )

    # Relationships
    goal: Mapped["Goal"] = relationship(back_populates="milestones")
    tasks: Mapped[list["Task"]] = relationship(
        back_populates="milestone", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<Milestone {self.id} #{self.order_index} '{self.title}'>"


class Task(Base):
    """An individual actionable item within a milestone."""

    __tablename__ = "tasks"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()")
    )
    milestone_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("milestones.id", ondelete="CASCADE"), index=True
    )
    title: Mapped[str] = mapped_column(String(500))
    description: Mapped[str] = mapped_column(Text, default="", server_default=text("''"))
    task_type: Mapped[TaskType] = mapped_column(
        SAEnum(TaskType, name="task_type", create_type=False),
        default=TaskType.CUSTOM,
        server_default=text("'custom'"),
    )
    metadata_: Mapped[dict] = mapped_column(
        "metadata", JSON, default=dict, server_default=text("'{}'::jsonb")
    )
    xp_reward: Mapped[int] = mapped_column(
        Integer, default=10, server_default=text("10")
    )
    order_index: Mapped[int] = mapped_column(Integer, default=0, server_default=text("0"))
    status: Mapped[TaskStatus] = mapped_column(
        SAEnum(TaskStatus, name="task_status", create_type=False),
        default=TaskStatus.PENDING,
        server_default=text("'pending'"),
    )
    due_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    completed_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )

    # Relationships
    milestone: Mapped["Milestone"] = relationship(back_populates="tasks")

    def __repr__(self) -> str:
        return f"<Task {self.id} '{self.title}' [{self.status.value}]>"
