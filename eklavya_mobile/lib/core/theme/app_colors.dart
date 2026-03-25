import 'package:flutter/material.dart';

/// Eklavya.AI color palette defined as a ThemeExtension.
/// Supports both dark and light modes cleanly via `context.colors`.
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color primary;
  final Color primaryLight;
  final Color secondary;
  final Color accent;
  final Color success;
  final Color warning;
  final Color error;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color glassTint;
  final Color glassBorder;
  final Color glassBorderLight;
  final Color glowPurple;
  final Color glowBlue;
  final Color glowCyan;
  final Color navBackground;
  final Color navText;
  final Color navInactiveIcon;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.glassTint,
    required this.glassBorder,
    required this.glassBorderLight,
    required this.glowPurple,
    required this.glowBlue,
    required this.glowCyan,
    required this.navBackground,
    required this.navText,
    required this.navInactiveIcon,
  });

  @override
  AppColors copyWith() {
    return this;
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      glassTint: Color.lerp(glassTint, other.glassTint, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassBorderLight: Color.lerp(glassBorderLight, other.glassBorderLight, t)!,
      glowPurple: Color.lerp(glowPurple, other.glowPurple, t)!,
      glowBlue: Color.lerp(glowBlue, other.glowBlue, t)!,
      glowCyan: Color.lerp(glowCyan, other.glowCyan, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      navText: Color.lerp(navText, other.navText, t)!,
      navInactiveIcon: Color.lerp(navInactiveIcon, other.navInactiveIcon, t)!,
    );
  }

  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [background, Color.lerp(background, primary, 0.15)!],
  );

  LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  LinearGradient get accentGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static const dark = AppColors(
    background: Color(0xFF0A0E1A),
    surface: Color(0xFF141829),
    surfaceLight: Color(0xFF1E2340),
    primary: Color(0xFF7C3AED),
    primaryLight: Color(0xFF9F67FF),
    secondary: Color(0xFF3B82F6),
    accent: Color(0xFF06B6D4),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    textTertiary: Color(0xFF64748B),
    glassTint: Color(0x14FFFFFF),
    glassBorder: Color(0x1FFFFFFF),
    glassBorderLight: Color(0x33FFFFFF),
    glowPurple: Color(0x407C3AED),
    glowBlue: Color(0x403B82F6),
    glowCyan: Color(0x4006B6D4),
    navBackground: Color(0xFF141829),
    navText: Color(0xFFF8FAFC),
    navInactiveIcon: Color(0xFF94A3B8),
  );

  static const light = AppColors(
    background: Color(0xFFF0F4FF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFE8EEFF),
    primary: Color(0xFF7C3AED),
    primaryLight: Color(0xFF9F67FF),
    secondary: Color(0xFF3B82F6),
    accent: Color(0xFF06B6D4),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textTertiary: Color(0xFF94A3B8),
    glassTint: Color(0x0A000000),
    glassBorder: Color(0x22000000),
    glassBorderLight: Color(0x33000000),
    glowPurple: Color(0x337C3AED),
    glowBlue: Color(0x333B82F6),
    glowCyan: Color(0x3306B6D4),
    // Light mode: dark nav for premium look
    navBackground: Color(0xFF1E2340),
    navText: Color(0xFFF8FAFC),
    navInactiveIcon: Color(0xFF94A3B8),
  );
}

extension AppColorsExtension on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

