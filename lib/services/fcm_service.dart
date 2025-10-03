import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_background_handler.dart';

class FCMService {
  static FirebaseMessaging? _messaging;
  static String? _currentToken;

  /// Initialize Firebase dan FCM
  static Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      
      _messaging = FirebaseMessaging.instance;
      
      // Request permission untuk notifications
      await _requestPermission();
      
      // Setup handlers
      await _setupHandlers();
      
      // Get dan save initial token
      await _getAndSaveToken();
      
      // Listen for token refresh
      _messaging!.onTokenRefresh.listen(_saveTokenToDatabase);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing FCM: $e');
      }
    }
  }

  /// Request notification permission
  static Future<void> _requestPermission() async {
    if (_messaging == null) return;

    NotificationSettings settings = await _messaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }
  }

  /// Setup message handlers
  static Future<void> _setupHandlers() async {
    if (_messaging == null) return;

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle app launch from notification
    _messaging!.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessageOpenedApp(message);
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Get FCM token dan save ke database
  static Future<void> _getAndSaveToken() async {
    if (_messaging == null) return;

    try {
      String? token = await _messaging!.getToken();
      if (token != null) {
        _currentToken = token;
        await _saveTokenToDatabase(token);
        if (kDebugMode) {
          print('FCM Token: $token');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  /// Save token ke Supabase database
  static Future<void> _saveTokenToDatabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('User not logged in, token not saved');
        }
        return;
      }

      // Retry mechanism untuk mengatasi race condition saat Google Sign In
      int retryCount = 0;
      const maxRetries = 5;
      const retryDelay = Duration(seconds: 3);

      while (retryCount < maxRetries) {
        try {
          // STEP 1: Pastikan profile user sudah ada di database
          final profileCheck = await Supabase.instance.client
              .from('profiles')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();

          if (profileCheck == null) {
            retryCount++;
            if (kDebugMode) {
              print('Profile not found, waiting for profile creation... (attempt $retryCount/$maxRetries)');
            }
            if (retryCount < maxRetries) {
              await Future.delayed(retryDelay);
              continue;
            } else {
              throw Exception('Profile not created after $maxRetries attempts');
            }
          }

          // STEP 2: Profile sudah ada, sekarang save FCM token
          await Supabase.instance.client
              .from('notifications')
              .upsert({
                'user_id': user.id,
                'fcm_token': token,
              }, onConflict: 'fcm_token');

          if (kDebugMode) {
            print('FCM token saved to database for user: ${user.id}');
          }
          return; // Success, exit retry loop

        } catch (e) {
          retryCount++;
          if (e.toString().contains('row-level security policy') && retryCount < maxRetries) {
            if (kDebugMode) {
              print('RLS error, retrying in ${retryDelay.inSeconds}s... (attempt $retryCount/$maxRetries)');
            }
            await Future.delayed(retryDelay);
          } else if (retryCount >= maxRetries) {
            if (kDebugMode) {
              print('Max retries reached, giving up saving FCM token');
            }
            return;
          } else {
            // If not RLS error, rethrow
            rethrow;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token to database: $e');
      }
    }
  }

  /// Handle foreground messages (app is open)
  static void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Received foreground message: ${message.messageId}');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }
    
    // Show in-app notification atau update UI
    if (message.notification != null) {
      _showInAppNotification(message);
    }
  }

  /// Handle message when app is opened from notification
  static void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('App opened from notification: ${message.messageId}');
    }
    
    // Navigate berdasarkan data payload
    _handleNavigation(message.data);
  }

  /// Show in-app notification
  static void _showInAppNotification(RemoteMessage message) {
    // Implementasi untuk show snackbar atau dialog
    // Bisa disesuaikan dengan UI/UX yang diinginkan
    if (kDebugMode) {
      print('Show notification: ${message.notification!.title}');
    }
  }

  /// Handle navigation berdasarkan notification data
  static void _handleNavigation(Map<String, dynamic> data) {
    try {
      if (data.containsKey('screen')) {
        String screen = data['screen'];
        
        // Navigate ke screen yang sesuai
        switch (screen) {
          case '/track-report':
            // Navigate ke track report dengan report_id
            if (data.containsKey('report_id')) {
              _navigateToTrackReport(data['report_id']);
            }
            break;
          case '/admin/kelola-laporan':
            // Navigate ke admin kelola laporan
            _navigateToAdminReports();
            break;
          default:
            if (kDebugMode) {
              print('Unknown screen: $screen');
            }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling navigation: $e');
      }
    }
  }

  /// Navigate to track report screen
  static void _navigateToTrackReport(String reportId) {
    // Implementasi navigation ke track report
    // Sesuaikan dengan routing app Anda
    if (kDebugMode) {
      print('Navigate to track report: $reportId');
    }
  }

  /// Navigate to admin reports screen
  static void _navigateToAdminReports() {
    // Implementasi navigation ke admin reports
    if (kDebugMode) {
      print('Navigate to admin reports');
    }
  }

  /// Get current FCM token
  static String? getCurrentToken() {
    return _currentToken;
  }

  /// Delete token dari database (saat logout)
  static Future<void> deleteTokenFromDatabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || _currentToken == null) return;

      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('user_id', user.id)
          .eq('fcm_token', _currentToken!);

      if (kDebugMode) {
        print('FCM token deleted from database');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting FCM token: $e');
      }
    }
  }

  /// Subscribe to topic (optional)
  static Future<void> subscribeToTopic(String topic) async {
    if (_messaging == null) return;
    
    try {
      await _messaging!.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic: $e');
      }
    }
  }

  /// Unsubscribe from topic (optional)
  static Future<void> unsubscribeFromTopic(String topic) async {
    if (_messaging == null) return;
    
    try {
      await _messaging!.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic: $e');
      }
    }
  }

  /// DEBUG: Print FCM status dan token untuk testing
  static Future<void> debugFCMStatus() async {
    if (kDebugMode) {
      print('=== FCM DEBUG STATUS ===');
    }
    
    if (_messaging == null) {
      if (kDebugMode) {
        print('❌ FCM not initialized');
      }
      return;
    }
    
    if (kDebugMode) {
      print('✅ FCM initialized');
    }
    
    // Check permission
    NotificationSettings settings = await _messaging!.getNotificationSettings();
    if (kDebugMode) {
      print('Permission status: ${settings.authorizationStatus}');
      print('Alert setting: ${settings.alert}');
      print('Badge setting: ${settings.badge}');
      print('Sound setting: ${settings.sound}');
    }
    
    // Check token
    if (_currentToken != null) {
      if (kDebugMode) {
        print('✅ Current FCM Token: $_currentToken');
      }
    } else {
      if (kDebugMode) {
        print('❌ No FCM token available');
      }
      try {
        String? token = await _messaging!.getToken();
        if (kDebugMode) {
          print('Fresh token: $token');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error getting fresh token: $e');
        }
      }
    }
    
    // Check user login status
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      if (kDebugMode) {
        print('✅ User logged in: ${user.id}');
      }
    } else {
      if (kDebugMode) {
        print('❌ User not logged in');
      }
    }
    
    if (kDebugMode) {
      print('=== END FCM DEBUG ===');
    }
  }
}

 