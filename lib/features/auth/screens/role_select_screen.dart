import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});
  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  bool _busy = false;
  String? _selected;

  Future<void> _chooseRole(String role) async {
    if (_busy) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/auth/sign-in');
      return;
    }
    setState(() {
      _busy = true;
      _selected = role;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .applyRoleToFirestore(role: role, user: user);
      if (!mounted) return;
      if (role == FirestoreKeys.roleBarber) {
        context.go('/barber/onboarding');
      } else {
        context.go('/customer/onboarding');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _selected = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save role: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) context.go('/auth/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout_rounded, size: 20),
          tooltip: 'Sign out',
          onPressed: _busy ? null : _signOut,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How will you use BarberBook?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Choose once. You’ll set up your profile next — this can’t be '
                'changed later without support.',
                style: TextStyle(
                  color: AppColors.secondaryText(isDark),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              _RoleCard(
                title: 'I’m a Customer',
                subtitle: 'Find shops nearby, book slots, and message barbers.',
                icon: Icons.person_search_rounded,
                selected: _selected == FirestoreKeys.roleCustomer,
                busy: _busy && _selected == FirestoreKeys.roleCustomer,
                enabled: !_busy,
                onTap: () => _chooseRole(FirestoreKeys.roleCustomer),
              ),
              const SizedBox(height: 14),
              _RoleCard(
                title: 'I’m a Barber',
                subtitle: 'Set up your shop, hours, services, and queue.',
                icon: Icons.content_cut_rounded,
                selected: _selected == FirestoreKeys.roleBarber,
                busy: _busy && _selected == FirestoreKeys.roleBarber,
                enabled: !_busy,
                onTap: () => _chooseRole(FirestoreKeys.roleBarber),
              ),
              const Spacer(),
              Text(
                'Signed in as ${FirebaseAuth.instance.currentUser?.email ?? 'Google account'}',
                style: TextStyle(
                  color: AppColors.mutedText(isDark),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.selected,
    required this.busy,
    required this.enabled,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final bool busy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: AppColors.card(isDark),
      borderRadius: BorderRadius.circular(AppRadius.r20),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.r20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.r20),
            border: Border.all(
              color: selected ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
            boxShadow: isDark ? null : AppColors.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                ),
                child: busy
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: selected ? Colors.white : AppColors.accent,
                        ),
                      )
                    : Icon(
                        icon,
                        color: selected ? Colors.white : AppColors.accent,
                        size: 26,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: AppColors.onSurface(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.secondaryText(isDark),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.mutedText(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
