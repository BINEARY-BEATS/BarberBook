import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../barber/providers/barber_provider.dart';

/// Shows the customer's real-time position in the barber's walk-in queue.
class QueueStatusWidget extends ConsumerWidget {
  /// Creates a [QueueStatusWidget].
  const QueueStatusWidget({required this.barberId, super.key});

  /// Barber uid that owns the queue document.
  final String barberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final queueAsync = ref.watch(barberQueueProvider(barberId));

    return queueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Queue error: $e')),
      data: (queueData) {
        if (queueData == null) {
          return const Text('Queue is empty.');
        }

        final entriesValue = queueData[FirestoreKeys.queueEntries];
        if (entriesValue is! List || entriesValue.isEmpty) {
          return const Text('Queue is empty.');
        }

        final entries = entriesValue.whereType<Map>().toList();
        final myUid = currentUser?.uid ?? '';

        final index = entries.indexWhere((entry) {
          final customerId = entry[FirestoreKeys.queueEntryCustomerId];
          return customerId is String && customerId == myUid;
        });

        if (index < 0) {
          return const Text('You are not currently in the queue.');
        }

        final position = index + 1;
        final avgWait = queueData[FirestoreKeys.queueAvgWaitMins];
        final avgWaitMins = avgWait is int
            ? avgWait
            : (avgWait is num ? avgWait.toInt() : 10);

        final estimatedWait = (position - 1) * avgWaitMins;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              position == 1
                  ? 'You\'re next!'
                  : 'You are number $position in queue',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'About $estimatedWait minutes',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
      },
    );
  }
}

