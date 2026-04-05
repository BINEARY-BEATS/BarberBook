import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/google_sign_in_screen.dart';
import '../../features/auth/screens/role_select_screen.dart';
import '../../features/barber/screens/barber_home_screen.dart';
import '../../features/barber/screens/barber_onboarding_screen.dart';
import '../../features/customer/screens/customer_home_screen.dart';
import '../../features/customer/screens/barber_detail_screen.dart';
import '../../features/customer/screens/customer_booking_screen.dart';
import '../../features/customer/screens/customer_my_bookings_screen.dart';
import 'splash_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() { _subscription.cancel(); super.dispose(); }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authChanges = FirebaseAuth.instance.authStateChanges();
  final refresh = GoRouterRefreshStream(authChanges);
  ref.onDispose(refresh.dispose);

  const splashPath = '/splash';
  const roleSelectPath = '/auth/role-select';
  const signInPath = '/auth/sign-in';
  const barberHomePath = '/barber/home';
  const customerHomePath = '/customer/home';

  return GoRouter(
    initialLocation: splashPath,
    refreshListenable: refresh,
    routes: [
      GoRoute(path: splashPath, name: 'splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/', redirect: (context, state) => splashPath),
      GoRoute(path: roleSelectPath, name: 'roleSelect', builder: (context, state) => const RoleSelectScreen()),
      GoRoute(path: signInPath, name: 'signIn', builder: (context, state) => const GoogleSignInScreen()),
      GoRoute(path: barberHomePath, name: 'barberHome', builder: (context, state) => const BarberHomeScreen()),
      GoRoute(path: '/barber/onboarding', name: 'barberOnboarding', builder: (context, state) => const BarberOnboardingScreen()),
      GoRoute(path: customerHomePath, name: 'customerHome', builder: (context, state) => const CustomerHomeScreen()),
      GoRoute(
        path: '/customer/barber/:barberId',
        name: 'customerBarberDetail',
        builder: (context, state) => BarberDetailScreen(barberId: state.pathParameters['barberId'] ?? ''),
      ),
      GoRoute(
        path: '/customer/booking/:barberId',
        name: 'customerBooking',
        builder: (context, state) {
          final barberId = state.pathParameters['barberId'] ?? '';
          final serviceIndex = int.tryParse(state.uri.queryParameters['serviceIndex'] ?? '0') ?? 0;
          return CustomerBookingScreen(barberId: barberId, serviceIndex: serviceIndex);
        },
      ),
      GoRoute(path: '/customer/my_bookings', name: 'customerMyBookings', builder: (context, state) => const CustomerMyBookingsScreen()),
    ],
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == splashPath) return null;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (path == roleSelectPath || path == signInPath) return null;
        return splashPath;
      }
      if (path == signInPath) return splashPath;
      return null;
    },
  );
});
