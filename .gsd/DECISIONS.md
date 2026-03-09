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
