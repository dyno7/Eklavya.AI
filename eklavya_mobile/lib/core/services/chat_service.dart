import 'dart:convert';
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

/// Service that communicates with the Guru Agent backend.
/// Falls back to offline canned responses if backend is unreachable.
class ChatService {
  String get _baseUrl => AppConfig.backendUrl;

  final String domain;
  int _offlineStep = 0;

  ChatService({
    this.domain = 'learning',
  });

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = AuthService.accessToken;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  /// Send a message and get the Guru's reply.
  /// Returns (replyText, isRoadmapReady, roadmapJson)
  Future<(String, bool, Map<String, dynamic>?)> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/chat/send'),
        headers: _headers,
        body: jsonEncode({
          'message': message,
          'domain': domain,
          'user_id': AuthService.userId,
        }),
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (
          data['reply'] as String,
          data['is_roadmap_ready'] as bool? ?? false,
          data['roadmap'] as Map<String, dynamic>?,
        );
      }
    } catch (_) {
      // Backend unreachable — fall back to offline mode
    }

    return _offlineResponse(message);
  }

  /// Reset the conversation session.
  Future<void> resetSession() async {
    _offlineStep = 0;
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/chat/reset/${AuthService.userId}'),
        headers: _headers,
      ).timeout(Duration(seconds: 5));
    } catch (_) {
      // Ignore — offline mode just resets local step
    }
  }

  /// Offline canned responses for demo when backend isn't running.
  (String, bool, Map<String, dynamic>?) _offlineResponse(String message) {
    _offlineStep++;

    switch (_offlineStep) {
      case 1:
        return (
          "Welcome! I'm your Eklavya Guru for Deep Learning 🧠\n\n"
          "I'd love to help you create a personalized learning roadmap. "
          "To start — what specific aspect of Deep Learning interests you most? "
          "For example: computer vision, NLP, generative AI, or the fundamentals?",
          false,
          null,
        );
      case 2:
        return (
          "Great choice! That's a fascinating area with lots of practical applications.\n\n"
          "How would you describe your current experience level? Are you a complete beginner, "
          "or do you have some programming/math background already?",
          false,
          null,
        );
      case 3:
        return (
          "Perfect, that helps me calibrate things nicely.\n\n"
          "One more thing — how much time can you realistically commit per day? "
          "Even 30 minutes of focused learning adds up quickly!",
          false,
          null,
        );
      default:
        return (
          "🎉 Your personalized roadmap is ready! I've created a structured plan tailored just for you.",
          true,
          _demoRoadmap(),
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
