import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../appointments/data/appointment_repository.dart';
import '../../barber/models/barber_model.dart';
import '../../barber/models/service_model.dart';
import '../../barber/providers/barber_provider.dart';

class CustomerBookingScreen extends ConsumerStatefulWidget {
  const CustomerBookingScreen({super.key, required this.barberId, required this.serviceIndex});
  final String barberId; final int serviceIndex;
  @override
  ConsumerState<CustomerBookingScreen> createState() => _CustomerBookingScreenState();
}

class _CustomerBookingScreenState extends ConsumerState<CustomerBookingScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _isBooking = false;

  final List<TimeOfDay> _availableSlots = [
    const TimeOfDay(hour: 9, minute: 0), const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 11, minute: 0), const TimeOfDay(hour: 13, minute: 0),
    const TimeOfDay(hour: 14, minute: 0), const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 16, minute: 0), const TimeOfDay(hour: 17, minute: 0),
  ];

  Future<void> _confirmBooking(BarberModel barber, ServiceModel service) async {
    if (_selectedTime == null) return;
    setState(() => _isBooking = true);
    final user = FirebaseAuth.instance.currentUser; if (user == null) return;
    
    final slot = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime!.hour, _selectedTime!.minute);
    
    try {
      await ref.read(appointmentRepositoryProvider).createAppointment({
        FirestoreKeys.appointmentBarberId: widget.barberId,
        FirestoreKeys.appointmentCustomerId: user.uid,
        FirestoreKeys.appointmentCustomerName: user.displayName ?? 'Elite Guest',
        FirestoreKeys.appointmentService: service.toMap(),
        FirestoreKeys.appointmentSlot: Timestamp.fromDate(slot),
      });
      if (mounted) context.go('/customer/home');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
    } finally { if (mounted) setState(() => _isBooking = false); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barberAsync = ref.watch(currentBarberProvider(widget.barberId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 20), onPressed: () => context.pop())),
      body: barberAsync.when(
        data: (barber) {
          if (barber == null) return const Center(child: Text('Barber not found.'));
          final service = barber.services[widget.serviceIndex];

          return ListView(
            padding: const EdgeInsets.all(32),
            children: [
              Text('RESERVE SLOT', style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              Text(service.name.toUpperCase(), style: theme.textTheme.displayMedium?.copyWith(fontSize: 32)),
              const SizedBox(height: 8),
              Text('WITH ${barber.shopName.toUpperCase()}', style: const TextStyle(color: Colors.white24, fontSize: 12, letterSpacing: 1.5)),
              const SizedBox(height: 64),
              
              Text('SELECT TIME', style: theme.textTheme.labelLarge),
              const SizedBox(height: 32),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.2),
                itemCount: _availableSlots.length,
                itemBuilder: (context, i) {
                  final slot = _availableSlots[i];
                  final isSelected = _selectedTime == slot;
                  return InkWell(
                    onTap: () => setState(() => _selectedTime = slot),
                    child: Container(
                      decoration: BoxDecoration(color: isSelected ? Colors.white : const Color(0xFF0F0F0F), borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.center,
                      child: Text('${slot.hour}:${slot.minute.toString().padLeft(2, '0')}', style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 120),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton(
                  onPressed: _selectedTime == null || _isBooking ? null : () => _confirmBooking(barber, service),
                  child: _isBooking ? const CircularProgressIndicator(color: Colors.black) : const Text('CONFIRM RESERVATION'),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
