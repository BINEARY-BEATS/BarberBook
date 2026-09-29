import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/book_empty_state.dart';
import '../../../core/widgets/book_primary_button.dart';
import '../../../core/widgets/book_skeleton.dart';
import '../../../core/widgets/book_status_chip.dart';
import '../../../core/widgets/portfolio_image.dart';
import '../../barber/providers/barber_provider.dart';
import '../../chat/data/chat_repository.dart';
import '../../portfolio/data/portfolio_repository.dart';
import '../../queue/data/queue_repository.dart';
import '../../reviews/data/review_repository.dart';
import '../widgets/queue_status_widget.dart';

class BarberDetailScreen extends ConsumerWidget {
  const BarberDetailScreen({super.key, required this.barberId});
  final String barberId;

  Future<void> _joinOrLeave(
    BuildContext context,
    WidgetRef ref, {
    required bool inQueue,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final repo = ref.read(queueRepositoryProvider);
    try {
      if (inQueue) {
        await repo.leaveQueue(barberId: barberId, customerId: user.uid);
      } else {
        await repo.joinQueue(
          barberId: barberId,
          customerId: user.uid,
          name: user.displayName ?? 'Guest',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final id = await ref.read(chatRepositoryProvider).getOrCreateConversation(
            barberId: barberId,
            customerId: user.uid,
          );
      if (context.mounted) {
        context.push('/customer/chat/$id');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _leaveReview(BuildContext context, WidgetRef ref) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    double rating = 5;
    final comment = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.customerCard,
      builder: (ctx) {
        return Theme(
          data: AppTheme.customer(),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              final accent = Theme.of(ctx).colorScheme.primary;
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
                      'Leave a review',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        return IconButton(
                          onPressed: () =>
                              setModal(() => rating = star.toDouble()),
                          icon: Icon(
                            star <= rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: accent,
                          ),
                        );
                      }),
                    ),
                    TextField(
                      controller: comment,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Comment'),
                    ),
                    const SizedBox(height: 20),
                    BookPrimaryButton(
                      label: 'Submit',
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    if (ok != true) return;
    try {
      await ref.read(reviewRepositoryProvider).submitReview(
            barberId: barberId,
            customerId: user.uid,
            customerName: user.displayName ?? 'Guest',
            rating: rating,
            comment: comment.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for the review.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: AppTheme.customer(),
      child: _BarberDetailBody(
        barberId: barberId,
        onJoinOrLeave: (inQueue) =>
            _joinOrLeave(context, ref, inQueue: inQueue),
        onOpenChat: () => _openChat(context, ref),
        onLeaveReview: () => _leaveReview(context, ref),
      ),
    );
  }
}

class _BarberDetailBody extends ConsumerWidget {
  const _BarberDetailBody({
    required this.barberId,
    required this.onJoinOrLeave,
    required this.onOpenChat,
    required this.onLeaveReview,
  });

  final String barberId;
  final Future<void> Function(bool inQueue) onJoinOrLeave;
  final VoidCallback onOpenChat;
  final VoidCallback onLeaveReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final asyncBarber = ref.watch(currentBarberProvider(barberId));
    final portfolioAsync = ref.watch(barberPortfolioProvider(barberId));
    final reviewsAsync = ref.watch(
      StreamProvider.autoDispose(
        (ref) => ref.watch(reviewRepositoryProvider).watchReviews(barberId),
      ),
    );
    final queueAsync = ref.watch(barberQueueProvider(barberId));
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: asyncBarber.when(
        data: (barber) {
          if (barber == null) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                ),
              ),
              body: const BookEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Not found',
                subtitle: 'This shop is no longer available.',
              ),
            );
          }

          final inQueue = queueAsync.maybeWhen(
            data: (q) {
              final entries = (q?['entries'] as List?) ?? [];
              return entries.any(
                (e) => e is Map && e['customerId'] == uid,
              );
            },
            orElse: () => false,
          );

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.darkSurface,
                leading: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                    ),
                    tooltip: 'Message',
                    onPressed: onOpenChat,
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (barber.photoUrl.trim().isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: barber.photoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => _heroFallback(barber.shopName),
                        )
                      else
                        _heroFallback(barber.shopName),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0xCC121212),
                              AppColors.darkSurface,
                            ],
                            stops: [0.35, 0.75, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Text(
                          barber.shopName,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              barber.ownerName,
                              style: const TextStyle(
                                color: AppColors.customerSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (barber.isPro)
                            BookStatusChip(
                              label: 'Pro',
                              tone: BookStatusTone.accent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.gold,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${barber.rating.toStringAsFixed(1)} · ${barber.totalReviews} reviews',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (barber.address.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: AppColors.customerSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                barber.address,
                                style: const TextStyle(
                                  color: AppColors.customerSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: BookPrimaryButton(
                              label: 'Call Now',
                              outlined: true,
                              icon: Icons.phone_rounded,
                              onPressed: barber.phone.isEmpty
                                  ? null
                                  : () async {
                                      final uri = Uri(
                                        scheme: 'tel',
                                        path: barber.phone,
                                      );
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: BookPrimaryButton(
                              label: 'Message',
                              outlined: true,
                              icon: Icons.chat_bubble_outline_rounded,
                              onPressed: onOpenChat,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      if (barber.isActive) ...[
                        Text(
                          'Walk-in queue',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        QueueStatusWidget(barberId: barberId),
                        const SizedBox(height: 12),
                        BookPrimaryButton(
                          label: inQueue
                              ? 'Leave queue'
                              : 'Join walk-in queue',
                          accent: !inQueue,
                          onPressed: () => onJoinOrLeave(inQueue),
                        ),
                        const SizedBox(height: 28),
                      ],
                      Text(
                        'Services',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (barber.services.isEmpty)
                        const Text(
                          'No services listed yet.',
                          style: TextStyle(color: AppColors.customerSecondary),
                        )
                      else
                        ...barber.services.asMap().entries.map((entry) {
                          final i = entry.key;
                          final service = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.customerCard,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.r16),
                              border:
                                  Border.all(color: AppColors.customerBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '${service.durationMinutes} min',
                                        style: const TextStyle(
                                          color: AppColors.customerSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${service.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilledButton(
                                  onPressed: () => context.push(
                                    '/customer/booking/$barberId?serviceIndex=$i',
                                  ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(72, 40),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                  ),
                                  child: const Text('Book'),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 24),
                      Text(
                        'Portfolio',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      portfolioAsync.when(
                        data: (items) {
                          if (items.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 28,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.r16),
                                border: Border.all(
                                  color: AppColors.customerBorder,
                                  style: BorderStyle.solid,
                                  width: 1.5,
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.photo_library_outlined,
                                    color: AppColors.customerSecondary,
                                    size: 32,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Photos coming soon',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.customerSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, i) => ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.r12),
                                child: PortfolioImage(
                                  imageUrl: items[i].imageUrl,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                        loading: () => const BookSkeleton(height: 110),
                        error: (e, _) => Text('$e'),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text(
                            'Reviews',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: onLeaveReview,
                            child: const Text('Write'),
                          ),
                        ],
                      ),
                      reviewsAsync.when(
                        data: (reviews) {
                          if (reviews.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'No reviews yet. Be the first.',
                                style: TextStyle(
                                  color: AppColors.customerSecondary,
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: reviews.take(5).map((r) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.customerCard,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.r16,
                                  ),
                                  border: Border.all(
                                    color: AppColors.customerBorder,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          r.customerName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${r.rating.toStringAsFixed(1)}★',
                                          style: const TextStyle(
                                            color: AppColors.gold,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (r.comment.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        r.comment,
                                        style: const TextStyle(
                                          color: AppColors.customerSecondary,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: BookSkeleton(height: 64),
                        ),
                        error: (e, _) => Text('$e'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(body: BookDetailSkeleton()),
        error: (e, _) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: Center(child: Text('$e')),
        ),
      ),
    );
  }

  Widget _heroFallback(String name) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2A2A), Color(0xFF121212)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
    );
  }
}
