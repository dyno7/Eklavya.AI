class DemoUser {
  final String displayName;
  final String? avatarUrl;
  final int totalXp;
  final int level;
  final int currentStreak;
  final int longestStreak;

  const DemoUser({
    required this.displayName,
    this.avatarUrl,
    required this.totalXp,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
  });
}

class DemoGoal {
  final String id;
  final String title;
  final String domain;
  final double progress;
  final String status;
  final int milestonesCount;
  final int completedMilestones;

  const DemoGoal({
    required this.id,
    required this.title,
    required this.domain,
    required this.progress,
    required this.status,
    required this.milestonesCount,
    required this.completedMilestones,
  });
}

class DemoTask {
  final String id;
  final String title;
  final String type;
  final int xpReward;
  bool isCompleted;
  final DateTime dueDate;

  DemoTask({
    required this.id,
    required this.title,
    required this.type,
    required this.xpReward,
    required this.isCompleted,
    required this.dueDate,
  });
}

class DemoAnalytics {
  final List<int> weeklyXp;
  final List<int> streakHistory;
  final Map<String, double> domainDistribution;

  const DemoAnalytics({
    required this.weeklyXp,
    required this.streakHistory,
    required this.domainDistribution,
  });
}

class DemoData {
  static const user = DemoUser(
    displayName: 'Arjun',
    avatarUrl: null,
    totalXp: 2450,
    level: 7,
    currentStreak: 12,
    longestStreak: 21,
  );

  static const goals = [
    DemoGoal(
      id: 'g1',
      title: 'Master Deep Learning',
      domain: 'learning',
      progress: 0.35,
      status: 'active',
      milestonesCount: 8,
      completedMilestones: 3,
    ),
    DemoGoal(
      id: 'g2',
      title: 'Build MVP Startup',
      domain: 'startup',
      progress: 0.15,
      status: 'active',
      milestonesCount: 5,
      completedMilestones: 1,
    ),
    DemoGoal(
      id: 'g3',
      title: 'Read 24 Books',
      domain: 'writing',
      progress: 0.5,
      status: 'active',
      milestonesCount: 3,
      completedMilestones: 1,
    ),
  ];

  static List<DemoTask> get tasks {
    final now = DateTime.now();
    return [
      DemoTask(
        id: 't1',
        title: 'Watch Neural Networks lecture',
        type: 'watch',
        xpReward: 25,
        isCompleted: false,
        dueDate: now,
      ),
      DemoTask(
        id: 't2',
        title: 'Practice backpropagation',
        type: 'practice',
        xpReward: 30,
        isCompleted: false,
        dueDate: now,
      ),
      DemoTask(
        id: 't3',
        title: 'Read Chapter 5: CNNs',
        type: 'read',
        xpReward: 15,
        isCompleted: true,
        dueDate: now,
      ),
      DemoTask(
        id: 't4',
        title: 'Quiz: Loss Functions',
        type: 'quiz',
        xpReward: 40,
        isCompleted: false,
        dueDate: now,
      ),
      DemoTask(
        id: 't5',
        title: 'Review startup pitch draft',
        type: 'custom',
        xpReward: 20,
        isCompleted: false,
        dueDate: now,
      ),
    ];
  }

  static const analytics = DemoAnalytics(
    weeklyXp: [120, 300, 50, 450, 200, 0, 150],
    streakHistory: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], // last 12 days
    domainDistribution: {
      'learning': 0.6,
      'startup': 0.3,
      'writing': 0.1,
    },
  );
}
