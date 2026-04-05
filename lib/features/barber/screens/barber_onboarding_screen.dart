import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/firestore_keys.dart';
import '../models/service_model.dart';
import '../providers/barber_provider.dart';

/// Multi-step onboarding flow for new barber accounts.
///
/// After completion, this screen saves shop details, working hours, and an
/// initial service to Firestore, then navigates to `/barber/home`.
class BarberOnboardingScreen extends ConsumerStatefulWidget {
  /// Creates the onboarding screen.
  const BarberOnboardingScreen({super.key});

  @override
  ConsumerState<BarberOnboardingScreen> createState() =>
      _BarberOnboardingScreenState();
}

class _BarberOnboardingScreenState
    extends ConsumerState<BarberOnboardingScreen> {
  int _stepIndex = 0;

  // Step 1 fields.
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Step 2 working hours state.
  static const List<String> _days = <String>[
    'mon',
    'tue',
    'wed',
    'thu',
    'fri',
    'sat',
    'sun',
  ];

  final Map<String, bool> _enabledDays = <String, bool>{
    'mon': true,
    'tue': true,
    'wed': true,
    'thu': true,
    'fri': true,
    'sat': false,
    'sun': false,
  };

  final Map<String, TimeOfDay> _openTimes = <String, TimeOfDay>{
    'mon': const TimeOfDay(hour: 9, minute: 0),
    'tue': const TimeOfDay(hour: 9, minute: 0),
    'wed': const TimeOfDay(hour: 9, minute: 0),
    'thu': const TimeOfDay(hour: 9, minute: 0),
    'fri': const TimeOfDay(hour: 9, minute: 0),
    'sat': const TimeOfDay(hour: 9, minute: 0),
    'sun': const TimeOfDay(hour: 9, minute: 0),
  };

  final Map<String, TimeOfDay> _closeTimes = <String, TimeOfDay>{
    'mon': const TimeOfDay(hour: 17, minute: 0),
    'tue': const TimeOfDay(hour: 17, minute: 0),
    'wed': const TimeOfDay(hour: 17, minute: 0),
    'thu': const TimeOfDay(hour: 17, minute: 0),
    'fri': const TimeOfDay(hour: 17, minute: 0),
    'sat': const TimeOfDay(hour: 17, minute: 0),
    'sun': const TimeOfDay(hour: 17, minute: 0),
  };

  // Step 3 fields.
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _servicePriceController = TextEditingController();
  final TextEditingController _serviceDurationController =
      TextEditingController(text: '30');

  bool _isSaving = false;

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    _serviceNameController.dispose();
    _servicePriceController.dispose();
    _serviceDurationController.dispose();
    super.dispose();
  }

  /// Advances to the next onboarding step (or finishes).
  Future<void> _onNext() async {
    if (_stepIndex < 2) {
      setState(() => _stepIndex += 1);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in as a barber.')),
      );
      return;
    }

    final repo = ref.read(barberRepositoryProvider);

    final shopName = _shopNameController.text.trim();
    final ownerName = _ownerNameController.text.trim();
    final address = _addressController.text.trim();

    final serviceName = _serviceNameController.text.trim();
    final price = double.tryParse(_servicePriceController.text.trim());
    final duration = int.tryParse(_serviceDurationController.text.trim());

    if (shopName.isEmpty || ownerName.isEmpty || address.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete step 1 fields.')),
      );
      return;
    }
    if (serviceName.isEmpty || price == null || price <= 0 || duration == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete step 3 (service) fields.')),
      );
      return;
    }

    // Build working hours map for enabled days.
    final workingHours = <String, Map<String, String>>{};
    for (final day in _days) {
      final enabled = _enabledDays[day] ?? false;
      if (!enabled) continue;

      final open = _openTimes[day]!;
      final close = _closeTimes[day]!;

      workingHours[day] = <String, String>{
        FirestoreKeys.workingHoursOpen: _formatTime(open),
        FirestoreKeys.workingHoursClose: _formatTime(close),
      };
    }

    if (workingHours.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable at least one working day.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await repo.updateBarberProfile(user.uid, <String, dynamic>{
        // Use repository setter methods later; here we save step 1 data.
        FirestoreKeys.barberShopName: shopName,
        FirestoreKeys.barberOwnerName: ownerName,
        FirestoreKeys.barberAddress: address,
        FirestoreKeys.barberIsActive: true,
        FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
      });

      await repo.setWorkingHours(user.uid, workingHours);
      await repo.addService(
        user.uid,
        ServiceModel(
          name: serviceName,
          price: price,
          durationMinutes: duration,
        ),
      );

      if (!mounted) return;
      context.go('/barber/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save onboarding: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Formats [time] as `HH:mm` string.
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Selects a time for a given [day] and [isOpen].
  Future<void> _pickTime({
    required String day,
    required bool isOpen,
  }) async {
    final current = isOpen ? _openTimes[day]! : _closeTimes[day]!;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked == null) return;

    setState(() {
      if (isOpen) {
        _openTimes[day] = picked;
      } else {
        _closeTimes[day] = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_stepIndex + 1) / 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barber onboarding'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (_stepIndex > 0) {
              setState(() => _stepIndex -= 1);
            } else {
              context.go('/splash');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 18),
              Text(
                'Step ${_stepIndex + 1} of 3',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (_stepIndex == 0) ...[
                TextField(
                  controller: _shopNameController,
                  decoration: const InputDecoration(
                    labelText: 'Shop name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ownerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Owner name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                ),
              ] else if (_stepIndex == 1) ...[
                Text(
                  'Working hours',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                ..._days.map(
                  (day) {
                    final enabled = _enabledDays[day] ?? false;
                    final open = _openTimes[day]!;
                    final close = _closeTimes[day]!;
                    final label = day.toUpperCase();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                                Switch(
                                  value: enabled,
                                  onChanged: (v) {
                                    setState(() => _enabledDays[day] = v);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed:
                                        enabled ? () => _pickTime(day: day, isOpen: true) : null,
                                    child: Text('Open: ${_formatTime(open)}'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed:
                                        enabled ? () => _pickTime(day: day, isOpen: false) : null,
                                    child:
                                        Text('Close: ${_formatTime(close)}'),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ] else ...[
                TextField(
                  controller: _serviceNameController,
                  decoration: const InputDecoration(
                    labelText: 'First service name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _servicePriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _serviceDurationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _isSaving ? null : _onNext,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_stepIndex < 2 ? 'Continue' : 'Finish Setup'),
              ),
              const SizedBox(height: 10),
              if (_stepIndex > 0)
                OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => setState(() => _stepIndex -= 1),
                  child: const Text('Back'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

