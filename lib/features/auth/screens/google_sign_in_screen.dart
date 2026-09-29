import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/barberbook_logo.dart';
import '../../../core/constants/firestore_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/book_primary_button.dart';
import '../providers/auth_provider.dart';

class GoogleSignInScreen extends ConsumerStatefulWidget {
  const GoogleSignInScreen({super.key});
  @override
  ConsumerState<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends ConsumerState<GoogleSignInScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _onContinueWithGoogle() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final credential =
          await ref.read(authRepositoryProvider).signInWithGoogle();
      if (credential == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      if (mounted) context.go('/splash');
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Sign-in failed. Please try again.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      }
    }
  }

  Future<void> _onTestAs(String role) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInAsDemo(role: role);
      if (mounted) {
        context.go(
          role == FirestoreKeys.roleBarber ? '/barber/home' : '/customer/home',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not start demo. Check Firebase Auth (Anonymous).';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Demo login failed: $e')),
        );
      }
    }
  }

  Future<void> _showDemoPicker() async {
    if (_busy) return;
    final role = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.customerCard,
      builder: (ctx) {
        return Theme(
          data: AppTheme.customer(),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Test the app',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Jump in with demo shops, bookings, and queue data. No Google account needed.',
                    style: TextStyle(
                      color: AppColors.customerSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DemoRoleTile(
                    icon: Icons.content_cut_rounded,
                    title: 'Test as Barber',
                    subtitle: 'Dashboard, schedule, queue & customers',
                    onTap: () => Navigator.pop(ctx, FirestoreKeys.roleBarber),
                  ),
                  const SizedBox(height: 12),
                  _DemoRoleTile(
                    icon: Icons.person_search_rounded,
                    title: 'Test as Customer',
                    subtitle: 'Browse shops, bookings & messages',
                    onTap: () => Navigator.pop(ctx, FirestoreKeys.roleCustomer),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (role != null) await _onTestAs(role);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: AppTheme.customer(),
      child: Scaffold(
        backgroundColor: AppColors.darkSurface,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1814),
                AppColors.darkSurface,
                Color(0xFF0E0E0E),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const BarberBookLogo(size: 88),
                  const SizedBox(height: 24),
                  Text(
                    'BarberBook',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Discover top barbers and book your look instantly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.customerSecondary,
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.r12),
                      ),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(flex: 3),
                  BookPrimaryButton(
                    label: 'Continue with Google',
                    loading: _busy,
                    icon: Icons.g_mobiledata_rounded,
                    onPressed: _busy ? null : _onContinueWithGoogle,
                  ),
                  const SizedBox(height: 12),
                  BookPrimaryButton(
                    label: 'Test the app',
                    outlined: true,
                    icon: Icons.science_outlined,
                    onPressed: _busy ? null : _showDemoPicker,
                  ),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      text: 'By continuing you agree to the ',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: 'Terms of Service',
                          style: const TextStyle(
                            color: AppColors.customerAccent,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.push('/legal/terms'),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoRoleTile extends StatelessWidget {
  const _DemoRoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: AppColors.customerAccent, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.customerAccent,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.customerOnAccent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.customerSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.customerAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
