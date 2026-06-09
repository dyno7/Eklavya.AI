import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/coach_service.dart';
import '../services/dashboard_service.dart';
import '../services/goals_service.dart';
import '../services/notification_service.dart';
import '../services/roadmap_sync_service.dart';

// ─── Roadmap Sync Bridge ─────────────────────────────────────────────────────
// Bridges the existing RoadmapSyncService ValueNotifier into Riverpod so that
// all data providers can declare a dependency on it and auto-rebuild when any
// roadmap update fires (task completion, new roadmap generated, etc.).
final roadmapSyncProvider = NotifierProvider<_RoadmapSyncNotifier, int>(
  _RoadmapSyncNotifier.new,
);

class _RoadmapSyncNotifier extends Notifier<int> {
  @override
  int build() {
    void listener() => state++;
    RoadmapSyncService.updates.addListener(listener);
    ref.onDispose(() => RoadmapSyncService.updates.removeListener(listener));
    return RoadmapSyncService.updates.value;
  }
}

// ─── Dashboard Provider ──────────────────────────────────────────────────────
final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardSummary>(
        DashboardNotifier.new);

class DashboardNotifier extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() {
    ref.watch(roadmapSyncProvider); // auto-rebuild on any roadmap update
    return DashboardService().getSummary();
  }

  Future<TaskClaimOutcome> completeTask(String taskId) =>
      DashboardService().completeTask(taskId);
  // DashboardService.completeTask calls RoadmapSyncService.notifyRoadmapUpdated
  // internally, which triggers roadmapSyncProvider → all watching providers rebuild.
}

// ─── Goals Provider ──────────────────────────────────────────────────────────
final goalsProvider =
    AsyncNotifierProvider<GoalsNotifier, List<GoalItem>>(GoalsNotifier.new);

class GoalsNotifier extends AsyncNotifier<List<GoalItem>> {
  @override
  Future<List<GoalItem>> build() {
    ref.watch(roadmapSyncProvider);
    return GoalsService().fetchGoals();
  }
}

// ─── Analytics Provider ──────────────────────────────────────────────────────
final analyticsProvider =
    AsyncNotifierProvider<AnalyticsNotifier, AnalyticsSummary?>(
        AnalyticsNotifier.new);

class AnalyticsNotifier extends AsyncNotifier<AnalyticsSummary?> {
  @override
  Future<AnalyticsSummary?> build() {
    ref.watch(roadmapSyncProvider);
    return DashboardService().getAnalyticsSummary();
  }
}

// ─── Coach Status Provider ───────────────────────────────────────────────────
final coachStatusProvider =
    AsyncNotifierProvider<CoachStatusNotifier, CoachStatusResponse?>(
        CoachStatusNotifier.new);

class CoachStatusNotifier extends AsyncNotifier<CoachStatusResponse?> {
  @override
  Future<CoachStatusResponse?> build() => CoachService().fetchStatus();
}

// ─── Notifications Provider ──────────────────────────────────────────────────
final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationItem>>(
        NotificationsNotifier.new);

class NotificationsNotifier extends AsyncNotifier<List<NotificationItem>> {
  @override
  Future<List<NotificationItem>> build() =>
      NotificationService().getMyNotifications();
}
