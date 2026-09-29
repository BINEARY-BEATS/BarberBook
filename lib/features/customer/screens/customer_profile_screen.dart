import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/book_list_tile.dart';
import '../../auth/providers/auth_provider.dart';

final _profileDocProvider =
    StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection(FirestoreKeys.users)
      .doc(uid)
      .snapshots()
      .map((s) => s.data());
});

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final themeMode = ref.watch(themeModeProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final profile = ref.watch(_profileDocProvider).maybeWhen(
          data: (d) => d,
          orElse: () => null,
        );
    final name = (profile?[FirestoreKeys.userName] as String?)?.trim();
    final email = (profile?[FirestoreKeys.userEmail] as String?)?.trim();
    final displayName = (name != null && name.isNotEmpty)
        ? name
        : (user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!
            : 'Jordan Miles');
    final displayEmail = (email != null && email.isNotEmpty)
        ? email
        : (user?.email ?? 'demo.customer@barberbook.app');
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'J';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          BookScaffoldPadding.bottomNav,
        ),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.customerAccentSoft,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Text(
                        initial,
                        style: TextStyle(
                          color: accent,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayEmail,
                      style: const TextStyle(
                        color: AppColors.customerSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ThemeIcon(
                icon: Icons.brightness_auto_rounded,
                selected: themeMode == ThemeMode.system,
                tooltip: 'System',
                onTap: () =>
                    ref.read(themeModeProvider.notifier).state =
                        ThemeMode.system,
              ),
              const SizedBox(width: 10),
              _ThemeIcon(
                icon: Icons.light_mode_rounded,
                selected: themeMode == ThemeMode.light,
                tooltip: 'Light',
                onTap: () =>
                    ref.read(themeModeProvider.notifier).state =
                        ThemeMode.light,
              ),
              const SizedBox(width: 10),
              _ThemeIcon(
                icon: Icons.dark_mode_rounded,
                selected: themeMode == ThemeMode.dark,
                tooltip: 'Dark',
                onTap: () =>
                    ref.read(themeModeProvider.notifier).state = ThemeMode.dark,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Support',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 12),
          BookListTile(
            title: 'Help Center',
            leading: Icon(Icons.help_outline_rounded, color: accent),
            onTap: () => context.push('/legal/help'),
          ),
          const SizedBox(height: 10),
          BookListTile(
            title: 'Privacy Policy',
            leading: Icon(Icons.privacy_tip_outlined, color: accent),
            onTap: () => context.push('/legal/privacy'),
          ),
          const SizedBox(height: 10),
          BookListTile(
            title: 'Terms & Conditions',
            leading: Icon(Icons.description_outlined, color: accent),
            onTap: () => context.push('/legal/terms'),
          ),
          const SizedBox(height: 10),
          BookListTile(
            title: 'About App',
            leading: Icon(Icons.info_outline_rounded, color: accent),
            onTap: () => context.push('/legal/about'),
          ),
          const SizedBox(height: 28),
          BookListTile(
            title: 'Sign out',
            leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
            showChevron: false,
            onTap: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
    );
  }
}

class _ThemeIcon extends StatelessWidget {
  const _ThemeIcon({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.22)
                : AppColors.customerCard,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            border: Border.all(
              color: selected ? accent : AppColors.customerBorder,
            ),
          ),
          child: Icon(
            icon,
            color: selected ? accent : AppColors.customerSecondary,
          ),
        ),
      ),
    );
  }
}
