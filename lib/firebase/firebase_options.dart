import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for the current platform.
///
/// Android values match [android/app/google-services.json]. For iOS/macOS, add
/// an app in Firebase Console, download `GoogleService-Info.plist`, then run
/// `flutterfire configure` or paste options here.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'AIzaSyDAkrw-MqcRFH9iZUCUczX-WjStzeVgygA',
    appId: '1:880569664883:android:e18ccc13f848138de83106',
    messagingSenderId: '880569664883',
    projectId: 'barberbook-4ca4f',
    storageBucket: 'barberbook-4ca4f.firebasestorage.app',
  );

  /// Whether [currentPlatform] has the minimum fields required to call
  /// [Firebase.initializeApp] (non-empty apiKey, appId, projectId).
  static bool get isConfigured {
    final o = currentPlatform;
    final apiKey = o.apiKey.trim();
    final appId = o.appId.trim();
    final projectId = o.projectId.trim();
    return apiKey.isNotEmpty && appId.isNotEmpty && projectId.isNotEmpty;
  }

  /// Returns [FirebaseOptions] for the current platform.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: '',
        appId: '',
        messagingSenderId: '',
        projectId: '',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: '',
          appId: '',
          messagingSenderId: '',
          projectId: '',
        );
      case TargetPlatform.macOS:
        return const FirebaseOptions(
          apiKey: '',
          appId: '',
          messagingSenderId: '',
          projectId: '',
        );
      case TargetPlatform.windows:
        return const FirebaseOptions(
          apiKey: '',
          appId: '',
          messagingSenderId: '',
          projectId: '',
        );
      case TargetPlatform.linux:
        return const FirebaseOptions(
          apiKey: '',
          appId: '',
          messagingSenderId: '',
          projectId: '',
        );
      default:
        return const FirebaseOptions(
          apiKey: '',
          appId: '',
          messagingSenderId: '',
          projectId: '',
        );
    }
  }
}
