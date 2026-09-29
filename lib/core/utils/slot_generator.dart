import '../../features/barber/models/barber_model.dart';
import '../../features/barber/models/service_model.dart';
import '../constants/firestore_keys.dart';

/// Builds bookable time slots from working hours minus existing bookings.
abstract final class SlotGenerator {
  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  /// Returns available [TimeOfDay]-like DateTimes on [date] for [service].
  static List<DateTime> availableSlots({
    required BarberModel barber,
    required ServiceModel service,
    required DateTime date,
    required List<DateTime> bookedStarts,
    int stepMinutes = 30,
  }) {
    final dayKey = _dayKeys[date.weekday - 1];
    final hours = barber.workingHours[dayKey];
    if (hours == null) return const [];

    final open = _parseHm(hours[FirestoreKeys.workingHoursOpen] ?? '9:00');
    final close = _parseHm(hours[FirestoreKeys.workingHoursClose] ?? '17:00');
    if (open == null || close == null) return const [];

    final duration = Duration(minutes: service.durationMinutes);
    var cursor = DateTime(date.year, date.month, date.day, open.hour, open.minute);
    final end = DateTime(date.year, date.month, date.day, close.hour, close.minute);
    final now = DateTime.now();
    final results = <DateTime>[];

    while (cursor.add(duration).isBefore(end) ||
        cursor.add(duration).isAtSameMomentAs(end)) {
      final slotEnd = cursor.add(duration);
      final overlaps = bookedStarts.any((b) {
        final bEnd = b.add(duration);
        return cursor.isBefore(bEnd) && slotEnd.isAfter(b);
      });
      final inPast = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day &&
          cursor.isBefore(now);
      if (!overlaps && !inPast) results.add(cursor);
      cursor = cursor.add(Duration(minutes: stepMinutes));
    }
    return results;
  }

  static ({int hour, int minute})? _parseHm(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return (hour: h, minute: m);
  }
}
