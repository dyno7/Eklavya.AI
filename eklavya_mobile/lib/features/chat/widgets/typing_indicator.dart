import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Animated typing indicator — 3 dots bouncing in sequence.
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Guru avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [context.colors.primary, context.colors.secondary],
              ),
            ),
            child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
          ),
          SizedBox(width: AppSpacing.sm),
          // Dots bubble
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: context.colors.surface,
              border: Border.all(color: context.colors.glassBorder),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: context.colors.textTertiary,
                    shape: BoxShape.circle,
                  ),
                )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scaleXY(
                  begin: 0.6,
                  end: 1.0,
                  duration: 600.ms,
                  delay: (i * 200).ms,
                  curve: Curves.easeInOut,
                )
                .fadeIn(
                  duration: 400.ms,
                  delay: (i * 200).ms,
                );
              }),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 200.ms),
    );
  }
}
