---
phase: 3
plan: 2
wave: 1
---

# Plan 3.2: Animated Bottom Nav & FAB Fix

## Objective
Upgrade the glass bottom nav with a two-stage label animation (label appears to the right of the icon first, then after 300ms transitions below the icon), increase the navbar height for a rounder feel, and fix the FAB on Goals tab being obscured behind the floating nav.

## Context
- eklavya_mobile/lib/core/widgets/glass_bottom_nav.dart — Current GlassBottomNav and _NavItem
- eklavya_mobile/lib/features/shell/main_shell.dart — extendBody setting
- eklavya_mobile/lib/features/goals/goals_tab.dart — FAB placement
- eklavya_mobile/lib/core/theme/app_spacing.dart — Spacing tokens

## Tasks

<task type="auto">
  <name>Upgrade GlassBottomNav with animated label transition</name>
  <files>
    eklavya_mobile/lib/core/widgets/glass_bottom_nav.dart
  </files>
  <action>
    Convert `_NavItem` from `StatelessWidget` to `StatefulWidget` and implement the 2-stage animation:

    **Stage 1 (0-0ms)**: When tab becomes active, label appears **to the RIGHT of the icon** in a Row — this is exactly what the current code does.

    **Stage 2 (after 300ms delay)**: Label animates from the right-of-icon position to **below the icon** in a Column layout. Use `AnimatedSwitcher` with a custom transition that combines `SlideTransition` (from right/below) and `FadeTransition`.

    Implementation steps:
    1. Add `bool _showBelow = false` state
    2. In `didUpdateWidget`, when `isActive` flips from false→true:
       - Set `_showBelow = false` immediately (show beside icon)
       - Start a `Timer(Duration(milliseconds: 300), () => setState(() => _showBelow = true))`
    3. When `isActive` becomes false, cancel timer and reset `_showBelow = false`
    4. Build returns `AnimatedSwitcher` child that is either:
       - `_LabelBeside` (Row: icon + label) when `!_showBelow`
       - `_LabelBelow` (Column: icon + label) when `_showBelow`
    5. `AnimatedSwitcher` duration: 250ms, transitionBuilder: custom fade+slide

    Nav bar sizing:
    - Change outer Container `padding.vertical` from `AppSpacing.sm` → `14` (explicit)
    - This makes the pill taller and more rounded visually

    What to avoid and WHY:
    - Do NOT use flutter_animate for this — need fine timer control for the stage delay, so manual StatefulWidget + Timer is cleaner
    - Do NOT animate while tab is inactive — only animate on activation
    - Do NOT use AnimatedContainer for layout switch (Row→Column) — AnimatedSwitcher handles cross-fade cleanly
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/core/widgets/glass_bottom_nav.dart</verify>
  <done>Active nav item: label first appears to the right (Row), then after 300ms slides/fades to below (Column). Nav bar is visibly taller than before.</done>
</task>

<task type="auto">
  <name>Fix FAB hidden behind navbar and finalize spacing</name>
  <files>
    eklavya_mobile/lib/features/shell/main_shell.dart
    eklavya_mobile/lib/features/goals/goals_tab.dart
    eklavya_mobile/lib/features/dashboard/home_tab.dart
    eklavya_mobile/lib/features/analytics/analytics_tab.dart
    eklavya_mobile/lib/features/profile/profile_tab.dart
  </files>
  <action>
    1. **main_shell.dart** — Remove `extendBody: true`:
       - With `extendBody: false`, Flutter auto-reserves space for the bottom nav bar, so scrollable content won't go under it
       - Keep `extendBodyBehindAppBar: true`

    2. **goals_tab.dart** — Fix FAB overlap:
       - Set `floatingActionButtonLocation: FloatingActionButtonLocation.endFloat`
       - Remove any explicit `SizedBox(height: 80)` at bottom of list (no longer needed with extendBody: false)
       - Keep the existing `+ FAB` code unchanged

    3. **home_tab.dart, analytics_tab.dart, profile_tab.dart** — Remove the `SizedBox(height: 80)` "hack" that was added to prevent nav overlap:
       - Search for `SizedBox(height: 80)` at the end of each scroll view and remove it
       - The system now handles the inset correctly

    What to avoid and WHY:
    - Do NOT add explicit padding calculations with MediaQuery — extendBody: false handles this automatically
    - Do NOT change GradientBackground — the background should still fill the whole screen including behind the nav area
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/features/ lib/features/shell/</verify>
  <done>FAB on Goals tab fully visible above navbar. No content hidden behind nav on any tab. extendBody is false.</done>
</task>

<task type="checkpoint:human-verify">
  <name>Visual verification of UI polish</name>
  <files>(none — visual verification)</files>
  <action>
    Run the app and verify:
    ```
    cd eklavya_mobile && flutter run
    ```

    Checklist:
    1. **Theme toggle**: Profile tab → toggle Dark Mode → app switches between dark (purple/blue/cyan) and light (clean white/blue) themes
    2. **Nav animation**: Tap each tab → label briefly appears to the RIGHT of the icon, then after ~300ms smoothly transitions to BELOW the icon
    3. **Nav height**: The floating navbar is visibly taller and rounder than before
    4. **FAB visible**: Go to Goals tab → the + FAB is fully visible and not hidden behind the navbar
    5. **No content hidden**: Scroll to bottom on Home, Analytics, Profile — content is fully visible, not obscured
    6. **Zero analyze errors**: `flutter analyze lib/` passes clean
  </action>
  <verify>flutter analyze lib/ passes with zero errors</verify>
  <done>All 6 visual checks pass. App looks polished and premium.</done>
</task>

## Success Criteria
- [ ] NavItem shows label beside icon → transitions to below icon after 300ms
- [ ] Navbar is visibly taller (14px vertical padding vs old 8px)
- [ ] Goals tab FAB is fully visible above the navbar
- [ ] No 80px hack-padding at bottom of tabs
- [ ] `flutter analyze` passes clean
- [ ] Theme toggle works correctly
