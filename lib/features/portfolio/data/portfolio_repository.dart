import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../firebase/revenuecat_config.dart';
import '../models/portfolio_item.dart';

final portfolioRepositoryProvider = Provider((ref) => PortfolioRepository());

final barberPortfolioProvider = StreamProvider.autoDispose
    .family<List<PortfolioItem>, String>((ref, barberId) {
  if (barberId.isEmpty) return Stream.value(const []);
  return ref.watch(portfolioRepositoryProvider).watchPortfolio(barberId);
});

/// Demo-friendly portfolio storage: compressed JPEG as a data-URI in Firestore.
/// Avoids Firebase Storage (Blaze plan) so Spark/free projects still work.
class PortfolioRepository {
  PortfolioRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Soft cap so a single Firestore doc stays under the 1 MB limit.
  static const int _maxBytes = 700 * 1024;

  Stream<List<PortfolioItem>> watchPortfolio(String barberId) {
    return _db
        .collection(FirestoreKeys.portfolio)
        .where(FirestoreKeys.portfolioBarberId, isEqualTo: barberId)
        .snapshots()
        .map((s) => s.docs
            .map((d) => PortfolioItem.fromMap(d.data(), id: d.id))
            .toList());
  }

  Future<int> countPhotos(String barberId) async {
    final snap = await _db
        .collection(FirestoreKeys.portfolio)
        .where(FirestoreKeys.portfolioBarberId, isEqualTo: barberId)
        .get();
    return snap.docs.length;
  }

  /// Saves a photo into Firestore (no Storage / paid plan required).
  Future<void> uploadPhoto({
    required String barberId,
    required File file,
    required bool isPro,
    String style = '',
  }) async {
    if (!isPro) {
      final count = await countPhotos(barberId);
      if (count >= kFreePortfolioLimit) {
        throw StateError(
          'Demo free plan allows $kFreePortfolioLimit photos. Upgrade to Pro.',
        );
      }
    }

    if (!await file.exists()) {
      throw StateError('Selected image file was not found.');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw StateError('Selected image is empty.');
    }
    if (bytes.length > _maxBytes) {
      throw StateError(
        'Image is still too large after compression. Try another photo.',
      );
    }

    final id = const Uuid().v4();
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    await _db.collection(FirestoreKeys.portfolio).doc(id).set({
      FirestoreKeys.id: id,
      FirestoreKeys.portfolioBarberId: barberId,
      FirestoreKeys.portfolioImageUrl: dataUrl,
      FirestoreKeys.portfolioStyle: style,
      FirestoreKeys.createdAt: FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePhoto(PortfolioItem item) async {
    await _db.collection(FirestoreKeys.portfolio).doc(item.id).delete();
  }
}
