# Eklavya.AI — Project Context

## What Is This

Eklavya.AI is a **gamified learning and execution platform** — a mobile app where users state a learning goal, an AI generates a personalized roadmap, and the app tracks progress with XP, streaks, milestones, and behavioral intelligence (GDI). Think Duolingo meets a personal learning coach.

**Stack:**
- Flutter mobile app (Android/iOS)
- FastAPI Python backend
- Supabase PostgreSQL database
- Google Gemini 2.5 Flash for AI agents
- Supabase Auth (JWT-based)

---

## Repository Structure

```
d:\Projects\Eklavya.AI\
├── eklavya_backend/          # FastAPI Python backend
│   ├── app/
│   │   ├── main.py           # FastAPI app, CORS, rate limiting, APScheduler
│   │   ├── agents/
│   │   │   ├── guru_agent.py          # Gemini-powered roadmap generator
│   │   │   ├── coach_agent.py         # Gemini-powered learning assistant
│   │   │   ├── prompts.py             # System prompts for both agents
│   │   │   └── roadmap_persistence.py # Converts roadmap JSON → DB records
│   │   ├── core/
│   │   │   ├── auth.py        # Supabase JWT validation, CurrentUser dep
│   │   │   ├── database.py    # SQLAlchemy async engine + session
│   │   │   ├── repositories.py # All DB queries (no ORM magic in routes)
│   │   │   ├── gdi_service.py  # Goal Drift Index calculation engine
│   │   │   └── cache.py        # In-memory dashboard cache (30s TTL)
│   │   ├── domain/
│   │   │   ├── models.py      # SQLAlchemy ORM models
│   │   │   └── enums.py       # Domain, GoalStatus, MilestoneStatus, TaskType etc.
│   │   └── presentation/
│   │       ├── chat.py        # POST /api/chat/send — Guru chat endpoint
│   │       ├── coach.py       # POST /api/v1/coach/ask — Coach endpoint
│   │       ├── dashboard.py   # GET /api/v1/dashboard/summary, POST claim-task
│   │       ├── goals.py       # CRUD for goals
│   │       ├── tasks.py       # Task management
│   │       ├── analytics.py   # Analytics endpoints
│   │       ├── users.py       # User profile
│   │       └── notifications.py
│   └── migrations/
│       ├── 001_initial_schema.sql   # Core tables: users, goals, milestones, tasks
│       └── 002_missing_tables.sql   # MUST RUN: adds XP/streak columns, badges,
│                                    # notifications, chat_memories, session logs,
│                                    # behavior logs, reward logs, gdi_weights
│
└── eklavya_mobile/            # Flutter app
    └── lib/
        ├── core/
        │   ├── config/app_config.dart      # Backend URL config
        │   ├── router/app_router.dart      # go_router — all routes + 5-tab shell
        │   ├── services/
        │   │   ├── auth_service.dart        # Supabase auth + token storage
        │   │   ├── chat_service.dart        # Guru API client (90s timeout)
        │   │   ├── coach_service.dart       # Coach API client
        │   │   ├── dashboard_service.dart   # Dashboard + claim-task API client
        │   │   ├── goals_service.dart       # Goals + roadmap API client
        │   │   ├── chat_seed_service.dart   # ValueNotifier: seed Guru chat from other tabs
        │   │   └── coach_context_service.dart # ValueNotifier: pass task context to Coach
        │   ├── theme/                       # AppColors, AppSpacing, AppRadii, fonts
        │   └── widgets/                     # GlassCard, GlassBottomNav, GradientBackground
        └── features/
            ├── shell/main_shell.dart        # 5-tab scaffold with GlassBottomNav
            ├── dashboard/home_tab.dart      # Home: XP, streak, GDI nudge card
            ├── goals/
            │   ├── goals_tab.dart           # List of user goals
            │   └── goal_roadmap_screen.dart # Milestone + task detail, "Ask Coach" button
            ├── chat/chat_tab.dart           # Guru chat UI (roadmap generator)
            ├── coach/coach_page.dart        # Coach chat UI (learning Q&A)
            ├── analytics/analytics_tab.dart # XP chart, streak calendar, focus breakdown
            ├── auth/                        # Login + Signup screens
            ├── onboarding/                  # Onboarding flow
            └── profile/                     # User profile
```

---

## Database Schema

### Core Tables (001_initial_schema.sql)

```sql
users          id(PK), display_name, avatar_url, total_xp, current_streak, created_at, updated_at
goals          id(PK), user_id(FK), domain, title, description, target_date, metadata(JSON), status, created_at, updated_at
milestones     id(PK), goal_id(FK), title, description, order_index, status(locked/active/completed), created_at
tasks          id(PK), milestone_id(FK), title, description, task_type, metadata(JSON), xp_reward, order_index, status(pending/in_progress/completed), due_date, completed_at, created_at
```

### Additional Tables (002_missing_tables.sql — MUST BE RUN IN SUPABASE)

```sql
badges              id, name, description, icon_url, required_xp
user_badges         id, user_id(FK), badge_id(FK), earned_at
notifications       id, user_id(FK), title, message, type, read_status, created_at
chat_memories       id, user_id(FK), session_id(UUID), role, content, created_at
user_session_logs   id, user_id(FK), login_timestamp, tasks_completed_in_session
user_behavior_logs  id, user_id(FK), date, momentum_score, avoidance_count, decay_value, gdi_score
reward_signal_logs  id, user_id(FK), timestamp, action_type, reward_value
user_gdi_weights    user_id(PK/FK), alpha, beta, gamma, delta, update_count, updated_at
```

### Enums
- `domain_type`: learning, fitness, startup, writing, custom
- `goal_status`: active, completed, archived, paused
- `milestone_status`: locked, active, completed
- `task_status`: pending, in_progress, completed
- `task_type`: read, watch, practice, quiz, write, exercise, custom

### Default Badges (seeded)
First Steps, Novice (100 XP), Centurion (500 XP), Consistency (7-day streak), Milestone Master, Goal Crusher

---

## AI Agents

### GuruAgent (`app/agents/guru_agent.py`)

The Guru is a **roadmap generator only** — it refuses to answer learning questions and redirects to Coach.

**Conversation flow (3 turns, then generate):**
1. User states goal → Guru acknowledges + asks skill level (QUICK_REPLY chips: Beginner/Intermediate/Advanced)
2. User answers → Guru asks daily time commitment (QUICK_REPLY: 30 min/day / 1 hr/day / 2+ hrs/day)
3. User answers → Guru outputs JSON roadmap immediately

**Key behaviors:**
- Flutter shows the greeting locally; the first API call is already the user's stated goal
- At turn 3 (`user_turn_count >= 3`), switches to `response_mime_type="application/json"` for clean JSON output
- Timeouts: 120s for roadmap generation, 30s for conversation
- Adaptive capability scalar based on streak: 0-2 days → 0.9 (easy), 3-6 → 1.0 (balanced), 7+ → 1.15 (ambitious)
- GDI coach state (ENGAGED/WAVERING/SILENT_RECESS) shapes roadmap pacing
- If user has an active goal already, references it instead of generating a new one
- In-memory sessions keyed by `session_id` UUID (not user_id) so each new chat gets a fresh agent
- QUICK_REPLY options are parsed client-side and rendered as tappable chips

**Roadmap JSON schema:**
```json
{
  "title": "...",
  "domain": "learning",
  "estimated_weeks": 8,
  "committed_minutes_per_day": 60,
  "milestones": [
    {
      "title": "...",
      "order": 1,
      "estimated_days": 14,
      "narrative_arc": "Setup",  // Setup → Rising Action → Climax → Shareability
      "tasks": [
        {
          "title": "...",
          "description": "2-3 sentences: what, why, tip",
          "type": "watch|read|practice|quiz|write|exercise|custom",
          "xp_reward": 10-50,
          "estimated_minutes": 30,
          "resources": [{"title": "...", "url": "https://..."}]
        }
      ]
    }
  ]
}
```

### CoachAgent (`app/agents/coach_agent.py`)

The Coach answers learning questions, explains concepts, suggests resources — knows the task/milestone context.

**Constructor params:** `task_title`, `task_description`, `task_type`, `milestone_title`  
**Endpoint:** `POST /api/v1/coach/ask`  
**Session store:** in-memory `_coach_sessions: dict[str, CoachAgent]` keyed by session_id  
**Timeout:** 30s, max 1024 output tokens  
**Behavior:** Max 4 sentences per reply, no roadmap generation, redirects to Guru if asked

---

## Backend API Endpoints

```
GET  /health

# Chat (Guru)
POST /api/chat/send          — send message, get reply + optional roadmap
GET  /api/chat/sessions      — list past sessions (ChatGPT-style sidebar)
GET  /api/chat/sessions/{id} — load messages for a session
GET  /api/chat/history       — legacy history endpoint
GET  /api/chat/memory        — recent chat memories
POST /api/chat/reset         — purge all GuruAgent sessions for authenticated user

# Coach
POST /api/v1/coach/ask       — ask the Coach agent a question

# Dashboard
GET  /api/v1/dashboard/summary            — user stats + active goal + milestone + pending tasks
POST /api/v1/dashboard/claim-task/{id}    — complete task, earn XP, advance milestone/goal

# Goals
GET    /api/v1/goals/         — list goals
POST   /api/v1/goals/         — create goal
GET    /api/v1/goals/{id}     — get goal
GET    /api/v1/goals/{id}/milestones     — milestones with tasks
PATCH  /api/v1/goals/{id}     — update goal
DELETE /api/v1/goals/{id}     — delete goal

# Tasks
GET    /api/v1/tasks/{id}
PATCH  /api/v1/tasks/{id}
POST   /api/v1/tasks/{id}/complete

# Users
GET  /api/v1/users/me
POST /api/v1/users/session-start   — log session open (used for GDI V(t))

# Analytics
GET  /api/v1/analytics/summary

# Notifications
GET  /api/v1/notifications/
POST /api/v1/notifications/{id}/read
```

**Rate limiting:** 30 req/60s per IP on `/api/chat/send` and `/api/v1/dashboard/claim-task`  
**Auth:** Supabase JWT in `Authorization: Bearer <token>` header on all protected routes

---

## Goal Drift Index (GDI)

The GDI is the behavioral intelligence engine. It classifies user engagement state and drives coach nudges.

```
GDI(t) = α·M(t) + β·V(t) + γ·c(t) + δ·D(t)

α = 0.4   M(t) = normalized XP earned last 7 days (0-1)
β = -0.2  V(t) = empty sessions (open app, do nothing) last 7 days (0-1)
γ = -0.2  c(t) = avoidance score (easy tasks done while hard pending) (0-1)
δ = -0.3  D(t) = decay since last task completion, days/7 capped at 1.0

States:
  GDI > 0.1   → ENGAGED      (no intervention)
  GDI > -0.2  → WAVERING     (soft nudge in Home tab)
  GDI < -0.2  → SILENT_RECESS (roadmap adjust nudge + "Get Back on Track" button)
```

**Nightly sweep:** APScheduler runs `GdiService.run_midnight_decay_sweep()` at midnight UTC — writes `UserBehaviorLog` rows for every user.

**Per-user weights:** `user_gdi_weights` table stores adaptive α/β/γ/δ per user (cold-start: global defaults).

---

## XP & Gamification System

- Tasks award `xp_reward` XP (10-50 base, set by AI)
- Streak multiplier on task completion: 3+ day streak → 1.2×, 7+ → 1.5×
- Milestone completion bonus: +50 XP
- Goal completion bonus: +200 XP
- Level = `total_xp // 100`
- Badges checked on every claim-task: First Steps, Novice, Centurion, Consistency, Milestone Master, Goal Crusher
- Milestone unlock chain: completing all tasks in milestone M → M becomes COMPLETED → next locked milestone becomes ACTIVE

---

## Flutter App Architecture

### Navigation
- `go_router` with `StatefulShellRoute.indexedStack` (5 tabs, state preserved on tab switch)
- Tabs: Home (`/home`) → Goals (`/goals`) → Guru (`/chat`) → Coach (`/coach`) → Analytics (`/analytics`)
- Standalone routes outside shell: `/`, `/login`, `/signup`, `/onboarding`, `/profile`, `/notifications`

### Cross-Tab Communication (ValueNotifier pattern)
Because `StatefulShellRoute.indexedStack` keeps all tabs alive, `initState` only runs once. Cross-tab communication uses singleton `ValueNotifier` services:

- **ChatSeedService** (`lib/core/services/chat_seed_service.dart`): pre-seeds a message into the Guru chat. Home tab calls `ChatSeedService.seed("message")` → Chat tab listener picks it up and sends it automatically. Used by the GDI nudge card ("Get Back on Track" button).
- **CoachContextService** (`lib/core/services/coach_context_service.dart`): passes `CoachTaskContext` (taskTitle, taskDescription, taskType, milestoneTitle) from GoalRoadmapScreen to CoachPage. CoachPage clears session and pre-greets with the task context.

### Key Services
- `AuthService` — Supabase sign in/up/out, JWT token storage
- `ChatService` — Guru API client; `sendMessage` has 90s timeout; `startNewSession()` is async and calls backend `/reset`; `_offlineResponse()` returns retry message mid-session instead of restarting
- `CoachService` — Coach API client; `logSessionStart()` has 5s timeout (prevents hang when backend unreachable)
- `DashboardService` — dashboard summary + `completeTask(taskId)` → claim-task endpoint
- `GoalsService` — goals list + `fetchGoalRoadmap(goalId)` → milestones with tasks

### Theme
Dark glassmorphism: `AppColors`, `AppSpacing`, `AppRadii`, `GlassCard` widget, `GradientBackground` widget

---

## Roadmap Persistence (`app/agents/roadmap_persistence.py`)

When Guru generates a roadmap, `persist_roadmap(db, user_id, roadmap_dict)` is called:
1. Creates a `Goal` with `domain`, `title`, `metadata_` (includes all resources flattened from tasks, max 15)
2. Creates `Milestone` rows in order
3. **First milestone (index 0) is set to `ACTIVE`** — rest stay `LOCKED`
4. Creates `Task` rows per milestone; `task_type` validated against `_VALID_TASK_TYPES` (read/watch/practice/quiz/write/exercise/custom), unknown types downgraded to "custom"
5. Returns `goal.id` UUID

---

## Known Issues & Pending Work

1. **CRITICAL: Run `002_missing_tables.sql` in Supabase SQL editor** — task completion, XP, streaks, chat memory, and GDI all fail without this migration.
2. **App polish for publishing** — UI/UX refinements not yet scoped.
3. **Security audit** — planned after all features are added.

---

## How to Run

### Backend
```bash
cd eklavya_backend
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Required `.env` vars:**
```
GEMINI_API_KEY=...
SUPABASE_URL=...
SUPABASE_KEY=...        # service role key
SUPABASE_JWT_SECRET=... # for JWT validation
ENVIRONMENT=development
DATABASE_URL=postgresql+asyncpg://...
```

### Flutter
```bash
cd eklavya_mobile
flutter pub get
flutter run
```

Backend URL configured in `lib/core/config/app_config.dart`.

---

## What Has Been Built (Chronological)

1. **Core schema + ORM** — users, goals, milestones, tasks with enums and relationships
2. **Auth** — Supabase JWT validation middleware, `CurrentUser` FastAPI dependency
3. **Dashboard endpoint** — unified summary + claim-task with XP, streak, milestone unlock chain, badge awards
4. **Guru Agent** — Gemini 2.5 Flash, 3-turn wizard, roadmap JSON generation, `roadmap_persistence.py`
5. **GDI engine** — M/V/c/D components, state classification, nightly APScheduler sweep
6. **Chat sessions** — session_id keying, ChatGPT-style session list, message persistence in `chat_memories`
7. **In-memory dashboard cache** (30s TTL) — prevents redundant DB hits on repeated loads
8. **Flutter UI** — glassmorphism dark theme, 5-tab shell, all major screens
9. **Analytics tab** — XP chart, full-month streak calendar, learning focus breakdown
10. **Guru/Coach split** — Guru generates roadmaps only; Coach answers learning questions with task context
11. **CoachPage** — full chat UI, context card (task/milestone), resource URL chips, typing indicator
12. **Ask Coach button** — per-task in GoalRoadmapScreen, sets CoachContextService and navigates to /coach
13. **ChatSeedService + CoachContextService** — ValueNotifier pattern for cross-tab communication in IndexedStack
14. **GDI nudge card** — Home tab shows WAVERING/SILENT_RECESS nudge, "Get Back on Track" seeds context message into Guru chat
15. **Rate limiting middleware** — 30 req/60s on chat/send and claim-task
16. **Roadmap first milestone ACTIVE** — first milestone unlocked immediately on roadmap creation
17. **startNewSession() → backend reset** — new chat purges old GuruAgent from server memory
18. **QUICK_REPLY option chips** — Guru appends `QUICK_REPLY:[...]` parsed and rendered as tappable chips in Flutter
19. **Timeout fixes** — 90s Flutter sendMessage timeout, 120s backend Gemini timeout for roadmap, 5s session-start timeout
