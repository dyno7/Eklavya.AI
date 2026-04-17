import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/dashboard_service.dart';
import '../../core/services/goals_service.dart';
import '../../core/services/roadmap_sync_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass_card.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  final _dashboardService = DashboardService();
  final _goalsService = GoalsService();
  DashboardSummary? _summary;
  AnalyticsSummary? _analytics;
  List<GoalItem> _allGoals = [];

  @override
  void initState() {
    super.initState();
    RoadmapSyncService.updates.addListener(_handleRoadmapUpdated);
    _fetchStats();
  }

  @override
  void dispose() {
    RoadmapSyncService.updates.removeListener(_handleRoadmapUpdated);
    super.dispose();
  }

  void _handleRoadmapUpdated() => _fetchStats();

  Future<void> _fetchStats() async {
    final summaryFuture = _dashboardService.getSummary();
    final analyticsFuture = _dashboardService.getAnalyticsSummary();
    final goalsFuture = _goalsService.fetchGoals();
    final results = await Future.wait([summaryFuture, analyticsFuture, goalsFuture]);
    if (!mounted) return;
    setState(() {
      _summary = results[0] as DashboardSummary;
      _analytics = results[1] as AnalyticsSummary?;
      _allGoals = results[2] as List<GoalItem>;
    });
  }

  static const _domainColors = {
    'learning': Color(0xFF8B5CF6),
    'startup': Color(0xFF3B82F6),
    'fitness': Color(0xFF10B981),
    'writing': Color(0xFFF59E0B),
    'finance': Color(0xFFEF4444),
  };

  @override
  Widget build(BuildContext context) {
    if (_summary == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }

    final theme = Theme.of(context);
    final summary = _summary!;
    final userStats = summary.user;
    final weeklyXp = _analytics?.dailyXp ?? List<int>.filled(7, 0);
    final completionRate = _analytics?.completionRate ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.lg),
              Text('Analytics', style: theme.textTheme.displayLarge?.copyWith(fontSize: 32)),
              SizedBox(height: 4),
              Text('Your learning journey', style: theme.textTheme.bodyLarge?.copyWith(color: context.colors.textSecondary)),
              SizedBox(height: AppSpacing.lg),

              // ─── Weekly XP Bar Chart ───
              _buildWeeklyXpCard(context, theme, weeklyXp, userStats),
              SizedBox(height: AppSpacing.lg),

              // ─── Streak Calendar (Full Month Grid) ───
              _buildStreakCalendar(context, theme, userStats),
              SizedBox(height: AppSpacing.lg),

              // ─── Learning Focus (Gradient Domain Distribution) ───
              _buildLearningFocus(context, theme),
              SizedBox(height: AppSpacing.lg),

              // ─── Completion Rate (Last) ───
              _buildCompletionRate(context, theme, completionRate),
              SizedBox(height: AppSpacing.xxxl),
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 1. Weekly XP — Proper Row Layout ────────────────
  Widget _buildWeeklyXpCard(BuildContext context, ThemeData theme, List<int> weeklyXp, UserSummary userStats) {
    final maxWeeklyXp = weeklyXp.reduce((a, b) => a > b ? a : b).toDouble();
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return GlassCard(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('This Week', style: theme.textTheme.titleMedium),
              TextButton(
                onPressed: () => context.go('/goals'),
                child: Text('Open Roadmap', style: TextStyle(color: context.colors.primaryLight)),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '${userStats.totalXp} XP',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: context.colors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final heightRatio = maxWeeklyXp > 0 ? weeklyXp[i] / maxWeeklyXp : 0.0;
                final isToday = i == 6;
                final barHeight = 120.0 * heightRatio + 4;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${weeklyXp[i]}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isToday ? context.colors.primaryLight : context.colors.textTertiary,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        width: 32,
                        height: barHeight,
                        decoration: BoxDecoration(
                          gradient: isToday
                              ? LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [context.colors.primary, context.colors.accent],
                                )
                              : LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    context.colors.primary.withAlpha(40),
                                    context.colors.primary.withAlpha(100),
                                  ],
                                ),
                          borderRadius: AppRadii.sm,
                        ),
                      ).animate().scaleY(
                        alignment: Alignment.bottomCenter,
                        begin: 0, end: 1,
                        duration: 500.ms,
                        delay: (100 * i).ms,
                        curve: Curves.easeOutCubic,
                      ),
                      SizedBox(height: 8),
                      Text(days[i], style: theme.textTheme.labelMedium?.copyWith(
                        color: isToday ? context.colors.textPrimary : context.colors.textSecondary,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      )),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  // ─── 2. Full Month Streak Calendar Grid ──────────────
  Widget _buildStreakCalendar(BuildContext context, ThemeData theme, UserSummary userStats) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    // Monday=1 ... Sunday=7. Offset for grid alignment.
    final startWeekday = firstDayOfMonth.weekday; // 1=Mon
    final emptySlots = startWeekday - 1;

    // Determine which days the user was active (streak-based approximation)
    final streakDays = <int>{};
    for (int i = 0; i < userStats.currentStreak && i < daysInMonth; i++) {
      final day = now.day - i;
      if (day >= 1) streakDays.add(day);
    }

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return GlassCard(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _monthName(now.month),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text(
                    '${userStats.currentStreak} day streak 🔥',
                    style: theme.textTheme.labelMedium?.copyWith(color: context.colors.accent),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),

          // Day-of-week headers
          Row(
            children: dayLabels.map((d) => Expanded(
              child: Center(
                child: Text(d, style: theme.textTheme.labelSmall?.copyWith(
                  color: context.colors.textTertiary,
                  fontWeight: FontWeight.w600,
                )),
              ),
            )).toList(),
          ),
          SizedBox(height: AppSpacing.sm),

          // Calendar grid
          ...List.generate(((emptySlots + daysInMonth) / 7).ceil(), (week) {
            return Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Row(
                children: List.generate(7, (col) {
                  final cellIndex = week * 7 + col;
                  final dayNum = cellIndex - emptySlots + 1;

                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return Expanded(child: SizedBox(height: 40));
                  }

                  final isToday = dayNum == now.day;
                  final isActive = streakDays.contains(dayNum);
                  final isFuture = dayNum > now.day;

                  return Expanded(
                    child: Container(
                      height: 40,
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isFuture
                            ? context.colors.surfaceLight.withAlpha(60)
                            : isActive
                                ? context.colors.success.withAlpha(40)
                                : context.colors.surfaceLight.withAlpha(120),
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: context.colors.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: isFuture || (!isActive && dayNum <= now.day)
                            ? Text(
                                '$dayNum',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isFuture ? context.colors.textTertiary : context.colors.textSecondary,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                ),
                              )
                            : Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.colors.success,
                                ),
                              ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  String _monthName(int month) {
    const names = ['', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return names[month];
  }

  // ─── 3. Learning Focus (Gradient Domain Distribution) ──
  Widget _buildLearningFocus(BuildContext context, ThemeData theme) {
    // Build domain distribution from ALL goals weighted by completion
    final domainMap = <String, double>{};
    double totalWeight = 0;

    for (final goal in _allGoals) {
      final weight = goal.milestonesCount > 0
          ? goal.completedMilestones / goal.milestonesCount
          : 0.1; // Inactive goals still get a small slice
      final existing = domainMap[goal.domain] ?? 0;
      domainMap[goal.domain] = existing + weight + 0.1; // base 0.1 so new goals show up
      totalWeight += weight + 0.1;
    }

    // Normalize to percentages
    final distribution = <String, double>{};
    for (final entry in domainMap.entries) {
      distribution[entry.key] = totalWeight > 0 ? entry.value / totalWeight : 0;
    }

    return GlassCard(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Learning Focus', style: theme.textTheme.titleMedium),
          SizedBox(height: AppSpacing.xl),
          if (distribution.isEmpty)
            Text('No goals yet. Start a roadmap to see your focus.', style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary))
          else
            ...distribution.entries.map((e) {
              final domain = e.key;
              final percent = (e.value * 100).toInt();
              final color = _domainColors[domain] ?? context.colors.accent;
              final displayName = domain.substring(0, 1).toUpperCase() + domain.substring(1);
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(displayName, style: theme.textTheme.labelLarge),
                          ],
                        ),
                        Text('$percent%', style: theme.textTheme.labelMedium?.copyWith(
                          color: context.colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        )),
                      ],
                    ),
                    SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: AppRadii.pill,
                      child: LinearProgressIndicator(
                        value: e.value,
                        backgroundColor: context.colors.surfaceLight,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ).animate().scaleX(alignment: Alignment.centerLeft, begin: 0, end: 1, duration: 600.ms, curve: Curves.easeOutCubic),
                  ],
                ),
              );
            }),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  // ─── 4. Completion Rate (Bottom of Page) ────────────
  Widget _buildCompletionRate(BuildContext context, ThemeData theme, double completionRate) {
    return GlassCard(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Completion Rate', style: theme.textTheme.titleMedium),
              Text(
                '${(completionRate * 100).toInt()}%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: context.colors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadii.pill,
            child: LinearProgressIndicator(
              value: completionRate,
              backgroundColor: context.colors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.success),
              minHeight: 10,
            ),
          ).animate().scaleX(alignment: Alignment.centerLeft, begin: 0, end: 1, duration: 600.ms, curve: Curves.easeOutCubic),
          SizedBox(height: AppSpacing.sm),
          Text(
            '${_analytics?.completedTasks ?? 0} of ${_analytics?.totalTasks ?? 0} tasks completed • ${_analytics?.activeDaysLast30 ?? 0} active days (30d)',
            style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0, duration: 400.ms);
  }
}
