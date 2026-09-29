import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/google_sign_in_screen.dart';
import '../../features/auth/screens/role_select_screen.dart';
import '../../features/barber/screens/barber_home_screen.dart';
import '../../features/barber/screens/barber_onboarding_screen.dart';
import '../../features/barber/screens/customer_detail_screen.dart';
import '../../features/chat/screens/chat_inbox_screen.dart';
import '../../features/chat/screens/chat_thread_screen.dart';
import '../../features/customer/screens/barber_detail_screen.dart';
import '../../features/customer/screens/customer_booking_screen.dart';
import '../../features/customer/screens/customer_my_bookings_screen.dart';
import '../../features/customer/screens/customer_onboarding_screen.dart';
import '../../features/customer/screens/customer_shell_screen.dart';
import '../../features/payments/screens/paywall_screen.dart';
import '../../features/settings/screens/help_center_screen.dart';
import '../../features/settings/screens/legal_screens.dart';
import '../theme/app_theme.dart';
import 'role_home_resolver.dart';
import 'splash_screen.dart';

/// Global key so notification deep-links can navigate without a BuildContext.
final GlobalKey<NavigatorState> appRouterKey = GlobalKey<NavigatorState>();

class GoRouterRefreshStream extends ChangeNotifier {
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

final appRouterProvider = Provider<GoRouter>((ref) {
  final authChanges = FirebaseAuth.instance.authStateChanges();
  final refresh = GoRouterRefreshStream(authChanges);
  ref.onDispose(refresh.dispose);

  const splashPath = '/splash';
  const roleSelectPath = '/auth/role-select';
  const signInPath = '/auth/sign-in';
  const barberHomePath = '/barber/home';
  const barberOnboardingPath = '/barber/onboarding';
  const customerHomePath = '/customer/home';
  const customerOnboardingPath = '/customer/onboarding';

  return GoRouter(
    navigatorKey: appRouterKey,
    initialLocation: splashPath,
    refreshListenable: refresh,
    routes: [
      GoRoute(
        path: splashPath,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/', redirect: (context, state) => splashPath),
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
        path: barberOnboardingPath,
        name: 'barberOnboarding',
        builder: (context, state) => const BarberOnboardingScreen(),
      ),
      GoRoute(
        path: '/barber/paywall',
        name: 'barberPaywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/barber/messages',
        name: 'barberMessages',
        builder: (context, state) => const ChatInboxScreen(
          basePath: '/barber',
        ),
      ),
      GoRoute(
        path: '/barber/chat/:conversationId',
        name: 'barberChat',
        builder: (context, state) => ChatThreadScreen(
          conversationId: state.pathParameters['conversationId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/barber/customer/:appointmentId',
        name: 'barberCustomerDetail',
        builder: (context, state) => CustomerDetailScreen(
          appointmentId: state.pathParameters['appointmentId'] ?? '',
        ),
      ),
      GoRoute(
        path: customerOnboardingPath,
        name: 'customerOnboarding',
        builder: (context, state) => const CustomerOnboardingScreen(),
      ),
      GoRoute(
        path: customerHomePath,
        name: 'customerHome',
        builder: (context, state) {
          final tab =
              int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          return CustomerShellScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: '/customer/barber/:barberId',
        name: 'customerBarberDetail',
        builder: (context, state) => BarberDetailScreen(
          barberId: state.pathParameters['barberId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/customer/booking/:barberId',
        name: 'customerBooking',
        builder: (context, state) {
          final barberId = state.pathParameters['barberId'] ?? '';
          final serviceIndex =
              int.tryParse(state.uri.queryParameters['serviceIndex'] ?? '0') ??
                  0;
          return Theme(
            data: AppTheme.customer(),
            child: CustomerBookingScreen(
              barberId: barberId,
              serviceIndex: serviceIndex,
            ),
          );
        },
      ),
      GoRoute(
        path: '/customer/my_bookings',
        name: 'customerMyBookings',
        builder: (context, state) => Theme(
          data: AppTheme.customer(),
          child: const CustomerMyBookingsScreen(),
        ),
      ),
      GoRoute(
        path: '/customer/my-bookings',
        redirect: (context, state) => '/customer/home?tab=1',
      ),
      GoRoute(
        path: '/customer/chat/:conversationId',
        name: 'customerChat',
        builder: (context, state) => ChatThreadScreen(
          conversationId: state.pathParameters['conversationId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/legal/help',
        name: 'help',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/legal/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/legal/terms',
        name: 'terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/legal/about',
        name: 'about',
        builder: (context, state) => const AboutAppScreen(),
      ),
    ],
    redirect: (context, state) async {
      final path = state.uri.path;
      if (path == splashPath) return null;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (path == signInPath || path.startsWith('/legal/')) return null;
        // Signed-out users may not sit on role-select.
        if (path == roleSelectPath) return signInPath;
        return splashPath;
      }

      if (path == signInPath) return splashPath;

      // Profile completeness gates for home / onboarding / role-select.
      final needsGate = path == roleSelectPath ||
          path == barberHomePath ||
          path == barberOnboardingPath ||
          path == customerHomePath ||
          path == customerOnboardingPath;

      if (!needsGate) return null;

      try {
        final dest = await resolveRoleHomeForUid(user.uid)
            .timeout(const Duration(seconds: 8));

        if (path == roleSelectPath) {
          // Already has a role path — leave role-select.
          if (dest != roleSelectPath) return dest;
          return null;
        }

        if (path == barberHomePath && dest != barberHomePath) return dest;
        if (path == barberOnboardingPath && dest == barberHomePath) {
          return barberHomePath;
        }
        if (path == customerHomePath && dest != customerHomePath) return dest;
        if (path == customerOnboardingPath && dest == customerHomePath) {
          return customerHomePath;
        }
      } catch (_) {
        // Soft-fail: do not bounce to role-select on network blips.
        return null;
      }

      return null;
    },
  );
});
