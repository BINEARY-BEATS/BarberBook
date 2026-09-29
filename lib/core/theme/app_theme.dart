import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Soft-purple Material 3 theme (light + dark) + customer gold dark shell.
abstract final class AppTheme {
  static ThemeData dark() => _build(Brightness.dark, customer: false);
  static ThemeData light() => _build(Brightness.light, customer: false);

  /// Forced dark charcoal + warm gold for the customer shell.
  static ThemeData customer() => _build(Brightness.dark, customer: true);

  static ThemeData _build(Brightness brightness, {required bool customer}) {
    final isDark = brightness == Brightness.dark;
    final primary =
        customer ? AppColors.customerAccent : AppColors.accent;
    final onPrimary =
        customer ? AppColors.customerOnAccent : AppColors.onAccent;
    final secondary =
        customer ? AppColors.customerAccent : AppColors.accentDark;
    final surface = customer
        ? AppColors.darkSurface
        : AppColors.scaffold(isDark);
    final onSurface = AppColors.onSurface(isDark || customer);
    final cardColor = customer
        ? AppColors.customerCard
        : AppColors.card(isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark || customer ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: surface,
      colorScheme: ColorScheme(
        brightness: isDark || customer ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: onPrimary,
        surface: surface,
        onSurface: onSurface,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      textTheme: AppTypography.textTheme(isDark: isDark || customer),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: GoogleFonts.workSans(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: (isDark || customer)
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: primary.withValues(alpha: 0.35),
          disabledForegroundColor: onPrimary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.workSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: customer
            ? AppColors.customerCard
            : (isDark ? AppColors.surface : AppColors.lightCard),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r16),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r16),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: TextStyle(
          color: AppColors.mutedText(isDark || customer),
        ),
        hintStyle: TextStyle(
          color: AppColors.mutedText(isDark || customer),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return GoogleFonts.workSans(
            fontSize: 11,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel
                ? primary
                : AppColors.mutedText(isDark || customer),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return IconThemeData(
            color: sel
                ? primary
                : AppColors.mutedText(isDark || customer),
            size: 24,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: customer
            ? AppColors.surfaceElevated
            : (isDark ? AppColors.surface : AppColors.lightSurface),
        selectedColor: primary,
        labelStyle:
            GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r24),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.divider(isDark || customer),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: GoogleFonts.workSans(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: AppColors.customerSecondary,
        indicatorColor: primary,
        labelStyle: GoogleFonts.workSans(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.workSans(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}
