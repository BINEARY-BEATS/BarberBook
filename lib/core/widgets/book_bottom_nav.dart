import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BookBottomNavItem {
  const BookBottomNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Floating pill bottom navigation for customer / barber shells.
class BookBottomNav extends StatelessWidget {
  const BookBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.useCustomerAccent = false,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BookBottomNavItem> items;
  final bool useCustomerAccent;

  @override
  Widget build(BuildContext context) {
    final accent = useCustomerAccent
        ? AppColors.customerAccent
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(AppRadius.r24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < items.length; i++)
              _NavItem(
                item: items[i],
                selected: currentIndex == i,
                accent: accent,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final BookBottomNavItem item;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Icon(
          selected ? item.selectedIcon : item.icon,
          color: selected ? accent : Colors.white54,
          size: 24,
        ),
      ),
    );
  }
}
