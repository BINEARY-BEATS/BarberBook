const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

async function sendToUid(uid, collection, payload) {
  if (!uid) return;
  const snap = await db.collection(collection).doc(uid).get();
  const token = snap.exists ? snap.get("fcmToken") : null;
  if (!token) return;
  try {
    await getMessaging().send({
      token,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: {
        route: payload.route || "",
      },
    });
  } catch (e) {
    console.warn("FCM send failed", e.message);
  }
}

exports.onAppointmentCreated = onDocumentCreated(
  "appointments/{id}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const barberId = data.barberId;
    const customerName = data.customerName || "A customer";
    await sendToUid(barberId, "barbers", {
      title: "New booking",
      body: `${customerName} booked a slot.`,
      route: "/barber/home",
    });
  }
);

exports.onAppointmentUpdated = onDocumentUpdated(
  "appointments/{id}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === after.status) return;

    const customerId = after.customerId;
    await sendToUid(customerId, "users", {
      title: "Booking update",
      body: `Your appointment is now ${after.status}.`,
      route: "/customer/my_bookings",
    });
  }
);
