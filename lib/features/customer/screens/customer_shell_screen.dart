import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/book_bottom_nav.dart';
import '../../chat/screens/chat_inbox_screen.dart';
import 'customer_home_screen.dart';
import 'customer_my_bookings_screen.dart';
import 'customer_profile_screen.dart';

/// Customer bottom-nav shell: Home · Bookings · Messages · Profile.
class CustomerShellScreen extends StatefulWidget {
  const CustomerShellScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<CustomerShellScreen> createState() => _CustomerShellScreenState();
}

class _CustomerShellScreenState extends State<CustomerShellScreen> {
  late int _index;

  static const _items = [
    BookBottomNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    BookBottomNavItem(
      label: 'Bookings',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today_rounded,
    ),
    BookBottomNavItem(
      label: 'Messages',
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
    ),
    BookBottomNavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab.clamp(0, 3);
  }

  @override
  void didUpdateWidget(covariant CustomerShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _index = widget.initialTab.clamp(0, 3);
    }
  }

  void _onTap(int i) {
    setState(() => _index = i);
    context.go('/customer/home?tab=$i');
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.customer(),
      child: Scaffold(
        backgroundColor: AppTheme.customer().scaffoldBackgroundColor,
        extendBody: true,
        body: IndexedStack(
          index: _index,
          children: const [
            CustomerHomeScreen(),
            CustomerMyBookingsScreen(embedded: true),
            ChatInboxScreen(embedded: true, basePath: '/customer'),
            CustomerProfileScreen(),
          ],
        ),
        bottomNavigationBar: BookBottomNav(
          currentIndex: _index,
          onTap: _onTap,
          items: _items,
          useCustomerAccent: true,
        ),
      ),
    );
  }
}
