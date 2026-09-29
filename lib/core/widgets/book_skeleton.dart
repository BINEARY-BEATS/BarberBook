import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Lightweight shimmer block for loading states (no extra packages).
class BookSkeleton extends StatefulWidget {
  const BookSkeleton({
    this.width,
    this.height = 16,
    this.borderRadius,
    super.key,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<BookSkeleton> createState() => _BookSkeletonState();
}

class _BookSkeletonState extends State<BookSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.themeAccent(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(AppRadius.r12),
            color: Color.lerp(
              AppColors.surfaceElevated,
              accent.withValues(alpha: 0.22),
              t,
            ),
          ),
        );
      },
    );
  }
}

/// Shop card placeholder matching [BarberCard] proportions.
class BookShopCardSkeleton extends StatelessWidget {
  const BookShopCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.customerCard,
        borderRadius: BorderRadius.circular(AppRadius.r20),
        border: Border.all(color: AppColors.customerBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BookSkeleton(
            height: 168,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.r20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BookSkeleton(width: 160, height: 18),
                const SizedBox(height: 10),
                const BookSkeleton(width: 220, height: 12),
                const SizedBox(height: 14),
                const BookSkeleton(width: 120, height: 12),
                const SizedBox(height: 16),
                BookSkeleton(
                  height: 40,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Booking row placeholder.
class BookBookingRowSkeleton extends StatelessWidget {
  const BookBookingRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.customerCard,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.customerBorder),
      ),
      child: const Row(
        children: [
          BookSkeleton(
            width: 44,
            height: 44,
            borderRadius: BorderRadius.all(Radius.circular(22)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookSkeleton(width: 140, height: 14),
                SizedBox(height: 8),
                BookSkeleton(width: 180, height: 12),
              ],
            ),
          ),
          BookSkeleton(width: 64, height: 22),
        ],
      ),
    );
  }
}

/// Detail screen loading skeleton (hero + service rows).
class BookDetailSkeleton extends StatelessWidget {
  const BookDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const BookSkeleton(
          height: 260,
          borderRadius: BorderRadius.zero,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BookSkeleton(width: 200, height: 28),
              const SizedBox(height: 12),
              const BookSkeleton(width: 140, height: 14),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: BookSkeleton(
                      height: 48,
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BookSkeleton(
                      height: 48,
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const BookSkeleton(width: 100, height: 20),
              const SizedBox(height: 14),
              for (var i = 0; i < 3; i++) ...[
                BookSkeleton(
                  height: 72,
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
