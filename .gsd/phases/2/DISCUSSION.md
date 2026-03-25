# Phase 2 Discussion — Premium Flutter App Shell

> **Date**: 2026-03-11
> **Status**: Decided — ready for `/plan`

---

## Decisions Made

### 1. Screen Inventory

**5-tab bottom navigation + supporting screens:**

| Screen | Tab | Content (Phase 2) |
|--------|-----|--------------------|
| Splash / Loading | — | Animated Eklavya logo, transitions to login |
| Login / Signup | — | Dummy auth (admin@gmail.com / 123456), styled dark glassmorphism |
| Onboarding Intro | — | 3 swipeable pages before Guru chat (Phase 3) |
| Home / Dashboard | Tab 1 | Demo data — "Welcome back" greeting, XP card, daily tasks preview |
| Goals | Tab 2 | Demo goals list with domain chips, progress bars |
| Chat | Tab 3 | Placeholder for Guru (Phase 3) — styled empty state with animated Guru icon |
| Analytics | Tab 4 | Demo charts (streak, XP history, domain distribution) |
| Profile / Settings | Tab 5 | Avatar, display name, dummy settings toggles |

**Gamification**: Visible in Phase 2 UI as demo data (XP counters, badges in profile, streak counter). Backend gamification tables come in Phase 4 — data is hardcoded for now.

**Auth**: Dummy login (admin@gmail.com / 123456). Real Supabase JWT auth integrated later.

---

### 2. Design System — Option B: Full Design Tokens

Complete design token system:
- **Spacing scale**: 4px base (4, 8, 12, 16, 24, 32, 48)
- **Corner radii**: 8 (small), 16 (medium), 24 (large), 32 (XL — cards), 40 (pill)
- **Typography scale**: Display, Headline, Title, Body, Label, Caption
- **Color palette**: Deep purple → midnight blue gradient (NO orange)
- **Elevation**: Glow-based (no Material shadows)
- **Animation durations**: Fast (200ms), Normal (400ms), Slow (600ms), Cinematic (1000ms)
- **Icon set**: Material Icons + custom SVG for brand icons

---

### 3. Glassmorphism Approach

**Reference**: [Dribbble — Barber Booking App](https://dribbble.com/shots/27165661-Barber-Booking-App-Modern-Grooming-Service-Mobile-UI)

**What we take from it:**
- Floating bottom nav dock (rounded, frosted glass)
- Card layout with hero images and overlapping content cards
- Horizontal scroll category chips
- Clean top bar with avatar + greeting
- High corner radii (~30-40px on major cards)

**What we change:**
- Color: Deep purple / electric blue / cyan accent instead of orange
- Background: Gradient dark mesh (dark purple → midnight blue) instead of white
- All surfaces: Frosted glass effect with `BackdropFilter + blur`
- Glow effects on interactive elements (buttons, active states)
- Dark-first design (the reference is light mode — we flip to dark)

---

### 4. Animation Library — Option B: flutter_animate

- `flutter_animate` for declarative micro-animations (`.animate().fadeIn().slideY()`)
- Built-in Flutter transitions for page/route animations
- Hero animations for goal cards → detail views

---

### 5. Packages

**Current:**
- `flutter_riverpod` (state management)
- `go_router` (navigation)
- `google_fonts` (Inter typography)
- `shared_preferences` (local storage)

**Adding in Phase 2:**
- `flutter_animate` — micro-animations
- `shimmer` — skeleton loaders
- `flutter_svg` — SVG icon support
- `cached_network_image` — avatar/image caching

---

### 6. Content Strategy

**Phase 2 = interactive demo, not empty states.**

Screens are populated with hardcoded demo data to prove UX:
- Home: demo XP, tasks, greeting
- Goals: 2-3 sample goals with progress
- Analytics: demo charts
- Profile: demo avatar, badges

Phase 3 (Guru Chat) and Phase 4 (Dashboard) will replace hardcoded data with real backend data.

---

## Design Reference

![Dribbble Reference — Barber Booking App](C:/Users/amitd/.gemini/antigravity/brain/14f0340a-67dc-42d1-b7d5-38b1a30f460b/dribbble_full_res_image_1773214999702.png)

> We take the layout patterns and premium feel. Colors shift to deep purple / blue / cyan. Dark mode instead of light. Glassmorphism frosted glass on all surfaces.
