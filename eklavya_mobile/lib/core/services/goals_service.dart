import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';
import 'roadmap_sync_service.dart';

class GoalItem {
  final String id;
  final String title;
  final String description;
  final String domain;
  final String status;
  final int milestonesCount;
  final int completedMilestones;
  final double progress;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? archivedAt;
  final DateTime? lastActivityAt;
  final bool archived;

  GoalItem({
    required this.id,
    required this.title,
    required this.description,
    required this.domain,
    required this.status,
    required this.milestonesCount,
    required this.completedMilestones,
    required this.progress,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
    this.lastActivityAt,
    this.archived = false,
  });

  factory GoalItem.fromJson(Map<String, dynamic> json) => GoalItem(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        domain: json['domain'] ?? 'learning',
        status: json['status'] ?? 'active',
        milestonesCount: json['milestones_count'] ?? 0,
        completedMilestones: json['completed_milestones'] ?? 0,
        progress: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
        archivedAt: _parseDateTime(json['archived_at']),
        lastActivityAt: _parseDateTime(json['last_activity_at']),
        archived: json['archived'] ?? false,
      );

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class GoalsService {
  String get _baseUrl => AppConfig.backendUrl;

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = AuthService.accessToken;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<List<GoalItem>> fetchGoals({bool archived = false}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/goals/?archived=$archived'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final goals = data
            .map((g) => GoalItem.fromJson(g as Map<String, dynamic>))
            .toList();

        final enriched = await Future.wait(goals.map((goal) async {
          try {
            final mResponse = await http.get(
              Uri.parse('$_baseUrl/api/v1/goals/${goal.id}/milestones'),
              headers: _headers,
            ).timeout(const Duration(seconds: 10));

            if (mResponse.statusCode == 200) {
              final List<dynamic> milestones = jsonDecode(mResponse.body);
              final total = milestones.length;
              final completed = milestones.where((m) => (m['status'] ?? '') == 'completed').length;
              final progress = total == 0 ? 0.0 : (completed / total) * 100.0;
              return GoalItem(
                id: goal.id,
                title: goal.title,
                description: goal.description,
                domain: goal.domain,
                status: goal.status,
                milestonesCount: total,
                completedMilestones: completed,
                progress: progress,
              );
            }
          } catch (_) {
            // Keep base goal if enrichment fails.
          }
          return goal;
        }));

        return enriched;
      }
    } catch (e) {
      debugPrint('Goals API error: $e');
    }
    return [];
  }

  Future<bool> setGoalArchived(String goalId, bool archived) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/api/v1/goals/$goalId'),
        headers: _headers,
        body: jsonEncode({'archived': archived}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        RoadmapSyncService.notifyRoadmapUpdated();
        return true;
      }
    } catch (e) {
      debugPrint('Goal archive API error: $e');
    }
    return false;
  }

  Future<bool> archiveGoal(String goalId) => setGoalArchived(goalId, true);

  Future<bool> restoreGoal(String goalId) => setGoalArchived(goalId, false);

  Future<bool> deleteGoal(String goalId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/v1/goals/$goalId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 204) {
        RoadmapSyncService.notifyRoadmapUpdated();
        return true;
      }
    } catch (e) {
      debugPrint('Goal delete API error: $e');
    }
    return false;
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/v1/tasks/$taskId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 204) {
        RoadmapSyncService.notifyRoadmapUpdated();
        return true;
      }
    } catch (e) {
      debugPrint('Task delete API error: $e');
    }
    return false;
  }

  /// Start the timer for a task
  Future<TaskItem?> startTaskTimer(String taskId) async {
    return _postWithRetry(
      '$_baseUrl/api/v1/tasks/$taskId/timer/start',
      'Start timer',
    );
  }

  /// Stop the timer for a task
  Future<TaskItem?> stopTaskTimer(String taskId) async {
    return _postWithRetry(
      '$_baseUrl/api/v1/tasks/$taskId/timer/stop',
      'Stop timer',
    );
  }

  /// Generic POST with retry logic for cold starts / transient failures
  Future<TaskItem?> _postWithRetry(String url, String label) async {
    const maxAttempts = 3;
    const baseDelay = Duration(seconds: 2);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        debugPrint('$label request (attempt ${attempt + 1}/$maxAttempts): $url');
        debugPrint('Headers: $_headers');

        final response = await http.post(
          Uri.parse(url),
          headers: _headers,
        ).timeout(const Duration(seconds: 30));

        debugPrint('$label response: ${response.statusCode} ${response.body}');

        if (response.statusCode == 200) {
          return TaskItem.fromJson(jsonDecode(response.body));
        }

        // Retry on 503 (service unavailable - cold start) or 502/504 (gateway issues)
        final shouldRetry = response.statusCode == 503 ||
            response.statusCode == 502 ||
            response.statusCode == 504;

        if (!shouldRetry || attempt == maxAttempts - 1) {
          debugPrint('$label failed with status ${response.statusCode}: ${response.body}');
          break;
        }
      } catch (e) {
        debugPrint('$label error (attempt ${attempt + 1}/$maxAttempts): $e');
        if (attempt == maxAttempts - 1) break;
      }

      // Exponential backoff: 2s, 4s
      final delay = baseDelay * (attempt + 1);
      debugPrint('$label retrying in ${delay.inSeconds}s...');
      await Future.delayed(delay);
    }
    return null;
  }

  Future<List<MilestoneItem>> fetchGoalRoadmap(String goalId) async {
    try {
      final mResponse = await http.get(
        Uri.parse('$_baseUrl/api/v1/goals/$goalId/milestones'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (mResponse.statusCode == 200) {
        final List<dynamic> mData = jsonDecode(mResponse.body);
        final milestones = mData.map((m) => MilestoneItem.fromJson(m)).toList();
        
        // Fetch tasks for each milestone in parallel
        await Future.wait(milestones.map((m) async {
          final tResponse = await http.get(
            Uri.parse('$_baseUrl/api/v1/tasks/milestone/${m.id}'),
            headers: _headers,
          );
          if (tResponse.statusCode == 200) {
            final List<dynamic> tData = jsonDecode(tResponse.body);
            m.tasks.addAll(tData.map((t) => TaskItem.fromJson(t)));
          }
        }));
        
        return milestones;
      }
    } catch (e) {
      debugPrint('Roadmap API error: $e');
    }
    return [];
  }
}

class TaskResource {
  final String title;
  final String url;

  TaskResource({required this.title, required this.url});

  factory TaskResource.fromJson(Map<String, dynamic> json) => TaskResource(
        title: json['title'] ?? '',
        url: json['url'] ?? '',
      );
}

class TaskItem {
  final String id;
  final String title;
  final String description;
  final String type;
  final int xpReward;
  final String status;
  final int estimatedMinutes;
  final List<TaskResource> resources;
  final DateTime? startedAt;
  final int? actualMinutes;
  final bool timerRunning;

  TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.type,
    required this.xpReward,
    required this.status,
    this.estimatedMinutes = 30,
    this.resources = const [],
    this.startedAt,
    this.actualMinutes,
    this.timerRunning = false,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final metadata = (json['metadata_'] ?? json['metadata']) as Map<String, dynamic>? ?? {};
    final rawResources = metadata['resources'] as List<dynamic>? ?? [];
    return TaskItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['task_type'] ?? 'custom',
      xpReward: json['xp_reward'] ?? 10,
      status: json['status'] ?? 'pending',
      estimatedMinutes: (metadata['estimated_minutes'] as int?) ?? (json['estimated_minutes'] as int?) ?? 30,
      resources: rawResources.map((r) => TaskResource.fromJson(r as Map<String, dynamic>)).toList(),
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at']) : null,
      actualMinutes: json['actual_minutes'] as int?,
      timerRunning: json['timer_running'] as bool? ?? false,
    );
  }
}

class MilestoneItem {
  final String id;
  final String title;
  final String? narrativeArc;
  final List<TaskItem> tasks;

  MilestoneItem({
    required this.id,
    required this.title,
    this.narrativeArc,
    this.tasks = const [],
  });

  factory MilestoneItem.fromJson(Map<String, dynamic> json) {
    final metadata = (json['metadata_'] ?? json['metadata']) as Map<String, dynamic>? ?? {};
    return MilestoneItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      narrativeArc: metadata['narrative_arc'] as String?,
      tasks: [], // populated later
    );
  }
}
