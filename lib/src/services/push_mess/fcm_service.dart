import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

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

    await _sendTokenToBackend(token);

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

    FirebaseMessaging.instance.onTokenRefresh.listen(_sendTokenToBackend);
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

  static Future<void> _sendTokenToBackend(String? token) async {
    if (token == null) return;

    const backendUrl = 'http://192.168.1.133:5001/register-token';

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fcmToken': token}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Токен надіслано на бекенд');
      } else {
        debugPrint('❌ Помилка відповіді бекенду: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Не вдалося надіслати токен: $e');
    }
  }
}
