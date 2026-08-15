import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Topic every student device subscribes to. Must match CIRCULAR_TOPIC
/// in backend/server.js.
const String kCircularTopic = 'circulars';

/// Must run at top-level (not inside a class) — required by FCM for
/// handling messages while the app is fully terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No UI work here — just log / cache if needed. The OS shows the
  // notification tray entry automatically for background/terminated state.
  debugPrint('Background circular notification: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Call this once from main(), after Firebase.initializeApp().
  Future<void> initialize({
    required void Function(RemoteMessage message) onCircularTapped,
  }) async {
    try {
      // 1. Ask permission (required on iOS, Android 13+)
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      // 2. Subscribe every device to the shared "circulars" topic so the
      //    admin backend can fan out one push to all students at once.
      await _messaging.subscribeToTopic(kCircularTopic);

      // 3. Local notifications setup (for showing a banner while app is
      //    in the foreground — FCM does not auto-display in that state).
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          // Handle tap on a locally-shown foreground notification if needed.
        },
      );

      const channel = AndroidNotificationChannel(
        'circulars_channel',
        'Circular Alerts',
        description: 'Notifications for new admin circulars',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 4. Foreground messages: show a local notification banner.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'circulars_channel',
                'Circular Alerts',
                channelDescription: 'Notifications for new admin circulars',
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
          );
        }
      });

      // 5. User tapped a notification while app was backgrounded (not killed).
      FirebaseMessaging.onMessageOpenedApp.listen(onCircularTapped);

      // 6. App was launched by tapping a notification (was fully terminated).
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        onCircularTapped(initialMessage);
      }

      // 7. Register the top-level background handler.
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('PushNotificationService initialization error: $e');
    }
  }
}
