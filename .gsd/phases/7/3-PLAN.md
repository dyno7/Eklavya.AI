---
phase: 7
plan: 3
wave: 3
depends_on: [1, 2]
autonomous: true
files_modified:
  - eklavya_mobile/lib/core/services/chat_service.dart
  - eklavya_mobile/lib/core/services/dashboard_service.dart
  - eklavya_mobile/lib/core/config/app_config.dart
  - eklavya_mobile/lib/features/auth/login_screen.dart
---

# Plan 7.3: JWT Propagation + Backend URL Config

## Objective
Two problems that prevent any backend data from loading:
1. **No auth header** — `ChatService` and `DashboardService` make HTTP requests without an `Authorization: Bearer <token>` header. The backend returns 401 for all protected endpoints, silently falling to demo mode.
2. **Hardcoded backend URL** — `10.0.2.2:8000` only works on Android emulator. Chrome (`localhost`) and physical devices need different URLs. We centralise this in `AppConfig`.

## Context
- eklavya_mobile/lib/core/services/chat_service.dart
- eklavya_mobile/lib/core/services/dashboard_service.dart
- eklavya_mobile/lib/core/services/auth_service.dart

## Tasks

<task type="auto">
  <name>Create AppConfig with configurable backend URL</name>
  <files>
    eklavya_mobile/lib/core/config/app_config.dart
  </files>
  <action>
    1. Create `lib/core/config/app_config.dart`:
       ```dart
       import 'package:flutter/foundation.dart';
       
       class AppConfig {
         /// Base URL for the Eklavya backend.
         /// - Android emulator: 10.0.2.2:8000
         /// - Chrome (web): localhost:8000
         /// - Physical device: set your machine's local IP, e.g. 192.168.1.x:8000
         static String get backendUrl {
           if (kIsWeb) return 'http://localhost:8000';
           // Override with --dart-define=BACKEND_URL=http://... for physical devices
           const overrideUrl = String.fromEnvironment('BACKEND_URL');
           if (overrideUrl.isNotEmpty) return overrideUrl;
           return 'http://10.0.2.2:8000';
         }
       }
       ```
    2. This allows: `flutter run --dart-define=BACKEND_URL=http://192.168.1.42:8000` for physical device.
  </action>
  <verify>flutter analyze lib/core/config/app_config.dart</verify>
  <done>Backend URL is configurable per environment, web defaults to localhost:8000</done>
</task>

<task type="auto">
  <name>Inject auth token into ChatService and DashboardService</name>
  <files>
    eklavya_mobile/lib/core/services/chat_service.dart
    eklavya_mobile/lib/core/services/dashboard_service.dart
  </files>
  <action>
    In both `ChatService` and `DashboardService`:
    1. Replace the hardcoded `static const String _baseUrl = 'http://10.0.2.2:8000'` with:
       ```dart
       String get _baseUrl => AppConfig.backendUrl;
       ```
    2. In every `http.get` / `http.post` call, add the auth header:
       ```dart
       final token = AuthService.accessToken;
       final headers = <String, String>{'Content-Type': 'application/json'};
       if (token != null) headers['Authorization'] = 'Bearer $token';
       ```
    3. In `ChatService.sendMessage()`:
       - Replace `'user_id': userId` in the JSON body with the actual user UUID from `AuthService.currentUser?.id ?? 'demo-user'`
    4. Remove the `userId` / `authToken` parameters from `getSummary()` and `completeTask()` in `DashboardService` — they now read from `AuthService` internally.
  </action>
  <verify>flutter analyze lib/core/services/</verify>
  <done>All HTTP calls carry the Supabase JWT. User ID is taken from the live session, not hardcoded.</done>
</task>

## Success Criteria
- [ ] Opening app in Chrome hits `localhost:8000` (not `10.0.2.2`)
- [ ] Every API call includes `Authorization: Bearer <token>` when logged in
- [ ] Dashboard `/summary` returns real data (not demo fallback) when backend is up
- [ ] `flutter analyze lib/` — zero errors
