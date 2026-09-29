import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_keys.dart';

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.barberId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String barberId;
  final String customerId;
  final String customerName;
  final double rating;
  final String comment;
  final Timestamp createdAt;

  factory ReviewModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return ReviewModel(
      id: id,
      barberId: map[FirestoreKeys.reviewBarberId] as String? ?? '',
      customerId: map[FirestoreKeys.reviewCustomerId] as String? ?? '',
      customerName: map[FirestoreKeys.reviewCustomerName] as String? ?? '',
      rating: (map[FirestoreKeys.reviewRating] as num?)?.toDouble() ?? 0,
      comment: map[FirestoreKeys.reviewComment] as String? ?? '',
      createdAt: map[FirestoreKeys.createdAt] as Timestamp? ?? Timestamp.now(),
    );
  }
}
