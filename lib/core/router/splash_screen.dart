import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../branding/barberbook_logo.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/book_primary_button.dart';
import 'role_home_resolver.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  String? _status;
  bool _showRetry = false;
  bool _booting = false;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_boot()));
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  Future<void> _boot({bool isRetry = false}) async {
    if (_booting) return;
    _booting = true;
    if (mounted) {
      setState(() {
        _showRetry = false;
        _status = isRetry ? 'Retrying…' : null;
      });
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) {
      _booting = false;
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _booting = false;
      context.go('/auth/sign-in');
      return;
    }

    setState(() => _status = 'Loading your workspace…');

    Future<String> resolveOnce() async {
      await NotificationService.instance.persistTokenForCurrentUser();
      return resolveRoleHomeForUid(user.uid)
          .timeout(const Duration(seconds: 12));
    }

    try {
      final home = await resolveOnce();
      if (mounted) context.go(home);
    } catch (_) {
      if (!mounted) {
        _booting = false;
        return;
      }
      setState(() => _status = 'Still loading…');
      try {
        final home = await resolveOnce();
        if (mounted) context.go(home);
      } catch (_) {
        if (!mounted) {
          _booting = false;
          return;
        }
        setState(() {
          _status = 'Could not load your profile. Check your connection.';
          _showRetry = true;
        });
      }
    } finally {
      _booting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.lightBackground,
      body: FadeTransition(
        opacity: _fade,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.08),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.25),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const BarberBookLogo(size: 88),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'BarberBook',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Book the chair. Own the look.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText(isDark),
                      ),
                    ),
                    const SizedBox(height: 48),
                    if (!_showRetry)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.accent,
                        ),
                      ),
                    if (_status != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _status!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.secondaryText(isDark),
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (_showRetry) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 200,
                        child: BookPrimaryButton(
                          label: 'Retry',
                          onPressed: () => unawaited(_boot(isRetry: true)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
