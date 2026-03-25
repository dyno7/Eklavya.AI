---
phase: 1
plan: 4
wave: 3
---

# Plan 1.4: Supabase Auth, Project Runner & Smoke Test

## Objective
Replace the auth stub with real Supabase JWT validation, create the dev server runner, add Supabase project setup guide, and run an end-to-end smoke test proving: auth → create goal → list goals. This validates the entire Phase 1 foundation.

## Context
- .gsd/phases/1/3-PLAN.md — API routers with stub auth (must be done)
- eklavya_backend/app/core/config.py — Has JWT_SECRET setting
- eklavya_backend/app/core/database.py — Async engine + session
- eklavya_backend/app/presentation/ — All routers with stub auth

## Tasks

<task type="auto">
  <name>Implement Supabase JWT auth + dev runner</name>
  <files>
    eklavya_backend/app/core/auth.py
    eklavya_backend/app/presentation/goals.py
    eklavya_backend/app/presentation/tasks.py
    eklavya_backend/app/presentation/users.py
    eklavya_backend/run.py
  </files>
  <action>
    1. **Create `auth.py`**:
       - Import `jose.jwt` for JWT decoding
       - `async def get_current_user_id(authorization: str = Header(...)) → UUID`:
         - Extract Bearer token from Authorization header
         - Decode using `jwt.decode(token, settings.JWT_SECRET, algorithms=["HS256"], audience="authenticated")`
         - Extract and return `sub` claim as UUID
         - Raise `HTTPException(401, "Invalid or expired token")` on any error
       - Make it a reusable FastAPI dependency

    2. **Update ALL router files**:
       - Replace stub `get_current_user_id` with real import from `app.core.auth`
       - Ensure every user-scoped endpoint injects `current_user_id: UUID = Depends(get_current_user_id)`

    3. **Create `run.py`** at eklavya_backend root:
       ```python
       import uvicorn
       if __name__ == "__main__":
           uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
       ```

    What to avoid and WHY:
    - Do NOT implement signup/login — Supabase Auth handles that (use existing tools)
    - Do NOT store tokens in the backend — JWTs are stateless (Poka-Yoke)
    - Do NOT add RBAC — YAGNI for MVP (Kaizen: JIT)
  </action>
  <verify>uv run python -c "from app.core.auth import get_current_user_id; print('Auth OK')"</verify>
  <done>JWT auth validates Supabase tokens, all routers use real auth, server starts with `uv run python run.py`</done>
</task>

<task type="auto">
  <name>Create Supabase setup guide</name>
  <files>
    eklavya_backend/docs/SUPABASE_SETUP.md
  </files>
  <action>
    Create a step-by-step guide for setting up the Supabase project:

    1. **Create Supabase Project**
       - Go to https://supabase.com → New Project
       - Choose a name (e.g., "eklavya-dev"), set database password, select region
       - Wait for project to provision (~2 minutes)

    2. **Get Connection Details**
       - Navigate to Settings → Database
       - Copy the "Session Mode" connection string (port 5432)
       - This becomes `DATABASE_URL` in your .env
       - Format: `postgresql+asyncpg://postgres.[project-ref]:[password]@aws-0-[region].pooler.supabase.com:5432/postgres`
       - NOTE: Replace `postgresql://` prefix with `postgresql+asyncpg://` for SQLAlchemy async

    3. **Get API Keys**
       - Navigate to Settings → API
       - Copy `Project URL` → `SUPABASE_URL`
       - Copy `anon public` key → `SUPABASE_ANON_KEY`
       - Copy `JWT Secret` from Settings → API → JWT Settings → `JWT_SECRET`

    4. **Run the Migration**
       - Go to SQL Editor in Supabase Dashboard
       - Paste contents of `migrations/001_initial_schema.sql`
       - Click "Run"
       - Verify tables appear in Table Editor

    5. **Create .env**
       - Copy `.env.example` to `.env`
       - Fill in all values from steps 2-3

    6. **Create a Test User**
       - Go to Authentication → Users → "Add User"
       - Create with email + password
       - This user can be used for API testing

    7. **Start the Backend**
       ```bash
       uv sync
       uv run python run.py
       ```
       Visit http://localhost:8000/docs for Swagger UI

    What to avoid and WHY:
    - Do NOT include real credentials in the guide — placeholder only
    - Do NOT assume Supabase CLI — dashboard is simpler for getting started
  </action>
  <verify>Test-Path "eklavya_backend/docs/SUPABASE_SETUP.md"</verify>
  <done>Setup guide covers project creation, credential extraction, migration execution, and first run</done>
</task>

<task type="checkpoint:human-verify">
  <name>End-to-end smoke test</name>
  <files>N/A — manual verification</files>
  <action>
    User follows SUPABASE_SETUP.md to:
    1. Create Supabase project (or use existing)
    2. Run SQL migration
    3. Create .env with real credentials
    4. Start backend: `uv run python run.py`
    5. Open http://localhost:8000/docs
    6. Verify all /api/v1 endpoints appear in Swagger
    7. Get a JWT token for the test user (via Supabase Auth dashboard or API)
    8. Test authenticated requests:
       - `POST /api/v1/goals` with Bearer token → creates goal
       - `GET /api/v1/goals` → lists the created goal
       - `GET /api/v1/users/me` → returns user profile
  </action>
  <verify>User confirms Swagger UI loads and at least one CRUD cycle works end-to-end</verify>
  <done>Backend starts, Swagger shows all routes, authenticated CRUD succeeds</done>
</task>

## Success Criteria
- [ ] JWT auth validates Supabase tokens, returns 401 on invalid/missing tokens
- [ ] All routers use real auth (no stubs remain)
- [ ] `uv run python run.py` starts the server, Swagger loads at /docs
- [ ] Supabase setup guide is complete and actionable
- [ ] At least one full CRUD cycle works (create goal → list goals)
