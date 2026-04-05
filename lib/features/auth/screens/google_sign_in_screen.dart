import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class GoogleSignInScreen extends ConsumerStatefulWidget {
  const GoogleSignInScreen({super.key});
  @override
  ConsumerState<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends ConsumerState<GoogleSignInScreen> {
  bool _busy = false;

  Future<void> _onContinueWithGoogle() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final credential = await repo.signInWithGoogle();
      if (credential == null) return;
      if (mounted) context.go('/splash');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.go('/splash'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AUTHENTICATION', style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              Text('Continue to BarberBook', style: theme.textTheme.displayMedium),
              const SizedBox(height: 16),
              const Text('Access your professional workspace or book your next session with a single tap.', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w300)),
              const SizedBox(height: 80),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton(
                  onPressed: _busy ? null : _onContinueWithGoogle,
                  child: _busy ? const CircularProgressIndicator(color: Colors.black) : const Text('CONTINUE WITH GOOGLE'),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'By continuing, you agree to our terms and elite grooming standards.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
