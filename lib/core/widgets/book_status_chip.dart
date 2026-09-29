import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Compact filled status pill (Success / Pending / Cancelled / accent).
class BookStatusChip extends StatelessWidget {
  const BookStatusChip({
    required this.label,
    this.tone = BookStatusTone.neutral,
    super.key,
  });

  final String label;
  final BookStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final (Color fg, Color bg) = switch (tone) {
      BookStatusTone.success => (
          Colors.white,
          AppColors.success,
        ),
      BookStatusTone.pending => (
          Colors.white,
          AppColors.pending,
        ),
      BookStatusTone.danger => (
          Colors.white,
          AppColors.danger,
        ),
      BookStatusTone.accent => (
          onPrimary,
          primary,
        ),
      BookStatusTone.neutral => (
          isDark ? Colors.white : AppColors.textPrimaryLight,
          isDark
              ? AppColors.customerAccent.withValues(alpha: 0.22)
              : AppColors.elevated(false),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r24),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum BookStatusTone { neutral, accent, success, pending, danger }
