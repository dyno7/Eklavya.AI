import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/dashboard_service.dart';
import '../../core/services/user_service.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass_card.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  final _dashboardService = DashboardService();
  final _userService = UserService();
  UserStats? _userStats;
  List<BadgeItem>? _badges;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final summaryFuture = _dashboardService.getSummary();
    final badgesFuture = _userService.getMyBadges();
    
    final results = await Future.wait([summaryFuture, badgesFuture]);
    if (!mounted) return;
    
    setState(() {
      _userStats = (results[0] as DashboardSummary).user;
      _badges = results[1] as List<BadgeItem>;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userStats == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }
    
    final theme = Theme.of(context);
    final userStats = _userStats!;
    final displayName = userStats.displayName.isNotEmpty ? userStats.displayName : 'User';
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.lg),
              
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                  ),
                ],
              ),
              
              // ─── Profile Header ───
              GlassCard(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
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
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: theme.textTheme.displayLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Text(displayName, style: theme.textTheme.headlineMedium),
                    SizedBox(height: 4),
                    Text('Level ${(userStats.totalXp ~/ 100) + 1} • ${userStats.totalXp} XP', style: theme.textTheme.bodyLarge?.copyWith(color: context.colors.textSecondary)),
                    SizedBox(height: AppSpacing.lg),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.colors.textPrimary,
                        side: BorderSide(color: context.colors.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: AppRadii.pill),
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                      ),
                      child: Text('Edit Profile'),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1, end: 0, duration: 400.ms),
              SizedBox(height: AppSpacing.xl),

              // ─── Badges Section ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Badges', style: theme.textTheme.titleLarge),
                  Text('${_badges?.where((b) => b.isEarned).length ?? 0} earned', style: theme.textTheme.labelMedium?.copyWith(color: context.colors.textSecondary)),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 120,
                child: _badges == null 
                  ? const Center(child: CircularProgressIndicator()) 
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      children: _badges!.map((b) => _BadgeCard(
                        icon: _mapIconNameToEmoji(b.iconUrl),
                        title: b.name,
                        description: b.description,
                        isEarned: b.isEarned,
                      )).toList().animate(interval: 100.ms).fadeIn().slideX(begin: 0.1, end: 0, duration: 400.ms),
                    ),
              ),
              SizedBox(height: AppSpacing.xl),

              // ─── Stats Row ───
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'Goals Active', value: '3')),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: _StatCard(label: 'Tasks Done', value: '47')),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: _StatCard(label: 'Days Active', value: '28')),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
              SizedBox(height: AppSpacing.xl),

              // ─── Settings Section ───
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.dark_mode_rounded, color: context.colors.primaryLight),
                      title: Text('Dark Mode', style: TextStyle(color: context.colors.textPrimary)),
                      trailing: Switch(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (isDark) {
                          ref.read(themeModeProvider.notifier).toggle(isDark);
                        },
                      ),
                    ),
                    Divider(color: context.colors.glassBorder, height: 1),
                    ListTile(
                      leading: Icon(Icons.notifications_rounded, color: context.colors.secondary),
                      title: Text('Notifications', style: TextStyle(color: context.colors.textPrimary)),
                      trailing: Switch(
                        value: true,
                        onChanged: (v) {},
                      ),
                    ),
                    Divider(color: context.colors.glassBorder, height: 1),
                    ListTile(
                      leading: Icon(Icons.language_rounded, color: context.colors.accent),
                      title: Text('Language', style: TextStyle(color: context.colors.textPrimary)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('English', style: TextStyle(color: context.colors.textSecondary)),
                          SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, color: context.colors.textTertiary),
                        ],
                      ),
                    ),
                    Divider(color: context.colors.glassBorder, height: 1),
                    ListTile(
                      leading: Icon(Icons.info_outline_rounded, color: context.colors.textSecondary),
                      title: Text('About Eklavya.AI', style: TextStyle(color: context.colors.textPrimary)),
                      trailing: Icon(Icons.chevron_right_rounded, color: context.colors.textTertiary),
                    ),
                    Divider(color: context.colors.glassBorder, height: 1),
                    ListTile(
                      leading: Icon(Icons.logout_rounded, color: context.colors.error),
                      title: Text('Sign Out', style: TextStyle(color: context.colors.error, fontWeight: FontWeight.w600)),
                      onTap: () async {
                        await AuthService.signOut();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
              
              SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
  String _mapIconNameToEmoji(String? iconName) {
    switch (iconName) {
      case 'badge_first_steps': return '🌱';
      case 'badge_novice': return '🥉';
      case 'badge_fast_learner': return '⚡';
      case 'badge_consistency': return '🔥';
      default: return '🏆';
    }
  }
}

class _BadgeCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final bool isEarned;

  const _BadgeCard({required this.icon, required this.title, required this.description, this.isEarned = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 110,
      margin: EdgeInsets.only(right: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isEarned ? context.colors.surface : context.colors.surface.withAlpha(100),
        borderRadius: BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: isEarned ? context.colors.surfaceLight : Colors.transparent),
      ),
      child: Opacity(
        opacity: isEarned ? 1.0 : 0.4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: 28)),
            SizedBox(height: AppSpacing.sm),
            Text(title, style: theme.textTheme.labelMedium, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 2),
            Text(description, style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary, fontSize: 10), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
      child: Column(
        children: [
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
