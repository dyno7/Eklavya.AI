---
phase: 2
plan: 2
wave: 1
---

# Plan 2.2: Navigation & Shell Structure

## Objective
Set up the GoRouter route tree (splash → login → onboarding → 5-tab shell) and the main shell scaffold with the floating glass bottom nav. This wires the entire app skeleton before we build individual screens.

## Context
- .gsd/phases/2/RESEARCH.md — GoRouter structure, StatefulShellRoute
- .gsd/phases/2/1-PLAN.md — GlassBottomNav widget (dependency)
- eklavya_mobile/lib/core/router/app_router.dart — Current placeholder router

## Tasks

<task type="auto">
  <name>Create tab screens and main shell scaffold</name>
  <files>
    eklavya_mobile/lib/features/shell/main_shell.dart
    eklavya_mobile/lib/features/dashboard/home_tab.dart
    eklavya_mobile/lib/features/goals/goals_tab.dart
    eklavya_mobile/lib/features/chat/chat_tab.dart
    eklavya_mobile/lib/features/analytics/analytics_tab.dart
    eklavya_mobile/lib/features/profile/profile_tab.dart
  </files>
  <action>
    1. **main_shell.dart** — `MainShell` StatelessWidget (or ConsumerWidget):
       - Receives `StatefulNavigationShell navigationShell` from GoRouter
       - Structure: GradientBackground → Scaffold (transparent) → body: navigationShell → bottomNavigationBar: GlassBottomNav
       - GlassBottomNav items: Home (Icons.home_rounded), Goals (Icons.flag_rounded), Chat (Icons.chat_bubble_rounded), Analytics (Icons.bar_chart_rounded), Profile (Icons.person_rounded)
       - onTap navigates via `navigationShell.goBranch(index)`

    2. **Create 5 tab placeholder files** (home_tab.dart, goals_tab.dart, chat_tab.dart, analytics_tab.dart, profile_tab.dart):
       - Each is a simple Scaffold with Center(Text("Tab Name"))
       - Uses AppColors.textPrimary for text
       - These will be replaced with full screens in Plans 2.3-2.5

    What to avoid and WHY:
    - Do NOT use BottomNavigationBar — we use custom GlassBottomNav (ADR-014)
    - Do NOT add real content to tabs yet — content is Plan 2.4/2.5
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/features/</verify>
  <done>MainShell scaffold with 5 tab placeholders, GlassBottomNav integrated</done>
</task>

<task type="auto">
  <name>Rewrite GoRouter with full route tree</name>
  <files>
    eklavya_mobile/lib/core/router/app_router.dart
    eklavya_mobile/lib/features/splash/splash_screen.dart
    eklavya_mobile/lib/features/auth/login_screen.dart
    eklavya_mobile/lib/features/onboarding/onboarding_screen.dart
  </files>
  <action>
    1. **Create stub screens** needed for routes:
       - `splash_screen.dart` — Simple Scaffold with Center(Text("Splash")), will be fleshed out in Plan 2.3
       - `login_screen.dart` — Simple Scaffold with Center(Text("Login")), will be fleshed out in Plan 2.3
       - `onboarding_screen.dart` — Simple Scaffold with Center(Text("Onboarding")), will be fleshed out in Plan 2.3

    2. **Rewrite app_router.dart**:
       ```
       Routes:
       / → SplashScreen (initial)
       /login → LoginScreen
       /onboarding → OnboardingScreen
       /shell → StatefulShellRoute.indexedStack
         ├── branch 0: /home → HomeTab
         ├── branch 1: /goals → GoalsTab
         ├── branch 2: /chat → ChatTab
         ├── branch 3: /analytics → AnalyticsTab
         └── branch 4: /profile → ProfileTab
       ```
       - Use `StatefulShellRoute.indexedStack` for tab state persistence
       - `navigatorKey` on root and each branch
       - Shell builder wraps child with `MainShell`

    What to avoid and WHY:
    - Do NOT use `ShellRoute` (non-stateful) — `StatefulShellRoute.indexedStack` preserves tab state
    - Do NOT add auth guards yet — dummy login handles routing manually
    - Do NOT add deep-link paths for details yet — shell-only in Phase 2
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/core/router/ && flutter analyze lib/features/</verify>
  <done>GoRouter has full route tree: splash → login → onboarding → 5-tab shell with StatefulShellRoute</done>
</task>

## Success Criteria
- [ ] MainShell scaffold with GlassBottomNav showing 5 tabs
- [ ] GoRouter routes: / (splash), /login, /onboarding, /shell with 5 branches
- [ ] Tab switching works without rebuilding (StatefulShellRoute.indexedStack)
- [ ] `flutter analyze` passes on router + features
