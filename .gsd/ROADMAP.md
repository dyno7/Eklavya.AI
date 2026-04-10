# ROADMAP.md

> **Current Phase**: 10 (⬜ Not Started)
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
**Status**: ✅ Complete
**Objective**: Render actionable roadmap via goals_tab timeline UI. Provide chatbot with roadmap memory + conversation history. Update Profile tab to use real Supabase queries with unlocked badges master table + 2 skeleton loaders. Polish UI by frosting the bottom navigation bar and adding global SlideTransition pages. Create notifications feature with unread badge + Realtime subscription.
**Depends on**: Phase 7

**Tasks**:
- [x] 8.1: GoalRoadmapScreen interactive timeline
- [x] 8.2: Chat roadmap context injection
- [x] 8.3: Profile real badge data
- [x] 8.4: Frosted bottom nav + slide transitions
- [x] 8.5: Notifications framework

**Verification**: ✅ Executed and verified.

---

### Phase 9: Bug Fixes, UI Polish & Chat Memory
**Status**: ✅ Complete
**Objective**: Fix critical UX bugs (stale milestone, hardcoded XP bar/streak, fake analytics, generic task detail), create real analytics endpoint, wire persistent chat memory.
**Requirements**: REQ-10 (Task rendering), REQ-11 (Gamification), REQ-14 (Behavioral chatbot)
**Depends on**: Phase 8

**Tasks**:
- [x] 9.1: Milestone sync fix + analytics endpoint + display name
- [x] 9.2: XP bar, streak dots, real analytics tab, task detail panel
- [x] 9.3: Chat memory (already wired)

**Verification**: ✅ All 8 must-haves PASS

---

### Phase 10: Gamification Improvements
**Status**: ⬜ Not Started
**Objective**: Deepen the XP/gamification loop — streak-based XP multipliers, milestone/goal completion bonuses, badge auto-award on trigger events, level-up detection from the API, floating XP toast overlay in Flutter, level-up modal, richer task cards (icon + time + XP pill + difficulty dot), and shimmer glow on earned badge cards in Profile.
**Requirements**: REQ-10 (Task rendering), REQ-11 (Gamification engine)
**Depends on**: Phase 9

**Tasks**:
- [ ] 10.1 (Wave 1): Backend — streak multiplier (1.2x at 3d, 1.5x at 7d), milestone +50 XP, goal +200 XP bonuses, level-up detection in `claim_task`, badge auto-award via `award_badge_if_not_earned`
- [ ] 10.2 (Wave 2): Flutter — floating XP toast overlay (animates up + fades), level-up bottom sheet modal, `TaskClaimResult` service class
- [ ] 10.3 (Wave 2): Flutter — rich task cards (icon circle, time/XP/difficulty pills), badge shimmer glow on Profile tab

**Verification**:
- Streak >= 3 user earns bonus XP on task completion (visible in response `bonus_xp`)
- Level-up modal appears when XP crosses a level boundary
- "First Steps" badge auto-awarded on first task completion
- Task cards show icon + time + XP pill on Home tab

---

### Phase 11: Coach Agent with RL-Based Drift Detection
**Status**: ⬜ Not Started
**Objective**: Build a backend Coach Agent that monitors user behavioral signals (task completion rate, streak breaks, XP velocity) over time to detect when a user is drifting off-track. Implement a simple reinforcement-learning-inspired scoring model (no full RL framework needed — rule-based reward shaping + trend analysis is sufficient) that triggers personalized re-engagement nudges and roadmap difficulty adjustments. Expose a `/coach/status` endpoint and wire nudge notifications into the Flutter app.
**Requirements**: REQ-12 (Coach Agent), REQ-13 (RL Drift Detection)
**Depends on**: Phase 10

**Tasks**:
- [ ] 11.1: Behavioral signal collector — aggregate daily XP, streak, and completion-rate metrics per user into a `user_behavior_log` table
- [ ] 11.2: Drift-detection model — sliding-window trend scorer (3-day / 7-day) with configurable thresholds; classifies user state as ON_TRACK / DRIFTING / DISENGAGED
- [ ] 11.3: Reward-shaping engine — define reward signals (task done on time = +1, missed = -0.5, streak break = -1) stored as RL-style episodic logs
- [ ] 11.4: Coach decision layer — given drift state + reward history, select intervention: none / soft-nudge / roadmap-adjust / hard-alert
- [ ] 11.5: `/coach/status` API endpoint — returns current drift state + recommended intervention for the authenticated user
- [ ] 11.6: Flutter Coach nudge UI — banner / notification card on Home tab when drift detected; "Get back on track" CTA
- [ ] 11.7: Scheduled background job (APScheduler) — runs drift detection daily for all active users

**Verification**:
- Drift state correctly classifies a simulated 7-day drop in completions as DRIFTING
- API returns nudge payload; Flutter displays banner
- Background job logs run timestamps

---

### Phase 12: Behavioral Chatbot for Ongoing Motivation
**Status**: ⬜ Not Started
**Objective**: Evolve the existing Guru chatbot into a full behavioral-psychology-informed motivational coach. The chatbot should detect emotional tone in user messages (frustration, plateau, excitement), adapt its response style accordingly, use Motivational Interviewing (MI) techniques, and proactively send scheduled check-in messages. Integrate Coach Agent drift state from Phase 11 so the chatbot has real-time context about the user's behavioral trajectory.
**Requirements**: REQ-14 (Behavioral Chatbot)
**Depends on**: Phase 11

**Tasks**:
- [ ] 12.1: Tone & sentiment classifier — lightweight prompt-based classifier (via Gemini) to label user message as: FRUSTRATED / PLATEAUED / MOTIVATED / NEUTRAL
- [ ] 12.2: Adaptive system prompt engine — dynamically prepend tone-appropriate persona instructions to the Gemini system prompt (e.g., empathetic + MI-style for FRUSTRATED)
- [ ] 12.3: Motivational Interviewing pattern library — curated set of MI techniques (open questions, affirmations, reflections, summaries) injected as few-shot examples based on tone
- [ ] 12.4: Coach Agent context injection — pull drift state from Phase 11's `/coach/status` and inject into chatbot context so Gemini knows user is ON_TRACK / DRIFTING
- [ ] 12.5: Proactive check-in scheduler — APScheduler job sends "How is it going?" style nudge messages to the chat via Supabase Realtime when user hasn't interacted in 48h
- [ ] 12.6: Flutter chat enhancements — typing indicator, emotion-tagged message bubbles (subtle colour tint based on detected tone), animated send button
- [ ] 12.7: Behavioral response metrics — log tone labels + intervention type per session for future analysis

**Verification**:
- Frustrated message receives empathetic MI-style response (not generic)
- Drifting user sees drift-aware chatbot context in reply
- Proactive check-in fires after simulated 48h inactivity
