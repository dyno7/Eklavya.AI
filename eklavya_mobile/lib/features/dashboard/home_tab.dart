import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

import '../goals/goal_roadmap_screen.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/chat_seed_service.dart';
import '../../core/services/coach_service.dart';
import '../../core/services/dashboard_service.dart';
import '../../core/services/goals_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass_card.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  void _onTaskTap(GoalSummary? activeGoal) {
    if (activeGoal == null) return;
    final goalItem = GoalItem(
      id: activeGoal.id,
      title: activeGoal.title,
      description: '',
      domain: activeGoal.domain,
      status: activeGoal.status,
      milestonesCount: activeGoal.totalMilestones,
      completedMilestones: activeGoal.completedMilestones,
      progress: activeGoal.totalMilestones > 0
          ? (activeGoal.completedMilestones / activeGoal.totalMilestones) * 100
          : 0,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GoalRoadmapScreen(goal: goalItem)),
    );
  }

  Future<void> _onTaskComplete(TaskSummary task) async {
    final outcome =
        await ref.read(dashboardProvider.notifier).completeTask(task.id);
    if (!mounted) return;
    if (outcome is TaskClaimResult) {
      _showXpToast(context, outcome.xpEarned, outcome.bonusXp);
      if (outcome.levelUp) _showLevelUpModal(context, outcome.newLevel);
      if (outcome.badgesAwarded.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          for (final badge in outcome.badgesAwarded) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('🏅 Badge Unlocked: $badge!'),
              backgroundColor: context.colors.accent,
              duration: const Duration(seconds: 2),
            ));
          }
        });
      }
    } else if (outcome is TaskClaimError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Couldn't complete task: ${outcome.message}"),
        backgroundColor: context.colors.error,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  void _showXpToast(BuildContext ctx, int xp, int bonusXp) {
    if (!mounted) return;
    final overlayContent = Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            gradient: context.colors.primaryGradient,
            borderRadius: AppRadii.pill,
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withAlpha(60),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Colors.white, size: 24),
              SizedBox(width: AppSpacing.sm),
              Text('+$xp XP',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              if (bonusXp > 0) ...[
                SizedBox(width: AppSpacing.sm),
                Text('(+$bonusXp bonus!)',
                    style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ],
            ],
          ),
        )
            .animate()
            .slideY(
                begin: 0,
                end: -0.3,
                duration: 1200.ms,
                curve: Curves.easeOutCubic)
            .fadeOut(delay: 800.ms, duration: 400.ms),
      ),
    );
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.15,
        left: 0,
        right: 0,
        child: overlayContent,
      ),
    );
    Overlay.of(ctx).insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  void _showLevelUpModal(BuildContext ctx, int newLevel) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: GlassCard(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: AppSpacing.md),
              Icon(Icons.bolt_rounded, size: 80, color: context.colors.accent)
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1.1, 1.1),
                      duration: 800.ms,
                      curve: Curves.easeInOut)
                  .then()
                  .scale(
                      begin: const Offset(1.1, 1.1),
                      end: const Offset(0.9, 0.9),
                      duration: 800.ms,
                      curve: Curves.easeInOut),
              SizedBox(height: AppSpacing.lg),
              Text('⚡ Level $newLevel Unlocked!',
                      style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary),
                      textAlign: TextAlign.center)
                  .animate()
                  .fadeIn()
                  .slideY(begin: 0.2, end: 0, duration: 500.ms),
              SizedBox(height: AppSpacing.md),
              Text("Keep it up — you're on fire 🔥",
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          color: context.colors.textSecondary),
                      textAlign: TextAlign.center)
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideY(begin: 0.2, end: 0, duration: 500.ms),
              SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: AppRadii.lg),
                  ),
                  child: const Text('Let\'s Go',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideY(begin: 0.2, end: 0, duration: 500.ms),
              SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  void _showResourcesSheet(List<dynamic> resources) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        if (resources.isEmpty) {
          return SafeArea(
            child: GlassCard(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'No resources yet. Generate a roadmap to see curated resources here.',
                style: TextStyle(color: context.colors.textSecondary),
              ),
            ),
          );
        }
        return SafeArea(
          child: GlassCard(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Suggested Resources',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: AppSpacing.md),
                ...resources.map((resource) {
                  final title = resource['title'] as String? ?? 'Resource';
                  final url = resource['url'] as String? ?? '';
                  final type = resource['type'] as String? ?? 'read';
                  IconData icon;
                  if (url.contains('youtube.com') || url.contains('youtu.be')) {
                    icon = Icons.play_circle_outline_rounded;
                  } else if (url.contains('github.com')) {
                    icon = Icons.code_rounded;
                  } else if (url.contains('coursera') || url.contains('udemy') || url.contains('edx')) {
                    icon = Icons.school_outlined;
                  } else if (url.contains('/docs') || url.contains('docs.') || url.contains('mdn')) {
                    icon = Icons.description_outlined;
                  } else {
                    icon = Icons.article_outlined;
                  }
                  return InkWell(
                    onTap: url.isNotEmpty
                        ? () async {
                            final uri = Uri.tryParse(url);
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          }
                        : null,
                    borderRadius: AppRadii.md,
                    child: Container(
                      margin: EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceLight,
                        borderRadius: AppRadii.md,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: context.colors.primary.withAlpha(30),
                              borderRadius: AppRadii.sm,
                            ),
                            child: Icon(icon, color: context.colors.primary, size: 18),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                Text(type[0].toUpperCase() + type.substring(1),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: context.colors.textSecondary)),
                              ],
                            ),
                          ),
                          if (url.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: context.colors.primaryGradient,
                                borderRadius: AppRadii.pill,
                              ),
                              child: const Text('Open →',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning,';
    if (hour >= 12 && hour < 17) return 'Good Afternoon,';
    if (hour >= 17 && hour < 21) return 'Good Evening,';
    return 'Good Night,';
  }

  Widget _buildCoachIndicator(CoachStatusResponse? coachStatus) {
    if (coachStatus == null || coachStatus.state != 'ENGAGED') {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.success.withAlpha(40),
        border: Border.all(color: context.colors.success.withAlpha(100)),
        borderRadius: AppRadii.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up_rounded,
              size: 14, color: context.colors.success),
          const SizedBox(width: 4),
          Text('On track',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.colors.success)),
        ],
      ),
    );
  }

  Widget _buildCoachNudgeCard(
      CoachStatusResponse? coachStatus, DashboardSummary data) {
    if (coachStatus == null) return const SizedBox.shrink();
    final isWavering = coachStatus.state == 'WAVERING';
    final isSilent = coachStatus.state == 'SILENT_RECESS';
    if (!isWavering && !isSilent) return const SizedBox.shrink();

    final theme = Theme.of(context);

    // Pull real context so nudges are specific, not generic
    final goalTitle = data.activeGoal?.title;
    final nextTask = data.pendingTasks.isNotEmpty ? data.pendingTasks.first : null;
    final nextTaskTitle = nextTask?.title;
    final nextTaskMins = nextTask?.estimatedMinutes ?? 20;
    final milestoneTitle = data.currentMilestone?.title;

    final Color accent =
        isSilent ? context.colors.error : context.colors.warning;
    final IconData icon =
        isSilent ? Icons.local_fire_department_rounded : Icons.bolt_rounded;

    // ── Carrot-first copy: lead on, don't shame ──
    final String headline;
    final String body;
    final String ctaLabel;
    final String seedMessage;

    if (isSilent) {
      headline = goalTitle != null
          ? "Your \"$goalTitle\" roadmap is waiting."
          : "Your roadmap is waiting.";
      body = nextTaskTitle != null
          ? "\"$nextTaskTitle\" (~$nextTaskMins min) is next. Users who return after a break and finish just one task are 3× more likely to complete their roadmap. That task keeps you ahead of 70% of learners."
          : "Finishing one task today puts you ahead of 70% of learners at the same stage. It takes less than 30 min.";
      ctaLabel = nextTaskTitle != null ? "Do \"${_truncate(nextTaskTitle, 22)}\" now →" : "Get back on track →";
      seedMessage = nextTaskTitle != null
          ? "I want to get back on track. My next task is \"$nextTaskTitle\"${milestoneTitle != null ? ' in the \"$milestoneTitle\" milestone' : ''}. Help me knock it out fast."
          : "I want to get back on track. What's the quickest win I can get right now?";
    } else {
      // WAVERING
      headline = nextTaskTitle != null
          ? "Do \"${_truncate(nextTaskTitle, 28)}\" — stay ahead."
          : "One task. Stay ahead.";
      body = goalTitle != null && nextTaskTitle != null
          ? "Complete \"$nextTaskTitle\" (~$nextTaskMins min) in $goalTitle and you'll be ahead of 73% of users at the same stage. Most people stop here — don't be most people."
          : "Complete your next task and you'll be ahead of 73% of users at this stage. Most people stop here — keep going.";
      ctaLabel = "Start now →";
      seedMessage = nextTaskTitle != null
          ? "Help me push through \"$nextTaskTitle\"${goalTitle != null ? ' for my $goalTitle goal' : ''}. I keep opening the app but not starting."
          : "I keep opening the app but not completing tasks. Help me break through and get started.";
    }

    return GestureDetector(
      onTap: () {
        ChatSeedService.seed(seedMessage);
        context.go('/chat');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: accent.withAlpha(18),
          borderRadius: AppRadii.lg,
          border: Border.all(color: accent.withAlpha(80)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: accent.withAlpha(40)),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headline,
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: accent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(body,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary, height: 1.45)),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                        color: accent, borderRadius: AppRadii.pill),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_forward_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(ctaLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';

  IconData _getDomainIcon(String domain) {
    switch (domain) {
      case 'learning':
        return Icons.school_rounded;
      case 'startup':
        return Icons.rocket_launch_rounded;
      case 'writing':
        return Icons.edit_note_rounded;
      case 'fitness':
        return Icons.fitness_center_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  Color _getDomainColor(String domain, BuildContext context) {
    switch (domain) {
      case 'learning':
        return context.colors.primary;
      case 'startup':
        return context.colors.secondary;
      case 'writing':
        return context.colors.warning;
      case 'fitness':
        return context.colors.success;
      default:
        return context.colors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final coachStatus = ref.watch(coachStatusProvider).asData?.value;
    final unreadCount = ref
            .watch(notificationsProvider)
            .asData
            ?.value
            .where((n) => !n.readStatus)
            .length ??
        0;

    return dashboardAsync.when(
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
              Text('Could not load dashboard',
                  style:
                      TextStyle(color: context.colors.textSecondary)),
              SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => ref.invalidate(dashboardProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        final theme = Theme.of(context);
        final priorityGoal = data.activeGoal;
        final userStats = data.user;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: RefreshIndicator(
              color: context.colors.primary,
              onRefresh: () async {
                ref.invalidate(dashboardProvider);
                ref.invalidate(coachStatusProvider);
                ref.invalidate(notificationsProvider);
                await ref.read(dashboardProvider.future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: AppSpacing.lg),
                    // ─── Top Bar ───
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: theme.textTheme.labelLarge?.copyWith(
                                    color: context.colors.textSecondary,
                                    fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    userStats.displayName.isNotEmpty
                                        ? userStats.displayName
                                        : 'User',
                                    style: theme.textTheme.headlineLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 28),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Lottie.asset(
                                        'assets/lottie/wave_hello.json',
                                        repeat: true),
                                  ),
                                ],
                              ),
                              _buildCoachIndicator(coachStatus),
                            ],
                          ),
                        ),
                        _NotificationBell(
                          hasUnread: unreadCount > 0,
                          onTap: () {
                            context.push('/notifications').then(
                                (_) => ref.invalidate(notificationsProvider));
                          },
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
                                colors: [
                                  context.colors.primary,
                                  context.colors.secondary
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                (userStats.displayName.isNotEmpty
                                        ? userStats.displayName[0]
                                        : 'U')
                                    .toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xl),

                    // ─── Priority Goal Card ───
                    if (priorityGoal != null)
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
                                  child: Lottie.asset(
                                      'assets/lottie/rocket_launch.json',
                                      repeat: true),
                                ),
                                SizedBox(width: AppSpacing.sm),
                                Text("Let's Continue",
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                            color: context.colors.primaryLight,
                                            fontWeight: FontWeight.w600)),
                              ],
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(priorityGoal.title,
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getDomainColor(
                                            priorityGoal.domain, context)
                                        .withAlpha(40),
                                    borderRadius: AppRadii.pill,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                          _getDomainIcon(priorityGoal.domain),
                                          size: 14,
                                          color: _getDomainColor(
                                              priorityGoal.domain, context)),
                                      const SizedBox(width: 4),
                                      Text(
                                        priorityGoal.domain[0].toUpperCase() +
                                            priorityGoal.domain.substring(1),
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _getDomainColor(
                                                priorityGoal.domain, context)),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: AppSpacing.md),
                                Text(
                                  '${priorityGoal.completedMilestones}/${priorityGoal.totalMilestones} milestones',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                      color: context.colors.textSecondary),
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.lg),
                            ClipRRect(
                              borderRadius: AppRadii.pill,
                              child: LinearProgressIndicator(
                                value: priorityGoal.totalMilestones > 0
                                    ? priorityGoal.completedMilestones /
                                        priorityGoal.totalMilestones
                                    : 0,
                                backgroundColor: context.colors.surfaceLight,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    context.colors.primary),
                                minHeight: 8,
                              ),
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${priorityGoal.totalMilestones > 0 ? ((priorityGoal.completedMilestones / priorityGoal.totalMilestones) * 100).toInt() : 0}% complete',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: context.colors.textSecondary),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/goals'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: context.colors.primaryGradient,
                                      borderRadius: AppRadii.pill,
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Continue',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13)),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_rounded,
                                            color: Colors.white, size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn()
                          .slideY(begin: 0.1, end: 0, duration: 500.ms),

                    if (priorityGoal == null)
                      GestureDetector(
                        onTap: () => context.go('/chat'),
                        child: GlassCard(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            children: [
                              Icon(Icons.rocket_launch_rounded,
                                  size: 48, color: context.colors.primaryLight),
                              SizedBox(height: AppSpacing.md),
                              Text('No active goal yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      color: context.colors.primaryLight,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: AppSpacing.sm),
                              Text(
                                  'Tap to chat with the Guru and create your roadmap!',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: context.colors.textSecondary)),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn()
                          .slideY(begin: 0.1, end: 0, duration: 500.ms),

                    SizedBox(height: AppSpacing.lg),

                    // ─── Coach Nudge Card ───
                    _buildCoachNudgeCard(coachStatus, data),

                    // ─── Streak Card ───
                    GlassCard(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Lottie.asset(
                                'assets/lottie/streak_fire.json',
                                repeat: true),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${userStats.currentStreak} Day Streak 🔥',
                                    style: theme.textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Row(
                                  children: List.generate(7, (index) {
                                    final isActive = index <
                                        userStats.currentStreak.clamp(0, 7);
                                    return Expanded(
                                      child: Container(
                                        height: 6,
                                        margin:
                                            const EdgeInsets.only(right: 4),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? context.colors.warning
                                              : context.colors.surfaceLight,
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
                    )
                        .animate()
                        .fadeIn(delay: 100.ms)
                        .slideY(begin: 0.1, end: 0, duration: 500.ms),

                    SizedBox(height: AppSpacing.lg),

                    // ─── XP Card ───
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
                                    child: Lottie.asset(
                                        'assets/lottie/xp_star.json',
                                        repeat: true),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('Total XP',
                                      style: theme.textTheme.titleMedium),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: context.colors.primary
                                      .withValues(alpha: 0.2),
                                  borderRadius: AppRadii.pill,
                                ),
                                child: Text(
                                    'Level ${(userStats.totalXp ~/ 100) + 1}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                            color:
                                                context.colors.primaryLight)),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.sm),
                          TweenAnimationBuilder<int>(
                            tween:
                                IntTween(begin: 0, end: userStats.totalXp),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) => Text(
                              value.toString(),
                              style:
                                  theme.textTheme.displayLarge?.copyWith(
                                color: context.colors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: AppSpacing.md),
                          ClipRRect(
                            borderRadius: AppRadii.pill,
                            child: LinearProgressIndicator(
                              value: (userStats.totalXp % 100) / 100.0,
                              backgroundColor: context.colors.surfaceLight,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  context.colors.accent),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.1, end: 0, duration: 500.ms),

                    SizedBox(height: AppSpacing.xxl),

                    // ─── Today's Tasks ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Today's Tasks",
                            style: theme.textTheme.titleLarge),
                        TextButton(
                          onPressed: () => context.go('/goals'),
                          child: Text('See All',
                              style: TextStyle(
                                  color: context.colors.primaryLight)),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.md),

                    if (data.pendingTasks.isEmpty)
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Center(
                          child: Text(
                              "No tasks pending! You're all caught up. 🎉",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: context.colors.textSecondary)),
                        ),
                      )
                    else
                      ...data.pendingTasks.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final task = entry.value;
                        return Padding(
                          padding:
                              EdgeInsets.only(bottom: AppSpacing.md),
                          child: _TaskCard(
                            task: task,
                            onTap: () => _onTaskTap(data.activeGoal),
                            onComplete: () => _onTaskComplete(task),
                          )
                              .animate()
                              .fadeIn(delay: (300 + idx * 100).ms)
                              .slideX(
                                  begin: 0.05, end: 0, duration: 400.ms),
                        );
                      }),

                    SizedBox(height: AppSpacing.xxl),

                    // ─── Suggested Resources ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Suggested Resources',
                            style: theme.textTheme.titleLarge),
                        TextButton(
                          onPressed: () => _showResourcesSheet(
                              data.activeGoal?.resources ?? []),
                          child: Text('See All',
                              style: TextStyle(
                                  color: context.colors.primaryLight)),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 130,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: () {
                          final resources =
                              data.activeGoal?.resources ?? [];
                          if (resources.isEmpty) {
                            return [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0),
                                  child: Text(
                                    'Generate a roadmap in the Chat to see AI curated resources here.',
                                    style: TextStyle(
                                        color:
                                            context.colors.textSecondary,
                                        fontSize: 13),
                                  ),
                                ),
                              ),
                            ];
                          }
                          return resources.map((r) {
                            final title = r['title'] as String? ?? 'Resource';
                            final type = r['type'] as String? ?? 'Read';
                            final url = r['url'] as String? ?? '';
                            IconData dIcon = Icons.menu_book_rounded;
                            Color dColor = context.colors.secondary;
                            if (type.toLowerCase().contains('watch')) {
                              dIcon = Icons.play_circle_outline_rounded;
                              dColor = context.colors.primary;
                            } else if (type.toLowerCase().contains('practice')) {
                              dIcon = Icons.code_rounded;
                              dColor = context.colors.accent;
                            }
                            return _ResourceCard(
                              icon: dIcon,
                              title: title,
                              subtitle: type,
                              tagColor: dColor,
                              url: url,
                            );
                          }).toList();
                        }(),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 500.ms)
                        .slideY(begin: 0.1, end: 0, duration: 400.ms),

                    SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Notification Bell ───────────────────────────────────────────────────────
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
            Icon(Icons.notifications_none_rounded,
                color: context.colors.textPrimary, size: 22),
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
                    border: Border.all(
                        color: context.colors.surface, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Resource Card ───────────────────────────────────────────────────────────
class _ResourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tagColor;
  final String url;

  const _ResourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tagColor,
    this.url = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: url.isNotEmpty
          ? () async {
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          : null,
      child: Container(
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
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagColor.withAlpha(30),
                    borderRadius: AppRadii.pill,
                  ),
                  child: Text('AI Recommended',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: tagColor)),
                ),
              ],
            ),
            const Spacer(),
            Text(title,
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(subtitle,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: context.colors.textSecondary)),
                ),
                if (url.isNotEmpty)
                  Icon(Icons.open_in_new_rounded,
                      size: 12, color: context.colors.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Task Card ───────────────────────────────────────────────────────────────
class _TaskCard extends StatefulWidget {
  final TaskSummary task;
  final VoidCallback? onTap;
  final Future<void> Function() onComplete;

  const _TaskCard({required this.task, this.onTap, required this.onComplete});

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _isChecking = false;

  IconData _getIcon(String type) {
    switch (type) {
      case 'watch':
        return Icons.play_circle_fill_rounded;
      case 'practice':
        return Icons.code_rounded;
      case 'read':
        return Icons.menu_book_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  Color _getColor(String type, BuildContext context) {
    switch (type) {
      case 'watch':
        return context.colors.primary;
      case 'practice':
        return context.colors.accent;
      case 'read':
        return context.colors.secondary;
      case 'quiz':
        return context.colors.warning;
      default:
        return context.colors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = widget.task.status == 'completed';
    final taskColor = isCompleted
        ? context.colors.success
        : _getColor(widget.task.taskType, context);
    final diffColor = widget.task.estimatedMinutes < 20
        ? context.colors.success
        : widget.task.estimatedMinutes < 45
            ? context.colors.warning
            : context.colors.error;

    return InkWell(
      onTap: !isCompleted ? widget.onTap : null,
      borderRadius: AppRadii.lg,
      child: Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadii.lg,
        border: Border.all(color: context.colors.surfaceLight),
      ),
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: taskColor.withAlpha(50)),
              child: Center(
                  child: Icon(_getIcon(widget.task.taskType),
                      color: taskColor, size: 22)),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted
                          ? context.colors.textTertiary
                          : context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      if (widget.task.estimatedMinutes > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 14,
                                color: context.colors.textSecondary),
                            const SizedBox(width: 4),
                            Text('${widget.task.estimatedMinutes}m',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: context.colors.textSecondary)),
                          ],
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.colors.accent.withAlpha(50),
                          borderRadius: AppRadii.pill,
                        ),
                        child: Text('+${widget.task.xpReward} XP',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: context.colors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 10)),
                      ),
                      if (widget.task.estimatedMinutes > 0)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: diffColor),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                if (isCompleted || _isChecking) return;
                setState(() => _isChecking = true);
                try {
                  await widget.onComplete();
                } finally {
                  if (mounted) setState(() => _isChecking = false);
                }
              },
              child: AnimatedScale(
                scale: _isChecking ? 1.3 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.fastOutSlowIn,
                child: Checkbox(
                  value: isCompleted,
                  activeColor: context.colors.success,
                  checkColor: context.colors.background,
                  side: BorderSide(
                      color: context.colors.textSecondary, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  onChanged: isCompleted
                      ? null
                      : (val) async {
                          if (val == true && !_isChecking) {
                            setState(() => _isChecking = true);
                            try {
                              await widget.onComplete();
                            } finally {
                              if (mounted) {
                                setState(() => _isChecking = false);
                              }
                            }
                          }
                        },
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
