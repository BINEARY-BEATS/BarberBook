import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../barber/models/barber_model.dart';

/// Card widget used on the customer home screen for displaying a barber.
class BarberCard extends StatelessWidget {
  /// Creates a [BarberCard].
  const BarberCard({
    required this.barber,
    required this.distanceKm,
    super.key,
  });

  /// Barber profile.
  final BarberModel barber;

  /// Distance from the current user in kilometers.
  final double distanceKm;

  /// Builds a basic star rating row.
  Widget _buildStars(double rating) {
    final rounded = rating.isNaN ? 0.0 : rating;
    final fullStars = rounded.floor().clamp(0, 5);
    final hasHalf = (rounded - fullStars) >= 0.5;
    final totalFilled = fullStars + (hasHalf ? 1 : 0);

    return Row(
      children: List.generate(5, (index) {
        final isOn = index < totalFilled;
        return Icon(
          isOn ? Icons.star : Icons.star_border,
          size: 16,
          color: isOn ? Colors.amber : null,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstTwoServices = barber.services.take(2).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              barber.shopName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              barber.ownerName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStars(barber.rating),
                const SizedBox(width: 8),
                Text(
                  barber.rating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${distanceKm.toStringAsFixed(1)} km away',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            if (firstTwoServices.isNotEmpty)
              ...firstTwoServices.map(
                (s) => Text(
                  '${s.name} - \$${s.price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (firstTwoServices.isEmpty)
              const Text('No services yet', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    context.push('/customer/booking/${barber.uid}'),
                child: const Text('Book Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

