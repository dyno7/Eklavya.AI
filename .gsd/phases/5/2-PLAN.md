---
phase: 5
plan: 2
wave: 2
depends_on: [1]
files_modified:
  - eklavya_mobile/lib/features/chat/chat_tab.dart
  - eklavya_mobile/lib/features/chat/widgets/chat_bubble.dart
  - eklavya_mobile/lib/features/chat/widgets/typing_indicator.dart
  - eklavya_mobile/lib/core/services/chat_service.dart
  - eklavya_mobile/pubspec.yaml
autonomous: true

must_haves:
  truths:
    - "Chat tab shows real message bubbles with send functionality"
    - "User messages appear on the right, Guru replies on the left"
    - "Typing indicator shows while waiting for AI response"
    - "Chat service calls the backend /api/chat/send endpoint"
  artifacts:
    - "chat_tab.dart is a functional chat screen with input field"
    - "chat_service.dart handles HTTP POST to backend"
    - "chat_bubble.dart renders styled bubbles for user/guru"
---

# Plan 5.2: Flutter Chat UI

## Objective
Replace the placeholder Chat tab with a functional real-time chat interface that communicates with the Guru Agent backend.

Purpose: This is the user-facing half of the Guru onboarding — a beautiful chat screen where users describe their goals and the Guru responds conversationally.

## Context
- .gsd/SPEC.md
- eklavya_mobile/lib/features/chat/chat_tab.dart
- eklavya_mobile/lib/core/theme/app_colors.dart

## Tasks

<task type="auto">
  <name>Build chat service and message models</name>
  <files>
    eklavya_mobile/lib/core/services/chat_service.dart
    eklavya_mobile/lib/core/data/demo_data.dart
    eklavya_mobile/pubspec.yaml
  </files>
  <action>
    1. Add `http: ^1.2.1` to pubspec.yaml (if not present) for REST calls
    2. Create lib/core/services/chat_service.dart:
       - class ChatMessage { final String text; final bool isUser; final DateTime timestamp; }
       - class ChatService:
         - String _baseUrl = 'http://10.0.2.2:8000' (Android emulator → host) or configurable
         - Future<String> sendMessage(String message, {String domain = 'learning'}) → calls POST /api/chat/send, returns reply text
         - Future<void> resetSession() → calls POST /api/chat/reset
       - For OFFLINE/DEMO MODE: if backend is unreachable, return canned responses that simulate the Guru conversation flow (3-4 hardcoded exchanges ending with "I'll generate your personalized roadmap now!")
    AVOID: Using dio — http package is simpler for MVP
    AVOID: Riverpod for now — use simple ChangeNotifier or stateful widget state
  </action>
  <verify>flutter analyze lib/core/services/chat_service.dart</verify>
  <done>ChatService class can POST to backend and return reply, with offline fallback</done>
</task>

<task type="auto">
  <name>Build premium chat UI with bubbles and input</name>
  <files>
    eklavya_mobile/lib/features/chat/chat_tab.dart
    eklavya_mobile/lib/features/chat/widgets/chat_bubble.dart
    eklavya_mobile/lib/features/chat/widgets/typing_indicator.dart
  </files>
  <action>
    1. Create lib/features/chat/widgets/chat_bubble.dart:
       - User bubble: right-aligned, gradient background (primary→secondary), white text, rounded corners (top-left, top-right, bottom-left — not bottom-right)
       - Guru bubble: left-aligned, glass surface background, themed text, rounded corners (top-left, top-right, bottom-right — not bottom-left)
       - Avatar: small guru icon (smart_toy_rounded) on left for guru, none for user
       - Timestamp in labelSmall below the bubble
       - Entry animation: fadeIn + slideX (from left for guru, from right for user)
    2. Create lib/features/chat/widgets/typing_indicator.dart:
       - 3 animated dots bouncing in sequence (use flutter_animate)
       - Wrapped in a guru-style bubble
    3. Rewrite lib/features/chat/chat_tab.dart:
       - AppBar with "Guru" title + domain tag chip
       - ListView.builder for chat messages (reversed, so newest at bottom)
       - Fixed bottom input area: TextField with glassmorphism styling + send button (gradient circle with arrow icon)
       - On send: add user message to list, show typing indicator, call ChatService.sendMessage(), add guru reply, hide indicator
       - Initial guru message: "Hello! I'm your Guru for {domain}. Tell me about your learning goals — what do you want to master?"
       - Scroll to bottom on new messages
    AVOID: Using a package like dash_chat — custom UI matches the app's glassmorphism design
    AVOID: Large message lists in state — keep it simple with a List<ChatMessage> in StatefulWidget
  </action>
  <verify>flutter analyze lib/features/chat/</verify>
  <done>Chat tab renders messages, accepts input, calls ChatService, shows typing indicator, and looks premium</done>
</task>

## Success Criteria
- [ ] Chat tab shows conversational message bubbles
- [ ] User can type and send messages
- [ ] Guru replies appear with typing indicator delay
- [ ] Offline mode works with canned responses
- [ ] `flutter analyze lib/` passes with zero errors
