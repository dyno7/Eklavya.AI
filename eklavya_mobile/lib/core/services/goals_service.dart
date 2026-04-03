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
}
