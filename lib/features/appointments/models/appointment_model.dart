import 'package:cloud_firestore/cloud_firestore.dart';

import '../../barber/models/service_model.dart';
import '../../../core/constants/firestore_keys.dart';

/// Represents a booked appointment between a barber and a customer.
class AppointmentModel {
  /// Creates an [AppointmentModel].
  const AppointmentModel({
    required this.id,
    required this.barberId,
    required this.customerId,
    required this.customerName,
    required this.service,
    required this.slot,
    required this.status,
    required this.createdAt,
  });

  /// Appointment document id.
  final String id;

  /// Barber uid.
  final String barberId;

  /// Customer uid.
  final String customerId;

  /// Customer display name.
  final String customerName;

  /// Service details.
  final ServiceModel service;

  /// Appointment slot time.
  final Timestamp slot;

  /// Appointment status.
  final String status;

  /// Creation timestamp.
  final Timestamp createdAt;

  /// Creates an [AppointmentModel] from a Firestore map.
  factory AppointmentModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return AppointmentModel(
      id: id,
      barberId: map[FirestoreKeys.appointmentBarberId] as String? ?? '',
      customerId: map[FirestoreKeys.appointmentCustomerId] as String? ?? '',
      customerName:
          map[FirestoreKeys.appointmentCustomerName] as String? ?? '',
      service: ServiceModel.fromMap(
        (map[FirestoreKeys.appointmentService] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{
              FirestoreKeys.serviceName: '',
              FirestoreKeys.servicePrice: 0.0,
              FirestoreKeys.serviceDurationMinutes: 0,
            },
      ),
      slot: map[FirestoreKeys.appointmentSlot] as Timestamp,
      status: map[FirestoreKeys.appointmentStatus] as String? ??
          FirestoreKeys.appointmentStatusPending,
      createdAt: map[FirestoreKeys.createdAt] as Timestamp,
    );
  }

  /// Serializes this appointment to a Firestore-friendly map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      FirestoreKeys.id: id,
      FirestoreKeys.appointmentBarberId: barberId,
      FirestoreKeys.appointmentCustomerId: customerId,
      FirestoreKeys.appointmentCustomerName: customerName,
      FirestoreKeys.appointmentService: service.toMap(),
      FirestoreKeys.appointmentSlot: slot,
      FirestoreKeys.appointmentStatus: status,
      FirestoreKeys.createdAt: createdAt,
    };
  }

  /// Creates a copy with optional overrides.
  AppointmentModel copyWith({
    String? barberId,
    String? customerId,
    String? customerName,
    ServiceModel? service,
    Timestamp? slot,
    String? status,
    Timestamp? createdAt,
  }) {
    return AppointmentModel(
      id: id,
      barberId: barberId ?? this.barberId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      service: service ?? this.service,
      slot: slot ?? this.slot,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

