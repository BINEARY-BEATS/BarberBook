/// Centralized Firestore collection + field name constants for BarberBook.
///
/// Keeping these as constants avoids subtle bugs caused by typos and makes
/// refactors (e.g. renaming a field) safe across the codebase.
class FirestoreKeys {
  FirestoreKeys._();

  // ----------------------------
  // Collections
  // ----------------------------
  static const String users = 'users';
  static const String barbers = 'barbers';
  static const String appointments = 'appointments';
  static const String queue = 'queue';
  static const String portfolio = 'portfolio';
  static const String reviews = 'reviews';

  // ----------------------------
  // Common Fields
  // ----------------------------
  static const String id = 'id';
  static const String uid = 'uid';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';

  // ----------------------------
  // Roles
  // ----------------------------
  static const String roleCustomer = 'customer';
  static const String roleBarber = 'barber';

  // ----------------------------
  // Appointment Statuses
  // ----------------------------
  static const String appointmentStatusPending = 'pending';
  static const String appointmentStatusConfirmed = 'confirmed';
  static const String appointmentStatusCompleted = 'completed';
  static const String appointmentStatusCancelled = 'cancelled';

  // ----------------------------
  // Users/{uid}
  // ----------------------------
  static const String userName = 'name';
  static const String userPhone = 'phone';
  static const String userPhotoUrl = 'photoUrl';
  static const String userRole = 'role';

  // ----------------------------
  // Barbers/{uid}
  // ----------------------------
  static const String barberShopName = 'shopName';
  static const String barberOwnerName = 'ownerName';
  static const String barberPhone = 'phone';
  static const String barberPhotoUrl = 'photoUrl';
  static const String barberLocation = 'location';
  static const String barberAddress = 'address';
  static const String barberRating = 'rating';
  static const String barberTotalReviews = 'totalReviews';
  static const String barberIsPro = 'isPro';
  static const String barberIsActive = 'isActive';
  static const String barberWorkingHours = 'workingHours';
  static const String barberServices = 'services';

  // ----------------------------
  // workingHours map: { mon-sun : { open, close } }
  // ----------------------------
  static const String workingHoursOpen = 'open';
  static const String workingHoursClose = 'close';

  // ----------------------------
  // services list: [{ name, price, durationMinutes }]
  // ----------------------------
  static const String serviceName = 'name';
  static const String servicePrice = 'price';
  static const String serviceDurationMinutes = 'durationMinutes';

  // ----------------------------
  // Appointments/{id}
  // ----------------------------
  static const String appointmentBarberId = 'barberId';
  static const String appointmentCustomerId = 'customerId';
  static const String appointmentCustomerName = 'customerName';
  static const String appointmentService = 'service';
  static const String appointmentSlot = 'slot';
  static const String appointmentStatus = 'status';

  // ----------------------------
  // Queue/{barberId}
  // ----------------------------
  static const String queueBarberId = 'barberId';
  static const String queueEntries = 'entries';
  static const String queueCurrentServing = 'currentServing';
  static const String queueAvgWaitMins = 'avgWaitMins';

  // Queue entry map fields: { customerId, name, joinedAt }
  static const String queueEntryCustomerId = 'customerId';
  static const String queueEntryName = 'name';
  static const String queueEntryJoinedAt = 'joinedAt';

  // ----------------------------
  // Portfolio/{id}
  // ----------------------------
  static const String portfolioBarberId = 'barberId';
  static const String portfolioImageUrl = 'imageUrl';
  static const String portfolioStyle = 'style';

  // ----------------------------
  // Reviews/{id}
  // ----------------------------
  static const String reviewBarberId = 'barberId';
  static const String reviewCustomerId = 'customerId';
  static const String reviewCustomerName = 'customerName';
  static const String reviewRating = 'rating';
  static const String reviewComment = 'comment';
}

