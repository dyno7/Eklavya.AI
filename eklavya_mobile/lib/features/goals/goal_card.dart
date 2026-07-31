import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/services/goals_service.dart';
import '../../core/theme/app_colors.dart';

enum _GoalMenuAction { open, primary, delete }

class GoalCard extends StatelessWidget {
  final GoalItem goal;
  final VoidCallback onTap;
  final Future<void> Function() onPrimaryAction;
  final Future<void> Function() onDelete;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final bool archivedView;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onTap,
    required this.onPrimaryAction,
    required this.onDelete,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
    this.archivedView = false,
  });

  Color _getDomainColor(BuildContext context, String domain) {
    switch (domain.toLowerCase()) {
      case 'learning':
        return context.colors.primary;
      case 'startup':
        return context.colors.secondary;
      case 'writing':
        return context.colors.accent;
      case 'fitness':
        return context.colors.success;
      default:
        return context.colors.textSecondary;
    }
  }

  IconData _getDomainIcon(String domain) {
    switch (domain.toLowerCase()) {
      case 'learning':
        return Icons.school_rounded;
      case 'startup':
        return Icons.rocket_launch_rounded;
      case 'writing':
        return Icons.edit_note_rounded;
      case 'fitness':
        return Icons.fitness_center_rounded;
      default:
        return Icons.track_changes_rounded;
    }
  }

  DateTime _effectiveSortDate() {
    return goal.lastActivityAt ?? goal.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Unknown date';
    final now = DateTime.now();
    final delta = now.difference(date);
    if (delta.inDays == 0) return 'Today';
    if (delta.inDays == 1) return 'Yesterday';
    if (delta.inDays < 7) return '${delta.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final domainColor = _getDomainColor(context, goal.domain);
    final isArchived = archivedView || goal.archived;
    final showMenuButton = true;

    return Slidable(
      key: ValueKey(goal.id),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.42,
        children: [
          SlidableAction(
            onPressed: (_) => unawaited(onPrimaryAction()),
            backgroundColor: domainColor,
            foregroundColor: Colors.white,
            icon: primaryActionIcon,
            label: primaryActionLabel,
            borderRadius: BorderRadius.circular(20),
          ),
          SlidableAction(
            onPressed: (_) => unawaited(onDelete()),
            backgroundColor: context.colors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Material(
          color: context.colors.surface,
          borderRadius: AppRadii.lg,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.lg,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: AppRadii.lg,
                border: Border.all(color: context.colors.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: domainColor.withValues(alpha: 0.2),
                          borderRadius: AppRadii.md,
                        ),
                        child: Icon(
                          _getDomainIcon(goal.domain),
                          color: domainColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    goal.title,
                                    style: theme.textTheme.titleMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (showMenuButton)
                                  Material(
                                    color: domainColor.withAlpha(18),
                                    shape: const CircleBorder(),
                                    child: PopupMenuButton<_GoalMenuAction>(
                                      tooltip: 'Roadmap actions',
                                      icon: Icon(
                                        Icons.more_vert_rounded,
                                        color: domainColor,
                                      ),
                                      onSelected: (value) {
                                        switch (value) {
                                          case _GoalMenuAction.open:
                                            onTap();
                                            break;
                                          case _GoalMenuAction.primary:
                                            unawaited(onPrimaryAction());
                                            break;
                                          case _GoalMenuAction.delete:
                                            unawaited(onDelete());
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: _GoalMenuAction.open,
                                          child: ListTile(
                                            dense: true,
                                            leading: Icon(Icons.open_in_new_rounded),
                                            title: Text('Open roadmap'),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: _GoalMenuAction.primary,
                                          child: ListTile(
                                            dense: true,
                                            leading: Icon(primaryActionIcon),
                                            title: Text(primaryActionLabel),
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: _GoalMenuAction.delete,
                                          child: ListTile(
                                            dense: true,
                                            leading: Icon(Icons.delete_outline_rounded),
                                            title: Text('Delete'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              goal.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.schedule_rounded,
                        label: 'Touched ${_dateLabel(_effectiveSortDate())}',
                        color: domainColor,
                      ),
                      _InfoChip(
                        icon: Icons.flag_rounded,
                        label: goal.status,
                        color: context.colors.textSecondary,
                      ),
                      if (isArchived)
                        _InfoChip(
                          icon: Icons.archive_outlined,
                          label: 'Archived',
                          color: context.colors.secondary,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                      Text(
                        '${goal.completedMilestones}/${goal.milestonesCount} milestones',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: AppRadii.pill,
                    child: LinearProgressIndicator(
                      value: goal.progress / 100.0,
                      backgroundColor: context.colors.surfaceLight,
                      valueColor: AlwaysStoppedAnimation<Color>(domainColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: AppRadii.pill,
        border: Border.all(color: color.withAlpha(32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}