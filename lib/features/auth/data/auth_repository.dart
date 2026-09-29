import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../core/utils/demo_seeder.dart';
import '../../../core/utils/profile_completion.dart';
import '../../../firebase/google_sign_in_config.dart';

/// Firebase Auth + Firestore role persistence for BarberBook.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? _createGoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  static GoogleSignIn _createGoogleSignIn() {
    final webId = kGoogleSignInWebClientId.trim();
    final configured = webId.isNotEmpty && !webId.startsWith('REPLACE_WITH');
    return GoogleSignIn(
      scopes: const <String>['email', 'profile'],
      serverClientId: configured ? webId : null,
    );
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Shows the Google account picker (does not auto-pick the last account).
  Future<UserCredential?> signInWithGoogle() async {
    await _clearGoogleSession();

    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Anonymous demo login — skips Google and seeds polished walkthrough data.
  Future<UserCredential> signInAsDemo({required String role}) async {
    if (role != FirestoreKeys.roleBarber &&
        role != FirestoreKeys.roleCustomer) {
      throw ArgumentError.value(role, 'role', 'Unsupported demo role');
    }

    if (_auth.currentUser != null) {
      await signOut();
    }

    final credential = await _auth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw StateError('Demo sign-in failed.');
    }

    try {
      if (role == FirestoreKeys.roleBarber) {
        await DemoSeeder.seedDemoBarberAccount(user.uid);
      } else {
        await DemoSeeder.seedDemoCustomerAccount(user.uid);
      }
    } catch (_) {
      // One retry — intermittent Firestore / network blips shouldn't kill demo.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (role == FirestoreKeys.roleBarber) {
        await DemoSeeder.seedDemoBarberAccount(user.uid);
      } else {
        await DemoSeeder.seedDemoCustomerAccount(user.uid);
      }
    }

    return credential;
  }

  /// Signs out of Firebase + Google and clears the cached Google account.
  Future<void> signOut() async {
    await _clearGoogleSession();
    await _auth.signOut();
  }

  Future<void> _clearGoogleSession() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  /// Persists the chosen [role] shell. Clears the other role doc.
  Future<void> applyRoleToFirestore({
    required String role,
    required User user,
  }) async {
    final uid = user.uid;
    final photoUrl = user.photoURL ?? '';
    final email = user.email?.trim() ?? '';
    final name = (user.displayName ?? '').trim();
    final phoneFromAuth = user.phoneNumber?.trim() ?? '';
    final phone = ProfileCompletion.isRealPhone(phoneFromAuth)
        ? ProfileCompletion.normalizePhone(phoneFromAuth)
        : '';
    final createdAt = FieldValue.serverTimestamp();

    if (role == FirestoreKeys.roleCustomer) {
      await _firestore.collection(FirestoreKeys.users).doc(uid).set(
        {
          FirestoreKeys.uid: uid,
          FirestoreKeys.userName: name,
          FirestoreKeys.userPhone: phone,
          FirestoreKeys.userEmail: email,
          FirestoreKeys.userPhotoUrl: photoUrl,
          FirestoreKeys.userRole: FirestoreKeys.roleCustomer,
          FirestoreKeys.profileComplete: false,
          FirestoreKeys.createdAt: createdAt,
        },
        SetOptions(merge: true),
      );
      try {
        await _firestore.collection(FirestoreKeys.barbers).doc(uid).delete();
      } catch (_) {}
      return;
    }

    if (role == FirestoreKeys.roleBarber) {
      await _firestore.collection(FirestoreKeys.barbers).doc(uid).set(
        {
          FirestoreKeys.uid: uid,
          FirestoreKeys.barberShopName: '',
          FirestoreKeys.barberOwnerName: name,
          FirestoreKeys.barberPhone: phone,
          FirestoreKeys.barberEmail: email,
          FirestoreKeys.barberPhotoUrl: photoUrl,
          FirestoreKeys.barberLocation: const GeoPoint(0, 0),
          FirestoreKeys.barberAddress: '',
          FirestoreKeys.barberRating: 0.0,
          FirestoreKeys.barberTotalReviews: 0,
          FirestoreKeys.barberIsPro: false,
          FirestoreKeys.barberIsActive: false,
          FirestoreKeys.barberWorkingHours: const <String, dynamic>{},
          FirestoreKeys.barberServices: const [],
          FirestoreKeys.profileComplete: false,
          FirestoreKeys.createdAt: createdAt,
        },
        SetOptions(merge: true),
      );
      try {
        await _firestore.collection(FirestoreKeys.users).doc(uid).delete();
      } catch (_) {}
      return;
    }

    throw ArgumentError.value(role, 'role', 'Unsupported role');
  }
}
