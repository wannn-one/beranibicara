import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const _androidChannel = AndroidNotificationChannel(
  'beranibicara_alerts',
  'Notifikasi Berani Bicara',
  description: 'Pembaruan laporan, balasan, dan pengumuman sekolah',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  String? currentToken;
  bool _initialized = false;

  Future<void> initialize({
    required void Function(String route) onOpenRoute,
    void Function(String token)? onToken,
  }) async {
    if (kIsWeb || _initialized) return;

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase init skipped: $e');
      return;
    }
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _local.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: (response) {
          final route = response.payload;
          if (route != null && route.isNotEmpty) onOpenRoute(route);
        },
      );

      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification == null) return;
        _local.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: _routeFromData(message.data),
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final route = _routeFromData(message.data);
        if (route.isNotEmpty) onOpenRoute(route);
      });

      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        final route = _routeFromData(initial.data);
        if (route.isNotEmpty) onOpenRoute(route);
      }

      currentToken = await FirebaseMessaging.instance.getToken();
      if (currentToken != null) onToken?.call(currentToken!);
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        currentToken = token;
        onToken?.call(token);
      });

      _initialized = true;
    } catch (e) {
      debugPrint('FCM setup skipped: $e');
    }
  }

  Future<String?> refreshToken() async {
    if (kIsWeb) return null;
    currentToken = await FirebaseMessaging.instance.getToken();
    return currentToken;
  }

  Future<void> deleteLocalToken() async {
    if (kIsWeb) return;
    await FirebaseMessaging.instance.deleteToken();
    currentToken = null;
  }

  String deviceOsLabel() {
    if (kIsWeb) return 'web';
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  }

  String _routeFromData(Map<String, dynamic> data) {
    final route = data['route']?.toString();
    if (route != null && route.isNotEmpty) return route;

    final type = data['related_entity_type']?.toString();
    final id = data['related_entity_id']?.toString();
    if (id == null || id.isEmpty) return '';
    switch (type) {
      case 'report':
        return '/reports/$id';
      case 'socialization':
        return '/socialization/$id';
      case 'cerita_kelas':
        return '/cerita-kelas/$id';
      default:
        return '';
    }
  }
}
