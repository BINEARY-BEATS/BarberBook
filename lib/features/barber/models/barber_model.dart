import 'package:cloud_firestore/cloud_firestore.dart';

import 'service_model.dart';
import '../../../core/constants/firestore_keys.dart';

/// Represents a barber profile stored in Firestore.
class BarberModel {
  /// Creates a [BarberModel].
  const BarberModel({
    required this.uid,
    required this.shopName,
    required this.ownerName,
    required this.phone,
    required this.photoUrl,
    required this.location,
    required this.address,
    required this.rating,
    required this.totalReviews,
    required this.isPro,
    required this.isActive,
    required this.workingHours,
    required this.services,
    this.createdAt,
  });

  /// Barber uid (document id).
  final String uid;

  /// Shop name.
  final String shopName;

  /// Owner name.
  final String ownerName;

  /// Barber phone.
  final String phone;

  /// Profile photo URL.
  final String photoUrl;

  /// Geographic location used for nearby-barber search.
  final GeoPoint location;

  /// Address string.
  final String address;

  /// Rating (average).
  final double rating;

  /// Total review count.
  final int totalReviews;

  /// Whether barber is Pro.
  final bool isPro;

  /// Whether barber is active/online in app.
  final bool isActive;

  /// Working hours map for mon-sun: { day: {open, close} }.
  final Map<String, Map<String, String>> workingHours;

  /// List of services offered by the barber.
  final List<ServiceModel> services;

  /// Document creation time.
  final Timestamp? createdAt;

  /// Creates a [BarberModel] from a Firestore document map.
  factory BarberModel.fromMap(Map<String, dynamic> map, {required String uid}) {
    final location = map[FirestoreKeys.barberLocation];
    return BarberModel(
      uid: uid,
      shopName: map[FirestoreKeys.barberShopName] as String? ?? '',
      ownerName: map[FirestoreKeys.barberOwnerName] as String? ?? '',
      phone: map[FirestoreKeys.barberPhone] as String? ?? '',
      photoUrl: map[FirestoreKeys.barberPhotoUrl] as String? ?? '',
      location: location is GeoPoint ? location : const GeoPoint(0, 0),
      address: map[FirestoreKeys.barberAddress] as String? ?? '',
      rating: (map[FirestoreKeys.barberRating] as num?)?.toDouble() ?? 0.0,
      totalReviews:
          (map[FirestoreKeys.barberTotalReviews] as num?)?.toInt() ?? 0,
      isPro: map[FirestoreKeys.barberIsPro] as bool? ?? false,
      isActive: map[FirestoreKeys.barberIsActive] as bool? ?? false,
      workingHours: _parseWorkingHours(map[FirestoreKeys.barberWorkingHours]),
      services: _parseServices(map[FirestoreKeys.barberServices]),
      createdAt: map[FirestoreKeys.createdAt] as Timestamp?,
    );
  }

  /// Serializes this barber to a Firestore-friendly map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      FirestoreKeys.uid: uid,
      FirestoreKeys.barberShopName: shopName,
      FirestoreKeys.barberOwnerName: ownerName,
      FirestoreKeys.barberPhone: phone,
      FirestoreKeys.barberPhotoUrl: photoUrl,
      FirestoreKeys.barberLocation: location,
      FirestoreKeys.barberAddress: address,
      FirestoreKeys.barberRating: rating,
      FirestoreKeys.barberTotalReviews: totalReviews,
      FirestoreKeys.barberIsPro: isPro,
      FirestoreKeys.barberIsActive: isActive,
      FirestoreKeys.barberWorkingHours: workingHours,
      FirestoreKeys.barberServices: services.map((s) => s.toMap()).toList(),
      FirestoreKeys.createdAt: createdAt,
    };
  }

  /// Creates a copy of this barber with optional overrides.
  BarberModel copyWith({
    String? shopName,
    String? ownerName,
    String? phone,
    String? photoUrl,
    GeoPoint? location,
    String? address,
    double? rating,
    int? totalReviews,
    bool? isPro,
    bool? isActive,
    Map<String, Map<String, String>>? workingHours,
    List<ServiceModel>? services,
    Timestamp? createdAt,
  }) {
    return BarberModel(
      uid: uid,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isPro: isPro ?? this.isPro,
      isActive: isActive ?? this.isActive,
      workingHours: workingHours ?? this.workingHours,
      services: services ?? this.services,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts workingHours Firestore value into a strong map.
  static Map<String, Map<String, String>> _parseWorkingHours(Object? value) {
    if (value is Map) {
      return value.map<String, Map<String, String>>((key, dayValue) {
        final dayKey = key.toString();
        if (dayValue is Map) {
          return MapEntry(
            dayKey,
            dayValue.map<String, String>(
              (openKey, openVal) => MapEntry(openKey.toString(), openVal.toString()),
            ),
          );
        }
        return MapEntry(dayKey, const <String, String>{});
      });
    }
    return const <String, Map<String, String>>{};
  }

  /// Converts services Firestore value into a strong list.
  static List<ServiceModel> _parseServices(Object? value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => ServiceModel.fromMap(e.cast<String, dynamic>()))
          .toList();
    }
    return const <ServiceModel>[];
  }

  /// Equality by value for easier state comparisons.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BarberModel &&
        other.uid == uid &&
        other.shopName == shopName &&
        other.ownerName == ownerName &&
        other.phone == phone &&
        other.photoUrl == photoUrl &&
        other.location == location &&
        other.address == address &&
        other.rating == rating &&
        other.totalReviews == totalReviews &&
        other.isPro == isPro &&
        other.isActive == isActive &&
        other.workingHours.toString() == workingHours.toString() &&
        other.services.toString() == services.toString();
  }

  /// Hash based on identity fields (best-effort).
  @override
  int get hashCode => Object.hash(
        uid,
        shopName,
        ownerName,
        phone,
        photoUrl,
        location,
        address,
        rating,
        totalReviews,
        isPro,
        isActive,
      );

  /// Returns a readable representation for debugging.
  @override
  String toString() => 'BarberModel(uid: $uid, shopName: $shopName)';
}

