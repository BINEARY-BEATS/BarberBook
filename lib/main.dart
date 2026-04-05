import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase/firebase_options.dart';

/// Application entrypoint for BarberBook.
///
/// [Firebase.initializeApp] failures on Android/iOS often arrive as
/// [PlatformException], not [FirebaseException], so both are caught explicitly.
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

/// Short, user-readable text for Firebase init [PlatformException]s.
String _firebasePlatformMessage(PlatformException e) {
  final msg = e.message ?? '';
  if (msg.contains('ApiKey must be set')) {
    return 'Firebase API key is missing. Run flutterfire configure and add '
        'google-services.json (Android) so lib/firebase/firebase_options.dart '
        'has a real apiKey.';
  }
  return msg.isNotEmpty ? msg : e.toString();
}

/// Shown when [DefaultFirebaseOptions] still has empty keys (dev placeholder).
class FirebaseNotConfiguredApp extends StatelessWidget {
  /// Creates the setup-required screen.
  const FirebaseNotConfiguredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BarberBook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A2E),
          secondary: const Color(0xFFE94560),
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('BarberBook'),
          backgroundColor: const Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Connect Firebase',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This project does not have Firebase keys yet. '
                  'Sign-in, Firestore, and maps need a real Firebase project.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Text(
                  'What you need to do',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                const _Step(
                  number: '1',
                  text:
                      'Create a project at https://console.firebase.google.com and add an Android (and/or iOS) app.',
                ),
                const _Step(
                  number: '2',
                  text:
                      'Install FlutterFire CLI: dart pub global activate flutterfire_cli',
                ),
                const _Step(
                  number: '3',
                  text:
                      'In this project folder run: flutterfire configure\n'
                      'Select your Firebase project and platforms. '
                      'This regenerates lib/firebase/firebase_options.dart with real apiKey, appId, projectId, etc.',
                ),
                const _Step(
                  number: '4',
                  text:
                      'Android: download google-services.json from Firebase Console '
                      'and place it in android/app/',
                ),
                const _Step(
                  number: '5',
                  text:
                      'iOS: add GoogleService-Info.plist to ios/Runner/ via Xcode.',
                ),
                const SizedBox(height: 24),
                Text(
                  'After that, run the app again.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Shown when Firebase.initializeApp throws (bad config, network, etc.).
class FirebaseInitFailedApp extends StatelessWidget {
  /// Creates the init-failed screen with a short [summary].
  FirebaseInitFailedApp({required this.summary, super.key});

  /// Short error summary (not the full platform stack trace).
  final String summary;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BarberBook',
      home: Scaffold(
        appBar: AppBar(title: const Text('BarberBook')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Firebase could not start',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  summary,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Check: google-services.json / GoogleService-Info.plist, '
                  'and re-run flutterfire configure so firebase_options.dart matches your Firebase app.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
