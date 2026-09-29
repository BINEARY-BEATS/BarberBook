import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/firestore_keys.dart';
import '../router/app_router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Background message: ${message.messageId}');
  }
}

typedef NotificationNavigationHandler = void Function(String route);

/// FCM + local notifications for BarberBook (Android-first).
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationNavigationHandler? onNavigate;

  Future<void> initialize() async {
    await _requestPermissions();
    await _setupLocalNotifications();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);

    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      _handleMessageNavigation(initial);
    }

    _fcm.onTokenRefresh.listen(persistTokenForCurrentUser);
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route == null || route.isEmpty) return;
    onNavigate?.call(route);
    // Fallback: use global router if registered.
    try {
      appRouterKey.currentContext;
    } catch (_) {}
  }

  Future<void> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) {
      print('FCM permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: android);
    await _localNotifications.initialize(
      settings: init,
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null && route.isNotEmpty) {
          onNavigate?.call(route);
        }
      },
    );

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Bookings & Queue',
      description: 'Appointment and queue alerts',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final route = message.data['route'] as String? ?? '';
    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Bookings & Queue',
          channelDescription: 'Appointment and queue alerts',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: route,
    );
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      if (kDebugMode) print('FCM token error: $e');
      return null;
    }
  }

  /// Saves the device token onto the signed-in user or barber document.
  Future<void> persistTokenForCurrentUser([String? token]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final t = token ?? await getToken();
    if (t == null || t.isEmpty) return;

    final fs = FirebaseFirestore.instance;
    final barber = await fs.collection(FirestoreKeys.barbers).doc(user.uid).get();
    if (barber.exists) {
      await barber.reference.set(
        {FirestoreKeys.fcmToken: t},
        SetOptions(merge: true),
      );
      return;
    }
    await fs.collection(FirestoreKeys.users).doc(user.uid).set(
      {FirestoreKeys.fcmToken: t},
      SetOptions(merge: true),
    );
  }

  Future<void> subscribeToTopic(String topic) => _fcm.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) =>
      _fcm.unsubscribeFromTopic(topic);
}
