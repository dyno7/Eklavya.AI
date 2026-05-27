import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'coach_context_service.dart';
import '../config/app_config.dart';

class CoachStatusResponse {
  final double gdiScore;
  final String state;
  final String intervention;
  final Map<String, double> components;

  CoachStatusResponse({
    required this.gdiScore,
    required this.state,
    required this.intervention,
    required this.components,
  });

  factory CoachStatusResponse.fromJson(Map<String, dynamic> json) {
    return CoachStatusResponse(
      gdiScore: (json['gdi_score'] as num).toDouble(),
      state: json['state'] as String,
      intervention: json['intervention'] as String,
      components: Map<String, double>.from(
          json['components'].map((key, value) => MapEntry(key, (value as num).toDouble()))),
    );
  }
}

class CoachMessage {
  final String text;
  final bool isUser;
  final List<String> resourceUrls;

  const CoachMessage({
    required this.text,
    required this.isUser,
    this.resourceUrls = const [],
  });
}

class CoachService {
  String? _sessionId;

  String? get sessionId => _sessionId;

  void startNewSession() => _sessionId = null;

  Future<CoachMessage?> ask({
    required String message,
    CoachTaskContext? taskContext,
  }) async {
    final token = AuthService.accessToken;
    if (token == null) return null;

    try {
      final body = <String, dynamic>{'message': message};
      if (_sessionId != null) body['session_id'] = _sessionId;
      if (taskContext != null) {
        body['task_title'] = taskContext.taskTitle;
        if (taskContext.taskDescription != null) body['task_description'] = taskContext.taskDescription;
        if (taskContext.taskType != null) body['task_type'] = taskContext.taskType;
        if (taskContext.milestoneTitle != null) body['milestone_title'] = taskContext.milestoneTitle;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/v1/coach/ask'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _sessionId = data['session_id'] as String?;
        final rawResources = data['resources'] as List<dynamic>?;
        final urls = rawResources
            ?.whereType<Map>()
            .map((r) => r['url'] as String? ?? '')
            .where((u) => u.isNotEmpty)
            .toList() ?? [];
        return CoachMessage(
          text: data['reply'] as String,
          isUser: false,
          resourceUrls: urls,
        );
      }
    } catch (e) {
      debugPrint('Coach ask error: $e');
    }
    return null;
  }

  Future<CoachStatusResponse?> fetchStatus() async {
    final token = AuthService.accessToken;
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.backendUrl}/api/v1/coach/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return CoachStatusResponse.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching coach status: $e');
    }
    return null;
  }

  Future<void> logSessionStart() async {
    final token = AuthService.accessToken;
    if (token == null) return;

    try {
      await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/v1/analytics/session_start'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Error logging session start: $e');
    }
  }
}
