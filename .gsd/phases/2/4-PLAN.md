---
phase: 2
plan: 4
wave: 2
---

# Plan 2.4: Home Dashboard, Goals Tab & Chat Placeholder

## Objective
Build the 3 core content tabs with demo data. Home shows a welcoming dashboard with XP/streak cards and task previews. Goals shows a list of sample goals with progress. Chat shows a styled placeholder for the Guru (Phase 3).

## Context
- .gsd/phases/2/DISCUSSION.md — Demo data strategy (ADR-016), gamification visible as demo
- .gsd/phases/2/1-PLAN.md — GlassCard, GradientButton, ShimmerLoader widgets
- .gsd/phases/2/2-PLAN.md — Tab stubs to replace
- .gsd/phases/2/RESEARCH.md — Demo data shapes

## Tasks

<task type="auto">
  <name>Create demo data provider</name>
  <files>
    eklavya_mobile/lib/core/data/demo_data.dart
  </files>
  <action>
    Create hardcoded demo data classes and instances:

    1. **DemoUser** class: displayName ("Arjun"), avatarUrl (null — use initials), totalXp (2450), level (7), currentStreak (12), longestStreak (21)

    2. **DemoGoal** class: id, title, domain (String), progress (0.0-1.0), status, milestonesCount, completedMilestones, iconData
       - 3 sample goals:
         - "Master Deep Learning" (learning, 0.35, active, 8 milestones)
         - "Build MVP Startup" (startup, 0.15, active, 5 milestones)
         - "Read 24 Books" (writing, 0.5, active, 3 milestones)

    3. **DemoTask** class: id, title, type (String), xpReward, isCompleted, dueDate
       - 5 sample tasks for today:
         - "Watch Neural Networks lecture" (watch, 25 XP, incomplete)
         - "Practice backpropagation" (practice, 30 XP, incomplete)
         - "Read Chapter 5: CNNs" (read, 15 XP, completed)
         - "Quiz: Loss Functions" (quiz, 40 XP, incomplete)
         - "Review startup pitch draft" (custom, 20 XP, incomplete)

    4. **DemoAnalytics** class: weeklyXp (List<int> — 7 days), streakHistory (List<int> — 30 days), domainDistribution (Map<String, double>)

    What to avoid and WHY:
    - Do NOT use Riverpod providers for demo data — simple static data, no reactivity needed
    - Do NOT create complex models — these are temporary and will be replaced by API models
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/core/data/</verify>
  <done>Demo data file with user, 3 goals, 5 tasks, analytics data — all hardcoded</done>
</task>

<task type="auto">
  <name>Build Home Dashboard tab</name>
  <files>
    eklavya_mobile/lib/features/dashboard/home_tab.dart
  </files>
  <action>
    Replace stub with full dashboard implementation:

    1. **Layout** — SafeArea → SingleChildScrollView → Column:
       - **Top bar**: Avatar circle (initials "A") + "Good Morning, Arjun 👋" greeting + notification bell icon
       - **XP Summary Card** (GlassCard): Large XP number with animated counter feel, level badge, progress bar to next level
       - **Streak Card** (GlassCard): Flame icon + "12 Day Streak 🔥" + mini calendar dots showing last 7 days
       - **Today's Tasks** section: "Today's Tasks" header + See All link, then 3-4 task cards from demo data
       - **Task card**: GlassCard with task icon (based on type), title, XP badge, checkbox (toggleable for demo)

    2. **Styling**:
       - All cards use GlassCard widget
       - XP number in displayLarge with AppColors.accent
       - Streak flame uses AppColors.warning
       - Task type icons: watch→play_circle, practice→code, read→menu_book, quiz→quiz, custom→star
       - Completed tasks have strikethrough + AppColors.success check

    3. **Animations** (flutter_animate):
       - Cards stagger in (fadeIn + slideY with 100ms delay each)
       - XP number counts up animation (simple TweenAnimationBuilder)

    What to avoid and WHY:
    - Do NOT use BackdropFilter inside the scrollable task list — use GlassCard only for static top cards, task cards use regular surface color
    - Do NOT wire up task completion to any state — just toggle local bool for demo
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/features/dashboard/</verify>
  <done>Home dashboard with greeting, XP card, streak card, today's tasks — all with demo data and stagger animations</done>
</task>

<task type="auto">
  <name>Build Goals tab and Chat placeholder</name>
  <files>
    eklavya_mobile/lib/features/goals/goals_tab.dart
    eklavya_mobile/lib/features/chat/chat_tab.dart
  </files>
  <action>
    1. **goals_tab.dart** — Replace stub:
       - SafeArea → Column:
         - Header: "My Goals" in headlineMedium + "3 active goals" subtitle
         - Domain filter chips: horizontal scroll — All, Learning, Fitness, Startup, Finance, Writing
           - Active chip: AppColors.primary background, white text
           - Inactive chip: AppColors.surface background, textSecondary text
         - Goals list (ListView.builder with 3 demo goals):
           - Each goal: GlassCard with:
             - Domain icon + colored dot (learning=purple, startup=blue, writing=cyan)
             - Goal title (titleMedium)
             - Progress bar (linear, filled with domain color)
             - "3/8 milestones" text in labelMedium
       - Floating "+" button (GradientButton, circular) — shows SnackBar "Coming in Phase 3!"
       - List items stagger in with flutter_animate

    2. **chat_tab.dart** — Replace stub:
       - GradientBackground → Center → Column:
         - Large animated Guru icon (smart_toy_rounded, 80px) with glow effect pulsing
         - "Meet Your Guru" in headlineMedium
         - "Your AI learning companion will be here soon" in bodyMedium/textSecondary
         - "Coming in Phase 3" badge (small GlassCard with accent text)
       - Icon pulse animation: scale 1.0→1.1→1.0 repeating (flutter_animate)

    What to avoid and WHY:
    - Do NOT implement goal detail navigation — shell only, no detail screens
    - Do NOT add chat input — that's Phase 3
  </action>
  <verify>cd eklavya_mobile && flutter analyze lib/features/goals/ && flutter analyze lib/features/chat/</verify>
  <done>Goals tab with 3 demo goals, progress bars, filter chips. Chat tab with animated Guru placeholder.</done>
</task>

## Success Criteria
- [ ] Demo data file with user, goals, tasks, analytics
- [ ] Home tab: greeting top bar, XP card, streak card, today's tasks with stagger animation
- [ ] Goals tab: domain filter chips, 3 goal cards with progress bars
- [ ] Chat tab: animated Guru icon placeholder with "Coming in Phase 3" badge
- [ ] All tabs use GlassCard + design tokens consistently
- [ ] `flutter analyze` passes on all feature dirs
