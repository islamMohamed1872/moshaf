import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('📋 Permission: ${settings.authorizationStatus}');


    // 2. iOS: wait for APNs token
    if (Platform.isIOS) {
      String? apnsToken;
      for (int i = 0; i < 10; i++) {
        apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) break;
        await Future.delayed(const Duration(seconds: 1));
      }
      if (apnsToken == null) {
        print('❌ APNs token not available');
        return;
      }
      print('✅ APNs ready');
    }


    // 3. Show notifications when app is in foreground (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Save FCM token to Firebase
    final fcmToken = await _messaging.getToken();
    print(" fcmToken : $fcmToken");
    if (fcmToken != null) await _saveToken(fcmToken);
    _messaging.onTokenRefresh.listen(_saveToken);

    // 5. Init local notifications (for foreground on Android)
    await _initLocalNotifications();

    // 6. Foreground: show local notification + handle
    FirebaseMessaging.onMessage.listen((message) {
      print('📨 Foreground: ${message.notification?.title}');
      _showLocalNotification(message);
      _handleMessage(message);
    });

    // 7. Background: app opened by tapping notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('📨 Opened from background: ${message.data}');
      _handleMessage(message);
    });

    // 8. Killed: app opened by tapping notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      print('📨 Opened from killed: ${initial.data}');
      _handleMessage(initial);
    }
  }

  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        print('🔔 Notification tapped: ${response.payload}');
        // Handle navigation here using payload
      },
    );

    // Create Android channel
    const channel = AndroidNotificationChannel(
      'orders_channel',
      'Orders',
      description: 'Order updates and status',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation
    <AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
     notification.title,
     notification.body,
    const NotificationDetails(
        android: AndroidNotificationDetails(
          'orders_channel',
          'Orders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['type'],
    );
  }

  static void _handleMessage(RemoteMessage message) {
    final type = message.data['type'];
    print('📨 Handling type: $type');
    // Add your navigation logic here
  }

  static Future<void> _saveToken(String token) async {
    if (FirebaseAuth.instance.currentUser==null) return;
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await _db.collection("FCM_tokens").doc(userId).set({
      "fcmToken" :token,
    });
    print('✅ Token saved for user $userId');
  }
}