import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'firebase/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!DefaultFirebaseOptions.isConfigured) {
    runApp(const FirebaseNotConfiguredApp());
    return;
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await NotificationService.instance.initialize();
      NotificationService.instance.onNavigate = (route) {
        final ctx = appRouterKey.currentContext;
        if (ctx != null) {
          GoRouter.of(ctx).go(route);
        }
      };
      await NotificationService.instance.persistTokenForCurrentUser();
    }
  } on FirebaseException catch (e) {
    runApp(FirebaseInitFailedApp(summary: e.message ?? 'FirebaseException'));
    return;
  } on PlatformException catch (e) {
    runApp(FirebaseInitFailedApp(summary: _firebasePlatformMessage(e)));
    return;
  } catch (e) {
    runApp(FirebaseInitFailedApp(summary: e.toString()));
    return;
  }

  runApp(
    const ProviderScope(
      child: BarberBookApp(),
    ),
  );
}

String _firebasePlatformMessage(PlatformException e) {
  final msg = e.message ?? '';
  if (msg.contains('ApiKey must be set')) {
    return 'Firebase API key is missing. Run flutterfire configure and add '
        'google-services.json (Android) so lib/firebase/firebase_options.dart '
        'has a real apiKey.';
  }
  return msg.isNotEmpty ? msg : e.toString();
}

class FirebaseNotConfiguredApp extends StatelessWidget {
  const FirebaseNotConfiguredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BarberBook',
      home: Scaffold(
        appBar: AppBar(title: const Text('BarberBook')),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Connect Firebase for Android: run flutterfire configure, '
              'add google-services.json under android/app/, and set MAPS_API_KEY '
              'in android/local.properties.',
            ),
          ),
        ),
      ),
    );
  }
}

class FirebaseInitFailedApp extends StatelessWidget {
  const FirebaseInitFailedApp({required this.summary, super.key});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BarberBook',
      home: Scaffold(
        appBar: AppBar(title: const Text('BarberBook')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(summary),
          ),
        ),
      ),
    );
  }
}
