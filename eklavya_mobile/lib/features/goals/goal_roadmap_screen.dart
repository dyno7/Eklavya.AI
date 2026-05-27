import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/coach_context_service.dart';
import '../../core/services/dashboard_service.dart';
import '../../core/services/goals_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass_card.dart';

class GoalRoadmapScreen extends StatefulWidget {
  final GoalItem goal;

  const GoalRoadmapScreen({super.key, required this.goal});

  @override
  State<GoalRoadmapScreen> createState() => _GoalRoadmapScreenState();
}

class _GoalRoadmapScreenState extends State<GoalRoadmapScreen> {
  final _goalsService = GoalsService();
  final _dashboardService = DashboardService();
  
  List<MilestoneItem>? _milestones;
  final Set<String> _completingTasks = {};
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    final results = await Future.wait([
      _goalsService.fetchGoalRoadmap(widget.goal.id),
      _dashboardService.getSummary(),
    ]);
    if (!mounted) return;
    setState(() {
      _milestones = results[0] as List<MilestoneItem>;
      final summary = results[1] as DashboardSummary?;
      _currentStreak = summary?.user.currentStreak ?? 0;
    });
  }

  Future<void> _fetchRoadmap() async {
    final data = await _goalsService.fetchGoalRoadmap(widget.goal.id);
    if (!mounted) return;
    setState(() {
      _milestones = data;
    });
  }

  Future<void> _completeTask(TaskItem task) async {
    if (task.status == 'completed' || _completingTasks.contains(task.id)) return;

    setState(() {
      _completingTasks.add(task.id);
    });

    final outcome = await _dashboardService.completeTask(task.id);
    if (!mounted) return;

    setState(() {
      _completingTasks.remove(task.id);
      if (outcome is TaskClaimResult) {
        for (var m in _milestones!) {
          for (int i = 0; i < m.tasks.length; i++) {
            if (m.tasks[i].id == task.id) {
              m.tasks[i] = TaskItem(
                id: task.id, title: task.title, type: task.type,
                xpReward: task.xpReward, status: 'completed',
                estimatedMinutes: task.estimatedMinutes,
                description: task.description,
                resources: task.resources,
              );
            }
          }
        }
      }
    });

    if (outcome is TaskClaimResult) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+${outcome.xpEarned}${outcome.bonusXp > 0 ? " (+${outcome.bonusXp} bonus)" : ""} XP earned! ⭐'),
          backgroundColor: context.colors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      await _fetchRoadmap();
    } else if (outcome is TaskClaimError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't complete task: ${outcome.message}"),
          backgroundColor: context.colors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildStreakBanner(ThemeData theme) {
    if (_currentStreak == 0) return const SizedBox.shrink();

    final Color color;
    final String label;
    final String subtitle;
    final IconData icon;

    if (_currentStreak >= 7) {
      color = const Color(0xFFFF6B35);
      icon = Icons.local_fire_department_rounded;
      label = '$_currentStreak-day streak — ambitious pacing unlocked';
      subtitle = 'This roadmap was tuned for high momentum. Later milestones are more challenging.';
    } else if (_currentStreak >= 3) {
      color = const Color(0xFFFFB800);
      icon = Icons.bolt_rounded;
      label = '$_currentStreak-day streak — balanced progression';
      subtitle = 'Difficulty scales steadily across milestones to keep you growing.';
    } else {
      color = const Color(0xFF6B9BFF);
      icon = Icons.trending_up_rounded;
      label = 'Building momentum — easy start enabled';
      subtitle = 'The first milestone is lightweight. Complete it to build your streak.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
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
      case 'watch': return Icons.play_circle_fill_rounded;
      case 'read': return Icons.menu_book_rounded;
      case 'practice': return Icons.code_rounded;
      case 'quiz': return Icons.help_center_rounded;
      case 'write': return Icons.edit_note_rounded;
      default: return Icons.task_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Roadmap', style: theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: _milestones == null
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : ListView.builder(
              padding: EdgeInsets.all(AppSpacing.lg),
              itemCount: _milestones!.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.goal.title, style: theme.textTheme.headlineMedium),
                        SizedBox(height: 8),
                        Text(widget.goal.description, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
                        SizedBox(height: AppSpacing.lg),
                        _buildStreakBanner(theme),
                      ],
                    ),
                  );
                }
                
                final milestone = _milestones![index - 1];
                final isMilestoneComplete = milestone.tasks.isNotEmpty && milestone.tasks.every((t) => t.status == 'completed');
                
                final completedTasks = milestone.tasks.where((t) => t.status == 'completed').length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      tilePadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      childrenPadding: EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.lg),
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isMilestoneComplete ? context.colors.success : context.colors.primary.withAlpha(40),
                        ),
                        child: Center(
                          child: isMilestoneComplete
                              ? Icon(Icons.check_rounded, color: Colors.white, size: 20)
                              : Text('$index', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (milestone.narrativeArc != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.colors.primary.withAlpha(40),
                                borderRadius: AppRadii.sm,
                              ),
                              child: Text(
                                milestone.narrativeArc!.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(milestone.title, style: theme.textTheme.titleLarge),
                        ],
                      ),
                      subtitle: Text('$completedTasks/${milestone.tasks.length} tasks complete', style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                      children: milestone.tasks.map((task) {
                        final isCompleted = task.status == 'completed';
                        final isCompleting = _completingTasks.contains(task.id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                            childrenPadding: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: AppSpacing.md),
                            leading: Checkbox(
                              value: isCompleted,
                              activeColor: context.colors.success,
                              onChanged: isCompleted || isCompleting ? null : (value) {
                                if (value == true) _completeTask(task);
                              },
                            ),
                            title: Text(
                              task.title,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                color: isCompleted ? context.colors.textSecondary : context.colors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '+${task.xpReward} XP',
                              style: theme.textTheme.labelMedium?.copyWith(color: context.colors.accent),
                            ),
                            trailing: isCompleting
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(isCompleted ? Icons.expand_more_rounded : Icons.info_outline_rounded),
                            children: [
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: context.colors.surfaceLight.withAlpha(80),
                                  borderRadius: AppRadii.md,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Task description
                                    if (task.description.isNotEmpty) ...[
                                      Text(
                                        task.description,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: context.colors.textPrimary,
                                          height: 1.5,
                                        ),
                                      ),
                                      SizedBox(height: AppSpacing.md),
                                    ],
                                    // Meta row
                                    Row(children: [
                                      Icon(Icons.timer_outlined, size: 14, color: context.colors.textSecondary),
                                      SizedBox(width: 4),
                                      Text('~${task.estimatedMinutes} min', style: theme.textTheme.labelMedium?.copyWith(color: context.colors.textSecondary)),
                                      SizedBox(width: AppSpacing.md),
                                      Icon(_getTaskIcon(task.type), size: 14, color: context.colors.textSecondary),
                                      SizedBox(width: 4),
                                      Text(
                                        '${task.type[0].toUpperCase()}${task.type.substring(1)}',
                                        style: theme.textTheme.labelMedium?.copyWith(color: context.colors.textSecondary),
                                      ),
                                    ]),
                                    // Resource links
                                    if (task.resources.isNotEmpty) ...[
                                      SizedBox(height: AppSpacing.md),
                                      Text(
                                        'Resources',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          color: context.colors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: AppSpacing.xs),
                                      ...task.resources.map((res) => Padding(
                                        padding: EdgeInsets.only(bottom: AppSpacing.xs),
                                        child: InkWell(
                                          onTap: () async {
                                            final uri = Uri.tryParse(res.url);
                                            if (uri != null && await canLaunchUrl(uri)) {
                                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                                            }
                                          },
                                          borderRadius: AppRadii.sm,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                            decoration: BoxDecoration(
                                              color: context.colors.primary.withAlpha(20),
                                              borderRadius: AppRadii.sm,
                                              border: Border.all(color: context.colors.primary.withAlpha(40)),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.link_rounded, size: 16, color: context.colors.primaryLight),
                                                SizedBox(width: AppSpacing.sm),
                                                Expanded(
                                                  child: Text(
                                                    res.title.isNotEmpty ? res.title : res.url,
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: context.colors.primaryLight,
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Icon(Icons.open_in_new_rounded, size: 14, color: context.colors.primaryLight),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )),
                                    ],
                                    // Ask Coach button
                                    SizedBox(height: AppSpacing.md),
                                    GestureDetector(
                                      onTap: () {
                                        CoachContextService.setContext(CoachTaskContext(
                                          taskTitle: task.title,
                                          taskDescription: task.description.isNotEmpty ? task.description : null,
                                          taskType: task.type,
                                          milestoneTitle: milestone.title,
                                        ));
                                        context.go('/coach');
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [context.colors.secondary.withAlpha(200), context.colors.accent.withAlpha(200)],
                                          ),
                                          borderRadius: AppRadii.pill,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.psychology_rounded, size: 16, color: Colors.white),
                                            SizedBox(width: AppSpacing.sm),
                                            Text(
                                              'Ask Coach',
                                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.05, end: 0, duration: 250.ms);
                      }).toList(),
                    ),
                  ),
                ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.1, end: 0, duration: 400.ms);
              },
            ),
    );
  }
}
