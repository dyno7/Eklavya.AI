import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen gradient background with subtle glow spots.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: context.colors.backgroundGradient),
      child: Stack(
        children: [
          // Purple glow — top left
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.colors.glowPurple.withAlpha(40),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Blue glow — bottom right
          Positioned(
            bottom: -120,
            right: -60,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.colors.glowBlue.withAlpha(30),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          child,
        ],
      ),
    );
  }
}
