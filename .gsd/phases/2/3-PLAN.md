---
phase: 2
plan: 3
wave: 2
---

# Plan 2.3: Splash, Login & Onboarding Screens

## Objective
Build the 3 pre-shell screens: animated splash with Eklavya logo, dark glassmorphism login/signup with dummy auth, and swipeable onboarding intro. These are the first screens users see — first impression matters.

## Context
- .gsd/phases/2/DISCUSSION.md — Dummy auth (admin@gmail.com / 123456), onboarding before Guru
- .gsd/phases/2/1-PLAN.md — Design tokens + widgets (GlassCard, GradientButton, GradientBackground)
- .gsd/phases/2/2-PLAN.md — Router already has routes for /splash, /login, /onboarding (stubs)
- .gsd/phases/2/RESEARCH.md — Color palette, flutter_animate patterns

## Tasks

<task type="auto">
  <name>Build animated splash screen</name>
  <files>
    eklavya_mobile/lib/features/splash/splash_screen.dart
  </files>
  <action>
    Replace stub with full implementation:

    1. **SplashScreen** — ConsumerStatefulWidget:
       - GradientBackground as base
       - Center content: "Eklavya" text in displayLarge + ".AI" in accent color
       - Subtle glow circle behind the text (AppColors.glowPurple)
       - Below: tagline "Master Your Journey" in textSecondary, bodyMedium
       - Entry animation using flutter_animate:
         - Logo fades in + scales up (0.8→1.0) over 800ms
         - Tagline fades in + slides up after 400ms delay
       - After 2.5s total, navigate to `/login` using `context.go('/login')`
       - Use a `Timer` or `Future.delayed` for the auto-navigation

    What to avoid and WHY:
    - Do NOT use Navigator.push — use GoRouter's `context.go()` (consistent navigation)
    - Do NOT make splash skippable — it's a branding moment (short enough at 2.5s)
    - Do NOT add loading logic — this is shell only (no API calls)
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/features/splash/</verify>
  <done>Splash screen with animated Eklavya.AI logo, auto-navigates to /login after 2.5s</done>
</task>

<task type="auto">
  <name>Build login/signup screen with dummy auth</name>
  <files>
    eklavya_mobile/lib/features/auth/login_screen.dart
  </files>
  <action>
    Replace stub with full implementation:

    1. **LoginScreen** — ConsumerStatefulWidget:
       - GradientBackground as base
       - SafeArea → SingleChildScrollView → Column
       - Top: "Welcome Back" in headlineMedium, "Sign in to continue your journey" in textSecondary
       - GlassCard containing:
         - Email TextField (dark styled, rounded, glass border)
         - Password TextField (obscured, dark styled)
         - "Sign In" GradientButton (full width)
         - "Don't have an account? Sign Up" TextButton
       - Below card: "Or continue with" divider + Google/Apple mock buttons (non-functional)

    2. **Dummy Auth Logic**:
       - On sign in: check if email == "admin@gmail.com" and password == "123456"
       - If match: `context.go('/onboarding')`
       - If no match: Show SnackBar "Invalid credentials" with error styling
       - Store login state in SharedPreferences (`isLoggedIn: true`)

    3. **Styling**:
       - TextField decoration: filled (AppColors.surface), rounded border (AppRadii.lg), white text
       - Focus border: AppColors.primary
       - All text uses AppColors tokens
       - Entry animations: form slides up + fades in on mount

    What to avoid and WHY:
    - Do NOT implement real auth — Phase 2 is shell only (ADR-015)
    - Do NOT add form validation beyond the dummy check — keep it simple
    - Do NOT use a separate signup screen — single screen with tab-like toggle (simpler)
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/features/auth/</verify>
  <done>Login screen accepts admin@gmail.com/123456, rejects others with SnackBar, glass-styled form</done>
</task>

<task type="auto">
  <name>Build swipeable onboarding intro</name>
  <files>
    eklavya_mobile/lib/features/onboarding/onboarding_screen.dart
  </files>
  <action>
    Replace stub with full implementation:

    1. **OnboardingScreen** — StatefulWidget:
       - GradientBackground as base
       - PageView with 3 pages:
         - Page 1: "Meet Your Guru" — Icon (smart_toy_rounded), description about AI-powered planning
         - Page 2: "Track Your Progress" — Icon (trending_up_rounded), description about gamified goals
         - Page 3: "Stay Consistent" — Icon (psychology_rounded), description about adaptive coaching
       - Each page: Large icon with glow effect, title in headlineMedium, description in bodyMedium/textSecondary
       - Bottom: dot indicators (active = AppColors.primary, inactive = AppColors.textTertiary) + navigation
       - Pages 1-2: "Next" button (GradientButton)
       - Page 3: "Get Started" button → `context.go('/shell')`
       - "Skip" text button on pages 1-2 → jumps to page 3

    2. **Animations**:
       - Each page content fades in + slides up when swiped to
       - Dot indicators animate width change (active dot wider)

    3. **SharedPreferences**: Set `hasOnboarded: true` on completion (to skip on next launch)

    What to avoid and WHY:
    - Do NOT use images — use large Material icons with glow effects (no asset files needed)
    - Do NOT add more than 3 pages — user attention drops after 3
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/features/onboarding/</verify>
  <done>3-page swipeable onboarding with dot indicators, skip button, "Get Started" routes to shell</done>
</task>

## Success Criteria
- [ ] Splash screen animates Eklavya.AI logo → auto-navigates to /login (2.5s)
- [ ] Login accepts admin@gmail.com / 123456, rejects others with SnackBar
- [ ] Login navigates to /onboarding on success
- [ ] Onboarding has 3 swipeable pages with dot indicators
- [ ] "Get Started" on last page routes to /shell
- [ ] All screens use GradientBackground + design tokens
- [ ] `flutter analyze` passes on all 3 feature dirs
