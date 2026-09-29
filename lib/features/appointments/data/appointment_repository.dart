import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_keys.dart';
import '../models/appointment_model.dart';

final appointmentRepositoryProvider = Provider((ref) => AppointmentRepository());

class AppointmentRepository {
  AppointmentRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Creates an appointment after checking for overlapping slots.
  Future<String> createAppointment(Map<String, dynamic> data) async {
    final barberId = data[FirestoreKeys.appointmentBarberId] as String? ?? '';
    final slot = data[FirestoreKeys.appointmentSlot] as Timestamp?;
    final service =
        (data[FirestoreKeys.appointmentService] as Map?)?.cast<String, dynamic>();
    final durationMins =
        (service?[FirestoreKeys.serviceDurationMinutes] as num?)?.toInt() ?? 30;

    if (barberId.isEmpty || slot == null) {
      throw StateError('barberId and slot are required');
    }

    final conflict = await hasConflict(
      barberId: barberId,
      slotStart: slot.toDate(),
      durationMinutes: durationMins,
    );
    if (conflict) {
      throw StateError('That time slot is no longer available.');
    }

    final doc = _db.collection(FirestoreKeys.appointments).doc();
    await doc.set({
      ...data,
      FirestoreKeys.id: doc.id,
      FirestoreKeys.createdAt: FieldValue.serverTimestamp(),
      FirestoreKeys.appointmentStatus: FirestoreKeys.appointmentStatusConfirmed,
    });
    return doc.id;
  }

  Future<bool> hasConflict({
    required String barberId,
    required DateTime slotStart,
    required int durationMinutes,
    String? excludeId,
  }) async {
    final dayStart = DateTime(slotStart.year, slotStart.month, slotStart.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final snap = await _db
        .collection(FirestoreKeys.appointments)
        .where(FirestoreKeys.appointmentBarberId, isEqualTo: barberId)
        .where(
          FirestoreKeys.appointmentSlot,
          isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),
        )
        .where(
          FirestoreKeys.appointmentSlot,
          isLessThan: Timestamp.fromDate(dayEnd),
        )
        .get();

    final slotEnd = slotStart.add(Duration(minutes: durationMinutes));
    for (final doc in snap.docs) {
      if (excludeId != null && doc.id == excludeId) continue;
      final data = doc.data();
      final status = data[FirestoreKeys.appointmentStatus] as String?;
      if (status == FirestoreKeys.appointmentStatusCancelled) continue;
      final otherSlot = data[FirestoreKeys.appointmentSlot] as Timestamp?;
      if (otherSlot == null) continue;
      final otherService =
          (data[FirestoreKeys.appointmentService] as Map?)?.cast<String, dynamic>();
      final otherDur =
          (otherService?[FirestoreKeys.serviceDurationMinutes] as num?)?.toInt() ??
              30;
      final otherStart = otherSlot.toDate();
      final otherEnd = otherStart.add(Duration(minutes: otherDur));
      if (slotStart.isBefore(otherEnd) && slotEnd.isAfter(otherStart)) {
        return true;
      }
    }
    return false;
  }

  Future<void> updateStatus(String appointmentId, String status) async {
    await _db.collection(FirestoreKeys.appointments).doc(appointmentId).update({
      FirestoreKeys.appointmentStatus: status,
      FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelAppointment(String appointmentId) =>
      updateStatus(appointmentId, FirestoreKeys.appointmentStatusCancelled);

  Future<void> completeAppointment(String appointmentId) =>
      updateStatus(appointmentId, FirestoreKeys.appointmentStatusCompleted);

  Stream<List<AppointmentModel>> getCustomerBookings(String customerId) {
    return _db
        .collection(FirestoreKeys.appointments)
        .where(FirestoreKeys.appointmentCustomerId, isEqualTo: customerId)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AppointmentModel.fromMap(d.data(), id: d.id))
            .toList()
          ..sort((a, b) => b.slot.compareTo(a.slot)));
  }

  Stream<List<AppointmentModel>> getBarberAppointmentsForDay(
    String barberId,
    DateTime day,
  ) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _db
        .collection(FirestoreKeys.appointments)
        .where(FirestoreKeys.appointmentBarberId, isEqualTo: barberId)
        .where(
          FirestoreKeys.appointmentSlot,
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where(
          FirestoreKeys.appointmentSlot,
          isLessThan: Timestamp.fromDate(end),
        )
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => AppointmentModel.fromMap(d.data(), id: d.id))
          .where((a) => a.status != FirestoreKeys.appointmentStatusCancelled)
          .toList()
        ..sort((a, b) => a.slot.compareTo(b.slot));
      return list;
    });
  }

  Stream<List<AppointmentModel>> getBarberAppointmentsForRange(
    String barberId,
    DateTime start,
    DateTime end,
  ) {
    return _db
        .collection(FirestoreKeys.appointments)
        .where(FirestoreKeys.appointmentBarberId, isEqualTo: barberId)
        .where(
          FirestoreKeys.appointmentSlot,
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where(
          FirestoreKeys.appointmentSlot,
          isLessThan: Timestamp.fromDate(end),
        )
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => AppointmentModel.fromMap(d.data(), id: d.id))
          .where((a) => a.status != FirestoreKeys.appointmentStatusCancelled)
          .toList()
        ..sort((a, b) => a.slot.compareTo(b.slot));
      return list;
    });
  }

  /// Active (non-cancelled) slot starts for a barber on [day].
  Future<List<DateTime>> getBookedStartsForDay(
    String barberId,
    DateTime day,
  ) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _db
        .collection(FirestoreKeys.appointments)
        .where(FirestoreKeys.appointmentBarberId, isEqualTo: barberId)
        .where(
          FirestoreKeys.appointmentSlot,
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where(
          FirestoreKeys.appointmentSlot,
          isLessThan: Timestamp.fromDate(end),
        )
        .get();

    return snap.docs
        .where((d) {
          final status = d.data()[FirestoreKeys.appointmentStatus] as String?;
          return status != FirestoreKeys.appointmentStatusCancelled;
        })
        .map((d) => (d.data()[FirestoreKeys.appointmentSlot] as Timestamp).toDate())
        .toList();
  }
}
