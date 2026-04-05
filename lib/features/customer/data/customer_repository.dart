import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../appointments/models/appointment_model.dart';
import '../models/customer_model.dart';

/// Repository for reading and writing customer data in Firestore.
class CustomerRepository {
  /// Creates a [CustomerRepository].
  CustomerRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Streams the customer profile for [uid].
  ///
  /// Emits `null` if the profile does not exist.
  Stream<CustomerModel?> getCustomer(String uid) {
    return _firestore
        .collection(FirestoreKeys.users)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return CustomerModel.fromMap(data, uid: uid);
    });
  }

  /// Updates the customer profile with a partial [data] map.
  Future<void> updateCustomer(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection(FirestoreKeys.users)
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  /// Streams all bookings for the customer [uid].
  ///
  /// Returns appointments ordered by slot time.
  Stream<List<AppointmentModel>> getMyBookings(String uid) {
    return _firestore
        .collection(FirestoreKeys.appointments)
        .where(FirestoreKeys.appointmentCustomerId, isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map(
            (doc) => AppointmentModel.fromMap(
              doc.data(),
              id: doc.id,
            ),
          )
          .toList();

      list.sort((a, b) => a.slot.toDate().compareTo(b.slot.toDate()));
      return list;
    });
  }
}

