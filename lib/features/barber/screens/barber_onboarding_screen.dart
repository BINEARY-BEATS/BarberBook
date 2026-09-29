import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/profile_completion.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import '../models/service_model.dart';
import '../providers/barber_provider.dart';

class BarberOnboardingScreen extends ConsumerStatefulWidget {
  const BarberOnboardingScreen({super.key});
  @override
  ConsumerState<BarberOnboardingScreen> createState() =>
      _BarberOnboardingScreenState();
}

class _BarberOnboardingScreenState extends ConsumerState<BarberOnboardingScreen> {
  int _step = 0;
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _serviceNameController = TextEditingController();
  final _servicePriceController = TextEditingController();
  final _serviceDurationController = TextEditingController(text: '30');

  static const _days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const _dayLabels = {
    'mon': 'Monday',
    'tue': 'Tuesday',
    'wed': 'Wednesday',
    'thu': 'Thursday',
    'fri': 'Friday',
    'sat': 'Saturday',
    'sun': 'Sunday',
  };

  final Map<String, bool> _enabledDays = {
    'mon': true,
    'tue': true,
    'wed': true,
    'thu': true,
    'fri': true,
    'sat': false,
    'sun': false,
  };
  final Map<String, TimeOfDay> _openTimes =
      Map.fromIterable(_days, value: (_) => const TimeOfDay(hour: 9, minute: 0));
  final Map<String, TimeOfDay> _closeTimes =
      Map.fromIterable(_days, value: (_) => const TimeOfDay(hour: 18, minute: 0));

  String? _shopError;
  String? _ownerError;
  String? _phoneError;
  String? _addressError;
  String? _hoursError;
  String? _serviceNameError;
  String? _servicePriceError;
  String? _serviceDurationError;
  String? _geoHint;
  GeoPoint? _geoPoint;
  bool _saving = false;
  bool _seeded = false;

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _serviceNameController.dispose();
    _servicePriceController.dispose();
    _serviceDurationController.dispose();
    super.dispose();
  }

  void _seedFromAuth() {
    if (_seeded) return;
    _seeded = true;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_ownerNameController.text.isEmpty) {
      _ownerNameController.text = user.displayName?.trim() ?? '';
    }
    final authPhone = user.phoneNumber?.trim() ?? '';
    if (_phoneController.text.isEmpty &&
        ProfileCompletion.isRealPhone(authPhone)) {
      _phoneController.text = ProfileCompletion.normalizePhone(authPhone);
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime({
    required String day,
    required bool open,
  }) async {
    final initial = open ? _openTimes[day]! : _closeTimes[day]!;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    setState(() {
      if (open) {
        _openTimes[day] = picked;
      } else {
        _closeTimes[day] = picked;
      }
      _hoursError = null;
    });
  }

  Future<GeoPoint?> _geocodeAddress(String address) async {
    try {
      final places = await locationFromAddress(address);
      if (places.isEmpty) return null;
      final p = places.first;
      return GeoPoint(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }

  bool _validateStep0({bool show = true}) {
    final shopErr = _shopNameController.text.trim().isEmpty
        ? 'Shop name is required'
        : null;
    final ownerErr =
        ProfileCompletion.validateName(_ownerNameController.text, label: 'Owner name');
    if (show) {
      setState(() {
        _shopError = shopErr;
        _ownerError = ownerErr;
      });
    }
    return shopErr == null && ownerErr == null;
  }

  Future<bool> _validateStep1({bool show = true}) async {
    final phoneErr = ProfileCompletion.validatePhone(_phoneController.text);
    final address = _addressController.text.trim();
    String? addressErr =
        address.isEmpty ? 'Address is required' : null;
    GeoPoint? point = _geoPoint;

    if (addressErr == null) {
      if (show) setState(() => _geoHint = 'Locating address…');
      point = await _geocodeAddress(address);
      if (point == null) {
        addressErr = 'Could not locate this address. Try a fuller one.';
      }
    }

    if (show) {
      setState(() {
        _phoneError = phoneErr;
        _addressError = addressErr;
        _geoPoint = point;
        _geoHint = point == null
            ? null
            : 'Pinned ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
      });
    }
    return phoneErr == null && addressErr == null && point != null;
  }

  bool _validateStep2({bool show = true}) {
    final anyOpen = _enabledDays.values.any((v) => v);
    String? err;
    if (!anyOpen) {
      err = 'Turn on at least one open day';
    } else {
      for (final d in _days) {
        if (_enabledDays[d] != true) continue;
        final open = _openTimes[d]!;
        final close = _closeTimes[d]!;
        final openMins = open.hour * 60 + open.minute;
        final closeMins = close.hour * 60 + close.minute;
        if (closeMins <= openMins) {
          err = '${_dayLabels[d]}: close time must be after open time';
          break;
        }
      }
    }
    if (show) setState(() => _hoursError = err);
    return err == null;
  }

  bool _validateStep3({bool show = true}) {
    final nameErr = _serviceNameController.text.trim().isEmpty
        ? 'Service name is required'
        : null;
    final price = double.tryParse(_servicePriceController.text.trim());
    final priceErr = price == null || price <= 0
        ? 'Enter a valid price greater than 0'
        : null;
    final duration = int.tryParse(_serviceDurationController.text.trim());
    final durationErr = duration == null || duration < 5 || duration > 240
        ? 'Duration must be between 5 and 240 minutes'
        : null;
    if (show) {
      setState(() {
        _serviceNameError = nameErr;
        _servicePriceError = priceErr;
        _serviceDurationError = durationErr;
      });
    }
    return nameErr == null && priceErr == null && durationErr == null;
  }

  Future<void> _onPrimary() async {
    if (_step == 0) {
      if (!_validateStep0()) return;
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      final ok = await _validateStep1();
      if (!ok) return;
      setState(() => _step = 2);
      return;
    }
    if (_step == 2) {
      if (!_validateStep2()) return;
      setState(() => _step = 3);
      return;
    }

    if (!_validateStep3()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/auth/sign-in');
      return;
    }

    setState(() => _saving = true);
    try {
      // Re-geocode if needed
      final point = _geoPoint ??
          await _geocodeAddress(_addressController.text.trim());
      if (point == null) {
        throw StateError('Address could not be located');
      }

      final workingHours = <String, Map<String, String>>{};
      for (final d in _days) {
        if (_enabledDays[d] == true) {
          workingHours[d] = {
            FirestoreKeys.workingHoursOpen: _formatTime(_openTimes[d]!),
            FirestoreKeys.workingHoursClose: _formatTime(_closeTimes[d]!),
          };
        }
      }

      final repo = ref.read(barberRepositoryProvider);
      await repo.updateBarberProfile(user.uid, {
        FirestoreKeys.barberShopName: _shopNameController.text.trim(),
        FirestoreKeys.barberOwnerName: _ownerNameController.text.trim(),
        FirestoreKeys.barberPhone:
            ProfileCompletion.normalizePhone(_phoneController.text),
        FirestoreKeys.barberAddress: _addressController.text.trim(),
        FirestoreKeys.barberLocation: point,
        FirestoreKeys.barberIsActive: true,
        FirestoreKeys.profileComplete: true,
      });
      await repo.setWorkingHours(user.uid, workingHours);
      await repo.addService(
        user.uid,
        ServiceModel(
          name: _serviceNameController.text.trim(),
          price: double.parse(_servicePriceController.text.trim()),
          durationMinutes: int.parse(_serviceDurationController.text.trim()),
        ),
      );
      if (mounted) context.go('/barber/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _seedFromAuth();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const titles = [
      'Your shop',
      'Contact & location',
      'Working hours',
      'First service',
    ];
    const subtitles = [
      'Tell customers who you are.',
      'We pin your shop so nearby clients can find you.',
      'Set the days and times you take bookings.',
      'Add at least one service to go live.',
    ];

    return OnboardingScaffold(
      stepIndex: _step,
      stepCount: 4,
      title: titles[_step],
      subtitle: subtitles[_step],
      primaryLabel: _step == 3 ? 'Finish setup' : 'Continue',
      primaryLoading: _saving,
      onBack: () {
        if (_step > 0) {
          setState(() => _step -= 1);
        } else {
          context.go('/auth/role-select');
        }
      },
      onPrimary: _onPrimary,
      body: switch (_step) {
        0 => Column(
            children: [
              OnboardingField(
                label: 'Shop name',
                controller: _shopNameController,
                hint: 'e.g. Captain Cuts',
                errorText: _shopError,
                prefixIcon: Icons.storefront_outlined,
                onChanged: (_) {
                  if (_shopError != null) _validateStep0();
                },
              ),
              const SizedBox(height: 16),
              OnboardingField(
                label: 'Owner name',
                controller: _ownerNameController,
                hint: 'Your name',
                errorText: _ownerError,
                prefixIcon: Icons.badge_outlined,
                onChanged: (_) {
                  if (_ownerError != null) _validateStep0();
                },
              ),
            ],
          ),
        1 => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingField(
                label: 'Phone number',
                controller: _phoneController,
                hint: '+92 300 1234567',
                errorText: _phoneError,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 16),
              OnboardingField(
                label: 'Shop address',
                controller: _addressController,
                hint: 'Street, area, city',
                errorText: _addressError,
                maxLines: 2,
                prefixIcon: Icons.place_outlined,
                onChanged: (_) {
                  _geoPoint = null;
                  _geoHint = null;
                },
              ),
              if (_geoHint != null) ...[
                const SizedBox(height: 10),
                Text(
                  _geoHint!,
                  style: TextStyle(
                    color: AppColors.secondaryText(isDark),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        2 => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_hoursError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _hoursError!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ..._days.map((d) {
                final enabled = _enabledDays[d] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card(isDark),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider(isDark)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _dayLabels[d]!,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface(isDark),
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: enabled,
                            activeThumbColor: AppColors.accent,
                            onChanged: (v) {
                              setState(() {
                                _enabledDays[d] = v;
                                _hoursError = null;
                              });
                            },
                          ),
                        ],
                      ),
                      if (enabled)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: _TimeChip(
                                  label: 'Open',
                                  time: _openTimes[d]!,
                                  onTap: () => _pickTime(day: d, open: true),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _TimeChip(
                                  label: 'Close',
                                  time: _closeTimes[d]!,
                                  onTap: () => _pickTime(day: d, open: false),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        _ => Column(
            children: [
              OnboardingField(
                label: 'Service name',
                controller: _serviceNameController,
                hint: 'e.g. Haircut',
                errorText: _serviceNameError,
                prefixIcon: Icons.content_cut_rounded,
              ),
              const SizedBox(height: 16),
              OnboardingField(
                label: 'Price',
                controller: _servicePriceController,
                hint: '25',
                errorText: _servicePriceError,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.attach_money_rounded,
              ),
              const SizedBox(height: 16),
              OnboardingField(
                label: 'Duration (minutes)',
                controller: _serviceDurationController,
                hint: '30',
                errorText: _serviceDurationError,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.timer_outlined,
              ),
            ],
          ),
      },
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = MaterialLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.elevated(isDark),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.mutedText(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              localizations.formatTimeOfDay(time),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
