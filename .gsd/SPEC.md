# SPEC.md — Project Specification

> **Status**: `FINALIZED`

## Vision
Eklavya.AI is an AI-powered goal achievement platform that transforms ambitions into actionable, gamified, and adaptive plans. It uses a GenAI "Guru" for personalized roadmap generation and an Agentic AI "Coach" for proactive drift detection and recovery. The MVP focuses on the "Learning Deep Learning" domain as proof of concept, delivered as a Flutter mobile app with a shared Python/FastAPI backend (also consumed by a React web app).

## Goals
1. **Guru Onboarding**: A conversational AI generates a personalized, time-bound Deep Learning curriculum with milestones.
2. **Gamified Execution**: Users progress through tasks earning XP, badges, streaks, and "Dhanushya Challenges."
3. **Agentic Coach**: A background AI agent detects when users drift off-track and auto-adjusts the plan with recovery strategies.
4. **Shared Backend**: A single Python/FastAPI + Supabase backend serves both the Flutter mobile app and the React web app.

## Non-Goals (Out of Scope)
- Voice-activated "Guru Mode" (future phase).
- Wearable integration (future phase).
- Multi-domain support beyond "Learning Deep Learning" (future phase — architecture supports it, but UI/prompts are scoped to one domain).
- Payment/subscription features.
- Social features (leaderboards, sharing).

## Users
- **Primary**: Ambitious learners who want to master Deep Learning but struggle with consistency and planning.
- **Secondary**: The development team pitching Eklavya.AI as a unified web + mobile product.

## Constraints
- **Technical**: Flutter for mobile, React for web, Python/FastAPI shared backend, Supabase (PostgreSQL) database.
- **Team**: App dev (user) builds the Flutter app; web dev builds the React app; backend is shared.
- **Timeline**: MVP / proof-of-concept scope — ship the smallest complete loop (onboard → generate plan → execute tasks → earn XP).
- **AI**: GenAI calls happen server-side only (Thin Client pattern). No LLM SDKs in the Flutter app.

## Success Criteria
- [ ] User completes the Guru onboarding chat and receives a personalized Deep Learning roadmap.
- [ ] Roadmap renders as actionable daily tasks in the Flutter app.
- [ ] Completing a task awards XP and triggers a gamification animation.
- [ ] The same roadmap data is accessible from the React web app via the shared backend.
- [ ] The Coach Agent detects 3+ days of inactivity and auto-adjusts the plan.
