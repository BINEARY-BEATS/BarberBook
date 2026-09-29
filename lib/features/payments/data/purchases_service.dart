import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../firebase/revenuecat_config.dart';

final purchasesServiceProvider = Provider((ref) => PurchasesService());

/// RevenueCat wrapper for BarberBook Pro (Android).
class PurchasesService {
  bool _configured = false;

  bool get isConfigured {
    final key = kRevenueCatAndroidApiKey.trim();
    return key.isNotEmpty && !key.startsWith('REPLACE_WITH');
  }

  Future<void> configure() async {
    if (!isConfigured || _configured) return;
    try {
      await Purchases.setLogLevel(LogLevel.warn);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final config = PurchasesConfiguration(kRevenueCatAndroidApiKey);
      if (uid != null) config.appUserID = uid;
      await Purchases.configure(config);
      _configured = true;
    } catch (e) {
      if (kDebugMode) print('RevenueCat configure failed: $e');
    }
  }

  Future<bool> isPro() async {
    if (!_configured) await configure();
    if (!_configured) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(kRevenueCatProEntitlementId);
    } catch (_) {
      return false;
    }
  }

  Future<Offerings?> getOfferings() async {
    if (!_configured) await configure();
    if (!_configured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  Future<bool> purchasePro() async {
    if (!_configured) await configure();
    if (!_configured) throw StateError('RevenueCat is not configured.');
    final offerings = await Purchases.getOfferings();
    final packages = offerings.current?.availablePackages ?? [];
    if (packages.isEmpty) throw StateError('No Pro package available.');
    final result = await Purchases.purchase(
      PurchaseParams.package(packages.first),
    );
    final active =
        result.customerInfo.entitlements.active.containsKey(kRevenueCatProEntitlementId);
    if (active) await syncProToFirestore(true);
    return active;
  }

  Future<void> restore() async {
    if (!_configured) await configure();
    if (!_configured) return;
    final info = await Purchases.restorePurchases();
    final active =
        info.entitlements.active.containsKey(kRevenueCatProEntitlementId);
    await syncProToFirestore(active);
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
