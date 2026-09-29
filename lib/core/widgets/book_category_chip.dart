import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BookCategoryItem {
  const BookCategoryItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

/// Horizontal category scroller — icon circle + label.
class BookCategoryRow extends StatelessWidget {
  const BookCategoryRow({
    required this.items,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  final List<BookCategoryItem> items;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final onAccent = Theme.of(context).colorScheme.onPrimary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = selectedId == item.id;
          return GestureDetector(
            onTap: () => onSelected(selected ? null : item.id),
            child: SizedBox(
              width: 64,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? accent
                          : (isDark
                              ? AppColors.surfaceElevated
                              : AppColors.accentSoft),
                      border: Border.all(
                        color: selected
                            ? accent
                            : (isDark
                                ? AppColors.customerBorder
                                : Colors.transparent),
                      ),
                    ),
                    child: Icon(
                      item.icon,
                      color: selected
                          ? onAccent
                          : accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.onSurface(isDark)
                          : AppColors.secondaryText(isDark),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
