import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/firestore_keys.dart';
import '../providers/barber_provider.dart';

class QueueManagerWidget extends ConsumerWidget {
  const QueueManagerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final asyncQueue = ref.watch(barberQueueProvider(user?.uid ?? ''));

    return asyncQueue.when(
      data: (queue) {
        if (queue == null) return const Center(child: Text('Service offline.', style: TextStyle(color: Colors.white24)));

        final entries = List<Map<String, dynamic>>.from(queue[FirestoreKeys.queueEntries] ?? []);
        final currentServing = queue[FirestoreKeys.queueCurrentServing] as int? ?? 10;
        final avgWait = queue[FirestoreKeys.queueAvgWaitMins] as int? ?? 15;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusItem(label: 'CURRENTLY SERVING', value: '#$currentServing'),
                  Container(width: 1, height: 40, color: Colors.white.withOpacity(0.05)),
                  _StatusItem(label: 'AVERAGE WAIT', value: '${avgWait}M'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (entries.isEmpty)
              const Center(child: Text('No customers in waitlist.', style: TextStyle(color: Colors.white12, fontStyle: FontStyle.italic)))
            else
              ...entries.take(3).map((entry) {
                final name = entry[FirestoreKeys.queueEntryName] ?? 'Guest';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050505),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.02)),
                  ),
                  child: Row(
                    children: [
                      Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 1)),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(backgroundColor: cs.secondary, foregroundColor: Colors.black),
                child: const Text('SERVE NEXT CUSTOMER'),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => Center(child: Text('Error: $e')),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.label, required this.value});
  final String label; final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 1.5)),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.lexend(fontSize: 24, fontWeight: FontWeight.w200, color: Colors.white)),
    ],
  );
}
