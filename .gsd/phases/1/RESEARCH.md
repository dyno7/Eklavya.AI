# Phase 1 Research — Foundation & Database

> **Discovery Level**: 2 (Standard Research)
> Architecture shifted from Supabase-py client to SQLAlchemy/asyncpg (ADR-007). Needs dependency + pattern verification.

## Key Technical Decisions

| Decision | Choice | Reference |
|----------|--------|-----------|
| Database | Supabase (PostgreSQL) — direct connection | ADR-003, ADR-007 |
| Data Access | SQLAlchemy 2.0 async + asyncpg | ADR-007 |
| Backend | Python / FastAPI | ADR-002 |
| Auth | Supabase Auth (JWT verified in backend) | ADR-003 |
| Project Mgmt | uv + pyproject.toml | ADR-008 |
| Validation | Pydantic v2 models | — |

## Schema Design

### Core Tables Only (Gamification deferred to Phase 4 — ADR-005)
```
users → goals (has domain enum) → milestones → tasks
```

**4 tables + enum types.** Domain-specific metadata lives in JSONB fields.

### Deferred to Phase 4
- `user_xp_log`, `badges`, `user_badges`, `user_streaks`

### No RLS (ADR-010)
Backend JWT auth + user_id scoping provides equivalent security under Thin Client architecture.

## SQLAlchemy 2.0 Async Stack

```
FastAPI ↔ SQLAlchemy 2.0 (async) ↔ asyncpg ↔ Supabase PostgreSQL
```

### Key Dependencies
- `sqlalchemy[asyncio]` — Async ORM + Core
- `asyncpg` — Async PostgreSQL driver
- `alembic` — Database migrations
- `python-jose[cryptography]` — JWT validation
- `python-dotenv` — Env loading (used by Pydantic Settings)

### SQLAlchemy Patterns
- **Mapped classes** using `DeclarativeBase` + `Mapped` type annotations (SA 2.0 style)
- **AsyncSession** via `async_sessionmaker`
- **Dependency injection**: `get_db()` yields sessions via FastAPI `Depends()`
- Models and Pydantic schemas kept separate (SA models ≠ API schemas)

## uv + pyproject.toml Setup

```bash
uv init          # Creates pyproject.toml
uv add fastapi uvicorn[standard] sqlalchemy[asyncio] asyncpg alembic ...
uv sync          # Installs all deps
uv run python run.py  # Runs the app
```

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Supabase connection string format | Use the "Session Mode" connection string from Supabase dashboard (port 5432) |
| AsyncPG + SQLAlchemy complexity | Follow SA 2.0 async tutorial patterns exactly |
| Schema changes later | Alembic migrations handle evolution; JSONB metadata fields for domain-specific flex |
