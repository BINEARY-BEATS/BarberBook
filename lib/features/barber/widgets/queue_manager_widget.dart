import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../core/widgets/book_empty_state.dart';
import '../providers/barber_provider.dart';

/// Real-time queue manager for barber walk-ins.
///
/// Supports:
/// - Viewing the queue with live position numbers.
/// - Marking the next customer as served ("Next customer").
/// - Adding a new walk-in customer ("Add walk-in").
class QueueManagerWidget extends ConsumerWidget {
  /// Creates a [QueueManagerWidget].
  const QueueManagerWidget({required this.barberId, super.key});

  /// The barber uid (used as the queue document id).
  final String barberId;

  /// Extracts queue entries from [data] document data.
  List<Map<String, dynamic>> _extractEntries(Map<String, dynamic> data) {
    final value = data[FirestoreKeys.queueEntries];
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
  }

  /// Gets currentServing from [data] safely.
  int _extractCurrentServing(Map<String, dynamic> data) {
    final v = data[FirestoreKeys.queueCurrentServing];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  /// Gets avgWaitMins from [data] safely.
  int _extractAvgWaitMins(Map<String, dynamic> data) {
    final v = data[FirestoreKeys.queueAvgWaitMins];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 10;
  }

  /// Marks the next customer in the queue as served.
  Future<void> _serveNext({
    required Map<String, dynamic> queueData,
    required BuildContext context,
  }) async {
    final entries = _extractEntries(queueData);
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No customers in queue.')),
      );
      return;
    }

    final fs = FirebaseFirestore.instance;
    final queueRef = fs.collection(FirestoreKeys.queue).doc(barberId);

    try {
      await fs.runTransaction((transaction) async {
        final snap = await transaction.get(queueRef);
        final data = snap.data();
        final serverData = data ?? queueData;

        final currentServing = _extractCurrentServing(serverData);
        final currentEntries = _extractEntries(serverData);
        if (currentEntries.isEmpty) return;

        final newEntries = currentEntries.skip(1).toList();
        final newCurrentServing = currentServing + 1;

        transaction.set(
          queueRef,
          <String, dynamic>{
            FirestoreKeys.queueEntries: newEntries,
            FirestoreKeys.queueCurrentServing: newCurrentServing,
            FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to serve next: ${e.toString()}')),
      );
    }
  }

  /// Adds a new walk-in customer to the queue.
  Future<void> _addWalkIn({
    required BuildContext context,
    required String customerName,
  }) async {
    final fs = FirebaseFirestore.instance;
    final queueRef = fs.collection(FirestoreKeys.queue).doc(barberId);

    try {
      await fs.runTransaction((transaction) async {
        final snap = await transaction.get(queueRef);
        final data = snap.data();

        final currentServing = data == null
            ? 0
            : _extractCurrentServing(data);
        final avgWaitMins = data == null
            ? 10
            : _extractAvgWaitMins(data);
        final currentEntries = data == null
            ? <Map<String, dynamic>>[]
            : _extractEntries(data);

        final newEntry = <String, dynamic>{
          FirestoreKeys.queueEntryCustomerId: '',
          FirestoreKeys.queueEntryName: customerName,
          FirestoreKeys.queueEntryJoinedAt: FieldValue.serverTimestamp(),
        };

        final newEntries = [...currentEntries, newEntry];

        transaction.set(
          queueRef,
          <String, dynamic>{
            FirestoreKeys.queueBarberId: barberId,
            FirestoreKeys.queueEntries: newEntries,
            FirestoreKeys.queueCurrentServing: currentServing,
            FirestoreKeys.queueAvgWaitMins: avgWaitMins,
            FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add walk-in: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(barberQueueProvider(barberId));

    return queueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: BookEmptyState(
          icon: Icons.groups_outlined,
          title: 'Queue unavailable',
          subtitle: e.toString(),
        ),
      ),
      data: (queueData) {
        if (queueData == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Card(
              elevation: 0,
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.45),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: BookEmptyState(
                  icon: Icons.queue_music_rounded,
                  title: 'No queue yet',
                  subtitle:
                      'When you add walk-ins or customers join, they will appear here.',
                ),
              ),
            ),
          );
        }

        final entries = _extractEntries(queueData);
        final currentServing = _extractCurrentServing(queueData);
        final avgWaitMins = _extractAvgWaitMins(queueData);

        final estimatedWait = entries.length * avgWaitMins;

        return Stack(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              elevation: 0,
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.55),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Walk-in queue',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Chip(
                          avatar: const Icon(Icons.timer_outlined, size: 18),
                          label: Text('~$estimatedWait min'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (entries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('No one is waiting right now.'),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final name =
                              (entry[FirestoreKeys.queueEntryName]
                                      as String?) ??
                                  'Customer';
                          final position = currentServing + index + 1;

                          return ListTile(
                            dense: true,
                            title: Text('$position. $name'),
                          );
                        },
                      ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () =>
                          _serveNext(queueData: queueData, context: context),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Serve next'),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: FloatingActionButton(
                onPressed: () async {
                  final controller = TextEditingController();
                  final name = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Add walk-in'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: 'Customer name',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              final text = controller.text.trim();
                              if (text.isEmpty) return;
                              Navigator.of(context).pop(text);
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      );
                    },
                  );

                  if (name == null) return;
                  if (!context.mounted) return;
                  await _addWalkIn(
                    context: context,
                    customerName: name,
                  );
                },
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }
}

