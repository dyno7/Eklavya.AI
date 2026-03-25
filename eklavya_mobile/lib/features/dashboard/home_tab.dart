import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../core/data/demo_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass_card.dart';

/// Home tab dashboard implementation.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late final DemoUser user;
  late final List<DemoTask> tasks;

  @override
  void initState() {
    super.initState();
    user = DemoData.user;
    tasks = DemoData.tasks;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning,';
    if (hour >= 12 && hour < 17) return 'Good Afternoon,';
    if (hour >= 17 && hour < 21) return 'Good Evening,';
    return 'Good Night,';
  }

  IconData _getTaskIcon(String type) {
    switch (type) {
      case 'watch': return Icons.play_circle_fill_rounded;
      case 'practice': return Icons.code_rounded;
      case 'read': return Icons.menu_book_rounded;
      case 'quiz': return Icons.quiz_rounded;
      default: return Icons.star_rounded;
    }
  }

  IconData _getDomainIcon(String domain) {
    switch (domain) {
      case 'learning': return Icons.school_rounded;
      case 'startup': return Icons.rocket_launch_rounded;
      case 'writing': return Icons.edit_note_rounded;
      case 'fitness': return Icons.fitness_center_rounded;
      default: return Icons.flag_rounded;
    }
  }

  Color _getDomainColor(String domain, BuildContext context) {
    switch (domain) {
      case 'learning': return context.colors.primary;
      case 'startup': return context.colors.secondary;
      case 'writing': return context.colors.warning;
      case 'fitness': return context.colors.success;
      default: return context.colors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityGoal = DemoData.goals.first; // Most recent / priority goal
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.lg),
              // ─── Blinkit-Style Top Bar ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: Greeting
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: context.colors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              user.displayName,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                            SizedBox(width: 4),
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: Lottie.asset('assets/lottie/wave_hello.json', repeat: true),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Right: Notification bell + Profile avatar
                  _NotificationBell(
                    hasUnread: true,
                    onTap: () {},
                  ),
                  SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [context.colors.primary, context.colors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user.displayName[0],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xl),
              
              // ─── Let's Continue Card (Priority Goal) ───
              GlassCard(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Lottie.asset('assets/lottie/rocket_launch.json', repeat: true),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text("Let's Continue", style: theme.textTheme.titleMedium?.copyWith(
                          color: context.colors.primaryLight,
                          fontWeight: FontWeight.w600,
                        )),
                      ],
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      priorityGoal.title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        // Domain tag chip
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getDomainColor(priorityGoal.domain, context).withAlpha(40),
                            borderRadius: AppRadii.pill,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getDomainIcon(priorityGoal.domain),
                                size: 14,
                                color: _getDomainColor(priorityGoal.domain, context),
                              ),
                              SizedBox(width: 4),
                              Text(
                                priorityGoal.domain[0].toUpperCase() + priorityGoal.domain.substring(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getDomainColor(priorityGoal.domain, context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Text(
                          '${priorityGoal.completedMilestones}/${priorityGoal.milestonesCount} milestones',
                          style: theme.textTheme.labelMedium?.copyWith(color: context.colors.textSecondary),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.lg),
                    // Progress bar
                    ClipRRect(
                      borderRadius: AppRadii.pill,
                      child: LinearProgressIndicator(
                        value: priorityGoal.progress,
                        backgroundColor: context.colors.surfaceLight,
                        valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                        minHeight: 8,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(priorityGoal.progress * 100).toInt()}% complete',
                          style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary),
                        ),
                        // Continue CTA
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: context.colors.primaryGradient,
                            borderRadius: AppRadii.pill,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Continue',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1, end: 0, duration: 500.ms),
              
              SizedBox(height: AppSpacing.lg),
              
              // ─── Streak Card ───
              GlassCard(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Lottie.asset('assets/lottie/streak_fire.json', repeat: true),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.currentStreak} Day Streak 🔥',
                            style: theme.textTheme.titleMedium,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: List.generate(7, (index) {
                              final isCurrentOrPast = index < 5;
                              return Expanded(
                                child: Container(
                                  height: 6,
                                  margin: EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: isCurrentOrPast ? context.colors.warning : context.colors.surfaceLight,
                                    borderRadius: AppRadii.pill,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0, duration: 500.ms),
              
              SizedBox(height: AppSpacing.lg),

              // ─── XP Summary Card (moved below streak) ───
              GlassCard(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Lottie.asset('assets/lottie/xp_star.json', repeat: true),
                            ),
                            SizedBox(width: 6),
                            Text('Total XP', style: theme.textTheme.titleMedium),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(alpha: 0.2),
                            borderRadius: AppRadii.pill,
                          ),
                          child: Text(
                            'Level ${user.level}',
                            style: theme.textTheme.labelMedium?.copyWith(color: context.colors.primaryLight),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: user.totalXp),
                      duration: Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Text(
                          value.toString(),
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: context.colors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: AppRadii.pill,
                      child: LinearProgressIndicator(
                        value: 0.7,
                        backgroundColor: context.colors.surfaceLight,
                        valueColor: AlwaysStoppedAnimation<Color>(context.colors.accent),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0, duration: 500.ms),
              
              SizedBox(height: AppSpacing.xxl),
              
              // ─── Today's Tasks ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Today\'s Tasks', style: theme.textTheme.titleLarge),
                  TextButton(
                    onPressed: () {},
                    child: Text('See All', style: TextStyle(color: context.colors.primaryLight)),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              
              ...tasks.asMap().entries.map((entry) {
                final idx = entry.key;
                final task = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: AppRadii.lg,
                      border: Border.all(color: context.colors.surfaceLight),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
                      leading: Icon(
                        _getTaskIcon(task.type),
                        color: task.isCompleted ? context.colors.success : context.colors.secondary,
                        size: 28,
                      ),
                      title: Text(
                        task.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted ? context.colors.textTertiary : context.colors.textPrimary,
                        ),
                      ),
                      subtitle: Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          '+${task.xpReward} XP',
                          style: theme.textTheme.labelMedium?.copyWith(color: context.colors.accent),
                        ),
                      ),
                      trailing: Checkbox(
                        value: task.isCompleted,
                        activeColor: context.colors.success,
                        checkColor: context.colors.background,
                        side: BorderSide(color: context.colors.textSecondary, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setState(() {
                            task.isCompleted = val ?? false;
                          });
                        },
                      ),
                    ),
                  ).animate().fadeIn(delay: (300 + idx * 100).ms).slideX(begin: 0.05, end: 0, duration: 400.ms),
                );
              }),
              
              SizedBox(height: AppSpacing.xxl),

              // ─── Suggested Resources ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Suggested Resources', style: theme.textTheme.titleLarge),
                  TextButton(
                    onPressed: () {},
                    child: Text('See All', style: TextStyle(color: context.colors.primaryLight)),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _ResourceCard(
                      icon: Icons.play_circle_outline_rounded,
                      title: '3Blue1Brown: Neural Networks',
                      subtitle: 'YouTube Video',
                      tagColor: context.colors.primary,
                    ),
                    _ResourceCard(
                      icon: Icons.menu_book_rounded,
                      title: 'Deep Learning Book Ch.6',
                      subtitle: 'Reading Material',
                      tagColor: context.colors.secondary,
                    ),
                    _ResourceCard(
                      icon: Icons.code_rounded,
                      title: 'PyTorch CNN Tutorial',
                      subtitle: 'Hands-on Exercise',
                      tagColor: context.colors.accent,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
              
              SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Notification Bell with Badge ───
class _NotificationBell extends StatelessWidget {
  final bool hasUnread;
  final VoidCallback onTap;

  const _NotificationBell({required this.hasUnread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.colors.surfaceLight,
          border: Border.all(color: context.colors.glassBorder),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, color: context.colors.textPrimary, size: 22),
            if (hasUnread)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: context.colors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.surface, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Resource Card ───
class _ResourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tagColor;

  const _ResourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 180,
      margin: EdgeInsets.only(right: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadii.lg,
        border: Border.all(color: context.colors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tagColor, size: 24),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tagColor.withAlpha(30),
                  borderRadius: AppRadii.pill,
                ),
                child: Text(
                  'AI Recommended',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: tagColor),
                ),
              ),
            ],
          ),
          Spacer(),
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}