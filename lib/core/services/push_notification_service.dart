import 'dart:developer' as dev;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'kali_rider_orders',
    'Order Notifications',
    description: 'Notifications for new orders and delivery updates',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      _log('Permission status: ${settings.authorizationStatus}');

      // Initialize local notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _localNotifs.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );

      // Create Android notification channel
      await _localNotifs
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Save FCM token
      await _saveToken();
      _messaging.onTokenRefresh.listen(_updateToken);
    } catch (e) {
      _log('FCM initialization failed (expected on simulator): $e');
    }
  }

  Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        _log('FCM Token: $token');
        await _updateToken(token);
      }
    } catch (e) {
      _log('Failed to get FCM token: $e');
    }
  }

  Future<void> _updateToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('riders')
            .doc(user.uid)
            .update({'fcmToken': token});
        _log('FCM token saved for rider/${user.uid}');
      } catch (e) {
        _log('Failed to save FCM token: $e');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _log('Foreground message: ${message.notification?.title}');
    final notification = message.notification;
    if (notification != null) {
      _localNotifs.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    _log('Notification tap: ${message.data}');
  }

  void _log(String message) {
    dev.log('[FCM] $message', name: 'KaliRider');
  }
}
