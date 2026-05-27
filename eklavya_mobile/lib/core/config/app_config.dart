import 'package:flutter/foundation.dart';

/// Centralised backend URL config.
/// Handles platform differences (emulator vs web vs physical device).
class AppConfig {
  /// Base URL for the Eklavya backend.
  /// Production: set via --dart-define=BACKEND_URL=https://api.eklavya.ai
  /// Android emulator: 10.0.2.2:8000
  /// Chrome (web): localhost:8000
  /// Physical device: use --dart-define=BACKEND_URL=http://192.168.x.x:8000
  static String get backendUrl {
    const overrideUrl = String.fromEnvironment('BACKEND_URL');
    if (overrideUrl.isNotEmpty) return overrideUrl;
    // Development fallbacks only — production must use --dart-define
    if (kIsWeb) return 'http://localhost:8000';
    if (kDebugMode) return 'http://10.0.2.2:8000';
    // Release mode without BACKEND_URL is a misconfiguration
    throw StateError(
      'BACKEND_URL not set for release build. '
      'Run with: flutter build --dart-define=BACKEND_URL=https://your-api.com',
    );
  }

  /// Whether the app is running in production mode.
  static bool get isProduction => kReleaseMode;
}
