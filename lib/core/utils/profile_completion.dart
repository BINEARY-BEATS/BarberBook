import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared completion checks for auth routing / onboarding.
abstract final class ProfileCompletion {
  static bool isRealPhone(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.contains('@')) return false;
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 15;
  }

  static String? validateName(String? value, {String label = 'Name'}) {
    final v = value?.trim() ?? '';
    if (v.length < 2) return '$label must be at least 2 characters';
    return null;
  }

  static String? validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Phone number is required';
    if (v.contains('@')) return 'Enter a phone number, not an email';
    if (!isRealPhone(v)) return 'Enter a valid phone number (10–15 digits)';
    return null;
  }

  static String normalizePhone(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return trimmed;
    final digits = trimmed.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('+')) return digits;
    return '+$digits';
  }

  static bool isCustomerComplete(Map<String, dynamic>? data) {
    if (data == null) return false;
    if (data['profileComplete'] == true) {
      final name = (data['name'] as String? ?? '').trim();
      final phone = (data['phone'] as String? ?? '').trim();
      return name.length >= 2 && isRealPhone(phone);
    }
    // Legacy docs without the flag.
    final role = data['role'] as String? ?? '';
    if (role != 'customer') return false;
    final name = (data['name'] as String? ?? '').trim();
    final phone = (data['phone'] as String? ?? '').trim();
    return name.length >= 2 && isRealPhone(phone);
  }

  static bool isBarberComplete(Map<String, dynamic>? data) {
    if (data == null) return false;
    final shopName = (data['shopName'] as String? ?? '').trim();
    final ownerName = (data['ownerName'] as String? ?? '').trim();
    final phone = (data['phone'] as String? ?? '').trim();
    final address = (data['address'] as String? ?? '').trim();
    final hours = data['workingHours'] as Map<String, dynamic>? ?? const {};
    final services = data['services'] as List<dynamic>? ?? const [];
    final location = data['location'];
    var hasLocation = false;
    if (location is GeoPoint) {
      hasLocation =
          location.latitude.abs() > 0.01 || location.longitude.abs() > 0.01;
    }

    final fieldsOk = shopName.isNotEmpty &&
        ownerName.length >= 2 &&
        isRealPhone(phone) &&
        address.isNotEmpty &&
        hasLocation &&
        hours.isNotEmpty &&
        services.isNotEmpty;

    if (data['profileComplete'] == true) return fieldsOk;
    return fieldsOk;
  }
}
