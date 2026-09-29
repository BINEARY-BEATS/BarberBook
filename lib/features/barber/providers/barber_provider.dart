import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../appointments/data/appointment_repository.dart';
import '../../appointments/models/appointment_model.dart';
import '../data/barber_repository.dart';
import '../models/barber_model.dart';

final barberRepositoryProvider = Provider<BarberRepository>((ref) {
  return BarberRepository();
});

final currentBarberProvider =
    StreamProvider.autoDispose.family<BarberModel?, String>((ref, uid) {
  final repo = ref.watch(barberRepositoryProvider);
  return repo.getBarber(uid);
});

final todayAppointmentsProvider = StreamProvider.autoDispose
    .family<List<AppointmentModel>, String>((ref, barberId) {
  final repo = ref.watch(appointmentRepositoryProvider);
  return repo.getBarberAppointmentsForDay(barberId, DateTime.now());
});

final barberDayAppointmentsProvider = StreamProvider.autoDispose
    .family<List<AppointmentModel>, ({String barberId, DateTime day})>(
        (ref, args) {
  final repo = ref.watch(appointmentRepositoryProvider);
  return repo.getBarberAppointmentsForDay(args.barberId, args.day);
});

final barberQueueProvider =
    StreamProvider.autoDispose.family<Map<String, dynamic>?, String>(
  (ref, barberId) {
    return ref.watch(barberRepositoryProvider).watchQueue(barberId);
  },
);

final barberStatsProvider =
    FutureProvider.autoDispose.family<BarberStats, String>((ref, uid) {
  return ref.watch(barberRepositoryProvider).getBarberStats(uid);
});
