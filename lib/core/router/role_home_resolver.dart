import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_keys.dart';
import '../utils/profile_completion.dart';

/// Resolves the GoRouter path for a signed-in [uid] using Firestore.
///
/// Barber docs win over stale `users/` docs so choosing Barber never loops
/// back to role-select.
Future<String> resolveRoleHomeForUid(String uid) async {
  final fs = FirebaseFirestore.instance;
  final results = await Future.wait([
    fs.collection(FirestoreKeys.users).doc(uid).get(),
    fs.collection(FirestoreKeys.barbers).doc(uid).get(),
  ]);
  final userDoc = results[0];
  final barberDoc = results[1];

  if (barberDoc.exists) {
    final data = barberDoc.data();
    return ProfileCompletion.isBarberComplete(data)
        ? '/barber/home'
        : '/barber/onboarding';
  }

  if (userDoc.exists) {
    final data = userDoc.data() ?? const <String, dynamic>{};
    final role = (data[FirestoreKeys.userRole] as String?) ?? '';
    if (role == FirestoreKeys.roleCustomer) {
      return ProfileCompletion.isCustomerComplete(data)
          ? '/customer/home'
          : '/customer/onboarding';
    }
  }

  return '/auth/role-select';
}
