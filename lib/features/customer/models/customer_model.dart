import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_keys.dart';

/// Represents a customer user profile stored in Firestore.
class CustomerModel {
  /// Creates a [CustomerModel].
  const CustomerModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.photoUrl,
    required this.role,
    required this.createdAt,
  });

  /// Customer uid.
  final String uid;

  /// Display name.
  final String name;

  /// Phone number.
  final String phone;

  /// Profile photo URL.
  final String photoUrl;

  /// Role string (expects `'customer'`).
  final String role;

  /// Creation timestamp.
  final Timestamp createdAt;

  /// Creates a [CustomerModel] from a Firestore map.
  factory CustomerModel.fromMap(
    Map<String, dynamic> map, {
    required String uid,
  }) {
    return CustomerModel(
      uid: uid,
      name: map[FirestoreKeys.userName] as String? ?? '',
      phone: map[FirestoreKeys.userPhone] as String? ?? '',
      photoUrl: map[FirestoreKeys.userPhotoUrl] as String? ?? '',
      role: map[FirestoreKeys.userRole] as String? ?? FirestoreKeys.roleCustomer,
      createdAt: map[FirestoreKeys.createdAt] as Timestamp? ??
          Timestamp.fromDate(DateTime.fromMillisecondsSinceEpoch(0)),
    );
  }

  /// Serializes this instance to a Firestore-friendly map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      FirestoreKeys.uid: uid,
      FirestoreKeys.userName: name,
      FirestoreKeys.userPhone: phone,
      FirestoreKeys.userPhotoUrl: photoUrl,
      FirestoreKeys.userRole: role,
      FirestoreKeys.createdAt: createdAt,
    };
  }
}

