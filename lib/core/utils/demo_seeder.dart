import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_keys.dart';

/// Seeds polished demo shops, portfolios, reviews, and appointments.
class DemoSeeder {
  DemoSeeder._();

  static const _defaultHours = <String, Map<String, String>>{
    'mon': {'open': '09:00', 'close': '20:00'},
    'tue': {'open': '09:00', 'close': '20:00'},
    'wed': {'open': '09:00', 'close': '20:00'},
    'thu': {'open': '09:00', 'close': '21:00'},
    'fri': {'open': '09:00', 'close': '21:00'},
    'sat': {'open': '10:00', 'close': '18:00'},
    'sun': {'open': '11:00', 'close': '16:00'},
  };

  static const _demoBarberCover =
      'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?auto=format&fit=crop&w=1200&q=80';

  static List<Map<String, dynamic>> get _premiumServices => [
        {
          FirestoreKeys.serviceName: 'Signature Fade',
          FirestoreKeys.servicePrice: 45.0,
          FirestoreKeys.serviceDurationMinutes: 40,
        },
        {
          FirestoreKeys.serviceName: 'Beard Trim & Shape',
          FirestoreKeys.servicePrice: 25.0,
          FirestoreKeys.serviceDurationMinutes: 25,
        },
        {
          FirestoreKeys.serviceName: 'Hot Towel Shave',
          FirestoreKeys.servicePrice: 35.0,
          FirestoreKeys.serviceDurationMinutes: 30,
        },
        {
          FirestoreKeys.serviceName: 'Hair + Beard Combo',
          FirestoreKeys.servicePrice: 60.0,
          FirestoreKeys.serviceDurationMinutes: 55,
        },
        {
          FirestoreKeys.serviceName: 'Style Finish',
          FirestoreKeys.servicePrice: 20.0,
          FirestoreKeys.serviceDurationMinutes: 20,
        },
      ];

  static const _portfolioPool = <String>[
    'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1585747860715-2ba37e789b80?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1605497787561-4d2b4d5e3e0e?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1493256338651-d82f7acb2b38?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1517832606299-7ae9b720a186?auto=format&fit=crop&w=800&q=80',
  ];

  static const _reviewTemplates = <({String name, double rating, String comment})>[
    (name: 'Chris M.', rating: 5, comment: 'Best fade in the city. Walked out sharp.'),
    (name: 'Priya S.', rating: 5, comment: 'Clean shop, on time, and the beard work is insane.'),
    (name: 'Marcus T.', rating: 4.5, comment: 'Great vibe and solid cut. Booking again.'),
    (name: 'Elena R.', rating: 5, comment: 'Hot towel shave was next level. Highly recommend.'),
    (name: 'Jayden K.', rating: 4, comment: 'Friendly staff and consistent results every visit.'),
  ];

  /// Runs shop seeding with a hard timeout so the UI never blocks forever.
  static Future<void> ensureDemoCatalogReliable() async {
    try {
      await ensureDemoCatalog().timeout(const Duration(seconds: 8));
    } catch (_) {
      try {
        await ensureDemoShopsFast().timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
  }

  static List<Map<String, dynamic>> get _catalogShops => [
        {
          'id': 'demo_shop_blend_house',
          'shopName': 'The Blend House',
          'ownerName': 'Tony Rivera',
          'phone': '+15551234001',
          'address': '12 Union Ave, Downtown',
          'location': const GeoPoint(24.8607, 67.0011),
          'rating': 4.9,
          'totalReviews': 128,
          'isPro': true,
          'photoUrl':
              'https://images.unsplash.com/photo-1585747860715-2ba37e789b80?auto=format&fit=crop&w=1200&q=80',
        },
        {
          'id': 'demo_shop_noir_cuts',
          'shopName': 'Noir Cuts Studio',
          'ownerName': 'Daniel Brooks',
          'phone': '+15551234002',
          'address': '88 Oak Street, Midtown',
          'location': const GeoPoint(24.8700, 67.0200),
          'rating': 4.7,
          'totalReviews': 86,
          'isPro': true,
          'photoUrl':
              'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=1200&q=80',
        },
        {
          'id': 'demo_shop_fade_lab',
          'shopName': 'Fade Lab',
          'ownerName': 'Marcus Lee',
          'phone': '+15551234003',
          'address': '5 Harbor Road',
          'location': const GeoPoint(24.8500, 66.9900),
          'rating': 4.8,
          'totalReviews': 64,
          'isPro': false,
          'photoUrl':
              'https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=1200&q=80',
        },
        {
          'id': 'demo_shop_luxe_chair',
          'shopName': 'Luxe Chair Barbers',
          'ownerName': 'Jamal Okonkwo',
          'phone': '+15551234004',
          'address': '220 King Blvd',
          'location': const GeoPoint(24.8655, 67.0105),
          'rating': 4.6,
          'totalReviews': 41,
          'isPro': false,
          'photoUrl':
              'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?auto=format&fit=crop&w=1200&q=80',
        },
      ];

  /// Shop + queue docs only (parallel) — what home needs to leave the skeleton.
  static Future<void> ensureDemoShopsFast() async {
    final fs = FirebaseFirestore.instance;
    await Future.wait([
      for (final shop in _catalogShops) _writeShopAndQueue(fs, shop),
    ]);
  }

  static Future<void> _writeShopAndQueue(
    FirebaseFirestore fs,
    Map<String, dynamic> shop,
  ) async {
    final id = shop['id'] as String;
    await Future.wait([
      fs.collection(FirestoreKeys.barbers).doc(id).set({
        FirestoreKeys.uid: id,
        FirestoreKeys.barberShopName: shop['shopName'],
        FirestoreKeys.barberOwnerName: shop['ownerName'],
        FirestoreKeys.barberPhone: shop['phone'],
        FirestoreKeys.barberEmail: '$id@demo.barberbook.app',
        FirestoreKeys.barberPhotoUrl: shop['photoUrl'],
        FirestoreKeys.barberLocation: shop['location'],
        FirestoreKeys.barberAddress: shop['address'],
        FirestoreKeys.barberRating: shop['rating'],
        FirestoreKeys.barberTotalReviews: shop['totalReviews'],
        FirestoreKeys.barberIsPro: shop['isPro'],
        FirestoreKeys.barberIsActive: true,
        FirestoreKeys.barberWorkingHours: _defaultHours,
        FirestoreKeys.barberServices: _premiumServices,
        FirestoreKeys.profileComplete: true,
        'isDemo': true,
        FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
        FirestoreKeys.createdAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
      fs.collection(FirestoreKeys.queue).doc(id).set({
        FirestoreKeys.queueBarberId: id,
        FirestoreKeys.queueEntries: [
          {
            FirestoreKeys.queueEntryCustomerId: 'demo_guest_1',
            FirestoreKeys.queueEntryName: 'Oliver Thompson',
            FirestoreKeys.queueEntryJoinedAt: Timestamp.now(),
          },
          {
            FirestoreKeys.queueEntryCustomerId: 'demo_guest_2',
            FirestoreKeys.queueEntryName: 'Noah Patel',
            FirestoreKeys.queueEntryJoinedAt: Timestamp.now(),
          },
        ],
        FirestoreKeys.queueCurrentServing: 3,
        FirestoreKeys.queueAvgWaitMins: 18,
        FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    ]);
  }

  /// Public catalog shops customers can browse (fixed demo IDs).
  static Future<void> ensureDemoCatalog() async {
    final fs = FirebaseFirestore.instance;
    final shops = _catalogShops;

    // Shops first (parallel) so discovery can unlock immediately.
    await Future.wait([
      for (final shop in shops) _writeShopAndQueue(fs, shop),
    ]);

    // Portfolios + reviews in parallel after shops exist.
    await Future.wait([
      for (var i = 0; i < shops.length; i++) ...[
        _seedPortfolio(fs, shops[i]['id'] as String, i),
        _seedReviews(fs, shops[i]['id'] as String, i),
      ],
    ]);
  }

  static Future<void> _seedPortfolio(
    FirebaseFirestore fs,
    String barberId,
    int shopIndex,
  ) async {
    await Future.wait([
      for (var i = 0; i < 4; i++)
        fs.collection(FirestoreKeys.portfolio).doc('demo_pf_${barberId}_$i').set({
          FirestoreKeys.id: 'demo_pf_${barberId}_$i',
          FirestoreKeys.portfolioBarberId: barberId,
          FirestoreKeys.portfolioImageUrl:
              _portfolioPool[(shopIndex * 2 + i) % _portfolioPool.length],
          FirestoreKeys.portfolioStyle: switch (i % 4) {
            0 => 'Fade',
            1 => 'Beard',
            2 => 'Classic',
            _ => 'Style',
          },
          'isDemo': true,
          FirestoreKeys.createdAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
    ]);
  }

  static Future<void> _seedReviews(
    FirebaseFirestore fs,
    String barberId,
    int shopIndex,
  ) async {
    await Future.wait([
      for (var i = 0; i < 3; i++)
        () {
          final template =
              _reviewTemplates[(shopIndex + i) % _reviewTemplates.length];
          final id = 'demo_rv_${barberId}_$i';
          return fs.collection(FirestoreKeys.reviews).doc(id).set({
            FirestoreKeys.id: id,
            FirestoreKeys.reviewBarberId: barberId,
            FirestoreKeys.reviewCustomerId: 'demo_reviewer_${barberId}_$i',
            FirestoreKeys.reviewCustomerName: template.name,
            FirestoreKeys.reviewRating: template.rating,
            FirestoreKeys.reviewComment: template.comment,
            'isDemo': true,
            FirestoreKeys.createdAt: Timestamp.fromDate(
              DateTime.now().subtract(Duration(days: 3 + i * 4)),
            ),
          }, SetOptions(merge: true));
        }(),
    ]);
  }

  /// Completes the signed-in demo barber profile + today's bookings/queue.
  static Future<void> seedDemoBarberAccount(String barberId) async {
    final fs = FirebaseFirestore.instance;
    final now = DateTime.now();

    await fs.collection(FirestoreKeys.barbers).doc(barberId).set({
      FirestoreKeys.uid: barberId,
      FirestoreKeys.barberShopName: 'Alex\'s Chair',
      FirestoreKeys.barberOwnerName: 'Alex Barber',
      FirestoreKeys.barberPhone: '+15559876001',
      FirestoreKeys.barberEmail: 'demo.barber@barberbook.app',
      FirestoreKeys.barberPhotoUrl: _demoBarberCover,
      FirestoreKeys.barberLocation: const GeoPoint(24.8607, 67.0011),
      FirestoreKeys.barberAddress: '101 Demo Street, City Center',
      FirestoreKeys.barberRating: 4.8,
      FirestoreKeys.barberTotalReviews: 52,
      FirestoreKeys.barberIsPro: true,
      FirestoreKeys.barberIsActive: true,
      FirestoreKeys.barberWorkingHours: _defaultHours,
      FirestoreKeys.barberServices: _premiumServices,
      FirestoreKeys.profileComplete: true,
      'isDemo': true,
      'excludeFromDiscovery': true,
      FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
      FirestoreKeys.createdAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await fs.collection(FirestoreKeys.users).doc(barberId).delete();
    } catch (_) {}

    await seedBarberData(barberId);
    await ensureDemoShopsFast().timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
    // ignore: unawaited_futures
    ensureDemoCatalog().catchError((_) {});

    for (final entry in [
      ('Maya Chen', 1),
      ('Lucas Wright', 2),
    ]) {
      final doc = fs.collection(FirestoreKeys.appointments).doc();
      await doc.set({
        FirestoreKeys.id: doc.id,
        FirestoreKeys.appointmentBarberId: barberId,
        FirestoreKeys.appointmentCustomerId: 'demo_past_${entry.$2}',
        FirestoreKeys.appointmentCustomerName: entry.$1,
        FirestoreKeys.appointmentService: _premiumServices[entry.$2 % 4],
        FirestoreKeys.appointmentSlot: Timestamp.fromDate(
          DateTime(now.year, now.month, now.day - entry.$2 - 1, 14, 0),
        ),
        FirestoreKeys.appointmentStatus:
            FirestoreKeys.appointmentStatusCompleted,
        'isDemo': true,
        FirestoreKeys.createdAt: FieldValue.serverTimestamp(),
      });
    }
  }

  /// Completes the signed-in demo customer + sample bookings against catalog.
  static Future<void> seedDemoCustomerAccount(String customerId) async {
    final fs = FirebaseFirestore.instance;
    final now = DateTime.now();

    // Fast shops first so home can load; extras in background.
    await ensureDemoShopsFast().timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
    // ignore: unawaited_futures
    ensureDemoCatalog().catchError((_) {});

    await fs.collection(FirestoreKeys.users).doc(customerId).set({
      FirestoreKeys.uid: customerId,
      FirestoreKeys.userName: 'Jordan Miles',
      FirestoreKeys.userPhone: '+15559876002',
      FirestoreKeys.userEmail: 'demo.customer@barberbook.app',
      FirestoreKeys.userPhotoUrl: '',
      FirestoreKeys.userRole: FirestoreKeys.roleCustomer,
      FirestoreKeys.userCity: 'Karachi',
      FirestoreKeys.profileComplete: true,
      'isDemo': true,
      FirestoreKeys.createdAt: FieldValue.serverTimestamp(),
      FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await fs.collection(FirestoreKeys.barbers).doc(customerId).delete();
    } catch (_) {}

    // Avoid duplicating demo bookings on every login — wipe prior demo rows.
    try {
      final existing = await fs
          .collection(FirestoreKeys.appointments)
          .where(FirestoreKeys.appointmentCustomerId, isEqualTo: customerId)
          .where('isDemo', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 3));
      await Future.wait(existing.docs.map((d) => d.reference.delete()));
    } catch (_) {}

    DateTime atClock(int dayOffset, int hour, int minute) {
      final d = now.add(Duration(days: dayOffset));
      return DateTime(d.year, d.month, d.day, hour, minute);
    }

    final bookings = [
      {
        'shopId': 'demo_shop_blend_house',
        'name': 'Jordan Miles',
        'service': _premiumServices[0],
        'when': atClock(1, 10, 0),
        'status': FirestoreKeys.appointmentStatusConfirmed,
      },
      {
        'shopId': 'demo_shop_noir_cuts',
        'name': 'Jordan Miles',
        'service': _premiumServices[3],
        'when': atClock(3, 14, 30),
        'status': FirestoreKeys.appointmentStatusConfirmed,
      },
      {
        'shopId': 'demo_shop_fade_lab',
        'name': 'Jordan Miles',
        'service': _premiumServices[1],
        'when': atClock(-5, 17, 0),
        'status': FirestoreKeys.appointmentStatusCompleted,
      },
    ];

    await Future.wait([
      for (final b in bookings)
        () {
          final doc = fs.collection(FirestoreKeys.appointments).doc();
          return doc.set({
            FirestoreKeys.id: doc.id,
            FirestoreKeys.appointmentBarberId: b['shopId'],
            FirestoreKeys.appointmentCustomerId: customerId,
            FirestoreKeys.appointmentCustomerName: b['name'],
            FirestoreKeys.appointmentService: b['service'],
            FirestoreKeys.appointmentSlot:
                Timestamp.fromDate(b['when'] as DateTime),
            FirestoreKeys.appointmentStatus: b['status'],
            'isDemo': true,
            FirestoreKeys.createdAt: FieldValue.serverTimestamp(),
          });
        }(),
    ]);
  }

  /// Existing helper used by the debug seed button on barber profile.
  static Future<void> seedBarberData(String barberId) async {
    final fs = FirebaseFirestore.instance;
    final now = DateTime.now();
    final demoServices = _premiumServices;

    await fs.collection(FirestoreKeys.barbers).doc(barberId).set({
      FirestoreKeys.barberServices: demoServices,
      FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final demoQueue = [
      {
        FirestoreKeys.queueEntryCustomerId: 'demo_1',
        FirestoreKeys.queueEntryName: 'James Wilson',
        FirestoreKeys.queueEntryJoinedAt:
            Timestamp.fromDate(now.subtract(const Duration(minutes: 45))),
      },
      {
        FirestoreKeys.queueEntryCustomerId: 'demo_2',
        FirestoreKeys.queueEntryName: 'Michael Chen',
        FirestoreKeys.queueEntryJoinedAt:
            Timestamp.fromDate(now.subtract(const Duration(minutes: 30))),
      },
      {
        FirestoreKeys.queueEntryCustomerId: 'demo_3',
        FirestoreKeys.queueEntryName: 'Oliver Thompson',
        FirestoreKeys.queueEntryJoinedAt:
            Timestamp.fromDate(now.subtract(const Duration(minutes: 10))),
      },
      {
        FirestoreKeys.queueEntryCustomerId: 'demo_4',
        FirestoreKeys.queueEntryName: "Liam O'Connor",
        FirestoreKeys.queueEntryJoinedAt:
            Timestamp.fromDate(now.subtract(const Duration(minutes: 2))),
      },
    ];

    await fs.collection(FirestoreKeys.queue).doc(barberId).set({
      FirestoreKeys.queueBarberId: barberId,
      FirestoreKeys.queueEntries: demoQueue,
      FirestoreKeys.queueCurrentServing: 16,
      FirestoreKeys.queueAvgWaitMins: 20,
      FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final todaySlots = [
      {'name': 'Ahmed Khan', 'hour': 10, 'min': 0, 'service': demoServices[0]},
      {'name': 'Ryan Cole', 'hour': 12, 'min': 30, 'service': demoServices[1]},
      {'name': 'Sarah Miller', 'hour': 15, 'min': 0, 'service': demoServices[2]},
      {'name': 'Robert Smith', 'hour': 17, 'min': 30, 'service': demoServices[3]},
    ];

    for (final app in todaySlots) {
      final doc = fs.collection(FirestoreKeys.appointments).doc();
      await doc.set({
        FirestoreKeys.id: doc.id,
        FirestoreKeys.appointmentBarberId: barberId,
        FirestoreKeys.appointmentCustomerId: 'demo_customer',
        FirestoreKeys.appointmentCustomerName: app['name'],
        FirestoreKeys.appointmentService: app['service'],
        FirestoreKeys.appointmentSlot: Timestamp.fromDate(
          DateTime(
            now.year,
            now.month,
            now.day,
            app['hour'] as int,
            app['min'] as int,
          ),
        ),
        FirestoreKeys.appointmentStatus:
            FirestoreKeys.appointmentStatusConfirmed,
        'isDemo': true,
        FirestoreKeys.createdAt: FieldValue.serverTimestamp(),
      });
    }
  }
}
