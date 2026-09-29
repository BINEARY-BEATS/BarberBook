import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../barber/models/barber_model.dart';

/// Premium dark shop card for the customer home feed.
class BarberCard extends StatelessWidget {
  const BarberCard({
    required this.barber,
    required this.distanceKm,
    this.compact = false,
    super.key,
  });

  final BarberModel barber;
  final double distanceKm;
  final bool compact;

  String get _fromPrice {
    if (barber.services.isEmpty) return '—';
    final min =
        barber.services.map((s) => s.price).reduce((a, b) => a < b ? a : b);
    return '\$${min.toStringAsFixed(0)}';
  }

  String get _hoursLabel {
    final today = DateTime.now().weekday;
    const keys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final key = keys[today - 1];
    final hours = barber.workingHours[key];
    if (hours == null) return barber.isActive ? 'Open now' : 'Closed';
    final open = hours['open'] ?? '09:00';
    final close = hours['close'] ?? '20:00';
    return barber.isActive ? 'Open · $open–$close' : 'Closed';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final hasPhoto = barber.photoUrl.trim().isNotEmpty;
    final imageH = compact ? 148.0 : 168.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/customer/barber/${barber.uid}'),
        borderRadius: BorderRadius.circular(AppRadius.r20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.customerCard,
            borderRadius: BorderRadius.circular(AppRadius.r20),
            border: Border.all(color: AppColors.customerBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.r20),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      height: imageH,
                      width: double.infinity,
                      child: hasPhoto
                          ? CachedNetworkImage(
                              imageUrl: barber.photoUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => _gradientFallback(),
                              errorWidget: (_, _, _) => _gradientFallback(),
                            )
                          : _gradientFallback(),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 80,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.72),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      bottom: 12,
                      right: 14,
                      child: Text(
                        barber.shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    if (barber.isPro)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(AppRadius.r24),
                          ),
                          child: Text(
                            'Pro',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      barber.address.isNotEmpty
                          ? barber.address
                          : barber.ownerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.customerSecondary,
                      ),
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
                          barber.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          ' (${barber.totalReviews})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.customerSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.near_me_rounded,
                          size: 14,
                          color: AppColors.customerSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.customerSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          barber.isActive ? 'Open' : 'Closed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: barber.isActive
                                ? AppColors.success
                                : AppColors.customerSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_hoursLabel · from $_fromPrice',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.customerSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            context.push('/customer/barber/${barber.uid}'),
                        style: TextButton.styleFrom(
                          foregroundColor: accent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        child: const Text(
                          'Book',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradientFallback() {
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
        barber.shopName,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}
