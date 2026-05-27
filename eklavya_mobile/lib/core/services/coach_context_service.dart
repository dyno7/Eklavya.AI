import 'package:flutter/foundation.dart';

class CoachTaskContext {
  final String taskTitle;
  final String? taskDescription;
  final String? taskType;
  final String? milestoneTitle;

  const CoachTaskContext({
    required this.taskTitle,
    this.taskDescription,
    this.taskType,
    this.milestoneTitle,
  });
}

/// Passes task context from GoalRoadmapScreen → CoachPage.
/// Uses a ValueNotifier so CoachPage reacts even if already mounted.
class CoachContextService {
  CoachContextService._();

  static final ValueNotifier<CoachTaskContext?> pending = ValueNotifier(null);

  static void setContext(CoachTaskContext ctx) => pending.value = ctx;

  static void consume() => pending.value = null;
}
