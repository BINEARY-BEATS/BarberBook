import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_keys.dart';

final queueRepositoryProvider = Provider((ref) => QueueRepository());

class QueueRepository {
  QueueRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _ref(String barberId) =>
      _db.collection(FirestoreKeys.queue).doc(barberId);

  Future<void> _ensureDoc(String barberId) async {
    final snap = await _ref(barberId).get();
    if (!snap.exists) {
      await _ref(barberId).set({
        FirestoreKeys.queueBarberId: barberId,
        FirestoreKeys.queueEntries: <Map<String, dynamic>>[],
        FirestoreKeys.queueCurrentServing: 0,
        FirestoreKeys.queueAvgWaitMins: 15,
        FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> joinQueue({
    required String barberId,
    required String customerId,
    required String name,
  }) async {
    await _ensureDoc(barberId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_ref(barberId));
      final data = snap.data() ?? {};
      final entries = List<Map<String, dynamic>>.from(
        (data[FirestoreKeys.queueEntries] as List?)?.map(
              (e) => Map<String, dynamic>.from(e as Map),
            ) ??
            [],
      );
      if (entries.any((e) => e[FirestoreKeys.queueEntryCustomerId] == customerId)) {
        return;
      }
      entries.add({
        FirestoreKeys.queueEntryCustomerId: customerId,
        FirestoreKeys.queueEntryName: name,
        FirestoreKeys.queueEntryJoinedAt: Timestamp.now(),
      });
      tx.set(
        _ref(barberId),
        {
          FirestoreKeys.queueBarberId: barberId,
          FirestoreKeys.queueEntries: entries,
          FirestoreKeys.queueAvgWaitMins: _avgWait(entries.length),
          FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> leaveQueue({
    required String barberId,
    required String customerId,
  }) async {
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_ref(barberId));
      if (!snap.exists) return;
      final data = snap.data()!;
      final entries = List<Map<String, dynamic>>.from(
        (data[FirestoreKeys.queueEntries] as List?)?.map(
              (e) => Map<String, dynamic>.from(e as Map),
            ) ??
            [],
      );
      entries.removeWhere(
        (e) => e[FirestoreKeys.queueEntryCustomerId] == customerId,
      );
      tx.update(_ref(barberId), {
        FirestoreKeys.queueEntries: entries,
        FirestoreKeys.queueAvgWaitMins: _avgWait(entries.length),
        FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> addWalkIn({
    required String barberId,
    required String name,
  }) async {
    await joinQueue(
      barberId: barberId,
      customerId: 'walkin_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
    );
  }

  Future<void> serveNext(String barberId) async {
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_ref(barberId));
      if (!snap.exists) return;
      final data = snap.data()!;
      final entries = List<Map<String, dynamic>>.from(
        (data[FirestoreKeys.queueEntries] as List?)?.map(
              (e) => Map<String, dynamic>.from(e as Map),
            ) ??
            [],
      );
      if (entries.isEmpty) return;
      entries.removeAt(0);
      final current = (data[FirestoreKeys.queueCurrentServing] as num?)?.toInt() ?? 0;
      tx.update(_ref(barberId), {
        FirestoreKeys.queueEntries: entries,
        FirestoreKeys.queueCurrentServing: current + 1,
        FirestoreKeys.queueAvgWaitMins: _avgWait(entries.length),
        FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
      });
    });
  }

  int _avgWait(int count) => count <= 0 ? 0 : count * 15;
}
