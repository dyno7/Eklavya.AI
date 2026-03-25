---
phase: 2
plan: 5
wave: 3
---

# Plan 2.5: Analytics Tab & Profile Tab

## Objective
Build the remaining 2 tabs. Analytics shows demo progress charts (XP history, streak calendar, domain distribution). Profile shows user info, badges, and settings toggles.

## Context
- .gsd/phases/2/RESEARCH.md — Demo data shapes (DemoAnalytics)
- .gsd/phases/2/4-PLAN.md — Demo data provider (dependency)
- .gsd/phases/2/1-PLAN.md — GlassCard, GlowIcon widgets

## Tasks

<task type="auto">
  <name>Build Analytics tab with demo charts</name>
  <files>
    eklavya_mobile/lib/features/analytics/analytics_tab.dart
  </files>
  <action>
    Replace stub with full analytics screen:

    1. **Layout** — SafeArea → SingleChildScrollView → Column:
       - **Header**: "Analytics" in headlineMedium + "Your learning journey" subtitle

       - **Weekly XP Card** (GlassCard):
         - "This Week" label + total XP number (bold, accent color)
         - Simple bar chart: 7 vertical bars (Mon-Sun) using Container widgets
         - Each bar height proportional to daily XP from demo data
         - Active day (today) highlighted with AppColors.primary, others AppColors.surfaceLight
         - Day labels below (M T W T F S S)

       - **Streak Calendar Card** (GlassCard):
         - "Current Streak: 12 days 🔥" header
         - Grid of 30 small circles (last 30 days):
           - Completed day: filled with AppColors.success
           - Missed day: AppColors.error at 30% opacity
           - Future day: AppColors.surface
           - Today: bordered with AppColors.primary

       - **Domain Distribution Card** (GlassCard):
         - "Learning Focus" header
         - Horizontal progress bars per domain:
           - Deep Learning: 45% (purple)
           - Startup: 30% (blue)
           - Writing: 25% (cyan)
         - Each bar: domain name + percentage label

    2. **Animations**:
       - Bar chart bars grow upward with stagger (flutter_animate)
       - Streak circles fade in row by row
       - All cards stagger in

    What to avoid and WHY:
    - Do NOT use chart packages (fl_chart etc) — build simple charts with Containers to avoid extra deps
    - Charts are demo-only and will be rebuilt with real data in Phase 4
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/features/analytics/</verify>
  <done>Analytics tab with 3 demo chart cards (weekly XP bars, streak calendar, domain distribution)</done>
</task>

<task type="auto">
  <name>Build Profile tab with settings</name>
  <files>
    eklavya_mobile/lib/features/profile/profile_tab.dart
  </files>
  <action>
    Replace stub with full profile screen:

    1. **Layout** — SafeArea → SingleChildScrollView → Column:
       - **Profile Header** (GlassCard, large):
         - Avatar circle (initials "A" on purple gradient, 80px)
         - "Arjun" display name in headlineMedium
         - "Level 7 • 2,450 XP" subtitle in textSecondary
         - "Edit Profile" outlined button

       - **Badges Section**:
         - "Badges" header + "4 earned" subtitle
         - Horizontal scroll of badge cards (small GlassCards):
           - "🔥 Week Warrior" (7-day streak)
           - "📚 Bookworm" (5 readings completed)
           - "🧠 Quiz Master" (10 quizzes passed)
           - "⚡ Fast Learner" (3 tasks in 1 day)
         - Each badge: emoji icon, title, description underneath

       - **Stats Row** (3 small GlassCards in a Row):
         - Goals Active: "3"
         - Tasks Done: "47"
         - Days Active: "28"

       - **Settings Section** (GlassCard):
         - ListTile-style rows:
           - "Dark Mode" — Toggle switch (always on, non-functional)
           - "Notifications" — Toggle switch (demo)
           - "Language" — "English" with chevron
           - "About Eklavya.AI" — chevron
           - "Sign Out" — AppColors.error text, navigates to /login

    2. **Sign Out** clears SharedPreferences and `context.go('/login')`

    3. **Animations**: Cards stagger in, badge scroll has entrance animation

    What to avoid and WHY:
    - Do NOT implement real profile editing — dummy data only
    - Do NOT add notification settings logic — just UI toggles
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/features/profile/</verify>
  <done>Profile tab with avatar, badges, stats, settings, and sign out — all demo data</done>
</task>

## Success Criteria
- [ ] Analytics tab: weekly XP bars, streak calendar grid, domain distribution bars
- [ ] Profile tab: avatar + info header, badge carousel, stats row, settings with sign out
- [ ] Sign out clears state and routes to /login
- [ ] All charts built with simple Container widgets (no chart packages)
- [ ] `flutter analyze` passes
