---
phase: 6
plan: 3
wave: 3
depends_on: [1, 2]
files_modified:
  - eklavya_mobile/lib/features/dashboard/home_tab.dart
  - eklavya_mobile/lib/features/chat/chat_tab.dart
  - eklavya_mobile/lib/core/widgets/glass_bottom_nav.dart
autonomous: false

must_haves:
  truths:
    - "Home tab Let's Continue card uses REAL active goal"
    - "Home tab Tasks list draws from REAL pending tasks"
    - "Home tab XP and streak cards use REAL user stats"
    - "Tapping 'View Your Roadmap' in chat routes to home and reloads data"
    - "Dangling buttons are connected or show 'Coming Soon' toasts"
  artifacts:
    - "home_tab.dart refactored to use FutureBuilder or explicit state for DashboardService"
---

# Plan 6.3: Flutter UI Data Binding & Linking

## Objective
Wire the final UI connections. Replace DemoData on the `HomeTab` with real data from `DashboardService`, and connect the standalone buttons that are currently dead.

Purpose: Complete the Phase 6 user journey. The app should feel completely "finished" from a navigation and onboarding standpoint.

## Context
- .gsd/SPEC.md
- eklavya_mobile/lib/features/dashboard/home_tab.dart
- eklavya_mobile/lib/features/chat/chat_tab.dart

## Tasks

<task type="auto">
  <name>Bind HomeTab to DashboardService</name>
  <files>
    eklavya_mobile/lib/features/dashboard/home_tab.dart
  </files>
  <action>
    1. Update `_HomeTabState` to fetch `DashboardSummary` in `initState()`
    2. Replace the static `DemoData.activeGoal` usage with the fetched goal (if none, show Empty State pointing to Chat)
    3. Replace `DemoData.todayTasks` with fetched tasks
    4. Replace XP/Streak hardcoded values with fetched `total_xp` / `current_streak`
    5. Add action to tasks: when clicking a task, show a fast loading state, call `completeTask()`, then refresh `getSummary()` and play `xp_star` animation!
  </action>
  <verify>flutter analyze lib/features/dashboard/home_tab.dart</verify>
  <done>Home screen reads and writes real data</done>
</task>

<task type="auto">
  <name>Link dangling buttons and complete flow</name>
  <files>
    eklavya_mobile/lib/features/chat/chat_tab.dart
    eklavya_mobile/lib/features/dashboard/home_tab.dart
  </files>
  <action>
    1. In `chat_tab.dart`: the "View Your Roadmap" button should call `context.go('/')` to navigate back to Home. Home will refetch on load.
    2. In `home_tab.dart`:
       - Notification button `onTap`: Check if user has notifications. Show empty state modal or toast "No new notifications".
       - Header Profile avatar `onTap`: `context.push('/profile')`
       - View All tasks button `onTap`: Toast "Coming soon (Phase 7)"
  </action>
  <verify>Manual verification in the app</verify>
  <done>All buttons are linked</done>
</task>

<task type="checkpoint:human-verify">
  <name>End-to-End Gamification Test</name>
  <action>
    1. User generates a roadmap in Chat.
    2. User clicks "View Your Roadmap".
    3. User is routed Home. Dashboard accurately shows the new goal.
    4. User taps a task. XP increments and animation plays.
  </action>
</task>

## Success Criteria
- [ ] No dead buttons in the UI
- [ ] `HomeTab` seamlessly updates from backend
- [ ] Chat flow deposits user back on `HomeTab`
- [ ] Task completion updates XP in real-time
