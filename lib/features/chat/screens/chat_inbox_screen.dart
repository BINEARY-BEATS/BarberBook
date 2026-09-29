import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/book_empty_state.dart';
import '../../barber/providers/barber_provider.dart';
import '../data/chat_repository.dart';
import '../models/chat_models.dart';

final chatInboxProvider =
    StreamProvider.autoDispose<List<ConversationModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).watchInbox(uid);
});

class ChatInboxScreen extends ConsumerWidget {
  const ChatInboxScreen({
    super.key,
    this.embedded = false,
    this.basePath = '/customer',
  });

  final bool embedded;
  final String basePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(chatInboxProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return const BookEmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No messages yet',
              subtitle: 'Message a shop from their profile to start a chat.',
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              embedded ? BookScaffoldPadding.bottomNav : 24,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final c = items[i];
              final otherId =
                  c.barberId == uid ? c.customerId : c.barberId;
              final isBarberSide = c.barberId == uid;
              return _InboxTile(
                conversation: c,
                otherId: otherId,
                showCustomerName: isBarberSide,
                isDark: isDark,
                onTap: () => context.push('$basePath/chat/${c.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _InboxTile extends ConsumerWidget {
  const _InboxTile({
    required this.conversation,
    required this.otherId,
    required this.showCustomerName,
    required this.isDark,
    required this.onTap,
  });

  final ConversationModel conversation;
  final String otherId;
  final bool showCustomerName;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleAsync = showCustomerName
        ? null
        : ref.watch(currentBarberProvider(otherId));

    String title = showCustomerName ? 'Customer' : 'Shop';
    if (!showCustomerName && titleAsync != null) {
      title = titleAsync.maybeWhen(
        data: (b) => b?.shopName.isNotEmpty == true ? b!.shopName : 'Shop',
        orElse: () => 'Shop',
      );
    }

    return Material(
      color: AppColors.card(isDark),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.accent.withValues(alpha: 0.18),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.lastMessage.isEmpty
                          ? 'Say hello…'
                          : conversation.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.secondaryText(isDark),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('MMM d').format(conversation.updatedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.mutedText(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
