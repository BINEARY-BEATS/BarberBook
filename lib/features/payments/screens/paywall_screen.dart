import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/book_primary_button.dart';
import '../data/purchases_service.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _busy = false;

  Future<void> _buy() async {
    setState(() => _busy = true);
    try {
      final svc = ref.read(purchasesServiceProvider);
      final ok = await svc.purchasePro();
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pro access enabled (Demo mode).')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Stand out.\nUnlimited craft.',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Unlock unlimited portfolio photos and a featured spot in nearby discovery.',
                style: TextStyle(
                  color: AppColors.secondaryText(isDark),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              _Perk(
                icon: Icons.photo_library_outlined,
                label: 'Unlimited portfolio',
                isDark: isDark,
              ),
              _Perk(
                icon: Icons.star_outline_rounded,
                label: 'Featured in nearby results',
                isDark: isDark,
              ),
              _Perk(
                icon: Icons.verified_outlined,
                label: 'Pro badge on your profile',
                isDark: isDark,
              ),
              const Spacer(),
              BookPrimaryButton(
                label: 'Activate Pro (Demo Mode)',
                loading: _busy,
                onPressed: _busy ? null : _buy,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () async {
                    await ref.read(purchasesServiceProvider).restore();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Purchases restored.')),
                      );
                    }
                  },
                  child: Text(
                    'Restore purchases',
                    style: TextStyle(color: AppColors.secondaryText(isDark)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({
    required this.icon,
    required this.label,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider(isDark)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface(isDark),
            ),
          ),
        ],
      ),
    );
  }
}
