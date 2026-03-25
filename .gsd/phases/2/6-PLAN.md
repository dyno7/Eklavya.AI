---
phase: 2
plan: 6
wave: 3
---

# Plan 2.6: Skeleton Loaders, Transitions & Final Polish

## Objective
Add skeleton loading states, page transition animations, and micro-interaction polish across all screens. This is the "wow factor" pass — making every interaction feel premium.

## Context
- .gsd/phases/2/1-PLAN.md — ShimmerLoader widget, AppDurations
- .gsd/phases/2/RESEARCH.md — flutter_animate patterns, stagger delays
- All Plan 2.1-2.5 screens (dependency — all screens must exist)

## Tasks

<task type="auto">
  <name>Add skeleton loaders to all tabs</name>
  <files>
    eklavya_mobile/lib/features/dashboard/home_tab.dart
    eklavya_mobile/lib/features/goals/goals_tab.dart
    eklavya_mobile/lib/features/analytics/analytics_tab.dart
    eklavya_mobile/lib/features/profile/profile_tab.dart
  </files>
  <action>
    Add a brief (800ms) skeleton loading state to each tab that shows on first mount:

    1. **Pattern for each tab**:
       - Add `bool _isLoading = true` state
       - In `initState()`, set a `Future.delayed(Duration(milliseconds: 800))` then `setState(() => _isLoading = false)`
       - In `build()`: if `_isLoading`, show skeleton version; else show real content

    2. **Home Tab skeleton**: ShimmerLoader rectangles matching greeting bar, XP card, streak card, 3 task cards

    3. **Goals Tab skeleton**: ShimmerLoader matching header, chip row, 3 goal cards

    4. **Analytics Tab skeleton**: ShimmerLoader matching 3 chart cards

    5. **Profile Tab skeleton**: ShimmerLoader matching avatar circle, badges row, stats row, settings card

    6. **Transition**: skeleton → real content fades using `AnimatedSwitcher` with `AppDurations.normal`

    What to avoid and WHY:
    - Do NOT show skeletons for more than 1s — it's demo, keep it snappy
    - Do NOT add skeleton to Splash/Login/Onboarding — they already have their own animations
    - Do NOT over-engineer with Riverpod async states — simple local bool for shell phase
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/features/</verify>
  <done>All 4 tab screens show skeleton loaders for 800ms on first mount, then fade to real content</done>
</task>

<task type="auto">
  <name>Add page transitions and micro-interactions</name>
  <files>
    eklavya_mobile/lib/core/router/app_router.dart
    eklavya_mobile/lib/core/theme/page_transitions.dart
  </files>
  <action>
    1. **page_transitions.dart** — Create custom `GoRouter` page builder:
       - `fadeSlideTransition` — Fade + SlideUp for most routes
       - Duration: AppDurations.normal (400ms)
       - Curve: Curves.easeOutCubic

    2. **app_router.dart** — Apply custom transitions:
       - splash → login: fade
       - login → onboarding: slideRight
       - onboarding → shell: fadeSlide
       - Add `pageBuilder` to each GoRoute using the custom transitions

    3. **Micro-interactions across all screens**:
       - Task checkboxes: scale bounce on tap (flutter_animate .scale(1.2).then().scale(1.0))
       - Goal cards: subtle scale on long press
       - Bottom nav: active icon has small bounce transition
       - Buttons: press feedback (scale 0.95 on tap down)

    What to avoid and WHY:
    - Do NOT add more than 400ms transitions — the app should feel snappy, not slow
    - Do NOT animate bottom nav tab switches — instant switching feels more responsive
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/core/ && flutter analyze lib/features/</verify>
  <done>Custom page transitions on all routes, micro-interactions on taps/toggles, bottom nav bounce</done>
</task>

<task type="checkpoint:human-verify">
  <name>Visual verification of complete shell</name>
  <files>(none — this is a verification checkpoint)</files>
  <action>
    Run the app and verify the complete flow:
    ```
    cd eklavya_mobile && flutter run
    ```

    Verify checklist:
    1. Splash screen: Eklavya.AI logo animates in → auto-navigates to login
    2. Login: Glass form, admin@gmail.com/123456 works, bad creds show error
    3. Onboarding: 3 swipeable pages, dot indicators, Get Started → shell
    4. Shell: 5-tab floating glass bottom nav
    5. Home tab: Skeleton → greeting, XP card, streak, tasks
    6. Goals tab: Skeleton → filter chips, 3 goal cards with progress
    7. Chat tab: Animated Guru placeholder
    8. Analytics tab: Skeleton → XP bars, streak calendar, domain chart
    9. Profile tab: Skeleton → avatar, badges, stats, settings
    10. Sign out returns to login
    11. All screens have dark glassmorphism styling with purple/blue/cyan
    12. Animations are smooth and not janky
  </action>
  <verify>Flutter app runs without crashes and all 12 visual checks pass</verify>
  <done>Complete app shell demo verified — all screens, animations, and navigation working</done>
</task>

## Success Criteria
- [ ] All 4 tabs show skeleton loaders then fade to content
- [ ] Custom fade/slide page transitions on route changes
- [ ] Micro-interactions: task checkbox bounce, button press scale, nav icon bounce
- [ ] Full flow verified: splash → login → onboarding → shell (5 tabs) → sign out → login
- [ ] Zero `flutter analyze` errors
- [ ] App feels premium and matches Dribbble-inspired design direction
