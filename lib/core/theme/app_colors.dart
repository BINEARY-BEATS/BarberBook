import 'package:flutter/material.dart';

/// Design tokens — purple for barber admin, gold for customer dark shell.
abstract final class AppColors {
  /// Barber admin CTA / active accent (soft purple).
  static const Color accent = Color(0xFF8B5CF6);
  static const Color accentDark = Color(0xFF7C3AED);
  static const Color accentSoft = Color(0xFFF3EEFF);
  static const Color onAccent = Color(0xFFFFFFFF);

  /// Customer premium accent (warm gold / tan).
  static const Color customerAccent = Color(0xFFD4B896);
  static const Color customerAccentSoft = Color(0x33D4B896);
  static const Color customerOnAccent = Color(0xFF1A1A1A);
  static const Color customerCard = Color(0xFF1E1E1E);
  static const Color customerBorder = Color(0xFF2A2A2A);
  static const Color customerSecondary = Color(0xFFB3B3B3);

  /// Secondary highlight (ratings).
  static const Color gold = Color(0xFFF5C518);

  static const Color black = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF121212);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceElevated = Color(0xFF222222);
  static const Color surfaceCard = Color(0xFF2A2A2A);

  static const Color lightBackground = Color(0xFFF8F8F8);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE8E8E8);

  static const Color border = Color(0x33FFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF8A8A8A);

  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF6B6B6B);
  static const Color textMutedLight = Color(0xFF9E9E9E);

  static const Color danger = Color(0xFFEF5350);
  static const Color success = Color(0xFF4CAF50);
  static const Color pending = Color(0xFFFF9800);

  /// Soft card shadow used across the light theme.
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static Color scaffold(bool isDark) =>
      isDark ? darkSurface : lightBackground;

  static Color card(bool isDark) =>
      isDark ? customerCard : lightCard;

  static Color elevated(bool isDark) =>
      isDark ? surfaceElevated : lightSurface;

  static Color onSurface(bool isDark) =>
      isDark ? textPrimary : textPrimaryLight;

  static Color secondaryText(bool isDark) =>
      isDark ? customerSecondary : textSecondaryLight;

  static Color mutedText(bool isDark) =>
      isDark ? textMuted : textMutedLight;

  static Color divider(bool isDark) =>
      isDark ? customerBorder : lightBorder;

  /// Active accent for the current theme (gold in customer shell, purple elsewhere).
  static Color themeAccent(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
}

/// Shared border-radius tokens.
abstract final class AppRadius {
  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;
}

/// Layout insets for floating bottom nav shells.
abstract final class BookScaffoldPadding {
  /// Clears the floating pill nav (~68 height + 20 bottom pad + buffer).
  static const double bottomNav = 100;
}
