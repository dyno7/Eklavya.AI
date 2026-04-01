import 'dart:convert';
import 'package:http/http.dart' as http;

import '../data/demo_data.dart';

// ─── Models ────────────────────────────────────────

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

  GoalSummary({
    required this.id, required this.title, required this.domain,
    required this.status, required this.totalMilestones, required this.completedMilestones,
  });

  factory GoalSummary.fromJson(Map<String, dynamic> json) => GoalSummary(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    domain: json['domain'] ?? 'learning',
    status: json['status'] ?? 'active',
    totalMilestones: json['total_milestones'] ?? 0,
    completedMilestones: json['completed_milestones'] ?? 0,
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
      ),
      currentMilestone: MilestoneSummary(
        id: 'demo-ms',
        title: 'Neural Network Basics',
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
  static const String _baseUrl = 'http://10.0.2.2:8000';

  /// Fetch dashboard summary from backend.
  /// Falls back to DemoData if backend is unreachable.
  Future<DashboardSummary> getSummary({String userId = 'demo-user', String? authToken}) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/dashboard/summary'),
        headers: headers,
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return DashboardSummary.fromJson(jsonDecode(response.body));
      }
    } catch (_) {
      // Backend unreachable — return demo data
    }
    return DashboardSummary.demo();
  }

  /// Complete a task and earn XP.
  /// Returns (xpEarned, newTotalXp) or null on failure.
  Future<(int, int)?> completeTask(String taskId, {String? authToken}) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/dashboard/claim-task/$taskId'),
        headers: headers,
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['xp_earned'] as int, data['new_total_xp'] as int);
      }
    } catch (_) {
      // Offline — silently fail
    }
    return null;
  }
}
