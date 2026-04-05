import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../branding/barberbook_logo.dart';
import 'role_home_resolver.dart';

/// First paint users see: branding + loader while auth / routing is resolved.
///
/// This avoids a blank screen caused by [GoRouter] async redirects blocking the
/// first frame while waiting on Firestore.
class SplashScreen extends StatefulWidget {
  /// Creates the splash screen.
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_boot()));
  }

  /// Decides where to send the user after Firebase Auth is known.
  Future<void> _boot() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      context.go('/auth/sign-in');
      return;
    }

    try {
      final home = await resolveRoleHomeForUid(user.uid)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      context.go(home);
    } on TimeoutException {
      if (!mounted) return;
      context.go('/auth/sign-in');
    } catch (_) {
      if (!mounted) return;
      context.go('/auth/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1A1A2E);
    const accent = Color(0xFFE94560);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary,
              Color(0xFF16213E),
              primary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BarberBookLogo(size: 112, showTile: true),
              const SizedBox(height: 24),
              Text(
                'BarberBook',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Book cuts. Skip the wait.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
