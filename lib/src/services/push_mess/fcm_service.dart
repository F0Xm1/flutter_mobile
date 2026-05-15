import 'dart:async';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await _firebaseMessaging.requestPermission();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    const thresholdChannel = AndroidNotificationChannel(
      'threshold_alerts',
      'Сповіщення порогів',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(thresholdChannel);

    final token = await _firebaseMessaging.getToken();
    log('FCM Token: $token', name: 'FCMService');

    FirebaseMessaging.onMessage.listen((message) {
      log(
        'FCM foreground: ${message.notification?.title}',
        name: 'FCMService',
      );
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      log(
        'FCM app opened via notification: ${message.notification?.title}',
        name: 'FCMService',
      );
    });

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      log(
        'FCM launch notification: ${initialMessage.notification?.title}',
        name: 'FCMService',
      );
    }
  }

  static void _showNotification(RemoteMessage message) {
    _localNotifications.show(
      0,
      message.notification?.title ?? 'Сповіщення',
      message.notification?.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Повідомлення',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> showLocalNotification(String title, String body) async {
    await _localNotifications.show(
      1,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'threshold_alerts',
          'Сповіщення порогів',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

}
