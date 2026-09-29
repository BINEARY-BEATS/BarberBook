import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/demo_seeder.dart';
import '../../../core/widgets/book_appointment_row.dart';
import '../../../core/widgets/book_bottom_nav.dart';
import '../../../core/widgets/book_empty_state.dart';
import '../../../core/widgets/book_list_tile.dart';
import '../../../core/widgets/book_section_header.dart';
import '../../../core/widgets/book_stat_card.dart';
import '../../../core/widgets/book_status_chip.dart';
import '../../../core/widgets/portfolio_image.dart';
import '../../appointments/data/appointment_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../portfolio/data/portfolio_repository.dart';
import '../providers/barber_provider.dart';
import '../widgets/queue_manager_widget.dart';

class BarberHomeScreen extends ConsumerStatefulWidget {
  const BarberHomeScreen({super.key});

  @override
  ConsumerState<BarberHomeScreen> createState() => _BarberHomeScreenState();
}

class _BarberHomeScreenState extends ConsumerState<BarberHomeScreen> {
  int _tabIndex = 0;

  static const _items = [
    BookBottomNavItem(
      label: 'Dashboard',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
    ),
    BookBottomNavItem(
      label: 'Schedule',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_month_rounded,
    ),
    BookBottomNavItem(
      label: 'Customers',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
    ),
    BookBottomNavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: const [
            _TodayTab(),
            _ScheduleTab(),
            _CustomersTab(),
            _ProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: BookBottomNav(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: _items,
      ),
    );
  }
}

class _TodayTab extends ConsumerWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final firstName =
        (user?.displayName ?? 'Barber').split(' ').first;
    final barberAsync = ref.watch(currentBarberProvider(uid));
    final appsAsync = ref.watch(todayAppointmentsProvider(uid));
    final statsAsync = ref.watch(barberStatsProvider(uid));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accentSoft,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Text(
                          firstName.isNotEmpty
                              ? firstName[0].toUpperCase()
                              : 'B',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey, $firstName',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMM d').format(DateTime.now()),
                        style: TextStyle(
                          color: AppColors.secondaryText(isDark),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                barberAsync.when(
                  data: (b) {
                    final online = b?.isActive ?? false;
                    return InkWell(
                      onTap: () {
                        if (b == null) return;
                        ref
                            .read(barberRepositoryProvider)
                            .setActiveStatus(uid, !online);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: BookStatusChip(
                        label: online ? 'Online' : 'Offline',
                        tone: online
                            ? BookStatusTone.success
                            : BookStatusTone.danger,
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: statsAsync.when(
              data: (stats) {
                final totalLabel = stats.totalBookings >= 1000
                    ? '${(stats.totalBookings / 1000).toStringAsFixed(1)}K'
                    : '${stats.totalBookings}';
                return Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: BookStatCard(
                              label: 'Total Bookings',
                              value: totalLabel,
                              icon: Icons.groups_rounded,
                              trend: '+8%',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: BookStatCard(
                              label: "Today's Schedule",
                              value: '${stats.todayCount}',
                              icon: Icons.event_available_rounded,
                              progress: stats.scheduleProgress,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: BookStatCard(
                              label: 'Retention',
                              value:
                                  '${(stats.retention * 100).round()}%',
                              icon: Icons.favorite_rounded,
                              progress: stats.retention,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: BookStatCard(
                              label: 'Productivity',
                              value:
                                  '${(stats.productivity * 100).round()}%',
                              icon: Icons.bolt_rounded,
                              progress: stats.productivity,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
        const SliverToBoxAdapter(
          child: BookSectionHeader(title: 'Walk-in Queue'),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: QueueManagerWidget(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
        const SliverToBoxAdapter(
          child: BookSectionHeader(title: 'Confirmed Today'),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        appsAsync.when(
          data: (apps) {
            final confirmed = apps
                .where(
                  (a) =>
                      a.status ==
                          FirestoreKeys.appointmentStatusConfirmed ||
                      a.status ==
                          FirestoreKeys.appointmentStatusCompleted,
                )
                .toList();
            if (confirmed.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: BookEmptyState(
                    icon: Icons.event_busy_rounded,
                    title: 'No appointments today',
                    subtitle: 'New bookings will show up here.',
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final app = confirmed[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BookAppointmentRow(
                        appointment: app,
                        showActions: true,
                        onTap: () => context
                            .push('/barber/customer/${app.id}'),
                        onComplete: () => ref
                            .read(appointmentRepositoryProvider)
                            .completeAppointment(app.id),
                        onCancel: () => ref
                            .read(appointmentRepositoryProvider)
                            .cancelAppointment(app.id),
                      ),
                    );
                  },
                  childCount: confirmed.length,
                ),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
          ),
          error: (e, _) => SliverToBoxAdapter(child: Text('$e')),
        ),
      ],
    );
  }
}

class _ScheduleTab extends ConsumerStatefulWidget {
  const _ScheduleTab();
  @override
  ConsumerState<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends ConsumerState<_ScheduleTab> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final monday = _selected.subtract(Duration(days: _selected.weekday - 1));
    final week = List.generate(7, (i) => monday.add(Duration(days: i)));
    final appsAsync = ref.watch(
      barberDayAppointmentsProvider((barberId: uid, day: _selected)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schedule',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('EEE, d MMM yy').format(_selected),
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 78,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: week.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final d = week[i];
              final sel = d.year == _selected.year &&
                  d.month == _selected.month &&
                  d.day == _selected.day;
              return InkWell(
                onTap: () => setState(() => _selected = d),
                borderRadius: BorderRadius.circular(AppRadius.r16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 56,
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.accent
                        : AppColors.card(isDark),
                    borderRadius: BorderRadius.circular(AppRadius.r16),
                    boxShadow: sel || isDark ? null : AppColors.cardShadow,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(d).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: sel
                              ? Colors.white70
                              : AppColors.secondaryText(isDark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: sel
                              ? Colors.white
                              : AppColors.onSurface(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: appsAsync.when(
            data: (apps) {
              if (apps.isEmpty) {
                return BookEmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'Nothing booked',
                  subtitle:
                      '${DateFormat('MMM d').format(_selected)} is free so far.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: apps.length,
                itemBuilder: (context, i) {
                  final app = apps[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BookAppointmentRow(
                      appointment: app,
                      showActions: true,
                      onTap: () =>
                          context.push('/barber/customer/${app.id}'),
                      onComplete: () => ref
                          .read(appointmentRepositoryProvider)
                          .completeAppointment(app.id),
                      onCancel: () => ref
                          .read(appointmentRepositoryProvider)
                          .cancelAppointment(app.id),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            error: (e, _) => Center(child: Text('$e')),
          ),
        ),
      ],
    );
  }
}

class _CustomersTab extends ConsumerStatefulWidget {
  const _CustomersTab();
  @override
  ConsumerState<_CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends ConsumerState<_CustomersTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final appsAsync = ref.watch(todayAppointmentsProvider(uid));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Text(
            'Customers',
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: TextField(
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search customer…',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.mutedText(isDark),
              ),
            ),
          ),
        ),
        Expanded(
          child: appsAsync.when(
            data: (apps) {
              final filtered = apps.where((a) {
                if (_query.isEmpty) return true;
                return a.customerName.toLowerCase().contains(_query) ||
                    a.service.name.toLowerCase().contains(_query);
              }).toList();
              if (filtered.isEmpty) {
                return const BookEmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'No customers yet',
                  subtitle: "Today's bookings will appear here.",
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final app = filtered[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BookAppointmentRow(
                      appointment: app,
                      onTap: () =>
                          context.push('/barber/customer/${app.id}'),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            error: (e, _) => Center(child: Text('$e')),
          ),
        ),
      ],
    );
  }
}

class _ProfileTab extends ConsumerStatefulWidget {
  const _ProfileTab();

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    if (_uploading) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final barber = await ref.read(currentBarberProvider(uid).future);
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 55,
      maxWidth: 900,
    );
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      await ref.read(portfolioRepositoryProvider).uploadPhoto(
            barberId: uid,
            file: File(file.path),
            isPro: barber?.isPro ?? false,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barberAsync = ref.watch(currentBarberProvider(uid));
    final portfolioAsync = ref.watch(barberPortfolioProvider(uid));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Text('Profile', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        barberAsync.when(
          data: (b) => Text(
            b?.shopName.isNotEmpty == true ? b!.shopName : 'Your shop',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),
        barberAsync.when(
          data: (b) {
            if (b?.isPro == true) {
              return const Align(
                alignment: Alignment.centerLeft,
                child: BookStatusChip(
                  label: 'Pro member',
                  tone: BookStatusTone.accent,
                ),
              );
            }
            return BookListTile(
              leading: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.accent,
              ),
              title: 'Upgrade to Pro',
              subtitle: 'Unlimited portfolio · featured listing',
              onTap: () => context.push('/barber/paywall'),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text(
              'Portfolio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _uploading ? null : _pickAndUpload,
              icon: _uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(_uploading ? 'Uploading…' : 'Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        portfolioAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                  boxShadow: isDark ? null : AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_library_outlined,
                        color: AppColors.accent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No photos yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.onSurface(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap Add to showcase your best cuts.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.secondaryText(isDark),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, i) {
                final item = items[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PortfolioImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => ref
                              .read(portfolioRepositoryProvider)
                              .deletePhoto(item),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          error: (e, _) => Text(
            'Could not load portfolio: $e',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
        const SizedBox(height: 28),
        BookListTile(
          leading: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.accent,
          ),
          title: 'Messages',
          onTap: () => context.push('/barber/messages'),
        ),
        const SizedBox(height: 10),
        BookListTile(
          leading: const Icon(
            Icons.help_outline_rounded,
            color: AppColors.accent,
          ),
          title: 'Help Center',
          onTap: () => context.push('/legal/help'),
        ),
        const SizedBox(height: 10),
        BookListTile(
          leading: const Icon(
            Icons.privacy_tip_outlined,
            color: AppColors.accent,
          ),
          title: 'Privacy Policy',
          onTap: () => context.push('/legal/privacy'),
        ),
        const SizedBox(height: 10),
        BookListTile(
          leading: const Icon(
            Icons.description_outlined,
            color: AppColors.accent,
          ),
          title: 'Terms & Conditions',
          onTap: () => context.push('/legal/terms'),
        ),
        const SizedBox(height: 10),
        BookListTile(
          leading: const Icon(
            Icons.info_outline_rounded,
            color: AppColors.accent,
          ),
          title: 'About App',
          onTap: () => context.push('/legal/about'),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 10),
          BookListTile(
            leading: const Icon(
              Icons.data_usage_rounded,
              color: AppColors.accent,
            ),
            title: 'Seed sample data',
            onTap: () async {
              await DemoSeeder.seedBarberData(uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sample data ready.')),
                );
              }
            },
          ),
        ],
        const SizedBox(height: 10),
        BookListTile(
          leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
          title: 'Sign out',
          onTap: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
    );
  }
}
