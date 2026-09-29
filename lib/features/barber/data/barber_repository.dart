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
      if (data['excludeFromDiscovery'] == true) continue;
      final location = data[FirestoreKeys.barberLocation];
      if (location is! GeoPoint) continue;

      final distanceKm = _haversineDistanceKm(center, location);
      if (distanceKm > radiusKm) continue;
      final model = BarberModel.fromMap(data, uid: doc.id);
      if (!_isDiscoverable(model)) continue;
      results.add(model);
    }

    results.sort((a, b) {
      final aBoost = a.isPro ? 0 : 1;
      final bBoost = b.isPro ? 0 : 1;
      if (aBoost != bBoost) return aBoost.compareTo(bBoost);
      return a.shopName.compareTo(b.shopName);
    });

    return results;
  }

  /// Searches for barbers by shop name (prefix search). Prefer local filter on home.
  Future<List<BarberModel>> searchBarbers(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final snap = await _firestore
        .collection(FirestoreKeys.barbers)
        .where(FirestoreKeys.barberShopName, isGreaterThanOrEqualTo: q)
        .where(FirestoreKeys.barberShopName, isLessThanOrEqualTo: '$q\uf8ff')
        .get();

    return snap.docs
        .map((doc) => BarberModel.fromMap(doc.data(), uid: doc.id))
        .where(_isDiscoverable)
        .toList();
  }

  /// All shops ready for customer discovery (named + photo, not private demo accounts).
  Future<List<BarberModel>> listDiscoverableShops({int limit = 40}) async {
    final snap = await _firestore
        .collection(FirestoreKeys.barbers)
        .limit(80)
        .get();

    final list = snap.docs
        .map((doc) {
          final data = doc.data();
          final model = BarberModel.fromMap(data, uid: doc.id);
          return (model: model, exclude: data['excludeFromDiscovery'] == true);
        })
        .where((e) => !e.exclude && _isDiscoverable(e.model))
        .map((e) => e.model)
        .take(limit)
        .toList();

    list.sort((a, b) {
      final aBoost = a.isPro ? 0 : 1;
      final bBoost = b.isPro ? 0 : 1;
      if (aBoost != bBoost) return aBoost.compareTo(bBoost);
      return a.shopName.toLowerCase().compareTo(b.shopName.toLowerCase());
    });
    return list;
  }

  bool _isDiscoverable(BarberModel b) {
    if (b.shopName.trim().isEmpty) return false;
    if (b.photoUrl.trim().isEmpty) return false;
    if (b.uid.startsWith('demo_shop_')) return true;
    final name = b.shopName.trim().toLowerCase();
    if (name == 'demo shop' || name == 'test shop') return false;
    final photo = b.photoUrl.trim().toLowerCase();
    if (photo.contains('ui-avatars') ||
        photo.contains('dicebear') ||
        photo.contains('pravatar') ||
        photo.contains('robohash')) {
      return false;
    }
    return photo.startsWith('http');
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

  /// Streams the walk-in queue document for [barberId].
  Stream<Map<String, dynamic>?> watchQueue(String barberId) {
    return _firestore
        .collection(FirestoreKeys.queue)
        .doc(barberId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return <String, dynamic>{
        ...snapshot.data()!,
        FirestoreKeys.queueBarberId: barberId,
      };
    });
  }

  /// Aggregates dashboard metrics for the barber admin home.
  Future<BarberStats> getBarberStats(String uid) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final windowStart = todayStart.subtract(const Duration(days: 90));

    final snap = await _firestore
        .collection(FirestoreKeys.appointments)
        .where(FirestoreKeys.appointmentBarberId, isEqualTo: uid)
        .get();

    var totalBookings = 0;
    var todayCount = 0;
    var completed90 = 0;
    var confirmedLike90 = 0;
    final customerCounts = <String, int>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      final status =
          data[FirestoreKeys.appointmentStatus] as String? ?? '';
      if (status == FirestoreKeys.appointmentStatusCancelled) continue;

      totalBookings++;

      final slot = data[FirestoreKeys.appointmentSlot];
      DateTime? slotDt;
      if (slot is Timestamp) slotDt = slot.toDate();

      if (slotDt != null &&
          !slotDt.isBefore(todayStart) &&
          slotDt.isBefore(todayEnd)) {
        todayCount++;
      }

      if (slotDt != null && !slotDt.isBefore(windowStart)) {
        confirmedLike90++;
        if (status == FirestoreKeys.appointmentStatusCompleted) {
          completed90++;
        }
        final customerId =
            data[FirestoreKeys.appointmentCustomerId] as String? ?? '';
        if (customerId.isNotEmpty) {
          customerCounts[customerId] = (customerCounts[customerId] ?? 0) + 1;
        }
      }
    }

    final uniqueCustomers = customerCounts.length;
    final repeatCustomers =
        customerCounts.values.where((c) => c > 1).length;
    final retention = uniqueCustomers == 0
        ? 0.0
        : repeatCustomers / uniqueCustomers;
    final productivity =
        confirmedLike90 == 0 ? 0.0 : completed90 / confirmedLike90;

    // Assume a soft daily capacity of 8 for schedule progress.
    const dailyCapacity = 8;
    final scheduleProgress =
        (todayCount / dailyCapacity).clamp(0.0, 1.0).toDouble();

    return BarberStats(
      totalBookings: totalBookings,
      todayCount: todayCount,
      retention: retention,
      productivity: productivity,
      scheduleProgress: scheduleProgress,
    );
  }
}

/// Dashboard metrics for a barber.
class BarberStats {
  const BarberStats({
    required this.totalBookings,
    required this.todayCount,
    required this.retention,
    required this.productivity,
    required this.scheduleProgress,
  });

  final int totalBookings;
  final int todayCount;
  final double retention;
  final double productivity;
  final double scheduleProgress;
}

