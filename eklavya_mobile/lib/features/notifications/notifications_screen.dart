import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  List<NotificationItem>? _notifications;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final notifs = await _notificationService.getMyNotifications();
    if (!mounted) return;
    setState(() {
      _notifications = notifs;
    });
  }

  Future<void> _markRead(NotificationItem item) async {
    if (item.readStatus) return;
    await _notificationService.markAsRead(item.id);
    _fetchNotifications();
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
        title: Text('Notifications', style: theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: _notifications == null
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _notifications!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_rounded, size: 64, color: context.colors.textTertiary),
                      SizedBox(height: AppSpacing.md),
                      Text('No notifications yet', style: theme.textTheme.bodyLarge?.copyWith(color: context.colors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(AppSpacing.md),
                  itemCount: _notifications!.length,
                  itemBuilder: (context, index) {
                    final item = _notifications![index];
                    final isUnread = !item.readStatus;
                    IconData icon;
                    if (item.type == 'badge_earned') {
                      icon = Icons.emoji_events_rounded;
                    } else if (item.type == 'streak_lost') {
                      icon = Icons.local_fire_department_rounded;
                    } else {
                      icon = Icons.info_rounded;
                    }

                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: GlassCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: isUnread ? context.colors.primary.withAlpha(40) : context.colors.surfaceLight.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: isUnread ? context.colors.primary : context.colors.textSecondary),
                        ),
                        title: Text(
                          item.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            item.message,
                            style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary),
                          ),
                        ),
                        trailing: isUnread 
                          ? Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: context.colors.primary),
                            )
                          : null,
                        onTap: () => _markRead(item),
                      ),
                      ),
                    ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1, end: 0, duration: 400.ms);
                  },
                ),
    );
  }
}
