import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/firestore_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/book_primary_button.dart';
import '../../../core/widgets/book_status_chip.dart';
import '../../../core/widgets/book_subpage_scaffold.dart';
import '../../appointments/models/appointment_model.dart';
import '../../chat/data/chat_repository.dart';

/// Barber-facing customer detail for a single appointment.
class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({required this.appointmentId, super.key});

  final String appointmentId;

  Future<AppointmentModel?> _loadAppointment() async {
    final snap = await FirebaseFirestore.instance
        .collection(FirestoreKeys.appointments)
        .doc(appointmentId)
        .get();
    if (!snap.exists || snap.data() == null) return null;
    return AppointmentModel.fromMap(snap.data()!, id: snap.id);
  }

  Future<Map<String, dynamic>?> _loadCustomer(String customerId) async {
    if (customerId.isEmpty) return null;
    final snap = await FirebaseFirestore.instance
        .collection(FirestoreKeys.users)
        .doc(customerId)
        .get();
    return snap.data();
  }

  BookStatusTone _tone(String status) {
    if (status == FirestoreKeys.appointmentStatusCompleted) {
      return BookStatusTone.success;
    }
    if (status == FirestoreKeys.appointmentStatusCancelled) {
      return BookStatusTone.danger;
    }
    if (status == FirestoreKeys.appointmentStatusConfirmed) {
      return BookStatusTone.pending;
    }
    return BookStatusTone.neutral;
  }

  String _statusLabel(String status) {
    if (status == FirestoreKeys.appointmentStatusCompleted) return 'Success';
    if (status == FirestoreKeys.appointmentStatusCancelled) return 'Cancelled';
    if (status == FirestoreKeys.appointmentStatusConfirmed) return 'Pending';
    return status;
  }

  Future<void> _call(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _message(
    BuildContext context,
    WidgetRef ref,
    AppointmentModel app,
  ) async {
    final chat = ref.read(chatRepositoryProvider);
    final conversationId = await chat.getOrCreateConversation(
      barberId: app.barberId,
      customerId: app.customerId,
    );
    if (context.mounted) {
      context.push('/barber/chat/$conversationId');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BookSubpageScaffold(
      title: 'Customer Details',
      fallbackLocation: '/barber/home',
      body: FutureBuilder<AppointmentModel?>(
        future: _loadAppointment(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }
          final app = snap.data;
          if (app == null) {
            return const Center(child: Text('Appointment not found.'));
          }

          return FutureBuilder<Map<String, dynamic>?>(
            future: _loadCustomer(app.customerId),
            builder: (context, custSnap) {
              final cust = custSnap.data;
              final phone =
                  cust?[FirestoreKeys.userPhone] as String? ?? '';
              final city = cust?[FirestoreKeys.userCity] as String? ?? '';
              final photoUrl =
                  cust?[FirestoreKeys.userPhotoUrl] as String? ?? '';
              final initial = app.customerName.isNotEmpty
                  ? app.customerName[0].toUpperCase()
                  : '?';
              final time =
                  DateFormat('h:mm a').format(app.slot.toDate());
              final total = app.service.price;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: AppColors.accentSoft,
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: AppColors.card(isDark),
                    borderRadius: BorderRadius.circular(AppRadius.r20),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: AppColors.card(isDark),
                        borderRadius:
                            BorderRadius.circular(AppRadius.r20),
                        boxShadow: isDark ? null : AppColors.cardShadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              app.customerName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface(isDark),
                              ),
                            ),
                            if (city.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 14,
                                    color: AppColors.mutedText(isDark),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    city,
                                    style: TextStyle(
                                      color:
                                          AppColors.secondaryText(isDark),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                BookStatusChip(
                                  label: _statusLabel(app.status),
                                  tone: _tone(app.status),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface(isDark),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: BookPrimaryButton(
                          label: 'Call Now',
                          icon: Icons.phone_rounded,
                          outlined: true,
                          onPressed: phone.isEmpty
                              ? null
                              : () => _call(phone),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BookPrimaryButton(
                          label: 'Message',
                          icon: Icons.chat_bubble_outline_rounded,
                          outlined: true,
                          onPressed: () => _message(context, ref, app),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Active Services',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: AppColors.card(isDark),
                    borderRadius: BorderRadius.circular(AppRadius.r16),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: AppColors.card(isDark),
                        borderRadius:
                            BorderRadius.circular(AppRadius.r16),
                        boxShadow: isDark ? null : AppColors.cardShadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.accentSoft,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.r12),
                              ),
                              child: const Icon(
                                Icons.content_cut_rounded,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    app.service.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface(isDark),
                                    ),
                                  ),
                                  Text(
                                    '${app.service.durationMinutes} Min',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.secondaryText(
                                        isDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryText(isDark),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\$${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
