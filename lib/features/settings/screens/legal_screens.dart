import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/book_subpage_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BookSubpageScaffold(
      title: 'Privacy Policy',
      fallbackLocation: '/customer/home',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'We collect account info (name, email, photo), location for nearby shops, '
            'and booking/chat data needed to run BarberBook.\n\n'
            'Data is stored in Firebase and used only to provide booking, queue, '
            'messaging, and notifications. We do not sell personal data.\n\n'
            'You can request deletion by signing out and contacting support via Help Center.',
            style: TextStyle(
              color: AppColors.secondaryText(isDark),
              height: 1.55,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BookSubpageScaffold(
      title: 'Terms & Conditions',
      fallbackLocation: '/customer/home',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'By using BarberBook you agree to book in good faith, respect shop policies, '
            'and not misuse messaging or reviews.\n\n'
            'Barbers are responsible for accurate hours, services, and availability. '
            'Appointments may be cancelled by either party according to shop rules.\n\n'
            'Pro subscriptions are managed through the app store / RevenueCat and renew '
            'until cancelled.',
            style: TextStyle(
              color: AppColors.secondaryText(isDark),
              height: 1.55,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return BookSubpageScaffold(
      title: 'About App',
      fallbackLocation: '/customer/home',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.content_cut_rounded,
                color: AppColors.onAccent,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'BarberBook',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText(isDark)),
          ),
          const SizedBox(height: 24),
          Text(
            'Book nearby barbers, manage queues, and chat with your shop — '
            'inspired by modern salon app design.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.secondaryText(isDark),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
