---
phase: 3
plan: 1
wave: 1
---

# Plan 3.1: Light / Dark Theme Toggle

## Objective
Add a Riverpod-powered light/dark theme toggle that the user can switch from the Profile tab Settings section. This makes the app feel polished and accessible to users who prefer light mode.

## Context
- eklavya_mobile/lib/main.dart — Where theme is applied to MaterialApp.router
- eklavya_mobile/lib/core/theme/app_theme.dart — AppTheme.darkTheme exists, need lightTheme
- eklavya_mobile/lib/core/theme/app_colors.dart — Need light-mode color tokens
- eklavya_mobile/lib/features/profile/profile_tab.dart — Dark Mode switch to wire up

## Tasks

<task type="auto">
  <name>Create lightTheme and themeModeProvider</name>
  <files>
    eklavya_mobile/lib/core/theme/app_colors.dart
    eklavya_mobile/lib/core/theme/app_theme.dart
    eklavya_mobile/lib/core/providers/theme_provider.dart
  </files>
  <action>
    1. **app_colors.dart** — Add a light-mode subset as a nested class `AppColors.Light`:
       - It can just be referenced inline in the lightTheme — no need for a full class
       - Key light values: background `Color(0xFFF0F4FF)`, surface `Color(0xFFFFFFFF)`, surfaceLight `Color(0xFFE8EEFF)`, textPrimary `Color(0xFF0F172A)`, textSecondary `Color(0xFF475569)`, glassTint `Color(0x14000000)`, glassBorder `Color(0x14000000)`
       - Keep all the accent/primary/secondary/warning/error the same (they work on both themes)

    2. **app_theme.dart** — Add `AppTheme.lightTheme` static getter:
       - `brightness: Brightness.light`
       - `scaffoldBackgroundColor: Color(0xFFF0F4FF)`
       - `colorScheme: ColorScheme.light(...)` with same primary/secondary/error as dark, but light surface/background
       - Copy all other theme config (inputDecoration, cardTheme, etc.) but adjusted for light background
       - Keep `useMaterial3: true`

    3. **lib/core/providers/theme_provider.dart** — New file:
       ```dart
       import 'package:flutter/material.dart';
       import 'package:flutter_riverpod/flutter_riverpod.dart';

       final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
       ```

    What to avoid and WHY:
    - Do NOT use SharedPreferences to persist theme yet — simple in-memory toggle for now
    - Do NOT change AppColors static consts — they're used everywhere; just add them to lightTheme inline
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/core/theme/ lib/core/providers/</verify>
  <done>lightTheme exists in AppTheme, themeModeProvider created, flutter analyze passes</done>
</task>

<task type="auto">
  <name>Wire theme toggle to main.dart and Profile tab</name>
  <files>
    eklavya_mobile/lib/main.dart
    eklavya_mobile/lib/features/profile/profile_tab.dart
  </files>
  <action>
    1. **main.dart** — Update EklavyaApp to use both themes:
       ```dart
       final themeMode = ref.watch(themeModeProvider);
       return MaterialApp.router(
         title: 'Eklavya.AI',
         debugShowCheckedModeBanner: false,
         theme: AppTheme.lightTheme,
         darkTheme: AppTheme.darkTheme,
         themeMode: themeMode,
         routerConfig: appRouter,
       );
       ```
       - Import `theme_provider.dart`
       - EklavyaApp must be `ConsumerWidget` (already is)

    2. **profile_tab.dart** — Convert to ConsumerWidget and wire Dark Mode switch:
       - Add `ref.watch(themeModeProvider)` to check current mode
       - Switch `onChanged` calls `ref.read(themeModeProvider.notifier).state = ThemeMode.dark or ThemeMode.light`
       - The switch value should be `themeMode == ThemeMode.dark`

    What to avoid and WHY:
    - Do NOT change the rest of Profile tab — only the switch wiring
    - Do NOT use Consumer widget inline — convert the whole ProfileTab to ConsumerStatelessWidget for cleanliness
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/main.dart lib/features/profile/</verify>
  <done>Toggling Dark Mode switch in Profile tab switches app-wide theme instantly</done>
</task>

## Success Criteria
- [ ] `AppTheme.lightTheme` exists and applies light background/surface colors
- [ ] `themeModeProvider` (StateProvider<ThemeMode>) created in core/providers/
- [ ] main.dart passes both `theme:` and `darkTheme:` to MaterialApp.router
- [ ] Profile Settings "Dark Mode" switch actually toggles the app theme
- [ ] `flutter analyze` passes on all changed files
