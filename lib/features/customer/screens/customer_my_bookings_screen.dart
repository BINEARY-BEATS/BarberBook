import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../core/widgets/book_empty_state.dart';
import '../../appointments/data/appointment_repository.dart';

class CustomerMyBookingsScreen extends ConsumerWidget {
  const CustomerMyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final asyncBookings = ref.watch(StreamProvider((ref) => ref.read(appointmentRepositoryProvider).getCustomerBookings(user?.uid ?? '')));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 20), onPressed: () => context.pop())),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32), child: Text('MY ELITE BOOKINGS', style: theme.textTheme.displayMedium?.copyWith(fontSize: 24))),
            Expanded(
              child: asyncBookings.when(
                data: (bookings) {
                  if (bookings.isEmpty) return const BookEmptyState(icon: Icons.history_rounded, title: 'NO BOOKINGS', subtitle: 'Your grooming history is empty.');
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    itemCount: bookings.length,
                    itemBuilder: (context, i) {
                      final b = bookings[i];
                      final service = (b[FirestoreKeys.appointmentService] as Map<String, dynamic>)[FirestoreKeys.serviceName] ?? 'Unknown Service';
                      final slot = b[FirestoreKeys.appointmentSlot] as Timestamp?;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: const Color(0xFF0F0F0F), borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(service.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1.5)),
                            const SizedBox(height: 6),
                            Text(slot != null ? '${slot.toDate().day}/${slot.toDate().month} - ${slot.toDate().hour}:${slot.toDate().minute.toString().padLeft(2, '0')}' : 'NO TIME', style: const TextStyle(color: Colors.white24, fontSize: 11)),
                          ])),
                          const Icon(Icons.check_circle_rounded, color: Colors.white10, size: 20),
                        ]),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, __) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
