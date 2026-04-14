import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/glass_bottom_nav.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/services/coach_service.dart';

/// Main app shell with floating glass bottom nav.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  static final _navItems = [
    const GlassNavItem(icon: Icons.home_rounded, label: 'Home'),
    const GlassNavItem(icon: Icons.flag_rounded, label: 'Goals'),
    const GlassNavItem(icon: Icons.chat_bubble_rounded, label: 'Chat'),
    const GlassNavItem(icon: Icons.bar_chart_rounded, label: 'Analytics'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Log initial session start when app loads
    CoachService().logSessionStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Fire session analytics when bringing app to foreground
      CoachService().logSessionStart();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: widget.navigationShell,
        bottomNavigationBar: GlassBottomNav(
          currentIndex: widget.navigationShell.currentIndex,
          onTap: (index) => widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          ),
          items: _navItems,
        ),
        extendBodyBehindAppBar: true,
      ),
    );
  }
}
