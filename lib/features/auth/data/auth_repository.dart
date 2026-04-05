import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../firebase/google_sign_in_config.dart';

/// Firebase Auth + Firestore role persistence for BarberBook.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Exposes FirebaseAuth's auth state stream.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  GoogleSignIn _googleSignIn() {
    final webId = kGoogleSignInWebClientId.trim();
    return GoogleSignIn(
      scopes: const <String>['email', 'profile'],
      serverClientId: webId.isNotEmpty ? webId : null,
    );
  }

  /// Signs in with Google and returns the [UserCredential], or `null` if the
  /// user closed the account picker.
  Future<UserCredential?> signInWithGoogle() async {
    final googleSignIn = _googleSignIn();
    final account = await googleSignIn.signIn();
    if (account == null) return null;

    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Signs out of Firebase and clears the Google session when applicable.
  Future<void> signOut() async {
    try {
      await _googleSignIn().signOut();
    } catch (_) {
      // Ignore if Google Sign-In was never used this session.
    }
    await _auth.signOut();
  }

  /// Persists the chosen [role] into Firestore after successful sign-in.
  ///
  /// - Customer role: creates/updates `users/{uid}`.
  /// - Barber role: creates/updates `barbers/{uid}`.
  ///
  /// The `phone` field in Firestore stores E.164 phone when present, otherwise
  /// the Google account email (or empty).
  Future<void> applyRoleToFirestore({
    required String role,
    required User user,
  }) async {
    final uid = user.uid;
    final photoUrl = user.photoURL ?? '';
    final contact = _profileContact(user);

    final createdAt = FieldValue.serverTimestamp();

    if (role == FirestoreKeys.roleCustomer) {
      await _firestore.collection(FirestoreKeys.users).doc(uid).set(
        {
          FirestoreKeys.uid: uid,
          FirestoreKeys.userName: user.displayName ?? '',
          FirestoreKeys.userPhone: contact,
          FirestoreKeys.userPhotoUrl: photoUrl,
          FirestoreKeys.userRole: FirestoreKeys.roleCustomer,
          FirestoreKeys.createdAt: createdAt,
        },
        SetOptions(merge: true),
      );
      return;
    }

    if (role == FirestoreKeys.roleBarber) {
      await _firestore.collection(FirestoreKeys.barbers).doc(uid).set(
        {
          FirestoreKeys.uid: uid,
          FirestoreKeys.barberShopName: '',
          FirestoreKeys.barberOwnerName: user.displayName ?? '',
          FirestoreKeys.barberPhone: contact,
          FirestoreKeys.barberPhotoUrl: photoUrl,
          FirestoreKeys.barberLocation: const GeoPoint(0, 0),
          FirestoreKeys.barberAddress: '',
          FirestoreKeys.barberRating: 0.0,
          FirestoreKeys.barberTotalReviews: 0,
          FirestoreKeys.barberIsPro: false,
          FirestoreKeys.barberIsActive: false,
          FirestoreKeys.barberWorkingHours: const <String, dynamic>{},
          FirestoreKeys.barberServices: const [],
          FirestoreKeys.createdAt: createdAt,
        },
        SetOptions(merge: true),
      );
      return;
    }

    throw ArgumentError.value(role, 'role', 'Unsupported role');
  }

  String _profileContact(User user) {
    final phone = user.phoneNumber?.trim();
    if (phone != null && phone.isNotEmpty) {
      return _normalizePhoneNumber(phone);
    }
    return user.email?.trim() ?? '';
  }

  String _normalizePhoneNumber(String phoneNumber) {
    final trimmed = phoneNumber.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.startsWith('+') ? trimmed : '+$trimmed';
  }
}
