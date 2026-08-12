import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/coach_context_service.dart';
import '../../core/services/dashboard_service.dart';
import '../../core/services/goals_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass_card.dart';

class GoalRoadmapScreen extends ConsumerStatefulWidget {
  final GoalItem goal;

  const GoalRoadmapScreen({super.key, required this.goal});

  @override
  ConsumerState<GoalRoadmapScreen> createState() =>
      _GoalRoadmapScreenState();
}

class _GoalRoadmapScreenState extends ConsumerState<GoalRoadmapScreen> {
  final _goalsService = GoalsService();
  List<MilestoneItem>? _milestones;
  final Set<String> _completingTasks = {};
  final Set<String> _deletingTasks = {};
  final Set<String> _startingTimers = {};
  final Set<String> _stoppingTimers = {};
  Timer? _timerUpdateTimer;
  final Map<String, DateTime> _timerStartTimes = {};

  @override
  void initState() {
    super.initState();
    _fetchRoadmap();
  }

  @override
  void dispose() {
    _timerUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRoadmap() async {
    final data = await _goalsService.fetchGoalRoadmap(widget.goal.id);
    if (!mounted) return;
    setState(() => _milestones = data);
  }

  Future<void> _startTaskTimer(TaskItem task) async {
    if (_startingTimers.contains(task.id) || task.timerRunning) {
      return;
    }

    setState(() {
      _startingTimers.add(task.id);
      _timerStartTimes[task.id] = DateTime.now();
    });

    final updatedTask = await _goalsService.startTaskTimer(task.id);
    if (!mounted) return;

    setState(() {
      _startingTimers.remove(task.id);
    });

    if (updatedTask != null) {
      _updateTaskInState(updatedTask);
      _startTimerUpdater();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Timer started for "${task.title}"'),
          backgroundColor: context.colors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        _timerStartTimes.remove(task.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start timer'),
          backgroundColor: context.colors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _stopTaskTimer(TaskItem task) async {
    if (_stoppingTimers.contains(task.id) || !task.timerRunning) {
      return;
    }

    setState(() {
      _stoppingTimers.add(task.id);
    });

    final updatedTask = await _goalsService.stopTaskTimer(task.id);
    if (!mounted) return;

    setState(() {
      _stoppingTimers.remove(task.id);
      _timerStartTimes.remove(task.id);
    });

    if (updatedTask != null) {
      _updateTaskInState(updatedTask);
      _maybeStopTimerUpdater();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Timer stopped — ${updatedTask.actualMinutes} min recorded'),
          backgroundColor: context.colors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stop timer'),
          backgroundColor: context.colors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _startTimerUpdater() {
    _timerUpdateTimer?.cancel();
    _timerUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _maybeStopTimerUpdater() {
    final hasRunningTimer = _milestones?.expand((m) => m.tasks).any((t) => t.timerRunning) ?? false;
    if (!hasRunningTimer) {
      _timerUpdateTimer?.cancel();
      _timerUpdateTimer = null;
    }
  }

  void _updateTaskInState(TaskItem updatedTask) {
    for (var m in _milestones!) {
      for (int i = 0; i < m.tasks.length; i++) {
        if (m.tasks[i].id == updatedTask.id) {
          m.tasks[i] = updatedTask;
          break;
        }
      }
    }
  }

  Future<void> _completeTask(TaskItem task) async {
    if (task.status == 'completed' || _completingTasks.contains(task.id)) {
      return;
    }

    // Optimistic update — mark completed immediately so the UI responds instantly.
    setState(() {
      _completingTasks.add(task.id);
      for (var m in _milestones!) {
        for (int i = 0; i < m.tasks.length; i++) {
          if (m.tasks[i].id == task.id) {
            m.tasks[i] = TaskItem(
              id: task.id,
              title: task.title,
              type: task.type,
              xpReward: task.xpReward,
              status: 'completed',
              estimatedMinutes: task.estimatedMinutes,
              description: task.description,
              resources: task.resources,
            );
          }
        }
      }
    });

    final outcome =
        await ref.read(dashboardProvider.notifier).completeTask(task.id);
    if (!mounted) return;

    setState(() => _completingTasks.remove(task.id));

    if (outcome is TaskClaimResult) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '+${outcome.xpEarned}${outcome.bonusXp > 0 ? " (+${outcome.bonusXp} bonus)" : ""} XP earned! ⭐'),
        backgroundColor: context.colors.success,
        duration: const Duration(seconds: 2),
      ));
      // Refresh dashboard data in background — don't block the UI.
      ref.invalidate(dashboardProvider);
    } else if (outcome is TaskClaimError) {
      // Revert optimistic update.
      setState(() {
        for (var m in _milestones!) {
          for (int i = 0; i < m.tasks.length; i++) {
            if (m.tasks[i].id == task.id) {
              m.tasks[i] = task;
            }
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Couldn't complete task: ${outcome.message}"),
        backgroundColor: context.colors.error,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  Future<void> _deleteTask(TaskItem task) async {
    if (_deletingTasks.contains(task.id)) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final successColor = context.colors.success;
    final errorColor = context.colors.error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('This permanently removes "${task.title}" from the roadmap.'),
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
    if (confirmed != true) {
      return;
    }

    setState(() {
      _deletingTasks.add(task.id);
    });

    final ok = await _goalsService.deleteTask(task.id);
    if (!mounted) return;

    setState(() {
      _deletingTasks.remove(task.id);
    });

    if (ok) {
      await _fetchRoadmap();
      ref.invalidate(dashboardProvider);
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Task deleted'),
          backgroundColor: successColor,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Could not delete task'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Widget _buildStreakBanner(ThemeData theme, int currentStreak) {
    if (currentStreak == 0) return const SizedBox.shrink();

    final Color color;
    final String label;
    final String subtitle;
    final IconData icon;

    if (currentStreak >= 7) {
      color = const Color(0xFFFF6B35);
      icon = Icons.local_fire_department_rounded;
      label = '$currentStreak-day streak — ambitious pacing unlocked';
      subtitle =
          'This roadmap was tuned for high momentum. Later milestones are more challenging.';
    } else if (currentStreak >= 3) {
      color = const Color(0xFFFFB800);
      icon = Icons.bolt_rounded;
      label = '$currentStreak-day streak — balanced progression';
      subtitle =
          'Difficulty scales steadily across milestones to keep you growing.';
    } else {
      color = const Color(0xFF6B9BFF);
      icon = Icons.trending_up_rounded;
      label = 'Building momentum — easy start enabled';
      subtitle =
          'The first milestone is lightweight. Complete it to build your streak.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: AppRadii.md,
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: color, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: context.colors.textSecondary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTaskIcon(String type) {
    switch (type.toLowerCase()) {
      case 'watch':
        return Icons.play_circle_fill_rounded;
      case 'read':
        return Icons.menu_book_rounded;
      case 'practice':
        return Icons.code_rounded;
      case 'quiz':
        return Icons.help_center_rounded;
      case 'write':
        return Icons.edit_note_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  String _formatElapsedTime(TaskItem task) {
    if (task.timerRunning && task.startedAt != null) {
      final elapsed = DateTime.now().difference(task.startedAt!);
      final minutes = elapsed.inMinutes;
      final seconds = elapsed.inSeconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    if (task.actualMinutes != null) {
      return '${task.actualMinutes}m';
    }
    return '00:00';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Read streak from the already-loaded dashboard provider (no extra fetch)
    final currentStreak =
        ref.watch(dashboardProvider).asData?.value.user.currentStreak ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Roadmap', style: theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: _milestones == null
          ? Center(
              child: CircularProgressIndicator(
                  color: theme.colorScheme.primary))
          : RefreshIndicator(
              color: context.colors.primary,
              onRefresh: _fetchRoadmap,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(AppSpacing.lg),
                itemCount: _milestones!.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.goal.title,
                              style: theme.textTheme.headlineMedium),
                          const SizedBox(height: 8),
                          Text(widget.goal.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: context.colors.textSecondary)),
                          SizedBox(height: AppSpacing.lg),
                          _buildStreakBanner(theme, currentStreak),
                        ],
                      ),
                    );
                  }

                  final milestone = _milestones![index - 1];
                  final isMilestoneComplete = milestone.tasks.isNotEmpty &&
                      milestone.tasks.every((t) => t.status == 'completed');
                  final completedTasks = milestone.tasks
                      .where((t) => t.status == 'completed')
                      .length;

                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        tilePadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md),
                        childrenPadding: EdgeInsets.only(
                            left: AppSpacing.lg,
                            right: AppSpacing.lg,
                            bottom: AppSpacing.lg),
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isMilestoneComplete
                                ? context.colors.success
                                : context.colors.primary.withAlpha(40),
                          ),
                          child: Center(
                            child: isMilestoneComplete
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 20)
                                : Text('$index',
                                    style: TextStyle(
                                        color: context.colors.primary,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (milestone.narrativeArc != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      context.colors.primary.withAlpha(40),
                                  borderRadius: AppRadii.sm,
                                ),
                                child: Text(
                                  milestone.narrativeArc!.toUpperCase(),
                                  style:
                                      theme.textTheme.labelSmall?.copyWith(
                                    color: context.colors.primary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(milestone.title,
                                style: theme.textTheme.titleLarge),
                          ],
                        ),
                        subtitle: Text(
                            '$completedTasks/${milestone.tasks.length} tasks complete',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: context.colors.textSecondary)),
                        children: milestone.tasks.map((task) {
                          final isCompleted = task.status == 'completed';
                          final isCompleting =
                              _completingTasks.contains(task.id);

                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md, vertical: 4),
                              childrenPadding: EdgeInsets.only(
                                  left: AppSpacing.md,
                                  right: AppSpacing.md,
                                  bottom: AppSpacing.md),
                              leading: Checkbox(
                                value: isCompleted,
                                activeColor: context.colors.success,
                                onChanged:
                                    isCompleted || isCompleting
                                        ? null
                                        : (value) {
                                            if (value == true) {
                                              _completeTask(task);
                                            }
                                          },
                              ),
                              title: Text(
                                task.title,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isCompleted
                                      ? context.colors.textSecondary
                                      : context.colors.textPrimary,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Text('+${task.xpReward} XP',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                              color: context.colors.accent)),
                                  if (task.resources.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () async {
                                        final uri = Uri.tryParse(
                                            task.resources.first.url);
                                        if (uri != null &&
                                            await canLaunchUrl(uri)) {
                                          await launchUrl(uri,
                                              mode: LaunchMode
                                                  .externalApplication);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: context.colors.primary
                                              .withAlpha(20),
                                          borderRadius: AppRadii.pill,
                                          border: Border.all(
                                              color: context.colors.primary
                                                  .withAlpha(50)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.open_in_new_rounded,
                                                size: 11,
                                                color: context
                                                    .colors.primaryLight),
                                            const SizedBox(width: 3),
                                            Text(
                                              task.resources.length > 1
                                                  ? '${task.resources.length} Resources'
                                                  : 'Open Resource',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: context
                                                      .colors.primaryLight,
                                                  fontWeight:
                                                      FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (task.actualMinutes != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: context.colors.success
                                            .withAlpha(20),
                                        borderRadius: AppRadii.pill,
                                        border: Border.all(
                                            color: context.colors.success
                                                .withAlpha(50)),
                                      ),
                                      child: Text(
                                        '${task.actualMinutes} min',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: context.colors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  if (!_deletingTasks.contains(task.id))
                                    IconButton(
                                      tooltip: 'Delete task',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: context.colors.error,
                                        size: 20,
                                      ),
                                      onPressed: isCompleting
                                          ? null
                                          : () => _deleteTask(task),
                                    )
                                  else
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: context.colors.primary,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  isCompleting
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: context.colors.primary,
                                          ),
                                        )
                                      : Icon(
                                          isCompleted
                                              ? Icons.expand_more_rounded
                                              : Icons.info_outline_rounded,
                                        ),
                                ],
                              ),
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: context.colors.surfaceLight
                                        .withAlpha(80),
                                    borderRadius: AppRadii.md,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (task.description.isNotEmpty) ...[
                                        Text(
                                          task.description,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                  color: context
                                                      .colors.textPrimary,
                                                  height: 1.5),
                                        ),
                                        SizedBox(height: AppSpacing.md),
                                      ],
                                      Row(children: [
                                        Icon(Icons.timer_outlined,
                                            size: 14,
                                            color: context
                                                .colors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                            '~${task.estimatedMinutes} min',
                                            style: theme
                                                .textTheme.labelMedium
                                                ?.copyWith(
                                                    color: context.colors
                                                        .textSecondary)),
                                        if (task.timerRunning) ...[
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: context.colors.primary
                                                  .withAlpha(20),
                                              borderRadius: AppRadii.pill,
                                              border: Border.all(
                                                  color: context.colors.primary
                                                      .withAlpha(50)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.timer_rounded,
                                                    size: 12,
                                                    color: context
                                                        .colors.primaryLight),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatElapsedTime(task),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: context
                                                        .colors.primaryLight,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'monospace'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ] else if (task.actualMinutes != null) ...[
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: context.colors.success
                                                  .withAlpha(20),
                                              borderRadius: AppRadii.pill,
                                              border: Border.all(
                                                  color: context.colors.success
                                                      .withAlpha(50)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check_circle_rounded,
                                                    size: 12,
                                                    color: context
                                                        .colors.success),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${task.actualMinutes} min actual',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: context.colors.success,
                                                    fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        SizedBox(width: AppSpacing.md),
                                        Icon(_getTaskIcon(task.type),
                                            size: 14,
                                            color: context
                                                .colors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${task.type[0].toUpperCase()}${task.type.substring(1)}',
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                                  color: context.colors
                                                      .textSecondary),
                                        ),
                                      ]),
if (task.resources.isNotEmpty) ...[
                                        SizedBox(height: AppSpacing.md),
                                        Text('Resources',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                    color: context.colors.textPrimary,
                                                    fontWeight: FontWeight.w600)),
                                        SizedBox(height: AppSpacing.sm),
                                        ...task.resources.map((res) => Padding(
                                          padding: EdgeInsets.only(bottom: AppSpacing.sm),
                                          child: _ResourceButton(resource: res),
                                        )),
                                      ],
                                      SizedBox(height: AppSpacing.md),
                                      // Timer + Coach row (prominent pill buttons)
                                      if (!isCompleted) ...[
                                        Row(
                                          children: [
                                            // Start/Stop Timer Pill Button
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: task.timerRunning
                                                    ? (_stoppingTimers.contains(task.id)
                                                        ? null
                                                        : () => _stopTaskTimer(task))
                                                    : (_startingTimers.contains(task.id)
                                                        ? null
                                                        : () => _startTaskTimer(task)),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 200),
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: AppSpacing.md,
                                                      vertical: AppSpacing.sm + 2),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: task.timerRunning
                                                          ? [
                                                              context.colors.error
                                                                  .withAlpha(200),
                                                              context.colors.error
                                                                  .withAlpha(180),
                                                            ]
                                                          : [
                                                              context.colors.success
                                                                  .withAlpha(200),
                                                              context.colors.success
                                                                  .withAlpha(180),
                                                            ],
                                                    ),
                                                    borderRadius: AppRadii.pill,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: (task.timerRunning
                                                            ? context.colors.error
                                                            : context.colors.success)
                                                            .withAlpha(80),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      if (_startingTimers.contains(task.id) ||
                                                          _stoppingTimers.contains(task.id))
                                                        SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Colors.white,
                                                          ),
                                                        )
                                                      else
                                                        Icon(
                                                            task.timerRunning
                                                                ? Icons.timer_rounded
                                                                : Icons.play_arrow_rounded,
                                                            size: 18,
                                                            color: Colors.white),
                                                      const SizedBox(width: AppSpacing.sm),
                                                      Text(
                                                        task.timerRunning
                                                            ? 'Stop Timer'
                                                            : 'Start Timer',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 14),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.md),
                                            // Ask Coach Pill Button
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  CoachContextService.setContext(
                                                      CoachTaskContext(
                                                    taskTitle: task.title,
                                                    taskDescription: task
                                                            .description.isNotEmpty
                                                        ? task.description
                                                        : null,
                                                    taskType: task.type,
                                                    milestoneTitle: milestone.title,
                                                  ));
                                                  context.go('/coach');
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: AppSpacing.md,
                                                      vertical: AppSpacing.sm + 2),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        context.colors.secondary
                                                            .withAlpha(200),
                                                        context.colors.accent
                                                            .withAlpha(200)
                                                      ],
                                                    ),
                                                    borderRadius: AppRadii.pill,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: context.colors.secondary
                                                            .withAlpha(80),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.psychology_rounded,
                                                        size: 18,
                                                        color: Colors.white),
                                                      SizedBox(width: AppSpacing.sm),
                                                      Text('Ask Coach',
                                                          style: TextStyle(
                                                              color: Colors.white,
                                                              fontWeight:
                                                                  FontWeight.w700,
                                                              fontSize: 14)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideY(
                              begin: 0.05, end: 0, duration: 250.ms);
                        }).toList(),
                      ),
                    ),
                  ).animate(delay: (index * 100).ms).fadeIn().slideX(
                      begin: 0.1, end: 0, duration: 400.ms);
                },
              ),
            ),
    );
  }
}

class _ResourceButton extends StatelessWidget {
  final TaskResource resource;
  const _ResourceButton({required this.resource});

  IconData _iconFor(String url) {
    final u = url.toLowerCase();
    if (u.contains('youtube.com') || u.contains('youtu.be')) return Icons.play_circle_outline_rounded;
    if (u.contains('github.com')) return Icons.code_rounded;
    if (u.contains('coursera') || u.contains('udemy') || u.contains('edx')) return Icons.school_outlined;
    if (u.contains('docs.') || u.contains('/docs') || u.contains('mdn') || u.contains('developer.')) return Icons.description_outlined;
    return Icons.article_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = resource.title.isNotEmpty ? resource.title : resource.url;

    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(resource.url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: context.colors.primary.withAlpha(18),
          borderRadius: AppRadii.md,
          border: Border.all(color: context.colors.primary.withAlpha(45)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.colors.primary.withAlpha(30),
                borderRadius: AppRadii.sm,
              ),
              child: Icon(_iconFor(resource.url), size: 17, color: context.colors.primaryLight),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: context.colors.primaryGradient,
                borderRadius: AppRadii.pill,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Open', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
