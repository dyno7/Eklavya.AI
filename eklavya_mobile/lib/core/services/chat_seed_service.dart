import 'package:flutter/foundation.dart';

/// Allows other parts of the app to pre-seed the chat tab with a message.
/// Works with IndexedStack navigation where initState is only called once.
class ChatSeedService {
  ChatSeedService._();

  static final ValueNotifier<String?> pending = ValueNotifier(null);

  static void seed(String message) => pending.value = message;

  static void consume() => pending.value = null;
}
