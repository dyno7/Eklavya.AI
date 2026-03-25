import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glow_icon.dart';

class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlowIcon(
              icon: Icons.smart_toy_rounded,
              color: context.colors.secondary,
              size: 80,
              glowRadius: 32,
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: Offset(1.0, 1.0), end: Offset(1.1, 1.1), duration: 2.seconds, curve: Curves.easeInOut),
            
            SizedBox(height: AppSpacing.xxxl),
            
            Text('Meet Your Guru', style: theme.textTheme.displayLarge),
            
            SizedBox(height: AppSpacing.sm),
            
            Text(
              'Your AI learning companion\nwill be here soon',
              style: theme.textTheme.bodyLarge?.copyWith(color: context.colors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: AppSpacing.xxxl),
            
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.accent.withValues(alpha: 0.15),
                borderRadius: AppRadii.pill,
                border: Border.all(color: context.colors.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Coming in Phase 3',
                style: theme.textTheme.labelLarge?.copyWith(color: context.colors.accent, fontWeight: FontWeight.bold),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
