import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class GoalItem {
  final String id;
  final String title;
  final String description;
  final String domain;
  final String status;
  final int milestonesCount;
  final int completedMilestones;
  final double progress;

  GoalItem({
    required this.id,
    required this.title,
    required this.description,
    required this.domain,
    required this.status,
    required this.milestonesCount,
    required this.completedMilestones,
    required this.progress,
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
      );
}

class GoalsService {
  String get _baseUrl => AppConfig.backendUrl;

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = AuthService.accessToken;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<List<GoalItem>> fetchGoals() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/goals/'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((g) => GoalItem.fromJson(g)).toList();
      }
    } catch (e) {
      debugPrint('Goals API error: $e');
    }
    return [];
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

class TaskItem {
  final String id;
  final String title;
  final String type;
  final int xpReward;
  final String status;

  TaskItem({
    required this.id,
    required this.title,
    required this.type,
    required this.xpReward,
    required this.status,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        type: json['task_type'] ?? 'custom',
        xpReward: json['xp_reward'] ?? 10,
        status: json['status'] ?? 'pending',
      );
}

class MilestoneItem {
  final String id;
  final String title;
  final List<TaskItem> tasks;

  MilestoneItem({
    required this.id,
    required this.title,
    this.tasks = const [],
  });

  factory MilestoneItem.fromJson(Map<String, dynamic> json) => MilestoneItem(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        tasks: [], // populated later
      );
}
