---
phase: 1
plan: 3
wave: 2
---

# Plan 1.3: API Routers & Repository Layer

## Objective
Build the full REST API surface (CRUD routers for Goals, Milestones, Tasks, Users) and a repository layer that uses SQLAlchemy async sessions. Wave 2 — depends on Plans 1.1 (database setup) and 1.2 (models + schemas).

## Context
- .gsd/phases/1/1-PLAN.md — database.py with get_db() dependency
- .gsd/phases/1/2-PLAN.md — SA models + Pydantic schemas
- .gsd/DECISIONS.md — ADR-006 (full API surface), ADR-007 (SQLAlchemy)
- eklavya_backend/app/presentation/ — Empty, will hold routers
- eklavya_backend/app/core/ — Will hold repositories

## Tasks

<task type="auto">
  <name>Create repository layer (SQLAlchemy async data access)</name>
  <files>
    eklavya_backend/app/core/repositories.py
  </files>
  <action>
    Create async repository functions that use SQLAlchemy `AsyncSession`:

    **Goals:**
    - `async create_goal(db: AsyncSession, user_id: UUID, data: GoalCreate) → Goal`
    - `async get_goals_for_user(db: AsyncSession, user_id: UUID) → list[Goal]`
    - `async get_goal_by_id(db: AsyncSession, goal_id: UUID) → Goal | None`
    - `async update_goal(db: AsyncSession, goal_id: UUID, data: GoalUpdate) → Goal`

    **Milestones:**
    - `async create_milestone(db: AsyncSession, data: MilestoneCreate) → Milestone`
    - `async get_milestones_for_goal(db: AsyncSession, goal_id: UUID) → list[Milestone]`

    **Tasks:**
    - `async create_task(db: AsyncSession, data: TaskCreate) → Task`
    - `async get_tasks_for_milestone(db: AsyncSession, milestone_id: UUID) → list[Task]`
    - `async get_task_by_id(db: AsyncSession, task_id: UUID) → Task | None`
    - `async update_task_status(db: AsyncSession, task_id: UUID, status: TaskStatus, completed_at: datetime | None) → Task`

    **Users:**
    - `async get_user_profile(db: AsyncSession, user_id: UUID) → User | None`
    - `async upsert_user_profile(db: AsyncSession, user_id: UUID, display_name: str, avatar_url: str | None) → User`

    Patterns:
    - Use `select(Model).where(...)` with `await db.execute(stmt)`
    - Use `db.add(instance)` + `await db.commit()` + `await db.refresh(instance)` for creates
    - Use `sqlalchemy.update(Model).where(...).values(...)` for updates
    - Return SA model instances (Pydantic conversion happens in router via `from_attributes=True`)

    What to avoid and WHY:
    - Do NOT create abstract base repositories — 4 entities don't justify the abstraction (Kaizen: YAGNI)
    - Do NOT catch exceptions here — let FastAPI exception handlers manage them (Poka-Yoke: fail fast)
    - Do NOT add pagination — YAGNI for MVP, easy to add later
  </action>
  <verify>uv run python -c "from app.core.repositories import create_goal, get_goals_for_user, upsert_user_profile; print('Repos OK')"</verify>
  <done>~12 async repository functions exist, all using SQLAlchemy AsyncSession</done>
</task>

<task type="auto">
  <name>Create API routers and wire into main.py</name>
  <files>
    eklavya_backend/app/presentation/goals.py
    eklavya_backend/app/presentation/tasks.py
    eklavya_backend/app/presentation/users.py
    eklavya_backend/app/presentation/__init__.py
    eklavya_backend/app/main.py
  </files>
  <action>
    Create 3 router modules:

    **goals.py** (prefix: `/api/v1/goals`):
    - `POST /` → Create a new goal (GoalCreate → GoalResponse, 201)
    - `GET /` → List user's goals (→ list[GoalResponse])
    - `GET /{goal_id}` → Get goal detail (→ GoalResponse, 404 if missing)
    - `PATCH /{goal_id}` → Update goal (GoalUpdate → GoalResponse)
    - `POST /{goal_id}/milestones` → Add milestone (MilestoneCreate → MilestoneResponse, 201)
    - `GET /{goal_id}/milestones` → List milestones (→ list[MilestoneResponse])

    **tasks.py** (prefix: `/api/v1/tasks`):
    - `POST /` → Create task (TaskCreate → TaskResponse, 201)
    - `GET /milestone/{milestone_id}` → List tasks for milestone (→ list[TaskResponse])
    - `GET /{task_id}` → Get single task (→ TaskResponse, 404)
    - `PATCH /{task_id}/status` → Update status (TaskStatusUpdate → TaskResponse)

    **users.py** (prefix: `/api/v1/users`):
    - `GET /me` → Get current user profile (→ UserResponse)
    - `PATCH /me` → Update display name, avatar (→ UserResponse)

    For each endpoint:
    - Inject `db: AsyncSession = Depends(get_db)` from database.py
    - Inject `current_user_id: UUID = Depends(get_current_user_id)` — **stub for now** (returns a hardcoded UUID in dev mode). Real auth in Plan 1.4.
    - Use response_model for Pydantic auto-serialization
    - Return proper status codes (201 for create, 404 for not found)

    Update `main.py`:
    - Import and `app.include_router()` all 3 routers
    - Add lifespan event to create tables on startup (using `Base.metadata.create_all`)

    What to avoid and WHY:
    - Do NOT implement real auth yet — Plan 1.4 (incremental delivery)
    - Do NOT add gamification endpoints — Phase 4
    - Do NOT add middleware — premature (Kaizen: JIT)
  </action>
  <verify>
    uv run python -c "from app.main import app; routes = [r.path for r in app.routes]; print([r for r in routes if '/api/' in r])"
  </verify>
  <done>3 routers with 12 endpoints registered in main.py under /api/v1</done>
</task>

## Success Criteria
- [ ] ~12 async repository functions using SQLAlchemy AsyncSession
- [ ] 3 API routers with 12 endpoints (goals: 6, tasks: 4, users: 2)
- [ ] All routers registered in main.py under /api/v1
- [ ] Pydantic response_model on all endpoints for auto-serialization
