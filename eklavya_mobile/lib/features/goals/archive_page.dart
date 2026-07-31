import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/goals_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'goal_card.dart';
import 'goal_roadmap_screen.dart';

class GoalArchivePage extends ConsumerWidget {
  const GoalArchivePage({super.key});

  Future<bool> _confirm(BuildContext context, String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _restoreGoal(BuildContext context, WidgetRef ref, GoalItem goal) async {
    final ok = await GoalsService().restoreGoal(goal.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Goal restored' : 'Could not restore goal'),
        backgroundColor: ok ? context.colors.success : context.colors.error,
      ),
    );
    if (ok) {
      ref.invalidate(archivedGoalsProvider);
      ref.invalidate(goalsProvider);
    }
  }

  Future<void> _deleteGoal(BuildContext context, WidgetRef ref, GoalItem goal) async {
    final confirmed = await _confirm(
      context,
      'Delete roadmap?',
      'This will permanently remove "${goal.title}" and all of its milestones and tasks.',
    );
    if (!confirmed) return;

    final ok = await GoalsService().deleteGoal(goal.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Goal deleted' : 'Could not delete goal'),
        backgroundColor: ok ? context.colors.success : context.colors.error,
      ),
    );
    if (ok) {
      ref.invalidate(archivedGoalsProvider);
      ref.invalidate(goalsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final archivedAsync = ref.watch(archivedGoalsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Archive', style: theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: archivedAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: context.colors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text('Could not load archive', style: TextStyle(color: context.colors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => ref.invalidate(archivedGoalsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (goals) {
          return RefreshIndicator(
            color: context.colors.primary,
            onRefresh: () async {
              ref.invalidate(archivedGoalsProvider);
              await ref.read(archivedGoalsProvider.future);
            },
            child: goals.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 100),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.archive_outlined, size: 52, color: context.colors.textTertiary),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Nothing archived yet',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Archived roadmaps will appear here.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: Text(
                          '${goals.length} archived roadmap${goals.length == 1 ? '' : 's'}',
                          style: theme.textTheme.bodyLarge?.copyWith(color: context.colors.textSecondary),
                        ),
                      ),
                      ...goals.map((goal) => GoalCard(
                            goal: goal,
                            archivedView: true,
                            primaryActionLabel: 'Restore',
                            primaryActionIcon: Icons.unarchive_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GoalRoadmapScreen(goal: goal),
                                ),
                              );
                            },
                            onPrimaryAction: () => _restoreGoal(context, ref, goal),
                            onDelete: () => _deleteGoal(context, ref, goal),
                          )),
                    ],
                  ),
          );
        },
      ),
    );
  }
}