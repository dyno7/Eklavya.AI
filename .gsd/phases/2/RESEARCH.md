# Phase 2 Research — Premium Flutter App Shell

> **Discovery Level**: 1 (Quick Verification)
> **Date**: 2026-03-11

## Rationale for Level 1
All packages are well-known Flutter community packages. Decision is already made (ADR-013, ADR-014). Just confirming versions and usage patterns.

## Package Versions (pub.dev latest stable)

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_animate` | ^4.5.0 | Declarative micro-animations (`.animate().fadeIn().slideY()`) |
| `shimmer` | ^3.0.0 | Skeleton loader shimmer effects |
| `flutter_svg` | ^2.0.10 | SVG icon rendering |
| `cached_network_image` | ^3.3.1 | Image caching with placeholders |

## Glassmorphism Pattern (Flutter)
```dart
// Core glassmorphism pattern — BackdropFilter + blur
Container(
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: content,
    ),
  ),
)
```

## Color Palette Decision
Based on Dribbble reference (dark premium feel) + user preference (no orange):

| Token | Value | Usage |
|-------|-------|-------|
| `background` | `#0A0E1A` | App background (near-black blue) |
| `surface` | `#141829` | Card backgrounds |
| `primary` | `#7C3AED` | Deep purple (primary brand) |
| `secondary` | `#3B82F6` | Electric blue (secondary actions) |
| `accent` | `#06B6D4` | Cyan (highlights, badges) |
| `success` | `#10B981` | Completed states, XP gains |
| `warning` | `#F59E0B` | Streaks, attention states |
| `error` | `#EF4444` | Errors, missed tasks |
| `glassTint` | `white @ 8%` | Glass surface overlay |
| `glassBorder` | `white @ 12%` | Glass card borders |
| `textPrimary` | `#F8FAFC` | Primary text (near-white) |
| `textSecondary` | `#94A3B8` | Secondary text (muted blue-grey) |

## GoRouter Navigation Structure
```
/ (splash) → /login → /onboarding → /shell
                                      ├── /home (tab 0)
                                      ├── /goals (tab 1)
                                      ├── /chat (tab 2)
                                      ├── /analytics (tab 3)
                                      └── /profile (tab 4)
```
Uses `StatefulShellRoute.indexedStack` for tab persistence.

## Demo Data Shape
```dart
// Hardcoded in lib/core/data/demo_data.dart
class DemoUser { displayName, avatarUrl, xp, level, streak }
class DemoGoal { title, domain, progress, status, milestones }
class DemoTask { title, type, xpReward, status, dueDate }
class DemoAnalytics { dailyXp[], streakHistory[], domainDistribution }
```

## Key Findings
- `flutter_animate` supports stagger (`.animate(delay: 100.ms)` per list item) — great for list entry animations
- `shimmer` works well with custom containers (not just text) — can wrap any widget shape
- `StatefulShellRoute.indexedStack` preserves tab state between switches (no rebuild)
- `BackdropFilter` performs well on modern devices but should be avoided in scrolling lists (performance hit) — use it on static containers only
