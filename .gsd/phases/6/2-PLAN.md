---
phase: 6
plan: 2
wave: 2
depends_on: [1]
files_modified:
  - eklavya_mobile/lib/core/services/dashboard_service.dart
  - eklavya_mobile/pubspec.yaml
autonomous: true

must_haves:
  truths:
    - "Flutter app can fetch the dashboard summary via HTTP"
    - "Flutter app can call the claim task endpoint"
  artifacts:
    - "lib/core/services/dashboard_service.dart created"
---

# Plan 6.2: Flutter Data Layer

## Objective
Create the Dart services and models to interact with the new backend Dashboard API.

Purpose: Bridge the gap between the beautiful UI (Phase 2/4) and the real backend data (Phase 6.1).

## Context
- .gsd/SPEC.md
- eklavya_mobile/lib/core/services/chat_service.dart (for HTTP pattern reference)

## Tasks

<task type="auto">
  <name>Build DashboardService</name>
  <files>
    eklavya_mobile/lib/core/services/dashboard_service.dart
  </files>
  <action>
    1. Create DashboardSummary model mapping closely to the backend JSON (User stats, Goal, Milestone, list of Tasks)
    2. Create DashboardService class with methods:
       - `Future<DashboardSummary?> getSummary(String userId)` -> calls GET /summary
       - `Future<bool> completeTask(String taskId, String userId)` -> calls POST /claim-task
    3. Implement safe fallback: if API fails or backend is unreachable (e.g. offline), return a stub `DashboardSummary` populated with `DemoData` so the UI never fundamentally breaks.
  </action>
  <verify>flutter analyze lib/core/services/dashboard_service.dart passes cleanly</verify>
  <done>Flutter has a robust service to fetch remote dashboard data with offline fallbacks</done>
</task>

## Success Criteria
- [ ] `DashboardService` securely wraps the backend `GET` and `POST` calls
- [ ] Robust error handling falls back to `DemoData` when offline
- [ ] Zero static analysis errors
