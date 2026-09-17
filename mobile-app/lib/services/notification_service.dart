import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/api_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifs = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Initialize Flutter Local Notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    try {
      await _localNotifs.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            // Deep link handling
          }
        },
      );
    } catch (e) {
      debugPrint('Local notifications init: $e');
    }

    // 2. Initialize Firebase Cloud Messaging if available
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _fcmToken = await messaging.getToken();
        if (_fcmToken != null) {
          _registerTokenWithBackend(_fcmToken!);
        }

        messaging.onTokenRefresh.listen((token) {
          _fcmToken = token;
          _registerTokenWithBackend(token);
        });

        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Foreground listener
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            showLocalNotification(
              id: DateTime.now().millisecond,
              title: notification.title ?? 'MyVault Alert',
              body: notification.body ?? '',
              payload: message.data['route'],
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Firebase messaging init (graceful fallback): $e');
    }

    _initialized = true;
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      await ApiClient.instance.dio.post('/notifications/register-token', data: {
        'token': token,
        'platform': 'android',
        'userId': 'student_myvault',
      });
    } catch (_) {}
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'myvault_alerts',
      'MyVault Important Alerts',
      channelDescription: 'Real-time updates on study materials, notes, exams & placements',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const details = NotificationDetails(android: androidDetails);
    await _localNotifs.show(id, title, body, details, payload: payload);
  }
}
