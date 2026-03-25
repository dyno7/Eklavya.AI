import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Icon with a subtle radial glow behind it.
class GlowIcon extends StatelessWidget {
  const GlowIcon({
    super.key,
    required this.icon,
    this.color,
    this.size = 24,
    this.glowRadius = 16,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final double glowRadius;

  @override
  Widget build(BuildContext context) {
    final finalColor = color ?? context.colors.primary;
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: finalColor.withAlpha(80),
            blurRadius: glowRadius,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: finalColor, size: size),
    );
  }
}
