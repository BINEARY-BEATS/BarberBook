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
import '../widgets/book_subpage_scaffold.dart';
import 'splash_screen.dart';

/// Refreshes [GoRouter] whenever Firebase auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  /// Subscribes to [stream] and notifies listeners on each event.
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Placeholder for routes not fully implemented yet.
class RouteStubScreen extends StatelessWidget {
  /// Creates a stub screen titled [title].
  const RouteStubScreen({
    required this.title,
    required this.fallbackLocation,
    super.key,
  });

  /// Title shown in the app bar.
  final String title;

  /// Where [Back] goes when the route stack is empty.
  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return BookSubpageScaffold(
      title: title,
      fallbackLocation: fallbackLocation,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 56,
                color: cs.primary.withOpacity(0.65),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This section is coming soon. Use the back arrow to return.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Central [GoRouter] for BarberBook.
///
/// Redirect is **synchronous** so the first frame is never blocked on Firestore.
/// Role resolution runs on [SplashScreen] after a visible splash is painted.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authChanges = FirebaseAuth.instance.authStateChanges();
  final refresh = GoRouterRefreshStream(authChanges);
  ref.onDispose(refresh.dispose);

  const splashPath = '/splash';
  const roleSelectPath = '/auth/role-select';
  const signInPath = '/auth/sign-in';

  const barberHomePath = '/barber/home';
  const customerHomePath = '/customer/home';

  bool isAuthRoute(String path) {
    return path == roleSelectPath || path == signInPath;
  }

  return GoRouter(
    initialLocation: splashPath,
    refreshListenable: refresh,
    errorBuilder: (context, state) {
      return BookSubpageScaffold(
        title: 'Something went wrong',
        fallbackLocation: splashPath,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                state.error?.toString() ?? 'Unknown routing error',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => GoRouter.of(context).go(splashPath),
                child: const Text('Back to start'),
              ),
            ],
          ),
        ),
      );
    },
    routes: [
      GoRoute(
        path: splashPath,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) => splashPath,
      ),
      GoRoute(
        path: roleSelectPath,
        name: 'roleSelect',
        builder: (context, state) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: signInPath,
        name: 'signIn',
        builder: (context, state) => const GoogleSignInScreen(),
      ),
      GoRoute(
        path: barberHomePath,
        name: 'barberHome',
        builder: (context, state) => const BarberHomeScreen(),
      ),
      GoRoute(
        path: '/barber/onboarding',
        name: 'barberOnboarding',
        builder: (context, state) => const BarberOnboardingScreen(),
      ),
      GoRoute(
        path: '/barber/manage-slots',
        name: 'barberManageSlots',
        builder: (context, state) => const RouteStubScreen(
          title: 'Manage Slots',
          fallbackLocation: '/barber/home',
        ),
      ),
      GoRoute(
        path: '/barber/portfolio',
        name: 'barberPortfolio',
        builder: (context, state) => const RouteStubScreen(
          title: 'Portfolio',
          fallbackLocation: '/barber/home',
        ),
      ),
      GoRoute(
        path: '/barber/earnings',
        name: 'barberEarnings',
        builder: (context, state) => const RouteStubScreen(
          title: 'Earnings',
          fallbackLocation: '/barber/home',
        ),
      ),
      GoRoute(
        path: '/barber/paywall',
        name: 'barberPaywall',
        builder: (context, state) => const RouteStubScreen(
          title: 'Paywall',
          fallbackLocation: '/barber/home',
        ),
      ),
      GoRoute(
        path: customerHomePath,
        name: 'customerHome',
        builder: (context, state) => const CustomerHomeScreen(),
      ),
      GoRoute(
        path: '/customer/barber/:barberId',
        name: 'customerBarberDetail',
        builder: (context, state) => const RouteStubScreen(
          title: 'Barber Detail',
          fallbackLocation: '/customer/home',
        ),
      ),
      GoRoute(
        path: '/customer/booking/:barberId',
        name: 'customerBooking',
        builder: (context, state) => const RouteStubScreen(
          title: 'Booking',
          fallbackLocation: '/customer/home',
        ),
      ),
      GoRoute(
        path: '/customer/booking-confirm',
        name: 'customerBookingConfirm',
        builder: (context, state) => const RouteStubScreen(
          title: 'Booking Confirm',
          fallbackLocation: '/customer/home',
        ),
      ),
      GoRoute(
        path: '/customer/my-bookings',
        name: 'customerMyBookings',
        builder: (context, state) => const RouteStubScreen(
          title: 'My Bookings',
          fallbackLocation: '/customer/home',
        ),
      ),
    ],
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == splashPath) return null;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (isAuthRoute(path)) return null;
        return splashPath;
      }

      // Signed in: never stay on the Google screen (resolver will send new users
      // to role-select). Role-select must stay reachable while finishing profile.
      if (path == signInPath) {
        return splashPath;
      }

      return null;
    },
  );
});
