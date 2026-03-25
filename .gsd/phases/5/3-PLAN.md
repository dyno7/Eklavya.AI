---
phase: 5
plan: 3
wave: 3
depends_on: [1, 2]
files_modified:
  - eklavya_backend/app/agents/guru_agent.py
  - eklavya_backend/app/presentation/chat.py
  - eklavya_backend/app/presentation/goals.py
  - eklavya_mobile/lib/features/chat/chat_tab.dart
  - eklavya_mobile/lib/features/dashboard/home_tab.dart
autonomous: false

must_haves:
  truths:
    - "Generated roadmap is saved as a Goal with Milestones and Tasks in the database"
    - "Chat UI shows a 'Roadmap Generated!' success state with confetti Lottie"
    - "Home tab Let's Continue card shows the newly generated goal"
  artifacts:
    - "POST /api/chat/send auto-persists roadmap when generation completes"
    - "chat_tab.dart shows success animation after roadmap generation"
---

# Plan 5.3: Roadmap Persistence + E2E Flow

## Objective
Connect the dots: when the Guru finishes generating a roadmap, save it to the database as a real Goal with Milestones and Tasks, and show a success state in the Flutter app.

Purpose: This completes the core loop — onboard → chat → generate plan → see it on dashboard.

## Context
- .gsd/SPEC.md
- eklavya_backend/app/agents/guru_agent.py
- eklavya_backend/app/presentation/goals.py
- eklavya_mobile/lib/features/chat/chat_tab.dart
- eklavya_mobile/lib/features/dashboard/home_tab.dart

## Tasks

<task type="auto">
  <name>Persist generated roadmap to database</name>
  <files>
    eklavya_backend/app/agents/guru_agent.py
    eklavya_backend/app/presentation/chat.py
    eklavya_backend/app/presentation/goals.py
  </files>
  <action>
    1. In chat.py POST /send handler: when GuruAgent returns a roadmap (is_roadmap_ready=True):
       - Parse the roadmap JSON into Goal + Milestone + Task creates
       - Call the existing goals repository to create the goal with nested milestones/tasks
       - Include the created goal_id in the response
    2. Add a new field to ChatMessageResponse: goal_id: str | None = None
    3. Ensure the generated roadmap includes realistic Deep Learning milestones:
       - Linear Algebra & Calculus fundamentals
       - Neural Network basics
       - Backpropagation & optimizers
       - CNNs & image recognition
       - RNNs & sequence models
       - Transformers & attention
       - Project: build and train a model
    AVOID: Duplicating goal creation logic — use the existing repository functions
  </action>
  <verify>Send chat messages until roadmap is generated, verify goal appears in GET /api/goals</verify>
  <done>Roadmap is saved to DB. Goal with milestones and tasks is queryable via existing API.</done>
</task>

<task type="checkpoint:human-verify">
  <name>Add success animation and verify E2E flow</name>
  <files>
    eklavya_mobile/lib/features/chat/chat_tab.dart
    eklavya_mobile/lib/features/dashboard/home_tab.dart
  </files>
  <action>
    1. In chat_tab.dart: when ChatService returns a response with roadmap data:
       - Show confetti Lottie animation (assets/lottie/confetti.json) overlay
       - Replace the chat input with a "View Your Roadmap →" gradient button
       - Show a success message bubble from Guru: "Your personalized {domain} roadmap is ready!"
    2. In home_tab.dart: when navigating back from chat, the Let's Continue card should reflect the new goal (for now, still uses DemoData — real data connection comes in Phase 6)
    3. USER VERIFIES: Run the full flow on device — open chat, have conversation, see roadmap generated, see confetti, tap button
  </action>
  <verify>User runs app and completes onboarding flow end-to-end on device</verify>
  <done>Full flow works: chat → AI conversation → roadmap generated → confetti → success state</done>
</task>

## Success Criteria
- [ ] Chat conversation leads to roadmap generation
- [ ] Roadmap is persisted as Goal + Milestones + Tasks in database
- [ ] Confetti animation plays on generation success
- [ ] "View Your Roadmap" button appears after generation
- [ ] `flutter analyze lib/` passes with zero errors
