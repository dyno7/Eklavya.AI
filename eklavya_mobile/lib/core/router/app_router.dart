import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/page_transitions.dart';
import '../widgets/gradient_background.dart';

import '../../features/analytics/analytics_tab.dart';
import '../../features/auth/login_screen.dart';
import '../../features/chat/chat_tab.dart';
import '../../features/dashboard/home_tab.dart';
import '../../features/goals/goals_tab.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_tab.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    // ─── Pre-shell routes ──────────────────────────────
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => fadeTransition(
        context: context,
        state: state,
        child: SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => fadeTransition(
        context: context,
        state: state,
        child: LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => fadeSlideTransition(
        context: context,
        state: state,
        child: OnboardingScreen(),
      ),
    ),

    // ─── Standalone Profile route (outside shell) ────────
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => fadeSlideTransition(
        context: context,
        state: state,
        child: GradientBackground(child: ProfileTab()),
      ),
    ),

    // ─── Main shell with 4 tabs ────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => HomeTab(),
            ),
          ],
        ),
        // Tab 1: Goals
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/goals',
              builder: (context, state) => GoalsTab(),
            ),
          ],
        ),
        // Tab 2: Chat
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              builder: (context, state) => ChatTab(),
            ),
          ],
        ),
        // Tab 3: Analytics
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => AnalyticsTab(),
            ),
          ],
        ),
      ],
    ),
  ],
);
