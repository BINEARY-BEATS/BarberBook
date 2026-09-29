import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/book_primary_button.dart';
import '../../../core/widgets/book_status_chip.dart';
import '../../queue/data/queue_repository.dart';
import '../providers/barber_provider.dart';

class QueueManagerWidget extends ConsumerWidget {
  const QueueManagerWidget({super.key});

  Future<void> _addWalkIn(BuildContext context, WidgetRef ref, String uid) async {
    final controller = TextEditingController();
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New walk-in',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Customer name'),
              ),
              const SizedBox(height: 24),
              BookPrimaryButton(
                label: 'Add to queue',
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
    if (name == null || name.isEmpty) return;
    await ref.read(queueRepositoryProvider).addWalkIn(barberId: uid, name: name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final asyncQueue = ref.watch(barberQueueProvider(uid));

    return asyncQueue.when(
      data: (queue) {
        final entries = List<Map<String, dynamic>>.from(
          queue?[FirestoreKeys.queueEntries] ?? [],
        );
        final currentServing =
            queue?[FirestoreKeys.queueCurrentServing] as int? ?? 0;
        final avgWait = queue?[FirestoreKeys.queueAvgWaitMins] as int? ?? 15;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card(isDark),
                borderRadius: BorderRadius.circular(AppRadius.r16),
                boxShadow: isDark ? null : AppColors.cardShadow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'Serving',
                      value: currentServing == 0 ? '—' : '#$currentServing',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: AppColors.divider(isDark),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'Waiting',
                      value: '${entries.length}',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: AppColors.divider(isDark),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'Avg wait',
                      value: entries.isEmpty ? '—' : '${avgWait}m',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No one in the waitlist.',
                  style: TextStyle(color: AppColors.secondaryText(isDark)),
                ),
              )
            else
              ...entries.take(5).toList().asMap().entries.map((e) {
                final name =
                    e.value[FirestoreKeys.queueEntryName] as String? ?? 'Guest';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.card(isDark),
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    boxShadow: isDark ? null : AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.accentSoft,
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.onSurface(isDark),
                          ),
                        ),
                      ),
                      const BookStatusChip(
                        label: 'Waiting',
                        tone: BookStatusTone.pending,
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 12),
            BookPrimaryButton(
              label: 'Serve next customer',
              icon: Icons.check_circle_outline,
              onPressed: entries.isEmpty
                  ? null
                  : () => ref.read(queueRepositoryProvider).serveNext(uid),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _addWalkIn(context, ref, uid),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Add walk-in'),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (e, _) =>
          Text('Queue error: $e', style: theme.textTheme.bodyMedium),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryText(isDark),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
