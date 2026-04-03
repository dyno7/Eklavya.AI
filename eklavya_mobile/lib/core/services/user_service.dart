import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../services/auth_service.dart';

class BadgeItem {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final int requiredXp;
  final bool isEarned;
  final DateTime? earnedAt;

  BadgeItem({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.requiredXp,
    required this.isEarned,
    this.earnedAt,
  });

  factory BadgeItem.fromJson(Map<String, dynamic> json) => BadgeItem(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        iconUrl: json['icon_url'],
        requiredXp: json['required_xp'] ?? 0,
        isEarned: json['is_earned'] ?? false,
        earnedAt: json['earned_at'] != null ? DateTime.tryParse(json['earned_at']) : null,
      );
}

class UserService {
  Future<List<BadgeItem>> getMyBadges() async {
    final token = AuthService.accessToken;
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.backendUrl}/api/v1/users/me/badges'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => BadgeItem.fromJson(e)).toList();
      } else {
        debugPrint('Failed to load badges: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error loading badges: $e');
      return [];
    }
  }
}
