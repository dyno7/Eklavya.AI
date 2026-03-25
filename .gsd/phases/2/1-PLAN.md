---
phase: 2
plan: 1
wave: 1
---

# Plan 2.1: Design System & Theme Foundation

## Objective
Create the complete design token system and reusable glassmorphism widgets. This is the visual DNA of the app — every screen in Phase 2-5 builds on these tokens and widgets.

## Context
- .gsd/phases/2/DISCUSSION.md — Design decisions (ADR-012, ADR-014)
- .gsd/phases/2/RESEARCH.md — Color palette, glassmorphism pattern
- eklavya_mobile/lib/main.dart — Current bare ThemeData to replace
- eklavya_mobile/pubspec.yaml — Packages to add

## Tasks

<task type="auto">
  <name>Add Phase 2 packages and create design tokens</name>
  <files>
    eklavya_mobile/pubspec.yaml
    eklavya_mobile/lib/core/theme/app_colors.dart
    eklavya_mobile/lib/core/theme/app_spacing.dart
    eklavya_mobile/lib/core/theme/app_radii.dart
    eklavya_mobile/lib/core/theme/app_typography.dart
    eklavya_mobile/lib/core/theme/app_durations.dart
    eklavya_mobile/lib/core/theme/app_theme.dart
  </files>
  <action>
    1. **pubspec.yaml** — Add dependencies:
       ```yaml
       flutter_animate: ^4.5.0
       shimmer: ^3.0.0
       flutter_svg: ^2.0.10
       cached_network_image: ^3.3.1
       ```
       Then run `flutter pub get`

    2. **app_colors.dart** — Abstract class `AppColors` with static const:
       - `background: Color(0xFF0A0E1A)` (near-black blue)
       - `surface: Color(0xFF141829)` (card backgrounds)
       - `surfaceLight: Color(0xFF1E2340)` (elevated surfaces)
       - `primary: Color(0xFF7C3AED)` (deep purple)
       - `primaryLight: Color(0xFF9F67FF)` (hover/active purple)
       - `secondary: Color(0xFF3B82F6)` (electric blue)
       - `accent: Color(0xFF06B6D4)` (cyan highlights)
       - `success: Color(0xFF10B981)` (completed, XP)
       - `warning: Color(0xFFF59E0B)` (streaks)
       - `error: Color(0xFFEF4444)` (errors)
       - `textPrimary: Color(0xFFF8FAFC)` (near-white)
       - `textSecondary: Color(0xFF94A3B8)` (muted blue-grey)
       - `textTertiary: Color(0xFF64748B)` (disabled)
       - `glassTint: Color(0x14FFFFFF)` (white @ 8%)
       - `glassBorder: Color(0x1FFFFFFF)` (white @ 12%)
       - `glowPurple: Color(0x407C3AED)` (purple glow @ 25%)
       - `glowBlue: Color(0x403B82F6)` (blue glow @ 25%)
       - `backgroundGradient` — `LinearGradient` from `Color(0xFF0A0E1A)` to `Color(0xFF1a1040)`

    3. **app_spacing.dart** — Abstract class `AppSpacing` with `double` constants:
       - `xs: 4`, `sm: 8`, `md: 12`, `lg: 16`, `xl: 24`, `xxl: 32`, `xxxl: 48`

    4. **app_radii.dart** — Abstract class `AppRadii` with `BorderRadius` constants:
       - `sm: 8`, `md: 16`, `lg: 24`, `xl: 32`, `pill: 40`, `circle: 999`

    5. **app_typography.dart** — Function `appTextTheme()` using `GoogleFonts.inter()`:
       - displayLarge: 32, w700
       - headlineMedium: 24, w600
       - titleLarge: 20, w600
       - titleMedium: 16, w600
       - bodyLarge: 16, w400
       - bodyMedium: 14, w400
       - labelLarge: 14, w500
       - labelMedium: 12, w500
       - All defaulting to `AppColors.textPrimary`

    6. **app_durations.dart** — Abstract class `AppDurations` with `Duration` constants:
       - `fast: 200ms`, `normal: 400ms`, `slow: 600ms`, `cinematic: 1000ms`
       - `stagger: 100ms` (delay between list item animations)

    7. **app_theme.dart** — `AppTheme.darkTheme` static getter returning `ThemeData`:
       - `brightness: Brightness.dark`
       - `scaffoldBackgroundColor: AppColors.background`
       - `colorScheme` built from AppColors (primary, secondary, surface, background, error)
       - `textTheme` from appTextTheme()
       - `appBarTheme` transparent, no elevation
       - `bottomNavigationBarTheme` transparent
       - `cardTheme` with AppColors.surface
       - `useMaterial3: true`

    What to avoid and WHY:
    - Do NOT use `withOpacity()` — use `withValues(alpha:)` or hex alpha (withOpacity is deprecated in newer Flutter)
    - Do NOT use Material elevation/shadows — we use glow effects (ADR-014)
    - Do NOT hardcode colors anywhere outside AppColors — all screens reference tokens
  </action>
  <verify>cd eklavya_mobile && flutter pub get && flutter analyze lib/core/theme/</verify>
  <done>7 design token files created, flutter analyze passes with zero errors on theme files</done>
</task>

<task type="auto">
  <name>Create reusable glassmorphism widgets</name>
  <files>
    eklavya_mobile/lib/core/widgets/glass_card.dart
    eklavya_mobile/lib/core/widgets/gradient_button.dart
    eklavya_mobile/lib/core/widgets/glass_bottom_nav.dart
    eklavya_mobile/lib/core/widgets/shimmer_loader.dart
    eklavya_mobile/lib/core/widgets/gradient_background.dart
    eklavya_mobile/lib/core/widgets/glow_icon.dart
  </files>
  <action>
    1. **glass_card.dart** — `GlassCard` StatelessWidget:
       - Props: `child`, `padding` (default EdgeInsets.all(16)), `borderRadius` (default AppRadii.xl), `blurSigma` (default 12)
       - Structure: Container → ClipRRect → BackdropFilter(blur) → child
       - Decoration: AppColors.glassTint fill, AppColors.glassBorder border, given borderRadius

    2. **gradient_button.dart** — `GradientButton` StatelessWidget:
       - Props: `label` (String), `onPressed` (VoidCallback), `icon` (IconData?), `gradient` (default purple→blue), `isLoading` (bool)
       - Pill shape (AppRadii.pill), gradient fill, subtle glow shadow
       - Loading state shows CircularProgressIndicator

    3. **glass_bottom_nav.dart** — `GlassBottomNav` StatelessWidget:
       - Props: `currentIndex`, `onTap`, `items: List<GlassNavItem>` (icon + label)
       - Floating container: Margin from edges ~ 16px, borderRadius: AppRadii.pill
       - BackdropFilter glass effect
       - Active tab: colored pill background (AppColors.primary) with icon + label
       - Inactive tab: icon only, AppColors.textSecondary
       - Based on Dribbble reference floating dock pattern

    4. **shimmer_loader.dart** — `ShimmerLoader` StatelessWidget:
       - Props: `width`, `height`, `borderRadius` (default AppRadii.md)
       - Uses `shimmer` package with AppColors.surface base and AppColors.surfaceLight highlight

    5. **gradient_background.dart** — `GradientBackground` StatelessWidget:
       - Props: `child`
       - Wraps child in Container with AppColors.backgroundGradient
       - Adds 2-3 subtle radial gradient overlay spots (purple glow top-left, blue glow bottom-right)

    6. **glow_icon.dart** — `GlowIcon` StatelessWidget:
       - Props: `icon`, `color` (default AppColors.primary), `size` (default 24), `glowRadius` (default 16)
       - Icon with a subtle radial glow behind it (Container with boxShadow)

    What to avoid and WHY:
    - Do NOT put BackdropFilter in scrollable lists — performance hit. Use only on static containers (RESEARCH.md finding)
    - Do NOT add state management to widgets — they're pure UI components
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/core/widgets/</verify>
  <done>6 reusable widgets created, all reference design tokens, flutter analyze passes</done>
</task>

<task type="auto">
  <name>Update main.dart to use AppTheme</name>
  <files>
    eklavya_mobile/lib/main.dart
  </files>
  <action>
    Replace the inline ThemeData in `EklavyaApp.build()` with:
    ```dart
    theme: AppTheme.darkTheme,
    ```
    Import `app_theme.dart`.

    What to avoid and WHY:
    - Do NOT remove ProviderScope or ConsumerWidget — state management stays (carry forward)
    - Do NOT change routerConfig yet — that's Plan 2.2
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/main.dart</verify>
  <done>main.dart uses AppTheme.darkTheme, zero inline colors</done>
</task>

## Success Criteria
- [ ] 4 new packages in pubspec.yaml, `flutter pub get` succeeds
- [ ] 7 design token files (colors, spacing, radii, typography, durations, theme)
- [ ] 6 reusable widgets (glass_card, gradient_button, glass_bottom_nav, shimmer_loader, gradient_background, glow_icon)
- [ ] main.dart uses `AppTheme.darkTheme`
- [ ] `flutter analyze` on lib/core/ passes with zero errors
