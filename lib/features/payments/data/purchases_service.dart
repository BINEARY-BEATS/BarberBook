import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_keys.dart';

final purchasesServiceProvider = Provider((ref) => PurchasesService());

/// Demo Pro service (RevenueCat disabled for demo purpose).
class PurchasesService {
  bool get isConfigured => false;

  Future<void> configure() async {
    // No-op: RevenueCat disabled for demo mode.
  }

  Future<bool> isPro() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestoreKeys.barbers)
          .doc(uid)
          .get();
      return doc.data()?[FirestoreKeys.barberIsPro] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> purchasePro() async {
    // Demo mode: simply activate Pro in Firestore directly
    await syncProToFirestore(true);
    return true;
  }

  Future<void> restore() async {
    // No-op for demo mode
  }

  Future<void> syncProToFirestore(bool isPro) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection(FirestoreKeys.barbers).doc(uid).set({
      FirestoreKeys.barberIsPro: isPro,
      if (isPro) FirestoreKeys.barberFeatured: true,
    }, SetOptions(merge: true));
  }
}
