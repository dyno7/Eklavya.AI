import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/data/demo_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass_card.dart';

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  // Distinct domain colors (semantic, not theme-dependent)
  static const _domainColors = {
    'learning': Color(0xFF8B5CF6), // Violet
    'startup': Color(0xFF3B82F6),  // Blue
    'writing': Color(0xFFF59E0B),  // Amber
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analytics = DemoData.analytics;

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

              // ─── Weekly XP Card ───
              GlassCard(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This Week', style: theme.textTheme.titleMedium),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      '${analytics.weeklyXp.fold<int>(0, (a,b) => a + b)} XP',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: context.colors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      height: 170,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (i) {
                          final maxWeeklyXp = analytics.weeklyXp.reduce((a, b) => a > b ? a : b).toDouble();
                          final heightRatio = maxWeeklyXp > 0 ? analytics.weeklyXp[i] / maxWeeklyXp : 0.0;
                          final isToday = i == 6;
                          final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          final barHeight = 120 * heightRatio + 4;
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Value label above bar
                              Text(
                                '${analytics.weeklyXp[i]}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isToday ? context.colors.primaryLight : context.colors.textTertiary,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 10,
                                ),
                              ),
                              SizedBox(height: 4),
                              // Bar with gradient
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
                                begin: 0, end: 1, duration: 500.ms, delay: (100 * i).ms,
                                curve: Curves.easeOutCubic,
                              ),
                              SizedBox(height: 8),
                              Text(days[i], style: theme.textTheme.labelMedium?.copyWith(
                                color: isToday ? context.colors.textPrimary : context.colors.textSecondary,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              )),
                            ],
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1, end: 0, duration: 400.ms),
              SizedBox(height: AppSpacing.lg),

              // ─── Streak Calendar Card ───
              GlassCard(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Streak: ${DemoData.user.currentStreak} days 🔥', style: theme.textTheme.titleMedium),
                    SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(30, (i) {
                        final isCompleted = i >= 30 - DemoData.user.currentStreak;
                        final isToday = i == 29;
                        final color = isCompleted ? context.colors.success : context.colors.surfaceLight;
                        
                        return Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isToday ? color : color.withValues(alpha: isCompleted ? 1 : 0.3),
                            shape: BoxShape.circle,
                            border: isToday ? Border.all(color: context.colors.primary, width: 2) : null,
                          ),
                        ).animate().fadeIn(delay: (10 * i).ms);
                      }),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
              SizedBox(height: AppSpacing.lg),

              // ─── Domain Distribution Card ───
              GlassCard(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Learning Focus', style: theme.textTheme.titleMedium),
                    SizedBox(height: AppSpacing.xl),
                    ...analytics.domainDistribution.entries.map((e) {
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
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(displayName, style: theme.textTheme.labelLarge ?? TextStyle()),
                                  ],
                                ),
                                Text('$percent%', style: theme.textTheme.labelMedium?.copyWith(
                                  color: context.colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ) ?? TextStyle()),
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
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
              SizedBox(height: AppSpacing.xxxl),
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
