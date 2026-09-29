import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../core/utils/profile_completion.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import '../data/customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

class CustomerOnboardingScreen extends ConsumerStatefulWidget {
  const CustomerOnboardingScreen({super.key});

  @override
  ConsumerState<CustomerOnboardingScreen> createState() =>
      _CustomerOnboardingScreenState();
}

class _CustomerOnboardingScreenState
    extends ConsumerState<CustomerOnboardingScreen> {
  int _step = 0;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  String? _nameError;
  String? _phoneError;
  bool _saving = false;
  bool _seeded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _seedFromAuth() {
    if (_seeded) return;
    _seeded = true;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_nameController.text.isEmpty) {
      _nameController.text = user.displayName?.trim() ?? '';
    }
    final authPhone = user.phoneNumber?.trim() ?? '';
    if (_phoneController.text.isEmpty &&
        ProfileCompletion.isRealPhone(authPhone)) {
      _phoneController.text = ProfileCompletion.normalizePhone(authPhone);
    }
  }

  bool _validateCurrentStep({bool showErrors = true}) {
    if (_step == 0) {
      final err = ProfileCompletion.validateName(_nameController.text);
      if (showErrors) setState(() => _nameError = err);
      return err == null;
    }
    if (_step == 1) {
      final err = ProfileCompletion.validatePhone(_phoneController.text);
      if (showErrors) setState(() => _phoneError = err);
      return err == null;
    }
    return true;
  }

  Future<void> _onPrimary() async {
    if (!_validateCurrentStep()) return;

    if (_step < 2) {
      setState(() => _step += 1);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/auth/sign-in');
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(customerRepositoryProvider);
      await repo.updateCustomer(user.uid, {
        FirestoreKeys.userName: _nameController.text.trim(),
        FirestoreKeys.userPhone:
            ProfileCompletion.normalizePhone(_phoneController.text),
        FirestoreKeys.userCity: _cityController.text.trim(),
        FirestoreKeys.userRole: FirestoreKeys.roleCustomer,
        FirestoreKeys.profileComplete: true,
        FirestoreKeys.updatedAt: FieldValue.serverTimestamp(),
      });
      if (mounted) context.go('/customer/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _seedFromAuth();

    final titles = ['Your name', 'Your phone', 'Almost done'];
    final subtitles = [
      'This is how barbers will see you on bookings.',
      'Used for appointment updates. Not your email.',
      'Optional: add your city so we can personalize nearby shops.',
    ];

    return OnboardingScaffold(
      stepIndex: _step,
      stepCount: 3,
      title: titles[_step],
      subtitle: subtitles[_step],
      primaryLabel: _step == 2 ? 'Finish setup' : 'Continue',
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
        0 => OnboardingField(
            label: 'Full name',
            controller: _nameController,
            hint: 'e.g. Aaron Ramsdale',
            errorText: _nameError,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.person_outline_rounded,
            onChanged: (_) {
              if (_nameError != null) {
                setState(() => _nameError =
                    ProfileCompletion.validateName(_nameController.text));
              }
            },
          ),
        1 => OnboardingField(
            label: 'Phone number',
            controller: _phoneController,
            hint: '+92 300 1234567',
            errorText: _phoneError,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.phone_outlined,
            onChanged: (_) {
              if (_phoneError != null) {
                setState(() => _phoneError =
                    ProfileCompletion.validatePhone(_phoneController.text));
              }
            },
          ),
        _ => OnboardingField(
            label: 'City (optional)',
            controller: _cityController,
            hint: 'e.g. Karachi',
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.location_city_outlined,
          ),
      },
    );
  }
}
