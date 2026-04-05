import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../barber/providers/barber_provider.dart';
import '../../../core/widgets/book_empty_state.dart';

class BarberDetailScreen extends ConsumerWidget {
  const BarberDetailScreen({super.key, required this.barberId});
  final String barberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncBarber = ref.watch(currentBarberProvider(barberId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 20), onPressed: () => context.pop())),
      body: asyncBarber.when(
        data: (barber) {
          if (barber == null) return const BookEmptyState(icon: Icons.error_outline_rounded, title: 'UNKNOWN ERROR', subtitle: 'This profile no longer exists.');
          return ListView(
            padding: const EdgeInsets.all(32),
            children: [
              Text(barber.shopName.toUpperCase(), style: theme.textTheme.displayMedium),
              const SizedBox(height: 8),
              Text(barber.ownerName, style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.w200, letterSpacing: 2)),
              const SizedBox(height: 16),
              Text(barber.address, style: const TextStyle(color: Colors.white10, fontSize: 13)),
              const SizedBox(height: 64),
              Text('MENU', style: theme.textTheme.labelLarge),
              const SizedBox(height: 32),
              if (barber.services.isEmpty)
                const Center(child: Text('No elite services listed.', style: TextStyle(color: Colors.white12, fontStyle: FontStyle.italic)))
              else
                ...barber.services.asMap().entries.map((entry) {
                  final i = entry.key;
                  final service = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: const Color(0xFF0F0F0F), borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(service.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('${service.durationMinutes} MINUTES', style: const TextStyle(fontSize: 10, color: Colors.white24, letterSpacing: 1.5)),
                      ])),
                      Text('\$${service.price.toStringAsFixed(0)}', style: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.w200)),
                      const SizedBox(width: 24),
                      FilledButton(onPressed: () => context.push('/customer/booking/$barberId?serviceIndex=$i'), child: const Text('BOOK')),
                    ]),
                  );
                }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
