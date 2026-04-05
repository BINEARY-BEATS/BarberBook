import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../core/widgets/book_empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/barber_provider.dart';
import '../widgets/queue_manager_widget.dart';

/// Home screen for barber accounts (queue + schedule + profile).
class BarberHomeScreen extends ConsumerStatefulWidget {
  /// Creates the barber home screen.
  const BarberHomeScreen({super.key});

  @override
  ConsumerState<BarberHomeScreen> createState() => _BarberHomeScreenState();
}

class _BarberHomeScreenState extends ConsumerState<BarberHomeScreen> {
  int _tabIndex = 0;

  static const List<String> _tabLabels = <String>[
    'Today',
    'Schedule',
    'Profile',
  ];

  Future<void> _onToggleOnline(bool isActive, String barberId) async {
    final repo = ref.read(barberRepositoryProvider);
    await repo.setActiveStatus(barberId, isActive);
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    context.go('/splash');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in again.')),
      );
    }

    final barberAsync = ref.watch(currentBarberProvider(user.uid));

    return barberAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('BarberBook')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: const Text('BarberBook'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/splash'),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: BookEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load your shop',
              subtitle: e.toString(),
              action: FilledButton(
                onPressed: () => context.go('/splash'),
                child: const Text('Back to start'),
              ),
            ),
          ),
        ),
      ),
      data: (barber) {
        final shopName = (barber?.shopName ?? '').trim().isEmpty
            ? 'Your shop'
            : barber!.shopName;
        final isActive = barber?.isActive ?? false;
        final email = user.email ?? '';

        return Scaffold(
          drawer: Drawer(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DrawerHeader(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primary,
                          cs.primary.withOpacity(0.85),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: cs.onPrimary.withOpacity(0.2),
                          child: Icon(
                            Icons.storefront_rounded,
                            size: 32,
                            color: cs.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          shopName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onPrimary.withOpacity(0.9),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.today_rounded),
                    title: const Text('Today'),
                    selected: _tabIndex == 0,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _tabIndex = 0);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month_rounded),
                    title: const Text('Schedule'),
                    selected: _tabIndex == 1,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _tabIndex = 1);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_rounded),
                    title: const Text('Profile'),
                    selected: _tabIndex == 2,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _tabIndex = 2);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout_rounded, color: cs.error),
                    title: Text(
                      'Sign out',
                      style: TextStyle(color: cs.error),
                    ),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _signOut();
                    },
                  ),
                ],
              ),
            ),
          ),
          appBar: AppBar(
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Menu',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  shopName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _tabLabels[_tabIndex],
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Online',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: isActive,
                      onChanged: (v) => _onToggleOnline(v, user.uid),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _tabIndex == 0
                ? _TodayTab(key: const ValueKey(0), barberId: user.uid)
                : _tabIndex == 1
                    ? const _ScheduleTab(key: ValueKey(1))
                    : const _ProfileTab(key: ValueKey(2)),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (i) => setState(() => _tabIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.today_outlined),
                selectedIcon: Icon(Icons.today_rounded),
                label: 'Today',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Schedule',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Today tab content for barber (queue + today's appointments).
class _TodayTab extends ConsumerWidget {
  /// Creates the today tab.
  const _TodayTab({required this.barberId, super.key});

  final String barberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(todayAppointmentsProvider(barberId));
    return appointmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: BookEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Appointments unavailable',
          subtitle: _friendlyAppointmentError(e.toString()),
          action: OutlinedButton.icon(
            onPressed: () => ref.invalidate(todayAppointmentsProvider(barberId)),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ),
      ),
      data: (docs) {
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            QueueManagerWidget(barberId: barberId),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.event_available_rounded, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Confirmed today',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
            _AppointmentsList(docs: docs),
          ],
        );
      },
    );
  }
}

String _friendlyAppointmentError(String raw) {
  if (raw.contains('index') && raw.contains('building')) {
    return 'Your Firestore index is still building. Wait a few minutes and pull to refresh, or check the Firebase Console → Firestore → Indexes.';
  }
  if (raw.contains('index')) {
    return 'Firestore needs a composite index for this query. Use the link in the debug console or Firebase → Indexes to create it.';
  }
  return raw;
}

/// Schedule tab content for barber.
class _ScheduleTab extends StatelessWidget {
  /// Creates the schedule tab.
  const _ScheduleTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        BookEmptyState(
          icon: Icons.schedule_rounded,
          title: 'Availability & slots',
          subtitle:
              'Set working hours and bookable slots so customers know when you are free.',
          action: FilledButton.icon(
            onPressed: () => context.push('/barber/manage-slots'),
            icon: const Icon(Icons.edit_calendar_rounded),
            label: const Text('Manage slots'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Card(
          elevation: 0,
          color: cs.surfaceContainerHighest.withOpacity(0.45),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_outlined, color: cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tip: Turn Online on from the Today tab when you are open for walk-ins.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Profile tab content for barber.
class _ProfileTab extends StatelessWidget {
  /// Creates the profile tab.
  const _ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Business',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: 12),
        _ProfileActionCard(
          icon: Icons.photo_library_rounded,
          title: 'Portfolio',
          subtitle: 'Show your cuts and styles',
          onTap: () => context.push('/barber/portfolio'),
        ),
        const SizedBox(height: 12),
        _ProfileActionCard(
          icon: Icons.payments_rounded,
          title: 'Earnings',
          subtitle: 'Track revenue and payouts',
          onTap: () => context.push('/barber/earnings'),
        ),
        const SizedBox(height: 28),
        Text(
          'Growth',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: 12),
        _ProfileActionCard(
          icon: Icons.workspace_premium_rounded,
          title: 'BarberBook Pro',
          subtitle: 'Unlock premium tools',
          onTap: () => context.push('/barber/paywall'),
        ),
      ],
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest.withOpacity(0.55),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: cs.primary, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small helper widget to list confirmed appointments for today.
class _AppointmentsList extends StatelessWidget {
  /// Creates the appointments list.
  const _AppointmentsList({required this.docs});

  final List<Map<String, dynamic>> docs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (docs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 0,
          color: cs.surfaceContainerHighest.withOpacity(0.4),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            child: BookEmptyState(
              icon: Icons.event_busy_rounded,
              title: 'No bookings today',
              subtitle: 'Confirmed appointments for today will show up here.',
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(docs.length, (index) {
          final doc = docs[index];
          final customerName =
              (doc[FirestoreKeys.appointmentCustomerName] as String?) ?? '';
          final slot = doc[FirestoreKeys.appointmentSlot];
          final status = doc[FirestoreKeys.appointmentStatus] as String? ?? '';

          String slotText = '';
          if (slot is Timestamp) {
            slotText = TimeOfDay.fromDateTime(slot.toDate()).format(context);
          } else if (slot is DateTime) {
            slotText = TimeOfDay.fromDateTime(slot).format(context);
          }

          return Padding(
            padding: EdgeInsets.only(bottom: index < docs.length - 1 ? 10 : 0),
            child: Card(
              elevation: 0,
              color: cs.surfaceContainerHighest.withOpacity(0.5),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.person_rounded, color: cs.onPrimaryContainer),
                ),
                title: Text(
                  customerName.isEmpty ? 'Customer' : customerName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(slotText.isEmpty ? 'Time TBD' : slotText),
                trailing: Chip(
                  label: Text(status),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
