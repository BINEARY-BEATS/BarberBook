import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/slot_generator.dart';
import '../../../core/widgets/book_primary_button.dart';
import '../../appointments/data/appointment_repository.dart';
import '../../barber/models/barber_model.dart';
import '../../barber/models/service_model.dart';
import '../../barber/providers/barber_provider.dart';

class CustomerBookingScreen extends ConsumerStatefulWidget {
  const CustomerBookingScreen({
    super.key,
    required this.barberId,
    required this.serviceIndex,
  });
  final String barberId;
  final int serviceIndex;

  @override
  ConsumerState<CustomerBookingScreen> createState() =>
      _CustomerBookingScreenState();
}

class _CustomerBookingScreenState extends ConsumerState<CustomerBookingScreen> {
  late DateTime _selectedDate;
  DateTime? _selectedSlot;
  bool _isBooking = false;
  List<DateTime> _slots = [];
  bool _loadingSlots = false;
  String? _loadedKey;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  Future<void> _ensureSlots(BarberModel barber, ServiceModel service) async {
    final key =
        '${widget.barberId}_${service.name}_${_selectedDate.toIso8601String()}';
    if (_loadedKey == key || _loadingSlots) return;
    setState(() => _loadingSlots = true);
    try {
      final booked = await ref
          .read(appointmentRepositoryProvider)
          .getBookedStartsForDay(widget.barberId, _selectedDate);
      final slots = SlotGenerator.availableSlots(
        barber: barber,
        service: service,
        date: _selectedDate,
        bookedStarts: booked,
      );
      if (mounted) {
        setState(() {
          _slots = slots;
          _selectedSlot = null;
          _loadingSlots = false;
          _loadedKey = key;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingSlots = false;
          _loadedKey = key;
        });
      }
    }
  }

  Future<void> _confirm(BarberModel barber, ServiceModel service) async {
    if (_selectedSlot == null) return;
    setState(() => _isBooking = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await ref.read(appointmentRepositoryProvider).createAppointment({
        FirestoreKeys.appointmentBarberId: widget.barberId,
        FirestoreKeys.appointmentCustomerId: user.uid,
        FirestoreKeys.appointmentCustomerName: user.displayName ?? 'Guest',
        FirestoreKeys.appointmentService: service.toMap(),
        FirestoreKeys.appointmentSlot: Timestamp.fromDate(_selectedSlot!),
      });
      if (mounted) context.go('/customer/home?tab=1');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _shiftMonth(int delta) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + delta,
        1,
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (_selectedDate.isBefore(today)) {
        _selectedDate = today;
      }
      _loadedKey = null;
      _slots = [];
      _selectedSlot = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barberAsync = ref.watch(currentBarberProvider(widget.barberId));
    final dates = List.generate(14, (i) {
      final n = DateTime.now();
      return DateTime(n.year, n.month, n.day).add(Duration(days: i));
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book appointment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: barberAsync.when(
        data: (barber) {
          if (barber == null) {
            return const Center(child: Text('Barber not found.'));
          }
          if (widget.serviceIndex >= barber.services.length) {
            return const Center(child: Text('Service not found.'));
          }
          final service = barber.services[widget.serviceIndex];
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _ensureSlots(barber, service);
          });

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    Text(service.name, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'with ${barber.shopName}',
                      style:
                          TextStyle(color: AppColors.secondaryText(isDark)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _shiftMonth(-1),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Text(
                            DateFormat('MMMM yyyy').format(_selectedDate),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _shiftMonth(1),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select date',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 78,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: dates.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final d = dates[i];
                          final sel = d == _selectedDate;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDate = d;
                                _loadedKey = null;
                                _slots = [];
                                _selectedSlot = null;
                              });
                            },
                            borderRadius:
                                BorderRadius.circular(AppRadius.r16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 60,
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.accent
                                    : AppColors.card(isDark),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.r16),
                                boxShadow: sel || isDark
                                    ? null
                                    : AppColors.cardShadow,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('E').format(d),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: sel
                                          ? AppColors.onAccent
                                          : AppColors.secondaryText(isDark),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${d.day}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: sel
                                          ? AppColors.onAccent
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
                    const SizedBox(height: 28),
                    Text(
                      'Choose a slot',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_loadingSlots)
                      const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      )
                    else if (_slots.isEmpty)
                      Text(
                        'No open slots this day.',
                        style: TextStyle(
                          color: AppColors.secondaryText(isDark),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _slots.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.4,
                        ),
                        itemBuilder: (context, i) {
                          final slot = _slots[i];
                          final sel = _selectedSlot == slot;
                          return InkWell(
                            onTap: () =>
                                setState(() => _selectedSlot = slot),
                            borderRadius:
                                BorderRadius.circular(AppRadius.r12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.accent
                                    : AppColors.card(isDark),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.r12),
                                boxShadow: sel || isDark
                                    ? null
                                    : AppColors.cardShadow,
                              ),
                              child: Text(
                                DateFormat('h:mm a').format(slot),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: sel
                                      ? AppColors.onAccent
                                      : AppColors.onSurface(isDark),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, -2),
                          ),
                        ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedSlot == null
                                  ? '${service.durationMinutes} min'
                                  : DateFormat('EEE, MMM d · h:mm a')
                                      .format(_selectedSlot!),
                              style: TextStyle(
                                color: AppColors.secondaryText(isDark),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '\$${service.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      BookPrimaryButton(
                        label: 'Confirm Booking',
                        loading: _isBooking,
                        onPressed: _selectedSlot == null || _isBooking
                            ? null
                            : () => _confirm(barber, service),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
