# DECISIONS.md — Architecture Decision Records

## ADR-001: Flutter over React Native
- **Date**: 2026-03-08
- **Decision**: Use Flutter for the mobile app
- **Alternatives**: React Native (would share code with React web dev)
- **Rationale**: User preference; Flutter excels at complex gamification animations (XP counters, Dhanushya Challenges)

## ADR-002: Python/FastAPI for Shared Backend
- **Date**: 2026-03-08
- **Decision**: Python with FastAPI
- **Alternatives**: Node.js/TypeScript
- **Rationale**: Best ecosystem for Agentic AI (LangChain, CrewAI, LangGraph). Both Flutter and React clients consume the same REST API.

## ADR-003: Supabase (PostgreSQL) over Firebase
- **Date**: 2026-03-08
- **Decision**: Supabase with PostgreSQL
- **Alternatives**: Firebase (Firestore)
- **Rationale**: Relational data model (Users → Goals → Milestones → Tasks). pgvector support for future semantic search. Real-time sync available via Supabase Realtime.

## ADR-004: Thin Client Architecture
- **Date**: 2026-03-08
- **Decision**: All AI logic lives on the backend. Flutter app contains zero prompt engineering or LLM SDKs.
- **Alternatives**: Thick client with local LLM calls
- **Rationale**: Ensures Web and Mobile stay perfectly synced. Avoids duplicating AI logic in Dart and JavaScript. Keeps mobile app lightweight.

---

## Phase 1 Decisions

**Date:** 2026-03-10

### ADR-005: Defer Gamification Tables to Phase 4
- **Decision**: Schema in Phase 1 includes only `users`, `goals`, `milestones`, `tasks`. Gamification tables (XP logs, badges, streaks) are created in Phase 4.
- **Alternatives**: Include all tables upfront for simpler migration
- **Rationale**: Kaizen JIT — build only what's needed now. Phase 4 (Gamified Dashboard) is where these tables are consumed.

### ADR-006: Keep Full API Surface in Phase 1
- **Decision**: Build all CRUD endpoints for the core entities (goals, milestones, tasks, users) in Phase 1, even though they won't be consumed until later phases.
- **Alternatives**: Minimal endpoints to prove foundation works
- **Rationale**: Planting routes now makes mapping and routing easier when building the Flutter UI in Phase 2 and beyond.

### ADR-007: SQLAlchemy/asyncpg over Supabase Python Client
- **Decision**: Use SQLAlchemy 2.0 async + asyncpg to connect directly to the Supabase PostgreSQL instance. Consider hybrid approach (Option C) later if needed.
- **Alternatives**: (A) supabase-py REST client, (C) Hybrid
- **Rationale**: Full SQL power, proper ORM support, migration capability with Alembic. Not locked into Supabase SDK limitations.

### ADR-008: uv + pyproject.toml for Python Project Management
- **Decision**: Adopt `uv` with `pyproject.toml` instead of plain `requirements.txt`.
- **Alternatives**: pip + requirements.txt
- **Rationale**: Modern Python project management, faster dependency resolution, lockfile support. User comfortable with both pip and uv.

### ADR-009: Defer Tests to Verification Phase
- **Decision**: No unit/integration tests in Phase 1. Add tests in a dedicated verification phase following Phase 1.
- **Alternatives**: Include basic API tests in Phase 1
- **Rationale**: Phase 1 focus is foundation delivery. Tests will be added systematically after the foundation is proven.

### ADR-010: Defer RLS to Later Phase
- **Decision**: Row Level Security policies are not added in Phase 1.
- **Alternatives**: Add RLS during initial schema creation
- **Rationale**: Thin Client architecture means all DB access goes through the backend — JWT auth + user_id scoping in queries provides equivalent security. RLS is important when clients access Supabase directly, which we don't do.

---

## Phase 2 Decisions

**Date:** 2026-03-11

### ADR-011: 5-Tab Bottom Navigation
- **Decision**: Main shell uses 5 tabs: Home, Goals, Chat, Analytics, Profile
- **Alternatives**: 3-4 tabs (no Analytics, or combining Profile into drawer)
- **Rationale**: Analytics tab surfaces progress/streaks data that motivates users. All 5 tabs are core to the gamified learning experience.

### ADR-012: Full Design Token System (Option B)
- **Decision**: Implement comprehensive design tokens: spacing scale, corner radii, elevation, typography, color palette, animation durations — all codified.
- **Alternatives**: Lightweight theme (Option A — just colors + text styles)
- **Rationale**: Full tokens ensure consistency across 10+ screens and make Phase 3/4/5 development faster. Investment now pays off throughout.

### ADR-013: flutter_animate for Micro-Animations
- **Decision**: Use `flutter_animate` package for declarative animation chaining.
- **Alternatives**: Flutter built-in transitions only (zero deps)
- **Rationale**: `flutter_animate` provides clean `.animate().fadeIn().slideY()` syntax, dramatically simplifies complex sequences. Gold standard in Flutter community.

### ADR-014: Dark Glassmorphism with Purple/Blue Palette
- **Decision**: Dark mode glassmorphism inspired by Dribbble reference (Barber Booking App). Colors: deep purple → midnight blue gradient. Accent: electric blue/cyan. No orange.
- **Alternatives**: Light mode, Material default theming
- **Rationale**: Dark glass aesthetic matches the "Guru/Mystical" brand. Reference provides proven layout patterns (floating nav dock, hero cards, category chips).

### ADR-015: Dummy Auth in Phase 2
- **Decision**: Implement a styled login/signup screen with hardcoded credentials (admin@gmail.com / 123456). Real Supabase JWT auth comes later.
- **Alternatives**: Skip auth screen entirely, or integrate real auth now
- **Rationale**: Shell needs the login flow for UX completeness. Hardcoded credentials let us demo without Supabase dependency.

### ADR-016: Demo Data Over Empty States
- **Decision**: Phase 2 screens show hardcoded demo data (sample goals, XP, tasks, charts) rather than empty states.
- **Alternatives**: Show "No data yet" empty states everywhere
- **Rationale**: Interactive demo proves UX quality. Hardcoded data will be replaced by real API calls in Phase 3/4.
