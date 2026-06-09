import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'goal_roadmap_screen.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

class GoalsTab extends ConsumerStatefulWidget {
  const GoalsTab({super.key});

  @override
  ConsumerState<GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends ConsumerState<GoalsTab> {
  final domains = ['All', 'Learning', 'Fitness', 'Startup', 'Finance', 'Writing'];
  String selectedDomain = 'All';

  Color _getDomainColor(String domain) {
    switch (domain) {
      case 'learning':
        return context.colors.primary;
      case 'startup':
        return context.colors.secondary;
      case 'writing':
        return context.colors.accent;
      default:
        return context.colors.textSecondary;
    }
  }

  IconData _getDomainIcon(String domain) {
    switch (domain) {
      case 'learning':
        return Icons.school_rounded;
      case 'startup':
        return Icons.rocket_launch_rounded;
      case 'writing':
        return Icons.edit_note_rounded;
      default:
        return Icons.track_changes_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goalsAsync = ref.watch(goalsProvider);

    return goalsAsync.when(
      loading: () => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
            child: CircularProgressIndicator(color: context.colors.primary)),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 48, color: context.colors.textTertiary),
              SizedBox(height: AppSpacing.md),
              Text('Could not load goals',
                  style: TextStyle(color: context.colors.textSecondary)),
              SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => ref.invalidate(goalsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (goals) {
        final displayedGoals = selectedDomain == 'All'
            ? goals
            : goals
                .where((g) =>
                    g.domain.toLowerCase() == selectedDomain.toLowerCase())
                .toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.go('/chat'),
            backgroundColor: context.colors.primary,
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Goals',
                          style: theme.textTheme.displayLarge
                              ?.copyWith(fontSize: 32)),
                      const SizedBox(height: 4),
                      Text(
                          '${goals.where((g) => g.status == 'active').length} active goals',
                          style: theme.textTheme.bodyLarge?.copyWith(
                              color: context.colors.textSecondary)),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // ─── Filter chips ───
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    children: domains.map((d) {
                      final isSelected = d == selectedDomain;
                      return Padding(
                        padding: EdgeInsets.only(right: AppSpacing.sm),
                        child: InkWell(
                          onTap: () =>
                              setState(() => selectedDomain = d),
                          borderRadius: AppRadii.pill,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.colors.primary
                                  : context.colors.surface,
                              borderRadius: AppRadii.pill,
                              border: Border.all(
                                  color: isSelected
                                      ? context.colors.primaryLight
                                      : context.colors.surfaceLight),
                            ),
                            child: Text(
                              d,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: isSelected
                                    ? context.colors.textPrimary
                                    : context.colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),

                // ─── Goals list with pull-to-refresh ───
                Expanded(
                  child: RefreshIndicator(
                    color: context.colors.primary,
                    onRefresh: () async {
                      ref.invalidate(goalsProvider);
                      await ref.read(goalsProvider.future);
                    },
                    child: displayedGoals.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: 80),
                              Center(
                                child: Text(
                                  'No goals found.\nTap + to create a roadmap!',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(
                                          color: context
                                              .colors.textSecondary),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg),
                            itemCount: displayedGoals.length,
                            itemBuilder: (context, index) {
                              final goal = displayedGoals[index];
                              final domainColor =
                                  _getDomainColor(goal.domain);
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            GoalRoadmapScreen(goal: goal)),
                                  );
                                },
                                borderRadius: AppRadii.lg,
                                child: Container(
                                  margin: EdgeInsets.only(
                                      bottom: AppSpacing.md),
                                  padding:
                                      EdgeInsets.all(AppSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: context.colors.surface,
                                    borderRadius: AppRadii.lg,
                                    border: Border.all(
                                        color:
                                            context.colors.glassBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: domainColor
                                                  .withValues(alpha: 0.2),
                                              borderRadius: AppRadii.md,
                                            ),
                                            child: Icon(
                                                _getDomainIcon(
                                                    goal.domain),
                                                color: domainColor,
                                                size: 20),
                                          ),
                                          SizedBox(width: AppSpacing.md),
                                          Expanded(
                                            child: Text(goal.title,
                                                style: theme.textTheme
                                                    .titleMedium),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: AppSpacing.lg),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                        children: [
                                          Text('Progress',
                                              style: theme
                                                  .textTheme.labelMedium
                                                  ?.copyWith(
                                                      color: context.colors
                                                          .textSecondary)),
                                          Text(
                                              '${goal.completedMilestones}/${goal.milestonesCount} milestones',
                                              style: theme
                                                  .textTheme.labelMedium
                                                  ?.copyWith(
                                                      color: context.colors
                                                          .textPrimary)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: AppRadii.pill,
                                        child: LinearProgressIndicator(
                                          value: goal.progress / 100.0,
                                          backgroundColor:
                                              context.colors.surfaceLight,
                                          valueColor:
                                              AlwaysStoppedAnimation<
                                                      Color>(
                                                  domainColor),
                                          minHeight: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: (100 * index).ms)
                                  .slideY(
                                      begin: 0.1,
                                      end: 0,
                                      duration: 400.ms);
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
