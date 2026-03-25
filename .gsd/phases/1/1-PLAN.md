---
phase: 1
plan: 1
wave: 1
---

# Plan 1.1: Project Setup & Database Schema

## Objective
Initialize the Python project with uv + pyproject.toml, create the Supabase PostgreSQL schema (core tables only — no gamification), and set up Alembic for migrations. Set up the backend config to connect to Supabase via SQLAlchemy async.

## Context
- .gsd/SPEC.md — Multi-domain goals, thin client arch
- .gsd/DECISIONS.md — ADR-005 (defer gamification), ADR-007 (SQLAlchemy), ADR-008 (uv)
- .gsd/phases/1/RESEARCH.md — SQLAlchemy stack, schema design
- eklavya_backend/ — Current directory with bare main.py

## Tasks

<task type="auto">
  <name>Initialize uv project and install dependencies</name>
  <files>
    eklavya_backend/pyproject.toml
    eklavya_backend/.python-version
  </files>
  <action>
    1. Navigate to `eklavya_backend/`
    2. Run `uv init` to create pyproject.toml (if not exists, otherwise create manually)
    3. Configure pyproject.toml with:
       - name: "eklavya-backend"
       - version: "0.1.0"
       - requires-python: ">=3.11"
    4. Add dependencies via `uv add`:
       ```
       fastapi
       uvicorn[standard]
       sqlalchemy[asyncio]
       asyncpg
       alembic
       pydantic
       pydantic-settings
       python-jose[cryptography]
       python-dotenv
       httpx
       ```
    5. Delete the old `requirements.txt`
    6. Create `.python-version` file with "3.11" or "3.12"

    What to avoid and WHY:
    - Do NOT keep requirements.txt alongside pyproject.toml — single source of truth (Standardized Work)
    - Do NOT pin exact versions — let uv lockfile handle that (Kaizen: simplest thing that works)
  </action>
  <verify>uv sync && uv run python -c "import fastapi, sqlalchemy, asyncpg; print('All deps OK')"</verify>
  <done>pyproject.toml exists with all deps, `uv sync` succeeds, imports work</done>
</task>

<task type="auto">
  <name>Create SQL migration and backend config</name>
  <files>
    eklavya_backend/migrations/001_initial_schema.sql
    eklavya_backend/app/core/config.py
    eklavya_backend/app/core/database.py
    eklavya_backend/app/core/__init__.py
    eklavya_backend/.env.example
  </files>
  <action>
    1. **Create SQL migration** (`migrations/001_initial_schema.sql`):
       - Enum types: `domain_type` (learning, fitness, startup, finance, writing), `goal_status` (active, paused, completed, abandoned), `milestone_status` (locked, active, completed), `task_status` (pending, in_progress, completed, skipped), `task_type` (read, watch, practice, quiz, custom)
       - **users** — `id` (UUID PK, references auth.users), `display_name` (VARCHAR), `avatar_url` (TEXT nullable), `created_at`, `updated_at`
       - **goals** — `id` (UUID PK, gen_random_uuid()), `user_id` (FK→users, ON DELETE CASCADE), `domain` (domain_type), `title`, `description` (TEXT), `target_date` (DATE nullable), `metadata` (JSONB DEFAULT '{}'), `status` (goal_status DEFAULT 'active'), `created_at`, `updated_at`
       - **milestones** — `id` (UUID PK), `goal_id` (FK→goals CASCADE), `title`, `description`, `order_index` (INT), `status` (milestone_status DEFAULT 'locked'), `created_at`
       - **tasks** — `id` (UUID PK), `milestone_id` (FK→milestones CASCADE), `title`, `description`, `task_type` (task_type DEFAULT 'custom'), `metadata` (JSONB DEFAULT '{}'), `xp_reward` (INT DEFAULT 10), `order_index` (INT), `status` (task_status DEFAULT 'pending'), `due_date` (DATE nullable), `completed_at` (TIMESTAMPTZ nullable), `created_at`
       - Indexes on all FK columns + (goals.user_id, goals.status) composite
       - Table comments explaining purpose

    2. **Create config.py** (Pydantic Settings):
       - `DATABASE_URL` (str, required — Supabase PostgreSQL connection string)
       - `SUPABASE_URL` (str, required — for auth operations)
       - `SUPABASE_ANON_KEY` (str, required)
       - `JWT_SECRET` (str, required — Supabase JWT secret)
       - `ENVIRONMENT` (str, default "development")
       - Singleton via `@lru_cache`

    3. **Create database.py** (SQLAlchemy async engine + session):
       - `create_async_engine(settings.DATABASE_URL)` with asyncpg
       - `async_sessionmaker` bound to the engine
       - `async def get_db()` — FastAPI dependency that yields `AsyncSession`
       - `Base = DeclarativeBase()` — base class for all models

    4. **Create .env.example** with all required vars + comments explaining where to find each value in Supabase dashboard

    What to avoid and WHY:
    - Do NOT add gamification tables — deferred to Phase 4 (ADR-005)
    - Do NOT add RLS policies — deferred (ADR-010)
    - Do NOT use sync engine — we want full async performance (Poka-Yoke)
  </action>
  <verify>uv run python -c "from app.core.config import get_settings; from app.core.database import Base, get_db; print('Config + DB OK')"</verify>
  <done>SQL migration has 4 core tables, config loads from .env, async engine + session factory ready</done>
</task>

## Success Criteria
- [ ] pyproject.toml with all dependencies, `uv sync` succeeds
- [ ] SQL migration file with 4 tables + 5 enum types
- [ ] Config loads DATABASE_URL, SUPABASE_URL, JWT_SECRET from .env
- [ ] Async SQLAlchemy engine and session factory created
- [ ] .env.example documents all required vars
