import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_keys.dart';

/// A developer utility to populate the app with realistic barber shop data.
class DemoSeeder {
  DemoSeeder._();

  static Future<void> seedBarberData(String barberId) async {
    final fs = FirebaseFirestore.instance;
    final now = DateTime.now();

    // 1. Seed Services
    final servicesRef = fs.collection(FirestoreKeys.barbers).doc(barberId).collection(FirestoreKeys.barberServices);
    
    final demoServices = [
      {'name': 'Midnight Signature Fade', 'price': 65.0, 'durationMinutes': 45},
      {'name': 'Royal Velvet Hot Shave', 'price': 55.0, 'durationMinutes': 40},
      {'name': 'VIP Beard Sculpting', 'price': 45.0, 'durationMinutes': 30},
      {'name': 'Executive Scissor Cut & Style', 'price': 85.0, 'durationMinutes': 60},
      {'name': 'The Gentleman\'s Ritual', 'price': 120.0, 'durationMinutes': 90},
      {'name': 'Neo-Tech Taper & Line-up', 'price': 35.0, 'durationMinutes': 20},
    ];

    for (final s in demoServices) {
      await servicesRef.add({
        ...s,
        FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
      });
    }

    // 2. Seed Queue Entries (Waitlist)
    final queueRef = fs.collection(FirestoreKeys.queue).doc(barberId);
    final demoQueue = [
      {'entryCustomerId': '', 'entryName': 'James Wilson', 'joinedAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 45)))},
      {'entryCustomerId': '', 'entryName': 'Michael Chen', 'joinedAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 30)))},
      {'entryCustomerId': '', 'entryName': 'Saeed Al-Mansoori', 'joinedAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 10)))},
      {'entryCustomerId': '', 'entryName': 'Liam O\'connor', 'joinedAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 2)))},
    ];

    await queueRef.set({
      FirestoreKeys.queueBarberId: barberId,
      FirestoreKeys.queueEntries: demoQueue,
      FirestoreKeys.queueCurrentServing: 12, // Arbitrary starting point
      FirestoreKeys.queueAvgWaitMins: 20,
      FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. Seed Appointments (Today)
    final appsRef = fs.collection(FirestoreKeys.appointments);
    
    final todaySlots = [
      {'customerName': 'Ahmed Khan', 'slot': Timestamp.fromDate(DateTime(now.year, now.month, now.day, 10, 0))},
      {'customerName': 'John Doe', 'slot': Timestamp.fromDate(DateTime(now.year, now.month, now.day, 12, 30))},
      {'customerName': 'Sarah Miller', 'slot': Timestamp.fromDate(DateTime(now.year, now.month, now.day, 15, 0))},
      {'customerName': 'Robert Smith', 'slot': Timestamp.fromDate(DateTime(now.year, now.month, now.day, 17, 30))},
    ];

    for (final app in todaySlots) {
      await appsRef.add({
        FirestoreKeys.appointmentBarberId: barberId,
        FirestoreKeys.appointmentCustomerName: app['customerName'],
        FirestoreKeys.appointmentSlot: app['slot'],
        FirestoreKeys.appointmentStatus: FirestoreKeys.appointmentStatusConfirmed,
        FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
      });
    }
  }
}
