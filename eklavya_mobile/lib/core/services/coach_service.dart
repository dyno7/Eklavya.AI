import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
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

class CoachService {
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
      print('Error fetching coach status: $e');
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
      );
    } catch (e) {
      print('Error logging session start: $e');
    }
  }
}
