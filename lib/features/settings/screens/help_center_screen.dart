import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/book_subpage_scaffold.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _faqs = [
    (
      'How do I book an appointment?',
      'Open a shop from Home, pick a service, choose a date and time, then tap Book Now.'
    ),
    (
      'How does the walk-in queue work?',
      'If a shop is online, join their walk-in queue from the shop page. Leave anytime from the same screen.'
    ),
    (
      'Can I message my barber?',
      'Yes. Open a shop and tap Message, or use the Messages tab.'
    ),
    (
      'How do I cancel a booking?',
      'Go to My Bookings and tap cancel on a confirmed appointment.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BookSubpageScaffold(
      title: 'Help Center',
      fallbackLocation: '/customer/home',
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _faqs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final faq = _faqs[i];
          return Container(
            decoration: BoxDecoration(
              color: AppColors.card(isDark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider(isDark)),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Text(
                faq.$1,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface(isDark),
                ),
              ),
              children: [
                Text(
                  faq.$2,
                  style: TextStyle(
                    color: AppColors.secondaryText(isDark),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
