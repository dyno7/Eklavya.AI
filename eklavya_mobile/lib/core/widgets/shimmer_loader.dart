import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

/// Skeleton shimmer loader for loading states.
class ShimmerLoader extends StatelessWidget {
  const ShimmerLoader({
    super.key,
    this.width = double.infinity,
    this.height = 80,
    this.borderRadius = AppRadii.md,
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colors.surface,
      highlightColor: context.colors.surfaceLight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
