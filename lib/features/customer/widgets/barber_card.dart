import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../barber/models/barber_model.dart';

class BarberCard extends StatelessWidget {
  const BarberCard({required this.barber, required this.distanceKm, super.key});
  final BarberModel barber;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.push('/customer/barber/${barber.uid}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.white10, radius: 24, child: Text(barber.shopName[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(barber.shopName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: Colors.white24, size: 14),
                    const SizedBox(width: 4),
                    Text(barber.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white24, fontSize: 11)),
                    const SizedBox(width: 12),
                    Text('${distanceKm.toStringAsFixed(1)} KM AWAY', style: const TextStyle(color: Colors.white10, fontSize: 10, letterSpacing: 1)),
                  ]),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
          ],
        ),
      ),
    );
  }
}
