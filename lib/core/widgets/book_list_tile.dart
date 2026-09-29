import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Settings-row style tile with soft card elevation.
class BookListTile extends StatelessWidget {
  const BookListTile({
    required this.title,
    required this.onTap,
    this.leading,
    this.subtitle,
    this.trailing,
    this.showChevron = true,
    super.key,
  });

  final String title;
  final VoidCallback onTap;
  final Widget? leading;
  final String? subtitle;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: AppColors.card(isDark),
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(AppRadius.r16),
            boxShadow: isDark ? null : AppColors.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.onSurface(isDark),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText(isDark),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
                if (showChevron)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.mutedText(isDark),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
