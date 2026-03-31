// notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class NotificationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize local notifications & Firebase messaging
  Future<void> init() async {
    // 1. Local notifications initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification clicked: ${details.payload}');
      },
    );

    // 2. Firebase Messaging initialization
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission (iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // Handle background messages (requires top-level function in main.dart)
    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   print('Notification clicked: ${message.notification?.title}');
    // });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked: ${message.notification?.title}');
      _handleNotificationClick(message.data);
    });

    // Optional: get FCM token
    String? token = await messaging.getToken();
    print('FCM Token: $token');
    AppConstants.firebase_token = token ?? '';
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    final route = data['route']; // Ensure your FCM payload has "route"

    if (route == 'receivables') {
      // navigatorKey.currentState?.push(
      //   MaterialPageRoute(builder: (_) => const ReceivablesPage()),
      // );
    }
    // Add more routes if needed
    else if (route == 'lowStock') {
      // navigatorKey.currentState?.push(
      //   MaterialPageRoute(builder: (_) => const MinLevelStockPage()),
      // );
    }
  }

  // Show a local notification
  Future<void> _showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'channel_id',
            'channel_name',
            channelDescription: 'Firebase notifications',
            importance: Importance.max,
            priority: Priority.high,
          );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
        payload: message.data['payload'] ?? '',
      );
    }
  }

  // Trigger a test local notification
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'This is a test notification',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Test Notification',
      'This is a test notification body',
      platformDetails,
    );
  }
}
