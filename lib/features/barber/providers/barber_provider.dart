import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_keys.dart';
import '../data/barber_repository.dart';
import '../models/barber_model.dart';

/// Provides a singleton [BarberRepository] instance.
final barberRepositoryProvider = Provider<BarberRepository>((ref) {
  return BarberRepository();
});

/// Streams the current barber profile for [uid].
final currentBarberProvider = StreamProvider.autoDispose
    .family<BarberModel?, String>((ref, uid) {
  final repo = ref.watch(barberRepositoryProvider);
  return repo.getBarber(uid);
});

/// Streams today's confirmed appointments for a [barberId].
///
/// Returns raw appointment maps to avoid introducing a new AppointmentModel
/// before the appointment module is implemented.
final todayAppointmentsProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, barberId) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

  return FirebaseFirestore.instance
      .collection(FirestoreKeys.appointments)
      .where(
        FirestoreKeys.appointmentBarberId,
        isEqualTo: barberId,
      )
      .where(
        FirestoreKeys.appointmentStatus,
        isEqualTo: FirestoreKeys.appointmentStatusConfirmed,
      )
      .where(
        FirestoreKeys.appointmentSlot,
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
      )
      .where(
        FirestoreKeys.appointmentSlot,
        isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
      )
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map(
              (doc) => <String, dynamic>{
                ...doc.data(),
                FirestoreKeys.id: doc.id,
              },
            )
            .toList();
      });
});

/// Streams the real-time queue document for a [barberId].
final barberQueueProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, barberId) {
  return FirebaseFirestore.instance
      .collection(FirestoreKeys.queue)
      .doc(barberId)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) return null;
        return <String, dynamic>{
          ...snapshot.data()!,
          FirestoreKeys.queueBarberId: barberId,
        };
      });
});

