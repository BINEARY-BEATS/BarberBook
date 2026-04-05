import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_keys.dart';
import '../data/auth_repository.dart';

/// Provides a singleton [AuthRepository] instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Streams the currently authenticated Firebase user (or `null` if signed out).
final currentUserProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

/// Fetches the current user's role from Firestore.
///
/// Role resolution:
/// - If `users/{uid}` exists -> returns `role` (expects `customer`)
/// - Else if `barbers/{uid}` exists -> returns `barber`
/// - Else -> returns `null`
final userRoleProvider = FutureProvider<String?>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.asData?.value;
  if (user == null) return null;

  final usersDoc =
      await FirebaseFirestore.instance.collection(FirestoreKeys.users).doc(user.uid).get();
  if (usersDoc.exists) {
    final role = usersDoc.data()? [FirestoreKeys.userRole] as String?;
    return role;
  }

  final barbersDoc =
      await FirebaseFirestore.instance.collection(FirestoreKeys.barbers).doc(user.uid).get();
  if (barbersDoc.exists) return FirestoreKeys.roleBarber;

  return null;
});

