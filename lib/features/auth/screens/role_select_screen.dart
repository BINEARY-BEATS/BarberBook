import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/firestore_keys.dart';
import '../providers/auth_provider.dart';

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});
  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  bool _busy = false;

  Future<void> _chooseRole(String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { context.go('/auth/sign-in'); return; }
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).applyRoleToFirestore(role: role, user: user);
      if (mounted) context.go('/splash');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0, leading: IconButton(icon: const Icon(Icons.logout_rounded, size: 20), onPressed: () => ref.read(authRepositoryProvider).signOut())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('IDENTIFY ROLE', style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              Text('Welcome to Elite Grooming', style: theme.textTheme.displayMedium),
              const SizedBox(height: 16),
              const Text('Select your path within the BarberBook ecosystem.', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w300)),
              const SizedBox(height: 80),
              if (_busy) const Center(child: CircularProgressIndicator(color: Colors.white10))
              else ...[
                _RoleCard(title: 'BARBER', subtitle: 'Manage your professional workspace.', icon: Icons.content_cut_rounded, onTap: () => _chooseRole(FirestoreKeys.roleBarber)),
                const SizedBox(height: 20),
                _RoleCard(title: 'CUSTOMER', subtitle: 'Discover and book master barbers.', icon: Icons.person_search_rounded, onTap: () => _chooseRole(FirestoreKeys.roleCustomer)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.title, required this.subtitle, required this.icon, required this.onTap});
  final String title, subtitle; final IconData icon; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(width: 24),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 12)),
        ])),
      ]),
    ),
  );
}
