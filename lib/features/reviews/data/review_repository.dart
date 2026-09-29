import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_keys.dart';
import '../models/review_model.dart';

final reviewRepositoryProvider = Provider((ref) => ReviewRepository());

final barberReviewsProvider =
    StreamProvider.autoDispose.family<List<ReviewModel>, String>((ref, barberId) {
  if (barberId.isEmpty) return Stream.value(const []);
  return ref.watch(reviewRepositoryProvider).watchReviews(barberId);
});

class ReviewRepository {
  ReviewRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<ReviewModel>> watchReviews(String barberId) {
    return _db
        .collection(FirestoreKeys.reviews)
        .where(FirestoreKeys.reviewBarberId, isEqualTo: barberId)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => ReviewModel.fromMap(d.data(), id: d.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> submitReview({
    required String barberId,
    required String customerId,
    required String customerName,
    required double rating,
    required String comment,
    String? appointmentId,
  }) async {
    // One review per customer per barber.
    final existing = await _db
        .collection(FirestoreKeys.reviews)
        .where(FirestoreKeys.reviewBarberId, isEqualTo: barberId)
        .where(FirestoreKeys.reviewCustomerId, isEqualTo: customerId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw StateError('You already reviewed this barber.');
    }

    final doc = _db.collection(FirestoreKeys.reviews).doc();
    await doc.set({
      FirestoreKeys.id: doc.id,
      FirestoreKeys.reviewBarberId: barberId,
      FirestoreKeys.reviewCustomerId: customerId,
      FirestoreKeys.reviewCustomerName: customerName,
      FirestoreKeys.reviewRating: rating,
      FirestoreKeys.reviewComment: comment,
      'appointmentId': ?appointmentId,
      FirestoreKeys.createdAt: FieldValue.serverTimestamp(),
    });

    await _recomputeRating(barberId);
  }

  Future<void> _recomputeRating(String barberId) async {
    final snap = await _db
        .collection(FirestoreKeys.reviews)
        .where(FirestoreKeys.reviewBarberId, isEqualTo: barberId)
        .get();
    if (snap.docs.isEmpty) {
      await _db.collection(FirestoreKeys.barbers).doc(barberId).set({
        FirestoreKeys.barberRating: 0.0,
        FirestoreKeys.barberTotalReviews: 0,
      }, SetOptions(merge: true));
      return;
    }
    var sum = 0.0;
    for (final d in snap.docs) {
      sum += (d.data()[FirestoreKeys.reviewRating] as num?)?.toDouble() ?? 0;
    }
    final avg = sum / snap.docs.length;
    await _db.collection(FirestoreKeys.barbers).doc(barberId).set({
      FirestoreKeys.barberRating: double.parse(avg.toStringAsFixed(1)),
      FirestoreKeys.barberTotalReviews: snap.docs.length,
    }, SetOptions(merge: true));
  }
}
