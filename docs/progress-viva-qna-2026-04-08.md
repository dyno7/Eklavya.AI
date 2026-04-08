# Eklavya.AI Viva Q&A (Condensed)

Date: 2026-04-08

## Q1. What problem does Eklavya.AI solve?
Eklavya.AI helps users convert broad goals into structured roadmaps (goals -> milestones -> tasks), then tracks progress live across the app.

## Q2. What architecture did you use?
Thin Client architecture:
- FastAPI backend for AI orchestration, persistence, and business logic.
- Flutter mobile/web client for UI and API consumption.
- Supabase for Auth + PostgreSQL.

## Q3. What was the main milestone achieved in this phase?
End-to-end roadmap flow is now reliable: chat-generated roadmap is persisted and reflected live in Home, Goals, Analytics, and Profile.

## Q4. What were the biggest technical blockers?
- JWT algorithm mismatch during token verification.
- Supabase DB connection/pooler issues.
- Enum mismatch between backend and PostgreSQL values.
- Milestones/tasks not updating in real time in UI.
- Android release blocked by NDK/toolchain issues.
- Signup failure from malformed Supabase URL formatting on client runtime.

## Q5. How did you solve JWT verification issues?
Implemented algorithm-aware verification and normalized user-claim extraction so ES256/RS256/HS256 token flows are handled correctly.

## Q6. Why was roadmap visible but still not progressing?
UI could display data, but backend transition logic (task -> milestone -> goal status/progress) was incomplete. We added explicit progression checks and updates in task claim flow.

## Q7. How did you fix stale UI across tabs?
Added a shared roadmap sync notifier and subscribed Home, Goals, Profile, and Analytics to refresh on roadmap/task events.

## Q8. How did you ensure profile identity is correct?
Added display-name repair/creation from auth claims so users no longer appear as generic placeholders.

## Q9. What did you do for persistent AI context?
Added chat memory persistence (`chat_memories`) and retrieval so Guru conversations can carry relevant context forward.

## Q10. What mobile UX improvements were made?
- Expandable roadmap task structure.
- Better refresh behavior after task completion.
- Working Home "See All" flows.
- Analytics/Profile now based on live backend values.

## Q11. What Android release issue occurred?
Gradle/NDK mismatch and broken local NDK path caused release build failures.

## Q12. How was Android build fixed?
- Removed invalid local NDK override.
- Set a valid installed NDK version in Gradle.
- Identified `ANDROID_NDK_HOME` environment override conflict and aligned it.
- Verified release APK build success.

## Q13. What proof can you show for progress?
- Updated backend modules for auth, repositories, chat, dashboard progression.
- Updated Flutter tabs/services for live sync and real data.
- Added phase planning artifact for phase 9.
- Successfully built release APK.

## Q14. What is currently stable?
- Auth to API integration.
- Roadmap persistence.
- Task completion updates.
- Cross-tab data refresh.
- Release build generation.

## Q15. What are the next technical steps?
- Two-device end-to-end regression testing.
- Permanent cleanup of local env overrides.
- Integration tests for roadmap transitions.
- Startup config validation checks for runtime URLs.

## Q16. One-line project status for viva
Eklavya.AI has moved from partially wired flows to a stable end-to-end roadmap system with key auth, DB, sync, and release blockers resolved.