---
phase: 9
plan: 1
wave: 1
---

# Plan 9.1: Roadmap Progress Sync, Live Profile, Analytics, and Chat Memory

## Objective
Make roadmap progression feel real-time and reliable across Home, Goals, Analytics, Profile, and Chat.

## Context
- eklavya_backend/app/presentation/dashboard.py
- eklavya_backend/app/presentation/chat.py
- eklavya_backend/app/presentation/users.py
- eklavya_backend/app/core/repositories.py
- eklavya_backend/app/domain/models.py
- eklavya_mobile/lib/features/dashboard/home_tab.dart
- eklavya_mobile/lib/features/goals/goals_tab.dart
- eklavya_mobile/lib/features/goals/goal_roadmap_screen.dart
- eklavya_mobile/lib/features/analytics/analytics_tab.dart
- eklavya_mobile/lib/features/profile/profile_tab.dart
- eklavya_mobile/lib/core/services/dashboard_service.dart
- eklavya_mobile/lib/core/services/goals_service.dart
- eklavya_mobile/lib/core/services/user_service.dart

## Tasks

<task type="auto">
  <name>Milestone Progress Sync</name>
  <files>eklavya_backend/app/presentation/dashboard.py, eklavya_backend/app/core/repositories.py</files>
  <action>
    Advance milestone and goal status when the last task in a milestone is completed, and mark the goal complete once all milestones are done.
  </action>
  <done>Goal progress reflects completed milestones instead of staying stuck at 0/n.</done>
</task>

<task type="auto">
  <name>Live UI Refresh</name>
  <files>eklavya_mobile/lib/core/services/dashboard_service.dart, eklavya_mobile/lib/features/dashboard/home_tab.dart, eklavya_mobile/lib/features/goals/goals_tab.dart, eklavya_mobile/lib/features/profile/profile_tab.dart, eklavya_mobile/lib/features/analytics/analytics_tab.dart</files>
  <action>
    Broadcast roadmap changes from task completion and refresh every dependent tab immediately.
  </action>
  <done>Home, Goals, Profile, and Analytics update without manual navigation refresh.</done>
</task>

<task type="auto">
  <name>Task Card UX</name>
  <files>eklavya_mobile/lib/features/goals/goal_roadmap_screen.dart</files>
  <action>
    Render milestones as expandable sections with task checkboxes and detail dropdowns for easier user comprehension.
  </action>
  <done>Each milestone contains tappable, expandable task cards with completion controls.</done>
</task>

<task type="auto">
  <name>User Identity Repair</name>
  <files>eklavya_backend/app/presentation/users.py, eklavya_backend/app/presentation/dashboard.py, eklavya_backend/app/core/auth.py</files>
  <action>
    Seed and repair display names from JWT claims or auth metadata so "User" is replaced with the actual login name where possible.
  </action>
  <done>Profile and home greeting use the login-provided display name instead of the placeholder.</done>
</task>

<task type="auto">
  <name>Persistent Chat Memory</name>
  <files>eklavya_backend/app/presentation/chat.py, eklavya_backend/app/agents/guru_agent.py, eklavya_backend/app/core/repositories.py, eklavya_backend/app/domain/models.py</files>
  <action>
    Persist recent chat turns and feed them back into the Guru so the user can retrieve and modify existing roadmaps.
  </action>
  <done>Chat memory is stored and reused as context for future roadmap edits.</done>
</task>

## Success Criteria
- [ ] Completing a task updates milestone and goal progress.
- [ ] UI refreshes automatically after roadmap changes.
- [ ] Profile uses real user identity.
- [ ] Chat can retrieve prior roadmap context.
