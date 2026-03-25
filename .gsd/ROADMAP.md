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
**Status**: ✅ Verified (10/10 must-haves PASS)
**Objective**: Design and deploy Supabase PostgreSQL schema (multi-domain aware), wire up basic API endpoints, set up auth.
**Requirements**: REQ-01 (DB schema), REQ-02 (Auth), REQ-03 (API scaffold)

### Phase 2: Premium Flutter App Shell
**Status**: ⬜ Not Started
**Objective**: Build a visually stunning Flutter app with dark glassmorphism theme, smooth navigation, skeleton loaders, micro-animations, and polished UX. This is the app shell before feature logic — navigation, theming, empty states, and design system.
**Requirements**: REQ-04 (Design system), REQ-05 (Navigation), REQ-06 (Animations)
**Depends on**: Phase 1

### Phase 3: App UI Polish
**Status**: ⬜ Not Started
**Objective**: Complete all visual and UX finishing touches on the Flutter app shell — light/dark theme toggle, animated bottom nav (label animates from beside icon to below icon), taller/rounder navbar, and fix the FAB visibility issue behind the navbar. After this phase, later phases only need to wire real data.
**Requirements**: REQ-04 (Design system), REQ-05 (Navigation), REQ-06 (Animations)
**Depends on**: Phase 2

### Phase 4: Home Screen Redesign & UI Polish
**Status**: ⬜ Not Started
**Objective**: Blinkit-style greeting header, notification badge, "Let's Continue" priority goal card, profile via avatar (removed from nav), Lottie animations, bottom nav fixes (shape glitch, label travel animation, light mode colors), analytics chart colors, and learning resources placeholder.
**Requirements**: REQ-04 (Design system), REQ-05 (Navigation), REQ-06 (Animations)
**Depends on**: Phase 3

### Phase 5: Guru Onboarding (GenAI)
**Status**: ⬜ Not Started
**Objective**: Build the conversational Guru Agent on the backend (multi-domain aware) and the chat UI in Flutter. User completes onboarding and receives a generated roadmap stored in the database. POC domain: Deep Learning.
**Requirements**: REQ-07 (Guru Agent), REQ-08 (Chat UI), REQ-09 (Multi-domain prompts)
**Depends on**: Phase 4

### Phase 6: Gamified Dashboard
**Status**: ⬜ Not Started
**Objective**: Render the generated roadmap as daily tasks in Flutter. Implement XP, badges, streaks, and Dhanushya Challenges with animations.
**Requirements**: REQ-10 (Task rendering), REQ-11 (Gamification engine)
**Depends on**: Phase 5

### Phase 7: Coach Agent, RL & Behavioral Chatbot
**Status**: ⬜ Not Started
**Objective**: Implement RL-based drift detection. Coach Agent auto-adjusts plans using user engagement signals. Behavioral chatbot provides ongoing motivation with adaptive tone and timing. Final E2E testing.
**Requirements**: REQ-12 (Coach Agent), REQ-13 (RL signals), REQ-14 (Behavioral chatbot), REQ-15 (E2E testing)
**Depends on**: Phase 6
