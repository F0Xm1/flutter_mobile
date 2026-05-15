import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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

    final token = await _firebaseMessaging.getToken();
    debugPrint('🔑 FCM Token: $token');

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        '📩 Отримано пуш у foreground: ${message.notification?.title}',
      );
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint(
        '🚪 Відкрито додаток через пуш: ${message.notification?.title}',
      );
    });

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '📦 Пуш, який відкрив додаток: ${initialMessage.notification?.title}',
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
