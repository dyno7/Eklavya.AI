---
phase: 7
plan: 1
wave: 1
depends_on: []
autonomous: true
files_modified:
  - eklavya_backend/alembic.ini
  - eklavya_backend/alembic/env.py
  - eklavya_backend/alembic/versions/001_add_gamification_fields.py
---

# Plan 7.1: Database Migration — Alembic Init & Apply

## Objective
The `users` table is missing the `total_xp` and `current_streak` columns added in Phase 6 to the SQLAlchemy model. Without them, every DB write fails with a `column does not exist` error. This plan initialises Alembic for the project and creates + applies a migration to add those columns.

## Context
- eklavya_backend/app/domain/models.py
- eklavya_backend/app/core/database.py
- eklavya_backend/pyproject.toml

## Tasks

<task type="auto">
  <name>Initialise Alembic and configure it for async SQLAlchemy</name>
  <files>
    eklavya_backend/alembic.ini
    eklavya_backend/alembic/env.py
  </files>
  <action>
    1. Inside `eklavya_backend/`, run:
       `uv run alembic init alembic`
    2. Edit `alembic.ini`:
       - Set `script_location = alembic`
       - Leave `sqlalchemy.url` blank (we override it in env.py)
    3. Edit `alembic/env.py`:
       - Import `asyncio`, `app.core.database.Base`, `app.core.config.get_settings`
       - Set `target_metadata = Base.metadata`
       - Override `get_url()` to return `get_settings().DATABASE_URL`
       - Use the async runner pattern:
         ```python
         def run_migrations_online():
             connectable = create_async_engine(get_url())
             async def run_async_migrations():
                 async with connectable.connect() as conn:
                     await conn.run_sync(do_run_migrations)
             asyncio.run(run_async_migrations())
         ```
    4. Add `alembic` to `pyproject.toml` dev dependencies if not present.
  </action>
  <verify>uv run alembic current (should not error even if no migrations yet)</verify>
  <done>Alembic is initialised and connected to the database</done>
</task>

<task type="auto">
  <name>Create and apply migration for total_xp and current_streak columns</name>
  <files>
    eklavya_backend/alembic/versions/001_add_gamification_fields.py
  </files>
  <action>
    1. Run autogenerate:
       `uv run alembic revision --autogenerate -m "add_gamification_fields"`
    2. Review the generated file — it should add:
       - `total_xp INTEGER NOT NULL DEFAULT 0`
       - `current_streak INTEGER NOT NULL DEFAULT 0`
       to the `users` table.
    3. If autogenerate misses them (it sometimes does with server_default), hand-write:
       ```python
       def upgrade():
           op.add_column('users', sa.Column('total_xp', sa.Integer(), nullable=False, server_default='0'))
           op.add_column('users', sa.Column('current_streak', sa.Integer(), nullable=False, server_default='0'))
       def downgrade():
           op.drop_column('users', 'current_streak')
           op.drop_column('users', 'total_xp')
       ```
    4. Apply: `uv run alembic upgrade head`
  </action>
  <verify>uv run alembic current (should show the migration as applied, e.g. "001_add_gamification_fields (head)")</verify>
  <done>Supabase DB has total_xp and current_streak columns in the users table</done>
</task>

## Success Criteria
- [ ] `uv run alembic current` shows a version applied
- [ ] `uv run uvicorn app.main:app` starts without SQLAlchemy column errors
- [ ] `curl http://localhost:8000/health` returns 200
