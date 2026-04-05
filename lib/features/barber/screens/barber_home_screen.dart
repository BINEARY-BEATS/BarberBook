import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../core/utils/demo_seeder.dart';
import '../providers/barber_provider.dart';
import '../widgets/queue_manager_widget.dart';

class BarberHomeScreen extends ConsumerStatefulWidget {
  const BarberHomeScreen({super.key});

  @override
  ConsumerState<BarberHomeScreen> createState() => _BarberHomeScreenState();
}

class _BarberHomeScreenState extends ConsumerState<BarberHomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            _TodayTab(),
            const Center(child: Text('Schedule Coming Soon', style: TextStyle(color: Colors.white24))),
            _ProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: _MinimalNavBar(
        index: _tabIndex,
        onChanged: (i) => setState(() => _tabIndex = i),
      ),
    );
  }
}

class _MinimalNavBar extends StatelessWidget {
  const _MinimalNavBar({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 70,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavIcon(icon: Icons.grid_view_rounded, active: index == 0, onTap: () => onChanged(0)),
          _NavIcon(icon: Icons.calendar_month_rounded, active: index == 1, onTap: () => onChanged(1)),
          _NavIcon(icon: Icons.person_rounded, active: index == 2, onTap: () => onChanged(2)),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.active, required this.onTap});
  final IconData icon; final bool active; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Icon(icon, color: active ? cs.secondary : Colors.white.withOpacity(0.2), size: 26),
    );
  }
}

class _TodayTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final asyncAppointments = ref.watch(todayAppointmentsProvider(user?.uid ?? ''));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BARBERBOOK', style: theme.textTheme.labelLarge),
                const SizedBox(height: 12),
                Text('Waitlist Overview', style: theme.textTheme.displayMedium?.copyWith(fontSize: 32)),
                const SizedBox(height: 32),
                const QueueManagerWidget(),
                const SizedBox(height: 48),
                Text('UPCOMING APPOINTMENTS', style: theme.textTheme.labelLarge),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        asyncAppointments.when(
          data: (apps) {
            if (apps.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(child: Text('No entries for today', style: TextStyle(color: Colors.white12))),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _AppointmentCard(app: apps[index]),
                  childCount: apps.length,
                ),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
          error: (e, __) => SliverToBoxAdapter(child: Text('Error: $e')),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.app});
  final Map<String, dynamic> app;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = app[FirestoreKeys.appointmentCustomerName] ?? 'Guest';
    final slot = app[FirestoreKeys.appointmentSlot] as Timestamp?;
    final timeStr = slot != null ? '${slot.toDate().hour.toString().padLeft(2, '0')}:${slot.toDate().minute.toString().padLeft(2, '0')}' : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Text(timeStr, style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.w300, color: cs.secondary)),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 1)),
              Text('Confirmed', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.3))),
            ],
          ),
          const Spacer(),
          const Icon(Icons.verified_rounded, color: Colors.white10, size: 16),
        ],
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        Text('SETTINGS', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 48),
        _SettingsTile(icon: Icons.logout_rounded, label: 'Sign Out', onTap: () => FirebaseAuth.instance.signOut()),
        const SizedBox(height: 12),
        _SettingsTile(icon: Icons.data_usage_rounded, label: 'Seed Sample Data', onTap: () async {
          if (user != null) {
            await DemoSeeder.seedBarberData(user.uid);
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sample data generated.')));
          }
        }),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    ),
  );
}
