import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_keys.dart';
import '../models/barber_model.dart';
import '../models/service_model.dart';

/// Repository for reading and writing barber data in Firestore.
class BarberRepository {
  /// Creates a [BarberRepository].
  BarberRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Returns a stream of the barber document for [uid].
  ///
  /// If the barber document does not exist, the stream emits `null`.
  Stream<BarberModel?> getBarber(String uid) {
    return _firestore
        .collection(FirestoreKeys.barbers)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return BarberModel.fromMap(data, uid: uid);
    });
  }

  /// Updates the barber profile with a partial [data] map.
  ///
  /// This uses `merge: true` to avoid overwriting unrelated fields.
  Future<void> updateBarberProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection(FirestoreKeys.barbers)
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  /// Adds [service] into the barber's `services` array.
  Future<void> addService(String uid, ServiceModel service) async {
    final serviceMap = service.toMap();

    await _firestore
        .collection(FirestoreKeys.barbers)
        .doc(uid)
        .set(
          {
            FirestoreKeys.barberServices: FieldValue.arrayUnion(<Map<String, dynamic>>[
              serviceMap,
            ]),
          },
          SetOptions(merge: true),
        );
  }

  /// Removes a service by matching its [serviceId] against the service name.
  ///
  /// Firestore `arrayRemove` requires exact map equality, so we perform a
  /// read-modify-write using a transaction.
  Future<void> removeService(String uid, String serviceId) async {
    final docRef = _firestore.collection(FirestoreKeys.barbers).doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
      final data = snap.data();
      if (data == null) return;

      final servicesValue = data[FirestoreKeys.barberServices];
      final currentServices = <Map<String, dynamic>>[];
      if (servicesValue is List) {
        currentServices.addAll(
          servicesValue.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList(),
        );
      }

      final filtered = currentServices.where((serviceMap) {
        return (serviceMap[FirestoreKeys.serviceName] as String?) != serviceId;
      }).toList();

      transaction.set(
        docRef,
        {
          FirestoreKeys.barberServices: filtered,
        },
        SetOptions(merge: true),
      );
    });
  }

  /// Sets the barber working hours map.
  Future<void> setWorkingHours(
    String uid,
    Map<String, Map<String, String>> workingHours,
  ) async {
    await updateBarberProfile(
      uid,
      {FirestoreKeys.barberWorkingHours: workingHours},
    );
  }

  /// Sets whether this barber is active/online.
  Future<void> setActiveStatus(String uid, bool isActive) async {
    await updateBarberProfile(
      uid,
      {FirestoreKeys.barberIsActive: isActive},
    );
  }

  /// Returns nearby barbers around [center] within [radiusKm].
  ///
  /// Uses a simple latitude/longitude bounding box query on the stored
  /// `GeoPoint`, then filters using a precise Haversine distance calculation.
  Future<List<BarberModel>> getNearbyBarbers(
    GeoPoint center,
    double radiusKm,
  ) async {
    final lat = center.latitude;
    final lng = center.longitude;

    // Approximate degrees per km.
    final latDelta = radiusKm / 110.574;
    final lonDelta = radiusKm / (111.320 * cos(lat * pi / 180));

    final minLat = lat - latDelta;
    final maxLat = lat + latDelta;
    final minLng = lng - lonDelta;
    final maxLng = lng + lonDelta;

    // Firestore lexicographic ordering over GeoPoint is not true distance,
    // so we filter accurately after fetching.
    final query = _firestore
        .collection(FirestoreKeys.barbers)
        .where(
          FirestoreKeys.barberLocation,
          isGreaterThanOrEqualTo: GeoPoint(minLat, minLng),
        )
        .where(
          FirestoreKeys.barberLocation,
          isLessThanOrEqualTo: GeoPoint(maxLat, maxLng),
        );

    final snap = await query.get();

    final results = <BarberModel>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final location = data[FirestoreKeys.barberLocation];
      if (location is! GeoPoint) continue;

      final distanceKm = _haversineDistanceKm(center, location);
      if (distanceKm <= radiusKm) {
        results.add(BarberModel.fromMap(data, uid: doc.id));
      }
    }

    return results;
  }

  /// Calculates the great-circle distance between two [GeoPoint] values.
  double _haversineDistanceKm(GeoPoint a, GeoPoint b) {
    const earthRadiusKm = 6371.0;

    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;

    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;

    final sinDLat = sin(dLat / 2);
    final sinDLng = sin(dLng / 2);

    final h = sinDLat * sinDLat + sinDLng * sinDLng * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(h), sqrt(1 - h));

    return earthRadiusKm * c;
  }
}

