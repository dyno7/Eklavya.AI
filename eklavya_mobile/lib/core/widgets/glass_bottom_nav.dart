import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// Data class for bottom nav items.
class GlassNavItem {
  const GlassNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Floating frosted glass bottom nav dock — inspired by Dribbble reference.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: context.colors.glassBorder.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: context.colors.glowPurple.withAlpha(30),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: context.colors.navBackground.withAlpha(240),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final isActive = index == currentIndex;
                return _NavItem(
                  item: items[index],
                  isActive: isActive,
                  onTap: () => onTap(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nav item with smooth label travel animation:
/// - Active: icon with label that slides from right-of-icon to below-icon
/// - Inactive: icon only
/// - Fixed height container prevents shape glitching
class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _travelAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _travelAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.isActive) {
      // Start in "below" state if initially active
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      // Became active: animate from beside → below
      _controller.forward(from: 0.0);
    } else if (!widget.isActive && old.isActive) {
      // Became inactive: reset
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    final iconColor = isActive ? context.colors.navText : context.colors.navInactiveIcon;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      // Fixed height wrapper prevents container shape changes
      child: SizedBox(
        height: 48,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? AppSpacing.lg : AppSpacing.md,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: isActive ? context.colors.primary : Colors.transparent,
            borderRadius: AppRadii.pill,
          ),
          child: isActive
              ? AnimatedBuilder(
                  animation: _travelAnimation,
                  builder: (context, child) {
                    final t = _travelAnimation.value;
                    // t=0: label beside icon (Row), t=1: label below icon (Column)
                    return _TravelingLabel(
                      item: widget.item,
                      progress: t,
                      color: context.colors.navText,
                    );
                  },
                )
              : Center(
                  child: Icon(
                    widget.item.icon,
                    size: 22,
                    color: iconColor,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Widget that smoothly transitions the label from beside the icon to below it.
/// [progress] 0.0 = label is to the right of the icon (Row layout)
/// [progress] 1.0 = label is below the icon (Column layout)
class _TravelingLabel extends StatelessWidget {
  const _TravelingLabel({
    required this.item,
    required this.progress,
    required this.color,
  });

  final GlassNavItem item;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Crossfade between Row layout (beside) and Column layout (below)
    final opacity = progress < 0.3
        ? 1.0 // Fully visible in "beside" mode
        : (progress < 0.5
            ? (1.0 - ((progress - 0.3) / 0.2)) // Fade out
            : (progress < 0.7
                ? ((progress - 0.5) / 0.2) // Fade in
                : 1.0)); // Fully visible in "below" mode

    final showBelow = progress > 0.5;

    return showBelow
        ? Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 22, color: color),
              SizedBox(height: 2),
              Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 22, color: color),
              SizedBox(width: AppSpacing.sm),
              Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
  }
}
