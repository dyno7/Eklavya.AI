import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gradient_background.dart';

/// Animated splash screen — Eklavya.AI branding + auto-navigate.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate — skip login if session exists
    Timer(Duration(milliseconds: 2500), () {
      if (mounted) context.go(AuthService.isLoggedIn ? '/home' : '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Logo text ───
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Eklavya',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                  ),
                  Text(
                    '.AI',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: context.colors.accent,
                          letterSpacing: -1,
                        ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 800.ms, curve: Curves.easeOutCubic)
                  .scale(
                    begin: Offset(0.8, 0.8),
                    end: Offset(1.0, 1.0),
                    duration: 800.ms,
                    curve: Curves.easeOutCubic,
                  ),
              SizedBox(height: 12),
              // ─── Tagline ───
              Text(
                'Master Your Journey',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                      letterSpacing: 1.5,
                    ),
              )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
