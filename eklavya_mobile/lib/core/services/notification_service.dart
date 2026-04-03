import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../services/auth_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool readStatus;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.readStatus,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        type: json['type'] ?? '',
        readStatus: json['read_status'] ?? false,
        createdAt: DateTime.parse(json['created_at']),
      );
}

class NotificationService {
  Future<List<NotificationItem>> getMyNotifications() async {
    final token = AuthService.accessToken;
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.backendUrl}/api/v1/notifications/'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => NotificationItem.fromJson(e)).toList();
      } else {
        debugPrint('Failed to load notifications: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String id) async {
    final token = AuthService.accessToken;
    try {
      await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/v1/notifications/$id/read'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }
}
