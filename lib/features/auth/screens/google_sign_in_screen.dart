import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

/// Google sign-in entry. Does **not** require a role: returning users go straight
/// to [/splash], which loads their Firestore profile and opens the right home.
///
/// If GoRouter `extra` includes `role` (legacy), that role is applied after sign-in
/// (merge write). Prefer using [RoleSelectScreen] after sign-in for new accounts.
class GoogleSignInScreen extends ConsumerStatefulWidget {
  /// Creates the Google sign-in screen.
  const GoogleSignInScreen({super.key});

  @override
  ConsumerState<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends ConsumerState<GoogleSignInScreen> {
  bool _busy = false;

  String? _extractOptionalRole() {
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, dynamic>) {
      final roleValue = extra['role'];
      if (roleValue is String) return roleValue;
    }
    return null;
  }

  Future<void> _onContinueWithGoogle() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final credential = await repo.signInWithGoogle();
      if (!mounted) return;
      if (credential == null) return;

      final user = credential.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in but no user was returned.')),
        );
        return;
      }

      final role = _extractOptionalRole();
      if (role != null) {
        await repo.applyRoleToFirestore(role: role, user: user);
      }

      if (!mounted) return;
      context.go('/splash');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final hint = (e.message ?? '').contains('id_token') ||
              (e.message ?? '').toLowerCase().contains('token')
          ? ' Set kGoogleSignInWebClientId in lib/firebase/google_sign_in_config.dart '
              '(Firebase → Authentication → Google → Web client ID).'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${e.message ?? 'Google sign-in failed.'}$hint'),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google sign-in failed: $e. On Android, set '
            'kGoogleSignInWebClientId in lib/firebase/google_sign_in_config.dart.',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/splash');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome back',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in with Google. If you already have a BarberBook profile, '
                'we’ll open your home automatically.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'New here? After signing in, you’ll choose Barber or Customer once.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _busy ? null : _onContinueWithGoogle,
                icon: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(_busy ? 'Signing in…' : 'Continue with Google'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
