import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_keys.dart';

/// Resolves the GoRouter path for a signed-in [uid] using Firestore.
///
/// Used from [SplashScreen] so startup does not block on async [GoRouter.redirect].
Future<String> resolveRoleHomeForUid(String uid) async {
  final userDoc = await FirebaseFirestore.instance
      .collection(FirestoreKeys.users)
      .doc(uid)
      .get();

  if (userDoc.exists) {
    final role =
        (userDoc.data()? [FirestoreKeys.userRole] as String?) ?? '';
    if (role == FirestoreKeys.roleCustomer) return '/customer/home';
    return '/auth/role-select';
  }

  final barberDoc = await FirebaseFirestore.instance
      .collection(FirestoreKeys.barbers)
      .doc(uid)
      .get();

  if (barberDoc.exists) {
    final data = barberDoc.data() ?? const <String, dynamic>{};
    final address =
        (data[FirestoreKeys.barberAddress] as String? ?? '').trim();
    final workingHours = data[FirestoreKeys.barberWorkingHours]
            as Map<String, dynamic>? ??
        const {};
    final services =
        data[FirestoreKeys.barberServices] as List<dynamic>? ?? const [];

    final isSetupComplete = address.isNotEmpty &&
        workingHours.isNotEmpty &&
        services.isNotEmpty;

    return isSetupComplete ? '/barber/home' : '/barber/onboarding';
  }

  return '/auth/role-select';
}
