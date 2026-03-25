import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/glass_bottom_nav.dart';
import '../../core/widgets/gradient_background.dart';

/// Main app shell with floating glass bottom nav.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static final _navItems = [
    const GlassNavItem(icon: Icons.home_rounded, label: 'Home'),
    const GlassNavItem(icon: Icons.flag_rounded, label: 'Goals'),
    const GlassNavItem(icon: Icons.chat_bubble_rounded, label: 'Chat'),
    const GlassNavItem(icon: Icons.bar_chart_rounded, label: 'Analytics'),
  ];

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: navigationShell,
        bottomNavigationBar: GlassBottomNav(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          items: _navItems,
        ),
        extendBodyBehindAppBar: true,
      ),
    );
  }
}
