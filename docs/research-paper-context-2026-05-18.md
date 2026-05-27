# Eklavya.AI Research Paper Context Pack

Last updated: 2026-05-18
Scope: Verified from current repository code and docs.
Purpose: A complete technical source document for drafting a research paper, thesis chapter, whitepaper, viva prep, or publication-ready sections.

## 1. Executive Technical Summary

Eklavya.AI is an AI-assisted, gamified goal execution platform with:
- Backend: FastAPI + async SQLAlchemy + Supabase Postgres.
- Mobile client: Flutter + Riverpod + go_router + Supabase Auth.
- AI orchestration: Google Gemini (`gemini-2.5-flash`) via server-side agent (`GuruAgent`).

The system converts conversational intent into structured roadmaps:
1. User chats with Guru.
2. LLM output is parsed into JSON roadmap.
3. Roadmap is persisted as goal -> milestones -> tasks.
4. Dashboard and analytics reflect progress and XP.
5. A Goal Drift Index (GDI) service computes engagement state.

## 2. Research Positioning Statement

Use this paragraph directly in a paper intro draft:

"Eklavya.AI implements a thin-client learning and execution architecture where AI orchestration, progression logic, and telemetry are centralized in an async Python backend, while mobile clients remain presentation-focused. The system integrates structured LLM generation, persistent roadmap decomposition, gamified reinforcement loops, and drift-aware coaching signals (GDI) into a single production-oriented stack."

## 3. System Architecture

### 3.1 High-level Architecture

- Presentation layer:
  - Flutter mobile app under `eklavya_mobile/lib`.
  - A React web app is mentioned in project docs (`technical_script.md`) but not present in this workspace snapshot.
- Application/API layer:
  - FastAPI app with modular routers under `eklavya_backend/app/presentation`.
- Domain/data layer:
  - SQLAlchemy ORM models + repository layer + Supabase Postgres.
- AI layer:
  - `GuruAgent` handles prompting, conversation state, JSON extraction, and roadmap readiness.
- Background computation:
  - APScheduler nightly GDI sweep.

### 3.2 Backend package structure

- `app/main.py`: app bootstrap, CORS, middleware, router registration, scheduler startup.
- `app/core/config.py`: env-driven settings.
- `app/core/database.py`: async DB engine and session factory.
- `app/core/auth.py`: JWT verification and user extraction.
- `app/core/repositories.py`: async data access abstraction.
- `app/core/gdi_service.py`: GDI scoring and nightly sweep.
- `app/domain/models.py`: ORM entity mapping.
- `app/domain/schemas.py`: API schemas.
- `app/domain/enums.py`: domain/status/task enums.
- `app/presentation/*.py`: endpoint routers.
- `app/agents/*.py`: AI prompt, agent runtime, roadmap persistence.

## 4. Technology Stack and Versions

### 4.1 Backend dependencies (`pyproject.toml`)

- Python >= 3.11
- fastapi >= 0.135.1
- uvicorn[standard] >= 0.41.0
- sqlalchemy[asyncio] >= 2.0.48
- asyncpg >= 0.31.0
- pydantic >= 2.12.5
- pydantic-settings >= 2.13.1
- alembic >= 1.18.4
- python-jose[cryptography] >= 3.5.0
- httpx >= 0.28.1
- python-dotenv >= 1.2.2
- google-generativeai >= 0.8.0

### 4.2 Mobile dependencies (`pubspec.yaml`)

- flutter_riverpod ^3.2.1
- go_router ^17.1.0
- supabase_flutter ^2.7.0
- http ^1.2.1
- google_fonts ^8.0.2
- shared_preferences ^2.5.4
- flutter_animate, shimmer, flutter_svg, cached_network_image, lottie, url_launcher

## 5. API Surface and Behavioral Contracts

### 5.1 Chat

- `POST /api/chat/send`
  - Input: `message`, `domain`, optional `session_id`
  - Output: `reply`, `session_id`, `is_roadmap_ready`, optional `roadmap`, optional `goal_id`, `navigate_to_roadmap`, optional quick reply options
  - Behavior:
    - Loads current active goal summary as context if present.
    - Loads last session memory for continuity.
    - Calls `GuruAgent.chat()`.
    - If roadmap ready, persists roadmap into DB.
    - Persists both user and assistant messages in `chat_memories`.

- `GET /api/chat/sessions`
  - Returns grouped past sessions with first user message as title.

- `GET /api/chat/sessions/{session_id}`
  - Returns full session history.

- `POST /api/chat/reset`
  - Clears in-memory Guru session state.

### 5.2 Goals and milestones

- `POST /api/v1/goals/`: create goal
- `GET /api/v1/goals/`: list all user goals
- `GET /api/v1/goals/{goal_id}`: get one goal
- `PATCH /api/v1/goals/{goal_id}`: partial update
- `POST /api/v1/goals/{goal_id}/milestones`: create milestone
- `GET /api/v1/goals/{goal_id}/milestones`: list milestones

### 5.3 Tasks

- `POST /api/v1/tasks/`: create task
- `GET /api/v1/tasks/milestone/{milestone_id}`: list tasks for milestone
- `GET /api/v1/tasks/{task_id}`: get one task
- `PATCH /api/v1/tasks/{task_id}/status`: update status

### 5.4 Dashboard and progression

- `GET /api/v1/dashboard/summary`
  - Unified read model:
    - user stats (XP, streak)
    - active goal
    - current milestone
    - up to 5 pending tasks

- `POST /api/v1/dashboard/claim-task/{task_id}`
  - Marks task complete, updates progression, computes rewards.

### 5.5 Analytics and coach

- `GET /api/v1/analytics/summary`: weekly XP, completion rate, active days, task counts.
- `POST /api/v1/analytics/session_start`: session telemetry.
- `GET /api/v1/coach/status`: current GDI state and components.

### 5.6 Users and notifications

- `GET /api/v1/users/me`, `PATCH /api/v1/users/me`
- `GET /api/v1/users/me/badges`
- `GET /api/v1/notifications/`
- `POST /api/v1/notifications/{notification_id}/read`

## 6. Data Model and Entity Relationships

### 6.1 Primary entities

- `users`
  - Core identity-linked profile.
  - Includes `total_xp`, `current_streak`.
- `goals`
  - `domain`, `status`, `metadata`, `target_date`.
- `milestones`
  - Ordered checkpoints per goal.
- `tasks`
  - Ordered actionable units with `task_type`, `xp_reward`, `status`, `completed_at`, `metadata`.
- `badges`, `user_badges`
  - Gamification achievements.
- `notifications`
  - System/user alerts.
- `chat_memories`
  - Persistent message history by `session_id`.
- `user_session_logs`, `user_behavior_logs`, `reward_signal_logs`
  - Engagement telemetry and drift signals.

### 6.2 Enums

- Domain: `learning`, `fitness`, `startup`, `finance`, `writing`.
- GoalStatus: `active`, `paused`, `completed`, `abandoned`.
- MilestoneStatus: `locked`, `active`, `completed`.
- TaskStatus: `pending`, `in_progress`, `completed`, `skipped`.
- TaskType: `read`, `watch`, `practice`, `quiz`, `write`, `exercise`, `custom`.

## 7. AI/LLM Integration and Prompting Design

### 7.1 Model provider and runtime

- Provider: Google Generative AI SDK.
- Model: `gemini-2.5-flash`.
- Config:
  - temperature = 0.7
  - roadmap turn token cap uses `max_output_tokens=8000`
  - for roadmap generation turns, response mime type requested as JSON

### 7.2 Prompt strategy

- Dynamic context includes:
  - Adaptive goal decomposition scalar (`user_capability_scalar`).
  - Existing active roadmap summary.
  - Recent conversation memory.
  - Navigation JSON command protocol.
- Static prompt template imposes:
  - max 2 sentences in conversational turns.
  - 4-turn flow: greet -> skill -> time -> generate roadmap.
  - `QUICK_REPLY:[...]` protocol for tappable options.
  - strict roadmap JSON schema with milestones/tasks/resources.

### 7.3 Domain prompt coverage nuance

- Prompt dictionary explicitly defines rich prompts for: `learning`, `fitness`, `startup`.
- Other domains fall back to generic template formatting.
- This matters for paper claims: domain enum coverage is broader than fully specialized prompt coverage.

### 7.4 Offline mode behavior

- If `GEMINI_API_KEY` absent:
  - Backend `GuruAgent` enters offline demo mode.
  - Returns canned staged responses and a hardcoded roadmap.
- Mobile `ChatService` also has independent local offline fallback flow.

## 8. Core Algorithms and Logic

### 8.1 Roadmap generation to persistence pipeline

1. Receive user chat message.
2. Resolve or create session.
3. Build context from goals + recent chat memory.
4. Call LLM and parse response.
5. Detect roadmap readiness.
6. Extract roadmap JSON.
7. Persist roadmap as relational entities.
8. Return reply + roadmap metadata to client.

### 8.2 Persistence decomposition algorithm

`persist_roadmap()` performs:
- Goal creation with aggregated metadata and resources.
- Milestone creation by supplied order.
- Task creation per milestone.
- Task type normalization to valid DB-supported subset:
  - valid in persistence whitelist: `read`, `watch`, `practice`, `quiz`, `custom`
  - unsupported generated types downgraded to `custom`

Paper-worthy implication:
- Prompt schema allows `write` and `exercise`, but persistence whitelist currently downgrades those to `custom`.

### 8.3 Task claim and reward algorithm

`claim-task` flow:
1. Validate task existence and not already completed.
2. Store previous completion timestamp for streak logic.
3. Complete task.
4. If milestone fully complete:
   - mark milestone completed
   - award milestone bonus XP (+50)
   - unlock next locked milestone
5. If all milestones complete:
   - mark goal completed
   - award goal bonus XP (+200)
6. Streak multiplier on base task XP:
   - streak >= 7: 1.5x
   - streak >= 3: 1.2x
   - else 1.0x
7. Recompute level as integer bucket (`level = total_xp // 100`).
8. Trigger badge awards using deterministic conditions.

### 8.4 Goal Drift Index (GDI)

Service computes:

GDI(t) = alpha * M(t) + beta * V(t) + gamma * c(t) + delta * D(t)

Where current implementation constants are:
- alpha = 0.4
- beta = -0.2
- gamma = -0.2
- delta = -0.3

Components:
- M(t): normalized XP momentum over 7 days.
- V(t): normalized empty sessions over 7 days.
- c(t): normalized easy-task completion proxy.
- D(t): normalized decay since last completion.

State classifier:
- `ENGAGED` if score > 0.1
- `WAVERING` if -0.2 < score <= 0.1
- `SILENT_RECESS` otherwise

Nightly process:
- APScheduler cron at 00:00 computes per-user GDI and stores daily telemetry.

## 9. Performance and Scalability

### 9.1 Implemented performance choices

- End-to-end async stack on backend.
- SQLAlchemy async engine with pooling and pre-ping.
- Supabase pooler compatibility via `statement_cache_size=0`.
- `selectinload` eager loading for dashboard active goal graph.
- Indexes on key FK/status/time fields (per model definitions and migrations).
- In-memory rate limiting on expensive/sensitive routes.

### 9.2 Known performance bottlenecks

- In-memory rate limiter is process-local and non-distributed.
- In-memory chat session store is non-durable and non-shared.
- Nightly GDI sweep loops users sequentially in one scheduler job.
- No API-level pagination on several collection endpoints.
- No shared cache (Redis/memcache) for hot summaries.
- No materialized aggregates for analytics.

### 9.3 Mobile performance and UX behavior

- `StatefulShellRoute.indexedStack` keeps tabs mounted (fast tab switching, more memory usage).
- Roadmap updates broadcast with local `ValueNotifier` (`RoadmapSyncService`).
- Some service methods use fallback behavior to avoid UX hard-fail when backend unavailable.

## 10. Security and Privacy

### 10.1 Implemented

- Bearer token auth for protected routes.
- JWT decoding supports HS256/RS256/ES256.
- JWKS retrieval from Supabase with 5-minute cache.
- Audience validation (`audience="authenticated"`).
- User context extraction from token claims.
- DB TLS requirement (`ssl=require`).
- Sensitive keys loaded via env, not hardcoded.

### 10.2 Security-relevant gaps to mention honestly

- Task endpoints do not enforce ownership checks in router layer (`tasks.py` currently fetches/updates by task id only).
- Rate limiter keyed by IP+path, not authenticated user identity.
- No explicit anti-prompt-injection guard layer before LLM call.
- No distributed audit log/trace of sensitive user actions.

If writing a paper, report these as "current limitations and future hardening priorities".

## 11. Mobile Client Architecture

### 11.1 App bootstrap and configuration

- Requires runtime `--dart-define` values for Supabase URL/key.
- Supabase URL normalization helper protects against malformed env values.
- Backend URL resolved via `AppConfig`:
  - explicit override via `BACKEND_URL`
  - local fallbacks for web/emulator debug
  - release mode throws if missing configuration

### 11.2 Routing and shell

- `go_router` with pre-auth style entry routes and tabbed shell.
- Main tabs:
  - Home
  - Goals
  - Chat
  - Analytics
- Additional routes include login/signup/onboarding/profile/notifications.

### 11.3 Service layer responsibilities

- `AuthService`: Supabase auth wrapper and token provider.
- `ChatService`: send/load/reset chat sessions, quick reply parsing support.
- `DashboardService`: summary fetch, task completion, analytics fetch helper.
- `GoalsService`: goals list enrichment + roadmap/task retrieval.
- `CoachService`: fetch GDI and log session start.
- `UserService`: badge retrieval.
- `NotificationService`: fetch + mark read.
- `RoadmapSyncService`: local cross-tab refresh signaling.

## 12. Reliability and Operational Notes

- Health check endpoint exists (`/health`).
- Backend docs disabled outside development mode.
- Scheduler startup errors are logged.
- Several services apply network timeout limits (client and server side where relevant).
- Multiple parts of stack include fallback/demo behavior to preserve product continuity during missing API connectivity.

## 13. Current Gaps and Technical Debt (Paper-ready)

1. Conversation state durability:
- In-memory `_sessions` means restart loses live assistant state.

2. Authorization consistency:
- Some task operations are not ownership-gated.

3. Type-system mismatch in roadmap generation:
- Prompt allows task types not whitelisted by persistence logic.

4. Scalability primitives missing:
- No distributed cache, no queue workers, no horizontal state strategy.

5. Observability maturity:
- No metrics/tracing pipeline defined in code snapshot.

6. Test coverage:
- No backend test files found in current workspace snapshot.

## 14. Suggested Research Paper Structure Using This Context

1. Problem Statement and Motivation
2. System Architecture and Design Principles
3. AI Orchestration and Structured Generation Pipeline
4. Gamification Engine and Progression Logic
5. Behavioral Analytics: Goal Drift Index
6. Security, Auth, and Privacy
7. Performance and Scalability Analysis
8. Limitations and Future Work
9. Conclusion

## 15. Reusable Writing Blocks

### 15.1 Contributions section draft bullets

- Introduces a thin-client architecture that centralizes AI and progression logic.
- Demonstrates structured LLM-to-relational persistence for personalized roadmaps.
- Integrates gamification with deterministic reward and progression transitions.
- Adds drift-aware behavioral scoring (GDI) for intervention readiness.

### 15.2 Limitations section draft bullets

- Current state/session and rate limit infrastructure are single-instance and in-memory.
- Authorization checks are uneven across endpoint families.
- Prompt-level task type expressiveness exceeds persistence type whitelist.
- Absence of automated integration tests increases regression risk.

## 16. Evidence Map (Primary File Index)

Backend app and runtime:
- `eklavya_backend/app/main.py`
- `eklavya_backend/app/core/config.py`
- `eklavya_backend/app/core/database.py`
- `eklavya_backend/app/core/auth.py`
- `eklavya_backend/app/core/repositories.py`
- `eklavya_backend/app/core/gdi_service.py`

AI agent and prompt system:
- `eklavya_backend/app/agents/guru_agent.py`
- `eklavya_backend/app/agents/prompts.py`
- `eklavya_backend/app/agents/roadmap_persistence.py`

API layer:
- `eklavya_backend/app/presentation/chat.py`
- `eklavya_backend/app/presentation/dashboard.py`
- `eklavya_backend/app/presentation/goals.py`
- `eklavya_backend/app/presentation/tasks.py`
- `eklavya_backend/app/presentation/analytics.py`
- `eklavya_backend/app/presentation/coach.py`
- `eklavya_backend/app/presentation/users.py`
- `eklavya_backend/app/presentation/notifications.py`

Domain models and schemas:
- `eklavya_backend/app/domain/enums.py`
- `eklavya_backend/app/domain/models.py`
- `eklavya_backend/app/domain/schemas.py`

Mobile app:
- `eklavya_mobile/pubspec.yaml`
- `eklavya_mobile/lib/main.dart`
- `eklavya_mobile/lib/core/config/app_config.dart`
- `eklavya_mobile/lib/core/router/app_router.dart`
- `eklavya_mobile/lib/core/services/auth_service.dart`
- `eklavya_mobile/lib/core/services/chat_service.dart`
- `eklavya_mobile/lib/core/services/dashboard_service.dart`
- `eklavya_mobile/lib/core/services/goals_service.dart`
- `eklavya_mobile/lib/core/services/coach_service.dart`
- `eklavya_mobile/lib/core/services/user_service.dart`
- `eklavya_mobile/lib/core/services/notification_service.dart`
- `eklavya_mobile/lib/core/services/roadmap_sync_service.dart`

Supporting docs:
- `technical_script.md`
- `docs/progress-report-2026-04-08.md`
- `docs/model-selection-playbook.md`
- `docs/token-optimization-guide.md`

## 17. How to Use This File for Fast Paper Generation

Prompt recipe:
- "Use docs/research-paper-context-2026-05-18.md as source of truth. Write Section X (Y words), academic tone, include architecture details, mention exact implemented formulas and limitations."

For each section request, specify:
- audience (review panel / conference / internal tech paper)
- word target
- citation style (IEEE/APA/none)
- whether you want equations included
- whether you want limitations and future work in that section

This file is intentionally exhaustive so section drafting can be done incrementally without rescanning the codebase each time.
