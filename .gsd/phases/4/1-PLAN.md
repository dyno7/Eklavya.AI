---
phase: 4
plan: 1
wave: 1
depends_on: []
files_modified:
  - eklavya_mobile/lib/features/dashboard/home_tab.dart
  - eklavya_mobile/lib/core/theme/app_colors.dart
autonomous: true

must_haves:
  truths:
    - "Home screen shows Blinkit-style greeting with time-of-day logic"
    - "Profile avatar + notification bell with red badge on the right side"
    - "Let's Continue card is the first widget below the greeting"
  artifacts:
    - "home_tab.dart has time-based greeting in headlineLarge"
    - "Notification icon has a red badge dot via Stack+Positioned"
    - "Let's Continue card shows goal title, progress, and CTA"
---

# Plan 4.1: Home Screen Redesign (Greeting + Notifications + Let's Continue)

## Objective
Redesign the Home tab top bar to Blinkit-style layout and replace the XP Summary card with a "Let's Continue" priority goal card.

## Context
- .gsd/SPEC.md
- eklavya_mobile/lib/features/dashboard/home_tab.dart
- eklavya_mobile/lib/core/data/demo_data.dart
- eklavya_mobile/lib/core/theme/app_colors.dart

## Tasks

<task type="auto">
  <name>Blinkit-style greeting header + notification badge</name>
  <files>eklavya_mobile/lib/features/dashboard/home_tab.dart</files>
  <action>
    Replace the current top bar Row with a Blinkit-style layout:
    - LEFT SIDE: Column with "Good [Morning/Afternoon/Evening/Night]," in labelLarge (14px, textSecondary) and "{Name} 👋" in headlineLarge (28px, bold, textPrimary)
    - RIGHT SIDE: Row containing [notification bell with red badge] + [profile avatar]
    - Time-of-day logic: hour 5-12 = Morning, 12-17 = Afternoon, 17-21 = Evening, 21-5 = Night
    - Notification bell: wrap Icon in a Stack with a Positioned red circle (8×8, top:0, right:0)
    - Profile avatar: CircleAvatar wrapped in GestureDetector → context.push('/profile')
    - Wrap both right-side icons in glass containers (surfaceLight bg, circular border)
    AVOID: Using const DateTime — use DateTime.now().hour for runtime greeting
  </action>
  <verify>flutter analyze lib/features/dashboard/home_tab.dart</verify>
  <done>Top bar shows bold greeting on left, avatar + badged bell on right. Greeting changes with time of day.</done>
</task>

<task type="auto">
  <name>Replace XP card with "Let's Continue" priority goal card</name>
  <files>eklavya_mobile/lib/features/dashboard/home_tab.dart</files>
  <action>
    Replace the XP Summary GlassCard (lines 88-138) with a "Let's Continue" card:
    - Show first goal from DemoData.goals: title, domain tag (colored chip), progress bar, milestone count
    - Add a "Continue →" gradient button CTA
    - Move the XP Summary card BELOW the streak card
    - Add a "Suggested Resources" section below Today's Tasks with 2-3 placeholder cards (icon + title + "AI Recommended" tag in a horizontal ListView)
    AVOID: Removing the XP card entirely — just move it down
  </action>
  <verify>flutter analyze lib/</verify>
  <done>"Let's Continue" card is the first content card. XP card is below streak. Resources section is visible at bottom.</done>
</task>

## Success Criteria
- [ ] Greeting shows correct time-of-day text in large bold font
- [ ] Notification bell has visible red badge dot
- [ ] Profile avatar is tappable
- [ ] "Let's Continue" card is first, XP card is below streak
- [ ] Resources placeholder section is visible
- [ ] `flutter analyze lib/` passes with zero errors
