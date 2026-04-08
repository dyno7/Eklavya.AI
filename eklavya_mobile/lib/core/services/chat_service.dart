import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../services/auth_service.dart';

/// A single chat message.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// A past chat session summary (like ChatGPT sidebar items).
class ChatSession {
  final String sessionId;
  final String title;
  final String? startedAt;
  final String? lastMessageAt;
  final int messageCount;

  ChatSession({
    required this.sessionId,
    required this.title,
    this.startedAt,
    this.lastMessageAt,
    this.messageCount = 0,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    sessionId: json['session_id'] ?? '',
    title: json['title'] ?? 'New conversation',
    startedAt: json['started_at'],
    lastMessageAt: json['last_message_at'],
    messageCount: json['message_count'] ?? 0,
  );
}

/// Service that communicates with the Guru Agent backend.
class ChatService {
  String get _baseUrl => AppConfig.backendUrl;

  final String domain;
  String? _currentSessionId;
  int _offlineStep = 0;

  ChatService({this.domain = 'learning'});

  String? get currentSessionId => _currentSessionId;

  /// Start a fresh conversation (clears session_id).
  void startNewSession() {
    _currentSessionId = null;
    _offlineStep = 0;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = AuthService.accessToken;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  /// Send a message and get the Guru's reply.
  /// Returns (replyText, isRoadmapReady, roadmapJson, navigateToRoadmap)
  Future<(String, bool, Map<String, dynamic>?, bool)> sendMessage(String message) async {
    try {
      final body = <String, dynamic>{
        'message': message,
        'domain': domain,
        'user_id': AuthService.userId ?? 'demo-user',
      };
      if (_currentSessionId != null) {
        body['session_id'] = _currentSessionId;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/chat/send'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Track session_id from response
        _currentSessionId = data['session_id'] as String?;
        return (
          data['reply'] as String,
          data['is_roadmap_ready'] as bool? ?? false,
          data['roadmap'] as Map<String, dynamic>?,
          data['navigate_to_roadmap'] as bool? ?? false,
        );
      }
    } catch (e) {
      debugPrint('Chat API error: $e');
    }

    return _offlineResponse(message);
  }

  /// Fetch the list of past conversation sessions.
  Future<List<ChatSession>> getSessions() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chat/sessions'),
        headers: _headers,
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessions = (data['sessions'] as List<dynamic>? ?? [])
            .map((s) => ChatSession.fromJson(s as Map<String, dynamic>))
            .toList();
        return sessions;
      }
    } catch (e) {
      debugPrint('Chat sessions API error: $e');
    }
    return [];
  }

  /// Load messages for a specific session.
  Future<List<ChatMessage>> loadSession(String sessionId) async {
    _currentSessionId = sessionId;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chat/sessions/$sessionId'),
        headers: _headers,
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = (data['messages'] as List<dynamic>? ?? []).map((m) {
          return ChatMessage(
            text: m['content'] ?? '',
            isUser: m['role'] == 'user',
            timestamp: m['created_at'] != null
                ? DateTime.tryParse(m['created_at']) ?? DateTime.now()
                : DateTime.now(),
          );
        }).toList();
        return messages;
      }
    } catch (e) {
      debugPrint('Load session API error: $e');
    }
    return [];
  }

  /// Reset the conversation session.
  Future<void> resetSession() async {
    _offlineStep = 0;
    _currentSessionId = null;
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/chat/reset/${AuthService.userId}'),
        headers: _headers,
      ).timeout(Duration(seconds: 5));
    } catch (_) {}
  }

  /// Offline canned responses for demo when backend isn't running.
  (String, bool, Map<String, dynamic>?, bool) _offlineResponse(String message) {
    _offlineStep++;

    switch (_offlineStep) {
      case 1:
        return (
          "Welcome! I'm your Eklavya Guru 🧠\n\n"
          "I'd love to help you create a personalized learning roadmap or goal tracker. "
          "To start — what specific skill or goal do you want to master?",
          false, null, false,
        );
      case 2:
        return (
          "Great choice! That's a fascinating area with lots of practical applications.\n\n"
          "How would you describe your current experience level? Are you a complete beginner, "
          "or do you have some programming/math background already?",
          false, null, false,
        );
      case 3:
        return (
          "Perfect, that helps me calibrate things nicely.\n\n"
          "One more thing — how much time can you realistically commit per day? "
          "Even 30 minutes of focused learning adds up quickly!",
          false, null, false,
        );
      default:
        return (
          "🎉 Your personalized roadmap is ready! I've created a structured plan tailored just for you.",
          true, _demoRoadmap(), false,
        );
    }
  }

  Map<String, dynamic> _demoRoadmap() => {
    'title': 'Master Deep Learning',
    'domain': 'learning',
    'estimated_weeks': 12,
    'milestones': [
      {'title': 'Math & Python Foundations', 'order': 1, 'tasks_count': 4},
      {'title': 'Neural Network Basics', 'order': 2, 'tasks_count': 4},
      {'title': 'CNNs & Computer Vision', 'order': 3, 'tasks_count': 4},
      {'title': 'RNNs & Sequence Models', 'order': 4, 'tasks_count': 3},
      {'title': 'Transformers & Attention', 'order': 5, 'tasks_count': 4},
      {'title': 'Capstone Project', 'order': 6, 'tasks_count': 4},
    ],
  };
}
