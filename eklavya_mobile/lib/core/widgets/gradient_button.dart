import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

/// Gradient pill button with subtle glow.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient,
    this.isLoading = false,
    this.isExpanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final LinearGradient? gradient;
  final bool isLoading;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final finalGradient = gradient ?? context.colors.primaryGradient;
    
    final button = Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: onPressed != null ? finalGradient : null,
        color: onPressed == null ? context.colors.surfaceLight : null,
        borderRadius: AppRadii.pill,
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: context.colors.glowPurple,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppRadii.pill,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.textPrimary,
                    ),
                  )
                : Row(
                    mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: context.colors.textPrimary, size: 20),
                        SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    if (isExpanded) return button;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: button,
    );
  }
}
