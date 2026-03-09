# ROADMAP.md

> **Current Phase**: Not started
> **Milestone**: v0.1 (MVP)

## Must-Haves (from SPEC)
- [ ] Guru Onboarding chat generates domain-specific roadmaps
- [ ] Multi-domain support (Learning, Fitness, Startup, Finance, Writing)
- [ ] Premium Flutter mobile app (gamified, animated, dark-mode)
- [ ] Gamified task dashboard with XP system
- [ ] Shared backend serving Flutter + React clients
- [ ] Coach Agent with RL-based drift detection
- [ ] Behavioral chatbot for ongoing motivation

## Phases

### Phase 1: Foundation & Database
**Status**: ⬜ Not Started
**Objective**: Design and deploy Supabase PostgreSQL schema (multi-domain aware), wire up basic API endpoints, set up auth.
**Requirements**: REQ-01 (DB schema), REQ-02 (Auth), REQ-03 (API scaffold)

### Phase 2: Premium Flutter App Shell
**Status**: ⬜ Not Started
**Objective**: Build a visually stunning Flutter app with dark glassmorphism theme, smooth navigation, skeleton loaders, micro-animations, and polished UX. This is the app shell before feature logic — navigation, theming, empty states, and design system.
**Requirements**: REQ-04 (Design system), REQ-05 (Navigation), REQ-06 (Animations)
**Depends on**: Phase 1

### Phase 3: Guru Onboarding (GenAI)
**Status**: ⬜ Not Started
**Objective**: Build the conversational Guru Agent on the backend (multi-domain aware) and the chat UI in Flutter. User completes onboarding and receives a generated roadmap stored in the database. POC domain: Deep Learning.
**Requirements**: REQ-07 (Guru Agent), REQ-08 (Chat UI), REQ-09 (Multi-domain prompts)
**Depends on**: Phase 2

### Phase 4: Gamified Dashboard
**Status**: ⬜ Not Started
**Objective**: Render the generated roadmap as daily tasks in Flutter. Implement XP, badges, streaks, and Dhanushya Challenges with animations.
**Requirements**: REQ-10 (Task rendering), REQ-11 (Gamification engine)
**Depends on**: Phase 3

### Phase 5: Coach Agent, RL & Behavioral Chatbot
**Status**: ⬜ Not Started
**Objective**: Implement RL-based drift detection. Coach Agent auto-adjusts plans using user engagement signals. Behavioral chatbot provides ongoing motivation with adaptive tone and timing. Final E2E testing.
**Requirements**: REQ-12 (Coach Agent), REQ-13 (RL signals), REQ-14 (Behavioral chatbot), REQ-15 (E2E testing)
**Depends on**: Phase 4
