import 'package:flutter/foundation.dart';

/// Broadcasts roadmap updates across tabs that are kept alive by IndexedStack.
class RoadmapSyncService {
  static final ValueNotifier<int> _version = ValueNotifier<int>(0);

  static ValueListenable<int> get updates => _version;

  static void notifyRoadmapUpdated() {
    _version.value = _version.value + 1;
  }
}
