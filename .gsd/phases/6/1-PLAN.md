---
phase: 6
plan: 1
wave: 1
depends_on: []
files_modified:
  - eklavya_backend/app/domain/models.py
  - eklavya_backend/app/domain/schemas.py
  - eklavya_backend/app/core/repositories.py
  - eklavya_backend/app/presentation/dashboard.py
  - eklavya_backend/app/main.py
autonomous: true

must_haves:
  truths:
    - "Users table has total_xp and current_streak fields"
    - "Dashboard API provides a unified view of the active goal, current milestone, and pending tasks"
    - "Dashboard API handles XP claiming when tasks are completed"
  artifacts:
    - "Alembic migration created and applied for gamification fields"
    - "app/presentation/dashboard.py router exists and is registered"
---

# Plan 6.1: Backend Dashboard & Gamification API

## Objective
Extend the database schema to support gamification (XP, streaks) and create a unified Dashboard endpoint that the Flutter app can call to perfectly populate the Home screen in one request.

Purpose: Instead of making the mobile app do 5 separate API calls (get user, get goals, get milestone, get tasks), we provide a `/api/v1/dashboard/summary` endpoint.

## Context
- .gsd/SPEC.md
- eklavya_backend/app/domain/models.py
- eklavya_backend/app/core/repositories.py

## Tasks

<task type="auto">
  <name>Add Gamification fields to User model</name>
  <files>
    eklavya_backend/app/domain/models.py
    eklavya_backend/app/domain/schemas.py
    eklavya_backend/app/core/repositories.py
  </files>
  <action>
    1. In models.py `User`, add `total_xp: Mapped[int] = mapped_column(default=0)` and `current_streak: Mapped[int] = mapped_column(default=0)`
    2. Expand `UserResponse` in schemas.py to include `total_xp` and `current_streak`
    3. Generate and apply alembic migration to update the DB
  </action>
  <verify>uv run alembic upgrade head passes, DB inspector shows new columns</verify>
  <done>User table has XP and streak columns</done>
</task>

<task type="auto">
  <name>Create Dashboard Router</name>
  <files>
    eklavya_backend/app/presentation/dashboard.py
    eklavya_backend/app/main.py
  </files>
  <action>
    1. Create app/presentation/dashboard.py with GET `/api/v1/dashboard/summary`.
    2. The endpoint returns:
       - user: total_xp, current_streak, display_name
       - active_goal: the latest ACTIVE goal (if any)
       - current_milestone: the first LOCKED or ACTIVE milestone for that goal
       - pending_tasks: up to 3 upcoming tasks for that milestone
    3. Add POST `/api/v1/dashboard/claim-task/{task_id}`:
       - marks task as COMPLETED
       - adds task.xp_reward to user.total_xp
       - returns the updated user stats and task
    4. Register dashboard_router in main.py
  </action>
  <verify>curl GET /api/v1/dashboard/summary returns 200 OK</verify>
  <done>Dashboard API exposes unified view and task-claiming logic</done>
</task>

## Success Criteria
- [ ] User table tracks `total_xp` and `current_streak`
- [ ] unified `/summary` endpoint works
- [ ] `/claim-task` endpoint correctly updates XP
