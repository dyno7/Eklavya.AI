---
phase: 1
plan: 2
wave: 1
---

# Plan 1.2: SQLAlchemy Models & Pydantic Schemas

## Objective
Create SQLAlchemy 2.0 ORM models that map to the 4 core database tables, plus Pydantic v2 schemas for API request/response validation. SA models = database, Pydantic schemas = API contract. Kept separate by design.

## Context
- .gsd/phases/1/1-PLAN.md — SQL schema (tables this maps to), database.py (Base class)
- .gsd/DECISIONS.md — ADR-007 (SQLAlchemy), ADR-005 (no gamification)
- eklavya_backend/app/domain/ — Empty directory to populate

## Tasks

<task type="auto">
  <name>Create SQLAlchemy ORM models</name>
  <files>
    eklavya_backend/app/domain/models.py
    eklavya_backend/app/domain/enums.py
    eklavya_backend/app/domain/__init__.py
  </files>
  <action>
    1. Create `enums.py` with Python enums (str, Enum mixin):
       - `Domain` — learning, fitness, startup, finance, writing
       - `GoalStatus` — active, paused, completed, abandoned
       - `MilestoneStatus` — locked, active, completed
       - `TaskStatus` — pending, in_progress, completed, skipped
       - `TaskType` — read, watch, practice, quiz, custom

    2. Create `models.py` with SQLAlchemy 2.0 mapped classes:

       **User:**
       - `__tablename__ = "users"`
       - `id: Mapped[uuid.UUID]` (PK)
       - `display_name: Mapped[str]`
       - `avatar_url: Mapped[Optional[str]]`
       - `created_at: Mapped[datetime]`
       - `updated_at: Mapped[datetime]`
       - `goals: Mapped[list["Goal"]]` (relationship, back_populates)

       **Goal:**
       - `__tablename__ = "goals"`
       - `id: Mapped[uuid.UUID]` (PK, default uuid4)
       - `user_id: Mapped[uuid.UUID]` (FK→users.id)
       - `domain: Mapped[Domain]` (SA Enum type)
       - `title: Mapped[str]`
       - `description: Mapped[str]`
       - `target_date: Mapped[Optional[date]]`
       - `metadata_: Mapped[dict]` (Column name "metadata", JSONB)
       - `status: Mapped[GoalStatus]` (default active)
       - `created_at, updated_at`
       - `user: Mapped["User"]` (relationship)
       - `milestones: Mapped[list["Milestone"]]` (relationship)

       **Milestone:**
       - Similar pattern with `goal_id` FK, `order_index`, `status`
       - `tasks: Mapped[list["Task"]]` (relationship)

       **Task:**
       - `milestone_id` FK, `task_type`, `xp_reward`, `order_index`, `status`, `due_date`, `completed_at`
       - `metadata_: Mapped[dict]` (JSONB)

       Use:
       - `from app.core.database import Base`
       - `from sqlalchemy.orm import Mapped, mapped_column, relationship`
       - `from sqlalchemy import String, Integer, DateTime, Date, ForeignKey, Enum as SAEnum, JSON`
       - `server_default=text("gen_random_uuid()")` for UUID PKs
       - `server_default=text("now()")` for timestamps

    3. Create `__init__.py` exporting all models and enums

    What to avoid and WHY:
    - Do NOT use SA column-based syntax (old style) — Mapped type annotations are SA 2.0 standard (Standardized Work)
    - Do NOT add gamification models — deferred to Phase 4 (ADR-005)
    - Do NOT use `metadata` as a Python attribute name — conflicts with SA's Base.metadata. Use `metadata_` mapped to column "metadata"
  </action>
  <verify>uv run python -c "from app.domain.models import User, Goal, Milestone, Task; from app.domain.enums import Domain; print('Models OK')"</verify>
  <done>4 SQLAlchemy models with relationships, 5 enum classes, all imports work</done>
</task>

<task type="auto">
  <name>Create Pydantic API schemas</name>
  <files>
    eklavya_backend/app/domain/schemas.py
  </files>
  <action>
    Create Pydantic v2 models in `schemas.py` following Create/Response/Update pattern:

    **UserResponse** — id, display_name, avatar_url, created_at

    **GoalCreate** — title, description, domain (Domain enum), target_date (optional), metadata (dict, default {})
    **GoalResponse** — id, user_id, domain, title, description, target_date, metadata, status, created_at, updated_at
    **GoalUpdate** — title (optional), description (optional), status (optional), target_date (optional)

    **MilestoneCreate** — goal_id, title, description, order_index
    **MilestoneResponse** — id, goal_id, title, description, order_index, status, created_at

    **TaskCreate** — milestone_id, title, description, task_type, xp_reward (default 10), metadata (dict, default {}), due_date (optional)
    **TaskResponse** — id, milestone_id, title, description, task_type, xp_reward, metadata, order_index, status, due_date, completed_at, created_at
    **TaskStatusUpdate** — status (TaskStatus enum)

    Use:
    - `model_config = ConfigDict(from_attributes=True)` on all Response models (for SA model → Pydantic conversion)
    - `Field(default=10, ge=0)` for xp_reward validation
    - Reuse enums from `app.domain.enums`

    What to avoid and WHY:
    - Do NOT merge SA models and Pydantic schemas — they serve different purposes (Standardized Work)
    - Do NOT add computed fields requiring DB aggregation — those are service-layer concerns
  </action>
  <verify>uv run python -c "from app.domain.schemas import GoalCreate, GoalResponse, TaskStatusUpdate; print('Schemas OK')"</verify>
  <done>All Pydantic schemas exist with Create/Response/Update pattern, from_attributes=True enabled</done>
</task>

## Success Criteria
- [ ] 5 enum classes in enums.py serialize as strings
- [ ] 4 SQLAlchemy models with proper relationships and Mapped types
- [ ] All Pydantic schemas follow Create/Response/Update pattern
- [ ] `from_attributes=True` enables SA model → Pydantic conversion
