# ROADMAP.md

> **Current Phase**: 6 (complete) → Phase 7 next
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
**Status**: ✅ Complete
**Objective**: Build a visually stunning Flutter app with dark glassmorphism theme, smooth navigation, skeleton loaders, micro-animations, and polished UX.
**Requirements**: REQ-04 (Design system), REQ-05 (Navigation), REQ-06 (Animations)
**Depends on**: Phase 1

### Phase 3: App UI Polish
**Status**: ✅ Complete
**Objective**: Complete all visual and UX finishing touches on the Flutter app shell — light/dark theme toggle, animated bottom nav, FAB fix.
**Requirements**: REQ-04 (Design system), REQ-05 (Navigation), REQ-06 (Animations)
**Depends on**: Phase 2

### Phase 4: Home Screen Redesign & UI Polish
**Status**: ✅ Complete
**Objective**: Blinkit-style greeting header, notification badge, "Let's Continue" priority goal card, profile via avatar, Lottie animations, nav fixes.
**Requirements**: REQ-04 (Design system), REQ-05 (Navigation), REQ-06 (Animations)
**Depends on**: Phase 3

### Phase 5: Guru Onboarding (GenAI)
**Status**: ✅ Complete
**Objective**: Build the conversational Guru Agent on the backend (multi-domain aware) and the chat UI in Flutter. User completes onboarding and receives a generated roadmap stored in the database.
**Requirements**: REQ-07 (Guru Agent), REQ-08 (Chat UI), REQ-09 (Multi-domain prompts)
**Depends on**: Phase 4

### Phase 6: Gamified Dashboard
**Status**: ✅ Complete
**Objective**: Render the generated roadmap as daily tasks in Flutter. Implement XP, streaks, and dashboard API. Wire real data to home screen.
**Requirements**: REQ-10 (Task rendering), REQ-11 (Gamification engine)
**Depends on**: Phase 5

### Phase 7: E2E Integration, Auth & Make It Work
**Status**: ✅ Complete
**Objective**: Make the app actually work end-to-end. Replace dummy auth (hardcoded `admin@gmail.com`) with real Supabase Auth (email+password + sign-up). Propagate the Supabase JWT from Flutter to all backend API calls. Run Alembic DB migrations so new columns exist. Verify Gemini API key is loaded and called. Fix the chat backend URL for physical devices. Full E2E flow on device: Login → Chat with Guru → AI-generated roadmap saved to DB → Home shows real goal and tasks.
**Requirements**: REQ-02 (Auth), REQ-03 (API), REQ-07 (Guru Agent), REQ-10 (Task rendering)
**Depends on**: Phase 6

---

### Phase 8: Roadmap UI, Chat Context & Profile Polishing
**Status**: ⬜ Not Started
**Objective**: Render actionable roadmap via goals_tab timeline UI. Provide chatbot with roadmap memory + conversation history. Update Profile tab to use real Supabase queries with unlocked badges master table + 2 skeleton loaders. Polish UI by frosting the bottom navigation bar and adding global SlideTransition pages. Create notifications feature with unread badge + Realtime subscription.
**Depends on**: Phase 7

**Tasks**:
- [ ] TBD (run /plan 8 to create)

**Verification**:
- TBD

---

### Phase 9: Coach Agent, RL & Behavioral Chatbot
**Status**: ⬜ Not Started
**Objective**: Implement RL-based drift detection. Coach Agent auto-adjusts plans using user engagement signals. Behavioral chatbot provides ongoing motivation with adaptive tone and timing. Final E2E testing.
**Requirements**: REQ-12 (Coach Agent), REQ-13 (RL signals), REQ-14 (Behavioral chatbot), REQ-15 (E2E testing)
**Depends on**: Phase 7
