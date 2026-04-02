import 'package:flutter/foundation.dart';

/// Centralised backend URL config.
/// Handles platform differences (emulator vs web vs physical device).
class AppConfig {
  /// Base URL for the Eklavya backend.
  /// - Android emulator: 10.0.2.2:8000
  /// - Chrome (web): localhost:8000
  /// - Physical device: use --dart-define=BACKEND_URL=http://192.168.x.x:8000
  static String get backendUrl {
    if (kIsWeb) return 'http://localhost:8000';
    const overrideUrl = String.fromEnvironment('BACKEND_URL');
    if (overrideUrl.isNotEmpty) return overrideUrl;
    return 'http://10.0.2.2:8000';
  }
}
