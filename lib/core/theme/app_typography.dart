import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography: Work Sans — clear hierarchy for the soft-purple UI.
abstract final class AppTypography {
  static TextTheme textTheme({required bool isDark}) {
    final onSurface = AppColors.onSurface(isDark);
    final base =
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final body = GoogleFonts.workSansTextTheme(base);

    return body.copyWith(
      displayLarge: GoogleFonts.workSans(
        fontWeight: FontWeight.w800,
        fontSize: 32,
        letterSpacing: -0.8,
        color: onSurface,
      ),
      displayMedium: GoogleFonts.workSans(
        fontWeight: FontWeight.w800,
        fontSize: 28,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      displaySmall: GoogleFonts.workSans(
        fontWeight: FontWeight.w700,
        fontSize: 24,
        letterSpacing: -0.3,
        color: onSurface,
      ),
      headlineMedium: GoogleFonts.workSans(
        fontWeight: FontWeight.w700,
        fontSize: 22,
        color: onSurface,
      ),
      headlineSmall: GoogleFonts.workSans(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: onSurface,
      ),
      titleLarge: GoogleFonts.workSans(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.workSans(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: onSurface,
      ),
      titleSmall: GoogleFonts.workSans(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: onSurface,
      ),
      bodyLarge: GoogleFonts.workSans(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: AppColors.secondaryText(isDark),
      ),
      bodyMedium: GoogleFonts.workSans(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: AppColors.secondaryText(isDark),
      ),
      bodySmall: GoogleFonts.workSans(
        fontWeight: FontWeight.w400,
        fontSize: 12,
        color: AppColors.mutedText(isDark),
      ),
      labelLarge: GoogleFonts.workSans(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        fontSize: 15,
        color: onSurface,
      ),
      labelMedium: GoogleFonts.workSans(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: AppColors.secondaryText(isDark),
      ),
      labelSmall: GoogleFonts.workSans(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        fontSize: 10,
        color: AppColors.secondaryText(isDark),
      ),
    );
  }
}
