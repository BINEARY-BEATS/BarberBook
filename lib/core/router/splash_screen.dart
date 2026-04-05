import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'role_home_resolver.dart';

class SplashScreen extends StatefulWidget {
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

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(seconds: 1)); // Small delay for effect
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { if (mounted) context.go('/auth/sign-in'); return; }
    try {
      final home = await resolveRoleHomeForUid(user.uid).timeout(const Duration(seconds: 15));
      if (mounted) context.go(home);
    } catch (_) { if (mounted) context.go('/auth/sign-in'); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.content_cut_rounded, color: Colors.white, size: 64),
            const SizedBox(height: 32),
            Text(
              'BARBERBOOK',
              style: theme.textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w200,
                letterSpacing: 10,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'EST. 2024',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white.withOpacity(0.2),
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 120),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white10),
            ),
          ],
        ),
      ),
    );
  }
}
