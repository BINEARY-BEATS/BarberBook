import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/book_empty_state.dart';
import '../../../core/widgets/book_skeleton.dart';
import '../../../core/widgets/book_status_chip.dart';
import '../../appointments/data/appointment_repository.dart';
import '../../appointments/models/appointment_model.dart';

final customerBookingsProvider =
    StreamProvider.autoDispose<List<AppointmentModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return ref.watch(appointmentRepositoryProvider).getCustomerBookings(uid);
});

class CustomerMyBookingsScreen extends ConsumerStatefulWidget {
  const CustomerMyBookingsScreen({
    super.key,
    this.embedded = false,
  });

  /// When true (inside bottom-nav shell), hide back affordances.
  final bool embedded;

  @override
  ConsumerState<CustomerMyBookingsScreen> createState() =>
      _CustomerMyBookingsScreenState();
}

class _CustomerMyBookingsScreenState
    extends ConsumerState<CustomerMyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<AppointmentModel> _filter(
    List<AppointmentModel> all,
    int tab,
  ) {
    final now = DateTime.now();
    return all.where((b) {
      switch (tab) {
        case 0:
          return b.status == FirestoreKeys.appointmentStatusConfirmed &&
              b.slot.toDate().isAfter(now);
        case 1:
          return b.status == FirestoreKeys.appointmentStatusCompleted ||
              (b.status == FirestoreKeys.appointmentStatusConfirmed &&
                  b.slot.toDate().isBefore(now));
        case 2:
          return b.status == FirestoreKeys.appointmentStatusCancelled;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final asyncBookings = ref.watch(customerBookingsProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: accent,
          unselectedLabelColor: AppColors.customerSecondary,
          indicatorColor: accent,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: asyncBookings.when(
        data: (bookings) {
          return TabBarView(
            controller: _tabs,
            children: List.generate(3, (tab) {
              final list = _filter(bookings, tab);
              if (list.isEmpty) {
                return BookEmptyState(
                  icon: Icons.calendar_month_rounded,
                  title: tab == 0
                      ? 'No upcoming bookings'
                      : tab == 1
                          ? 'No past bookings'
                          : 'No cancelled bookings',
                  subtitle: tab == 0
                      ? 'Reserve a slot from a barber nearby.'
                      : null,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  BookScaffoldPadding.bottomNav,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final b = list[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CustomerBookingTile(
                      appointment: b,
                      onCancel: b.status ==
                              FirestoreKeys.appointmentStatusConfirmed
                          ? () => ref
                              .read(appointmentRepositoryProvider)
                              .cancelAppointment(b.id)
                          : null,
                    ),
                  );
                },
              );
            }),
          );
        },
        loading: () => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: const [
            BookBookingRowSkeleton(),
            SizedBox(height: 10),
            BookBookingRowSkeleton(),
            SizedBox(height: 10),
            BookBookingRowSkeleton(),
          ],
        ),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _CustomerBookingTile extends StatelessWidget {
  const _CustomerBookingTile({
    required this.appointment,
    this.onCancel,
  });

  final AppointmentModel appointment;
  final VoidCallback? onCancel;

  BookStatusTone get _tone {
    final s = appointment.status;
    if (s == FirestoreKeys.appointmentStatusCompleted) {
      return BookStatusTone.success;
    }
    if (s == FirestoreKeys.appointmentStatusCancelled) {
      return BookStatusTone.danger;
    }
    if (s == FirestoreKeys.appointmentStatusConfirmed) {
      return BookStatusTone.neutral;
    }
    return BookStatusTone.neutral;
  }

  String get _statusLabel {
    final s = appointment.status;
    if (s == FirestoreKeys.appointmentStatusCompleted) return 'Completed';
    if (s == FirestoreKeys.appointmentStatusCancelled) return 'Cancelled';
    if (s == FirestoreKeys.appointmentStatusConfirmed) return 'Confirmed';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final when = DateFormat('EEE, MMM d · h:mm a')
        .format(appointment.slot.toDate());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.customerCard,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.customerBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.customerAccentSoft,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Icon(Icons.content_cut_rounded, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.service.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  when,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.customerSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              BookStatusChip(label: _statusLabel, tone: _tone),
              if (onCancel != null) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
