import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../data/demo_data.dart';
import '../services/auth_service.dart';
import '../services/roadmap_sync_service.dart';

// ─── Models ────────────────────────────────────────

/// Outcome of attempting to claim a task. Either a TaskClaimResult (success)
/// or a TaskClaimError (with status + message for the UI to display).
sealed class TaskClaimOutcome {
  const TaskClaimOutcome();
}

class TaskClaimResult extends TaskClaimOutcome {
  final int xpEarned;
  final int bonusXp;
  final int newTotalXp;
  final bool levelUp;
  final int newLevel;
  final List<String> badgesAwarded;
  const TaskClaimResult({required this.xpEarned, required this.bonusXp, required this.newTotalXp, required this.levelUp, required this.newLevel, required this.badgesAwarded});
}

class TaskClaimError extends TaskClaimOutcome {
  final int statusCode;
  final String message;
  const TaskClaimError({required this.statusCode, required this.message});
}

class UserStats {
  final String displayName;
  final int totalXp;
  final int currentStreak;

  UserStats({required this.displayName, required this.totalXp, required this.currentStreak});

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    displayName: json['display_name'] ?? '',
    totalXp: json['total_xp'] ?? 0,
    currentStreak: json['current_streak'] ?? 0,
  );
}

class GoalSummary {
  final String id;
  final String title;
  final String domain;
  final String status;
  final int totalMilestones;
  final int completedMilestones;
  final List<dynamic> resources;

  GoalSummary({
    required this.id, required this.title, required this.domain,
    required this.status, required this.totalMilestones, required this.completedMilestones,
    this.resources = const [],
  });

  factory GoalSummary.fromJson(Map<String, dynamic> json) => GoalSummary(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    domain: json['domain'] ?? 'learning',
    status: json['status'] ?? 'active',
    totalMilestones: json['total_milestones'] ?? 0,
    completedMilestones: json['completed_milestones'] ?? 0,
    resources: json['resources'] as List<dynamic>? ?? [],
  );
}

class MilestoneSummary {
  final String id;
  final String title;
  final int orderIndex;
  final String status;
  final int totalTasks;
  final int completedTasks;

  MilestoneSummary({
    required this.id, required this.title, required this.orderIndex,
    required this.status, required this.totalTasks, required this.completedTasks,
  });

  factory MilestoneSummary.fromJson(Map<String, dynamic> json) => MilestoneSummary(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    orderIndex: json['order_index'] ?? 0,
    status: json['status'] ?? 'locked',
    totalTasks: json['total_tasks'] ?? 0,
    completedTasks: json['completed_tasks'] ?? 0,
  );
}

class TaskSummary {
  final String id;
  final String title;
  final String taskType;
  final int xpReward;
  final String status;
  final int estimatedMinutes;

  TaskSummary({
    required this.id, required this.title, required this.taskType,
    required this.xpReward, required this.status, required this.estimatedMinutes,
  });

  factory TaskSummary.fromJson(Map<String, dynamic> json) => TaskSummary(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    taskType: json['task_type'] ?? 'custom',
    xpReward: json['xp_reward'] ?? 10,
    status: json['status'] ?? 'pending',
    estimatedMinutes: json['estimated_minutes'] ?? 30,
  );
}

class DashboardSummary {
  final UserStats user;
  final GoalSummary? activeGoal;
  final MilestoneSummary? currentMilestone;
  final List<TaskSummary> pendingTasks;

  DashboardSummary({
    required this.user,
    this.activeGoal,
    this.currentMilestone,
    this.pendingTasks = const [],
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
    user: UserStats.fromJson(json['user']),
    activeGoal: json['active_goal'] != null ? GoalSummary.fromJson(json['active_goal']) : null,
    currentMilestone: json['current_milestone'] != null ? MilestoneSummary.fromJson(json['current_milestone']) : null,
    pendingTasks: (json['pending_tasks'] as List? ?? [])
        .map((t) => TaskSummary.fromJson(t as Map<String, dynamic>))
        .toList(),
  );

  /// Offline demo fallback
  factory DashboardSummary.demo() {
    final demoGoal = DemoData.goals.first;
    final demoUser = DemoData.user;
    return DashboardSummary(
      user: UserStats(displayName: demoUser.displayName, totalXp: demoUser.totalXp, currentStreak: demoUser.currentStreak),
      activeGoal: GoalSummary(
        id: demoGoal.id,
        title: demoGoal.title,
        domain: demoGoal.domain,
        status: demoGoal.status,
        totalMilestones: demoGoal.milestonesCount,
        completedMilestones: demoGoal.completedMilestones,
        resources: [],
      ),
      currentMilestone: MilestoneSummary(
        id: 'demo-ms',
        title: 'Backend Database Setup',
        orderIndex: 2,
        status: 'active',
        totalTasks: 4,
        completedTasks: 0,
      ),
      pendingTasks: DemoData.tasks.map((t) => TaskSummary(
        id: t.id,
        title: t.title,
        taskType: t.type,
        xpReward: t.xpReward,
        status: t.isCompleted ? 'completed' : 'pending',
        estimatedMinutes: 30,
      )).toList(),
    );
  }
}

// ─── Service ───────────────────────────────────────

class DashboardService {
  String get _baseUrl => AppConfig.backendUrl;

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = AuthService.accessToken;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  /// Fetch dashboard summary from backend.
  /// Falls back to DemoData if backend is unreachable.
  Future<DashboardSummary> getSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/dashboard/summary'),
        headers: _headers,
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return DashboardSummary.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Dashboard API error: $e');
    }
    // Return an empty skeleton instead of demo data
    return DashboardSummary(
      user: UserStats(
        displayName: AuthService.displayName,
        totalXp: 0,
        currentStreak: 0,
      ),
      activeGoal: null,
      currentMilestone: null,
      pendingTasks: [],
    );
  }

  /// Complete a task and earn XP.
  /// Returns TaskClaimResult on success, or a TaskClaimError on failure
  /// (so the UI can surface what actually went wrong).
  Future<TaskClaimOutcome> completeTask(String taskId) async {
    final url = '$_baseUrl/api/v1/dashboard/claim-task/$taskId';
    debugPrint('[completeTask] POST $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      debugPrint('[completeTask] status=${response.statusCode} body=${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        RoadmapSyncService.notifyRoadmapUpdated();
        return TaskClaimResult(
          xpEarned: data['xp_earned'] as int? ?? 0,
          bonusXp: data['bonus_xp'] as int? ?? 0,
          newTotalXp: data['new_total_xp'] as int? ?? 0,
          levelUp: data['level_up'] as bool? ?? false,
          newLevel: data['new_level'] as int? ?? 0,
          badgesAwarded: (data['badges_awarded'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        );
      }

      // Non-200 — try to surface the backend's error detail
      String? detail;
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['detail'] != null) {
          detail = body['detail'].toString();
        }
      } catch (_) {}
      return TaskClaimError(
        statusCode: response.statusCode,
        message: detail ?? 'Server returned ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('[completeTask] EXCEPTION: $e');
      return TaskClaimError(statusCode: 0, message: e.toString());
    }
  }

  /// Fetch real analytics data from backend.
  Future<AnalyticsSummary?> getAnalyticsSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/analytics/summary'),
        headers: _headers,
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return AnalyticsSummary.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Analytics API error: $e');
    }
    return null;
  }
}

// ─── Analytics Model ───────────────────────────────

class AnalyticsSummary {
  final List<int> dailyXp;
  final double completionRate;
  final int activeDaysLast30;
  final int totalTasks;
  final int completedTasks;

  AnalyticsSummary({
    required this.dailyXp,
    required this.completionRate,
    required this.activeDaysLast30,
    required this.totalTasks,
    required this.completedTasks,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) => AnalyticsSummary(
    dailyXp: (json['daily_xp'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? List<int>.filled(7, 0),
    completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
    activeDaysLast30: json['active_days_last_30'] as int? ?? 0,
    totalTasks: json['total_tasks'] as int? ?? 0,
    completedTasks: json['completed_tasks'] as int? ?? 0,
  );
}
