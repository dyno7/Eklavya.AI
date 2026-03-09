# SPEC.md — Project Specification

> **Status**: `FINALIZED`

## Vision
Eklavya.AI is an AI-powered goal achievement platform that transforms ambitions into actionable, gamified, and adaptive plans across multiple domains (Learning, Fitness, Startup, Finance, Writing, and more). It uses a GenAI "Guru" for personalized roadmap generation, an Agentic AI "Coach" with reinforcement learning for proactive drift detection, and behavioral nudging for sustained motivation. The primary proof-of-concept domain is "Learning Deep Learning," delivered as a Flutter mobile app with a shared Python/FastAPI backend (also consumed by a React web app).

## Goals
1. **Guru Onboarding**: A conversational AI generates a personalized, time-bound roadmap with milestones for any supported domain.
2. **Multi-Domain Support**: Domain-specific AI tools for Learning, Fitness, Startup, Finance, Writing — each with tailored prompts, trackers, and analytics.
3. **Gamified Execution**: Users progress through tasks earning XP, badges, streaks, and "Dhanushya Challenges."
4. **Agentic Coach with RL**: A background AI agent uses reinforcement learning signals (user completion patterns, engagement decay) to detect drift and auto-adjust plans. Behavioral nudges are personalized based on the user's response history.
5. **Behavioral Chatbot**: The Guru isn't just an onboarding tool — it's an ongoing conversational coach that adapts its tone, motivation style, and intervention timing using behavioral psychology principles.
6. **Shared Backend**: A single Python/FastAPI + Supabase backend serves both the Flutter mobile app and the React web app.

## Non-Goals (Out of Scope)
- Voice-activated "Guru Mode" (future phase).
- Wearable integration (future phase).
- Payment/subscription features.
- Social features (leaderboards, sharing).

## Users
- **Primary**: Ambitious individuals pursuing goals across domains (learning, fitness, startups, finance, writing) who struggle with consistency and planning.
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
