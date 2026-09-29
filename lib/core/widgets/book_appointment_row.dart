import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/appointments/models/appointment_model.dart';
import '../constants/firestore_keys.dart';
import '../theme/app_colors.dart';
import 'book_status_chip.dart';

/// Appointment list row — avatar, name, service, status chip, time.
class BookAppointmentRow extends StatelessWidget {
  const BookAppointmentRow({
    required this.appointment,
    this.onTap,
    this.onComplete,
    this.onCancel,
    this.showActions = false,
    this.titleOverride,
    this.subtitleOverride,
    super.key,
  });

  final AppointmentModel appointment;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final bool showActions;
  final String? titleOverride;
  final String? subtitleOverride;

  BookStatusTone get _tone {
    final s = appointment.status;
    if (s == FirestoreKeys.appointmentStatusCompleted) {
      return BookStatusTone.success;
    }
    if (s == FirestoreKeys.appointmentStatusCancelled) {
      return BookStatusTone.danger;
    }
    if (s == FirestoreKeys.appointmentStatusConfirmed) {
      return BookStatusTone.pending;
    }
    return BookStatusTone.neutral;
  }

  String get _statusLabel {
    final s = appointment.status;
    if (s == FirestoreKeys.appointmentStatusCompleted) return 'Success';
    if (s == FirestoreKeys.appointmentStatusCancelled) return 'Cancelled';
    if (s == FirestoreKeys.appointmentStatusConfirmed) return 'Pending';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('h:mm a').format(appointment.slot.toDate());
    final title = titleOverride ?? appointment.customerName;
    final subtitle = subtitleOverride ?? appointment.service.name;
    final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';

    return Material(
      color: AppColors.card(isDark),
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(AppRadius.r16),
            boxShadow: isDark ? null : AppColors.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.accentSoft,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.onSurface(isDark),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText(isDark),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    BookStatusChip(label: _statusLabel, tone: _tone),
                    const SizedBox(height: 6),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface(isDark),
                      ),
                    ),
                  ],
                ),
                if (showActions &&
                    appointment.status ==
                        FirestoreKeys.appointmentStatusConfirmed) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Complete',
                    onPressed: onComplete,
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cancel',
                    onPressed: onCancel,
                    icon: const Icon(
                      Icons.cancel_rounded,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
