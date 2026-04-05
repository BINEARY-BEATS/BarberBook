import '../../../core/constants/firestore_keys.dart';

/// Represents a single barber service offered to customers.
class ServiceModel {
  /// Creates a [ServiceModel].
  ServiceModel({
    required this.name,
    required this.price,
    required this.durationMinutes,
  });

  /// Service name (e.g. "Haircut").
  final String name;

  /// Service price.
  final double price;

  /// Duration in minutes.
  final int durationMinutes;

  /// Creates a [ServiceModel] from a Firestore map.
  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      name: map[FirestoreKeys.serviceName] as String? ?? '',
      price: (map[FirestoreKeys.servicePrice] as num?)?.toDouble() ?? 0.0,
      durationMinutes:
          (map[FirestoreKeys.serviceDurationMinutes] as num?)?.toInt() ?? 0,
    );
  }

  /// Converts this instance into a Firestore-friendly map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      FirestoreKeys.serviceName: name,
      FirestoreKeys.servicePrice: price,
      FirestoreKeys.serviceDurationMinutes: durationMinutes,
    };
  }

  /// Creates a copy of this service with optional overrides.
  ServiceModel copyWith({
    String? name,
    double? price,
    int? durationMinutes,
  }) {
    return ServiceModel(
      name: name ?? this.name,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  /// Compares two [ServiceModel] objects by value.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceModel &&
        other.name == name &&
        other.price == price &&
        other.durationMinutes == durationMinutes;
  }

  /// Hashes this object by value.
  @override
  int get hashCode => Object.hash(name, price, durationMinutes);

  /// Returns a readable representation for debugging.
  @override
  String toString() => 'ServiceModel(name: $name, price: $price, durationMinutes: $durationMinutes)';
}

