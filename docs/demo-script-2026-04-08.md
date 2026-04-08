# Eklavya.AI Demo Script (5-7 Minutes)

Date: 2026-04-08
Audience: Professor / Evaluation Panel
Goal: Demonstrate end-to-end reliability and progress

## 0) Pre-Demo Checklist (Before Screen Share)
- Backend running and reachable.
- Mobile/web app running with correct runtime config.
- Test account available.
- Network stable.

## 1) Opening (30-45 sec)
Say:
"Eklavya.AI is a Thin Client learning platform where AI-generated roadmaps are persisted server-side and reflected live across the app. In this demo, I will show the full loop from roadmap generation to tracked progress updates."

## 2) Show Architecture Quickly (45 sec)
Show:
- Backend: FastAPI + Supabase/Postgres.
- Client: Flutter tabs (Home, Goals, Analytics, Profile, Chat).
Say:
"Business logic and persistence are in backend; app is a real-time consumer of API state."

## 3) Demo Flow A: Generate Roadmap from Chat (1.5 min)
Steps:
1. Open Chat tab.
2. Ask Guru to generate a roadmap for a specific goal.
3. Trigger roadmap creation and navigate to Goals.
Expected output:
- New goal appears.
- Milestones and tasks are visible.
Say:
"This verifies AI output is converted into normalized DB entities, not just shown as plain text."

## 4) Demo Flow B: Task Completion and Live Updates (2 min)
Steps:
1. Open roadmap detail screen.
2. Mark one or more tasks complete.
3. Switch to Home and Analytics/Profile.
Expected output:
- Milestone progress increases.
- Goal progress updates.
- Dashboard stats/streak/analytics values refresh.
Say:
"This was a key fix: previously tasks could tick but milestone progress stayed stale. Now backend progression logic and cross-tab refresh are synchronized."

## 5) Demo Flow C: Profile + Badge/Data Integrity (45 sec)
Steps:
1. Open Profile tab.
2. Show user display name and badge/state values.
Expected output:
- Real display name (not placeholder).
- Dynamic stats from backend.
Say:
"Identity and profile data now come from live auth claims + backend repositories."

## 6) Demo Flow D: Notifications / System Integration (30 sec)
Steps:
1. Open Notifications.
2. Show list and read-state change.
Expected output:
- Notifications loaded from backend.
- Read state persists.

## 7) Engineering Challenges + Fixes (60-90 sec)
Say:
"Major blockers and resolutions:"
- JWT failures -> algorithm-aware verification.
- Supabase connection/pooler issues -> SSL + pooler-safe DB config.
- Enum mismatch -> standardized enum value persistence.
- Stale UI updates -> roadmap sync notifier across tabs.
- Android release failures -> NDK/toolchain alignment + env override fix.
- Signup URL failures -> runtime Supabase URL normalization.

## 8) Close (20-30 sec)
Say:
"Current status: end-to-end roadmap lifecycle is stable, cross-tab updates are live, and release build pipeline is working. Next step is broader integration test coverage and multi-device regression."

## 9) Backup Lines If Something Fails Live
- If network is slow:
  "The same flow is pre-verified; I will continue with cached state and explain expected server response."
- If backend is temporarily down:
  "The failure is environmental, not logic-level; I can show validated logs and successful prior runs."
- If device build is unavailable:
  "I can run equivalent flow on web and show DB/API evidence from updated entities."

## 10) Suggested Demo Order (Quick Reference)
1. Chat roadmap generation
2. Goals roadmap view
3. Complete tasks
4. Home updates
5. Analytics updates
6. Profile + badges
7. Notifications
8. Challenges + fixes summary

## 11) What to Emphasize to Evaluators
- End-to-end integration (AI -> DB -> multi-tab UI)
- Debugging depth across auth/DB/mobile/build layers
- Production-minded fixes (resilience + validation)
- Measurable progress with working release artifact