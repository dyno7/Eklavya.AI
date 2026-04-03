import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchRoadmap();
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

    final result = await _dashboardService.completeTask(task.id);
    if (!mounted) return;

    setState(() {
      _completingTasks.remove(task.id);
      // Optimistically update
      if (result != null) {
        // find and update the task status in local state
        for (var m in _milestones!) {
          for (int i=0; i<m.tasks.length; i++) {
            if (m.tasks[i].id == task.id) {
              m.tasks[i] = TaskItem(
                id: task.id, title: task.title, type: task.type, 
                xpReward: task.xpReward, status: 'completed'
              );
            }
          }
        }
      }
    });

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+${result.$1} XP earned! ⭐'),
          backgroundColor: context.colors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
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
                      ],
                    ),
                  );
                }
                
                final milestone = _milestones![index - 1];
                final isMilestoneComplete = milestone.tasks.isNotEmpty && milestone.tasks.every((t) => t.status == 'completed');
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32, height: 32,
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
                          SizedBox(width: AppSpacing.md),
                          Expanded(child: Text(milestone.title, style: theme.textTheme.titleLarge)),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: context.colors.glassBorder, width: 2)),
                          ),
                          padding: const EdgeInsets.only(left: AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: milestone.tasks.map((task) {
                              final isCompleted = task.status == 'completed';
                              final isCompleting = _completingTasks.contains(task.id);
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: InkWell(
                                  onTap: () => _completeTask(task),
                                  borderRadius: AppRadii.lg,
                                  child: GlassCard(
                                    padding: EdgeInsets.all(AppSpacing.md),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isCompleted ? Icons.check_circle_rounded : _getTaskIcon(task.type),
                                          color: isCompleted ? context.colors.success : context.colors.primary,
                                        ),
                                        SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Text(
                                            task.title,
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                                              color: isCompleted ? context.colors.textSecondary : context.colors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (isCompleting)
                                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                        else if (!isCompleted)
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: context.colors.accent.withAlpha(30),
                                              borderRadius: AppRadii.pill,
                                            ),
                                            child: Text('+${task.xpReward} XP', style: TextStyle(color: context.colors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn().scaleXY(begin: 0.95);
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.1, end: 0, duration: 400.ms),
                );
              },
            ),
    );
  }
}
