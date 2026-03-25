---
phase: 4
plan: 3
wave: 2
depends_on: [1, 2]
files_modified:
  - eklavya_mobile/lib/features/analytics/analytics_tab.dart
  - eklavya_mobile/pubspec.yaml
autonomous: false
user_setup:
  - service: LottieFiles
    why: "Lottie JSON animations for premium UX"
    manual_action:
      - task: "Download 6 Lottie JSON files into assets/lottie/"
        files:
          - streak_fire.json
          - xp_star.json
          - rocket_launch.json
          - confetti.json
          - wave_hello.json
          - empty_inbox.json

must_haves:
  truths:
    - "Analytics chart bars use vibrant gradient colors"
    - "Domain distribution uses distinct named colors"
    - "Lottie dependency is added to pubspec"
  artifacts:
    - "analytics_tab.dart has gradient bars with value labels"
    - "pubspec.yaml includes lottie dependency and assets/lottie/"
---

# Plan 4.3: Analytics Colors + Lottie Setup

## Objective
Improve analytics chart color scheme and add Lottie animation dependency (user downloads animation files manually).

## Context
- eklavya_mobile/lib/features/analytics/analytics_tab.dart
- eklavya_mobile/pubspec.yaml

## Tasks

<task type="auto">
  <name>Improve analytics chart color scheme</name>
  <files>eklavya_mobile/lib/features/analytics/analytics_tab.dart</files>
  <action>
    1. Weekly XP bar chart: Replace surfaceLight color for non-today bars with primary.withAlpha(60). Today bar uses a gradient (primary→accent) via a BoxDecoration with gradient.
    2. Add value labels: Show the XP number above each bar in labelSmall font
    3. Domain distribution: Use explicit distinct colors:
       - Learning: #8B5CF6 (Violet)
       - Startup: #3B82F6 (Blue)
       - Writing: #F59E0B (Amber)
       Instead of reusing primary/secondary/accent
    4. Add rounded edges to progress bars (already using AppRadii.pill, just verify)
    AVOID: Using context.colors for domain-specific colors — use hardcoded Color() values for the 3 domain colors since they're semantic, not theme-dependent
  </action>
  <verify>flutter analyze lib/features/analytics/analytics_tab.dart</verify>
  <done>Bars have vibrant colors with value labels. Domain distribution uses 3 distinct named colors.</done>
</task>

<task type="checkpoint:human-action">
  <name>Add Lottie dependency and download animation files</name>
  <files>eklavya_mobile/pubspec.yaml</files>
  <action>
    1. Add to pubspec.yaml dependencies: lottie: ^3.3.1
    2. Add to pubspec.yaml assets: - assets/lottie/
    3. Create assets/lottie/ directory
    4. USER DOWNLOADS these Lottie JSON files (search LottieFiles.com):
       - streak_fire.json — fire/flame loop
       - xp_star.json — star sparkle
       - rocket_launch.json — rocket launch
       - confetti.json — celebration confetti
       - wave_hello.json — hand wave hello
       - empty_inbox.json — empty state illustration
    5. Run flutter pub get
  </action>
  <verify>flutter pub get succeeds; ls assets/lottie/ shows .json files</verify>
  <done>Lottie package added. Animation files are in assets/lottie/. flutter pub get passes.</done>
</task>

## Success Criteria
- [ ] Analytics bars are vibrant with value labels
- [ ] Domain distribution uses 3 distinct colors
- [ ] Lottie dependency added to pubspec.yaml
- [ ] assets/lottie/ directory exists with animation files
- [ ] `flutter analyze lib/` passes with zero errors
