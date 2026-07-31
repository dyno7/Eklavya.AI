import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/goals_service.dart';
import 'goal_card.dart';
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

  Future<void> _archiveSelectedGoal(GoalItem goal) async {
    final ok = await GoalsService().archiveGoal(goal.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Roadmap archived' : 'Could not archive roadmap'),
        backgroundColor: ok ? context.colors.success : context.colors.error,
      ),
    );
  }

  Future<void> _deleteGoal(GoalItem goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete roadmap?'),
        content: Text('This permanently removes "${goal.title}" and all of its milestones and tasks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await GoalsService().deleteGoal(goal.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Roadmap deleted' : 'Could not delete roadmap'),
        backgroundColor: ok ? context.colors.success : context.colors.error,
      ),
    );
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
      error: (error, stackTrace) => Scaffold(
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
        final filteredGoals = selectedDomain == 'All'
            ? goals
            : goals
                .where((g) =>
                    g.domain.toLowerCase() == selectedDomain.toLowerCase())
                .toList();
        final displayedGoals = filteredGoals;

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
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('My Goals',
                                    style: theme.textTheme.displayLarge
                                        ?.copyWith(fontSize: 32)),
                                const SizedBox(height: 4),
                                Text(
                                    '${goals.where((g) => g.status == 'active' && !g.archived).length} active goals',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        color: context.colors.textSecondary)),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Archived roadmaps',
                            onPressed: () => context.push('/goals/archive'),
                            icon: Icon(
                              Icons.archive_outlined,
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
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
                              return GoalCard(
                                goal: goal,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GoalRoadmapScreen(goal: goal),
                                    ),
                                  );
                                },
                                primaryActionLabel: 'Archive',
                                primaryActionIcon: Icons.archive_outlined,
                                onPrimaryAction: () => _archiveSelectedGoal(goal),
                                onDelete: () => _deleteGoal(goal),
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
