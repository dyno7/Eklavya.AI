---
phase: 4
plan: 2
wave: 1
depends_on: []
files_modified:
  - eklavya_mobile/lib/core/widgets/glass_bottom_nav.dart
  - eklavya_mobile/lib/features/shell/main_shell.dart
  - eklavya_mobile/lib/core/router/app_router.dart
  - eklavya_mobile/lib/core/theme/app_colors.dart
autonomous: true

must_haves:
  truths:
    - "Bottom nav has 4 tabs (no Profile)"
    - "Label travels from beside to below — no fade in/out"
    - "Nav bar container never changes shape during animation"
    - "Light mode nav has dark background with white icons/text"
  artifacts:
    - "main_shell.dart has 4 nav items"
    - "app_router.dart has /profile as standalone route"
    - "app_colors.dart has navBackground, navText, navInactiveIcon"
---

# Plan 4.2: Bottom Nav Bar Fixes + Profile Route Change

## Objective
Fix 3 bottom nav bugs (shape glitch, label travel, light mode colors), remove Profile tab from nav, add standalone /profile route.

## Context
- eklavya_mobile/lib/core/widgets/glass_bottom_nav.dart
- eklavya_mobile/lib/features/shell/main_shell.dart
- eklavya_mobile/lib/core/router/app_router.dart
- eklavya_mobile/lib/core/theme/app_colors.dart

## Tasks

<task type="auto">
  <name>Fix nav bar animation and add nav-specific colors</name>
  <files>
    eklavya_mobile/lib/core/widgets/glass_bottom_nav.dart
    eklavya_mobile/lib/core/theme/app_colors.dart
  </files>
  <action>
    1. ADD to AppColors: navBackground (dark: surface #141829, light: #1E2340), navText (always white #F8FAFC), navInactiveIcon (dark: textSecondary, light: #94A3B8)
    2. In GlassBottomNav: use context.colors.navBackground instead of context.colors.surface
    3. In _LabelBeside and _LabelBelow: use context.colors.navText instead of textPrimary
    4. In inactive icon: use context.colors.navInactiveIcon
    5. FIX SHAPE GLITCH: Wrap _NavItem's child in a SizedBox with fixed height (e.g. 44) so the AnimatedContainer never changes its intrinsic size
    6. FIX LABEL TRAVEL: Replace AnimatedSwitcher with AnimatedAlign + AnimatedOpacity so the label physically moves from Alignment.centerRight to Alignment.bottomCenter instead of fading out/in. Use a single Row→Column transition via AnimatedCrossFade or manually positioned widgets.
    AVOID: Using AnimatedSwitcher with FadeTransition — that causes the "fade out then fade in" effect the user complained about
  </action>
  <verify>flutter analyze lib/core/widgets/glass_bottom_nav.dart</verify>
  <done>Nav bar height never changes during animation. Label slides from side to bottom. Light mode shows dark nav with white text.</done>
</task>

<task type="auto">
  <name>Remove Profile from nav and add standalone route</name>
  <files>
    eklavya_mobile/lib/features/shell/main_shell.dart
    eklavya_mobile/lib/core/router/app_router.dart
  </files>
  <action>
    1. In main_shell.dart: Remove the Profile GlassNavItem from _navItems (5→4 items)
    2. In app_router.dart: Remove the Profile StatefulShellBranch from the indexed stack
    3. In app_router.dart: Add a standalone GoRoute for '/profile' outside the shell (uses ProfileTab, with fadeTransition)
    AVOID: Breaking the index mapping — ensure Home=0, Goals=1, Chat=2, Analytics=3
  </action>
  <verify>flutter analyze lib/</verify>
  <done>Bottom nav shows 4 tabs. Tapping profile avatar on home navigates to /profile screen.</done>
</task>

## Success Criteria
- [ ] Nav bar has exactly 4 tabs
- [ ] Label animation is smooth travel, not fade
- [ ] Nav container shape is stable during animation
- [ ] Light mode nav has dark background, white icons/text
- [ ] /profile route works as standalone screen
- [ ] `flutter analyze lib/` passes with zero errors
