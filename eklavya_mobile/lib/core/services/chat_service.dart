import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../services/auth_service.dart';

class ChatResource {
  final String title;
  final String url;
  final String? taskTitle;
  final String? milestoneTitle;

  ChatResource({
    required this.title,
    required this.url,
    this.taskTitle,
    this.milestoneTitle,
  });

  factory ChatResource.fromJson(Map<String, dynamic> json) => ChatResource(
        title: json['title'] ?? '',
        url: json['url'] ?? '',
        taskTitle: json['task_title'] as String?,
        milestoneTitle: json['milestone_title'] as String?,
      );
}

/// A single chat message.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? options;
  final List<ChatResource>? resources;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.options,
    this.resources,
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

  /// Start a fresh conversation — clears local state and purges backend agent.
  Future<void> startNewSession() async {
    _currentSessionId = null;
    _offlineStep = 0;
    await resetSession();
  }

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = AuthService.accessToken;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  /// Send a message and get the Guru's reply.
  /// Returns (replyText, isRoadmapReady, roadmapJson, navigateToRoadmap)
  Future<(String, bool, Map<String, dynamic>?, bool, List<String>?, List<ChatResource>?)> sendMessage(String message) async {
    try {
      final body = <String, dynamic>{
        'message': message,
        'domain': domain,
      };
      if (_currentSessionId != null) {
        body['session_id'] = _currentSessionId;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/chat/send'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentSessionId = data['session_id'] as String?;
        final rawOptions = data['options'] as List<dynamic>?;
        final options = rawOptions?.map((o) => o.toString()).toList();
        final rawResources = data['resources'] as List<dynamic>?;
        final resources = rawResources
            ?.whereType<Map>()
            .map((r) => ChatResource.fromJson(Map<String, dynamic>.from(r)))
            .toList();
        return (
          data['reply'] as String,
          data['is_roadmap_ready'] as bool? ?? false,
          data['roadmap'] as Map<String, dynamic>?,
          data['navigate_to_roadmap'] as bool? ?? false,
          options,
          resources,
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
        Uri.parse('$_baseUrl/api/chat/reset'),
        headers: _headers,
      ).timeout(Duration(seconds: 5));
    } catch (_) {}
  }

  /// Offline canned responses for demo when backend isn't running.
  (String, bool, Map<String, dynamic>?, bool, List<String>?, List<ChatResource>?) _offlineResponse(String message) {
    // Mid-conversation failure (session was active) — show retry instead of re-greeting.
    if (_currentSessionId != null) {
      return (
        "I'm taking longer than expected — please send your message again.",
        false, null, false, null, null,
      );
    }

    _offlineStep++;

    switch (_offlineStep) {
      case 1:
        return (
          "Welcome! I'm your Eklavya Guru 🧠\n\nWhat skill or goal do you want to master?",
          false, null, false, null, null,
        );
      case 2:
        return (
          "Nice! What's your experience level?",
          false, null, false,
          ["Beginner", "Intermediate", "Advanced"],
          null,
        );
      case 3:
        return (
          "How much time can you commit per day?",
          false, null, false,
          ["30 min/day", "1 hr/day", "2+ hrs/day"],
          null,
        );
      default:
        return (
          "🎉 Your roadmap is ready!",
          true, _demoRoadmap(), false, null, _demoResources(),
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
      List<ChatResource> _demoResources() => [
        ChatResource(title: 'Deep Learning Book', url: 'https://www.deeplearningbook.org/'),
        ChatResource(title: 'PyTorch Tutorials', url: 'https://pytorch.org/tutorials/'),
      ];

    }
