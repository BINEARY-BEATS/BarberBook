# BarberBook

Dark-luxury Android booking app for barbers and customers. Find nearby shops on a map, book timed slots, manage a walk-in queue, schedule, portfolio, reviews, and optional Pro via RevenueCat.

## Stack

- Flutter + Riverpod + go_router
- Firebase Auth (Google), Cloud Firestore, Storage, FCM
- OpenStreetMap / Carto dark tiles via `flutter_map` (no Google Maps API key)
- Geolocator + Geocoding
- RevenueCat (`purchases_flutter`)

## Android setup

1. **Firebase**
   - Place `google-services.json` in `android/app/`
   - Confirm `lib/firebase/firebase_options.dart` Android keys match your project (`barberbook-4ca4f` or yours)
2. **Google Sign-In Web client ID**
   - Firebase Console → Authentication → Google → copy **Web client ID**
   - Paste into [`lib/firebase/google_sign_in_config.dart`](lib/firebase/google_sign_in_config.dart) (`kGoogleSignInWebClientId`)
3. **Maps** — no API key needed (OpenStreetMap / Carto tiles via `flutter_map`)
4. **RevenueCat (optional Pro)**
   - Paste Android public SDK key into [`lib/firebase/revenuecat_config.dart`](lib/firebase/revenuecat_config.dart)
   - Create entitlement id `pro` and a current offering with at least one package
5. **Firestore indexes**
   - Deploy: `firebase deploy --only firestore:indexes` (see `firestore.indexes.json`)
6. **FCM Cloud Functions** (cross-user push)
   ```bash
   cd functions && npm install
   firebase deploy --only functions
   ```
   Requires Blaze plan for outbound FCM from Functions.

## Run

```bash
flutter pub get
flutter run
```

## Roles & flows

| Role | Flow |
|------|------|
| Customer | Map nearby → shop detail → book slot / join queue → my bookings → review |
| Barber | Onboarding (geocoded address) → Today (queue + appointments) → Schedule → Profile (portfolio, Pro, seed) |

## Demo seed

Barber Profile → **Seed sample data** writes correctly shaped services, queue entries, and today’s appointments.

## Manual QA checklist (Android)

- [ ] Google Sign-In → choose Barber / Customer
- [ ] Barber onboarding with a real address → appears on customer map
- [ ] Book a slot from working hours; conflict rejected if double-booked
- [ ] Cancel from my bookings; complete/cancel from barber Today
- [ ] Join / leave walk-in queue; Serve next; Add walk-in
- [ ] Online/Offline toggle
- [ ] Schedule week day picker shows appointments
- [ ] Upload portfolio photo (free limit 3; Pro unlocks more)
- [ ] Leave a review; rating updates on shop
- [ ] Paywall purchase / restore (sandbox) sets `isPro`

## Portfolio note

UI uses a Captain-inspired system (Work Sans, gold accent `#F5C518`, light + dark). Customer shell: Home · Bookings · Messages · Profile. Keep screens focused: one job per view, brand-forward splash/sign-in.
