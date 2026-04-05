import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/firestore_keys.dart';
import '../models/appointment_model.dart';

final appointmentRepositoryProvider = Provider((ref) => AppointmentRepository());

class AppointmentRepository {
  final _db = FirebaseFirestore.instance;

  Future<void> createAppointment(Map<String, dynamic> data) async {
    final doc = _db.collection(FirestoreKeys.appointments).doc();
    await doc.set({
      ...data,
      FirestoreKeys.id: doc.id,
      FirestoreKeys.createdAt: FieldValue.serverTimestamp(),
      FirestoreKeys.appointmentStatus: FirestoreKeys.appointmentStatusConfirmed,
    });
  }

  Stream<List<Map<String, dynamic>>> getCustomerBookings(String customerId) {
    return _db.collection(FirestoreKeys.appointments)
        .where(FirestoreKeys.appointmentCustomerId, isEqualTo: customerId)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }
}
