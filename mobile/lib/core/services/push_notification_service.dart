import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import 'storage_service.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 Background message: ${message.messageId}');
}

/// Push notification service provider
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});

/// Push Notification Service using Firebase Cloud Messaging
class PushNotificationService {
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  
  PushNotificationService(this._ref);
  
  /// Initialize the push notification service
  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _setupFCM();
      await _setupLocalNotifications();
    }
  }
  
  /// Setup Firebase Cloud Messaging
  Future<void> _setupFCM() async {
    // Set up background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Get FCM token
    _fcmToken = await _messaging.getToken();
    debugPrint('🔔 FCM Token obtained: $_fcmToken');
    
    // Don't register immediately - wait until user is authenticated
    // The token will be registered when registerTokenIfNeeded() is called after login
    
    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      debugPrint('🔔 FCM Token refreshed: $newToken');
      // Try to register the new token (will only succeed if authenticated)
      await registerTokenIfNeeded();
    });
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
    
    // Try to register token if user is already logged in
    await registerTokenIfNeeded();
  }
  
  /// Setup local notifications for foreground display
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('🔔 Local notification tapped: ${details.payload}');
        // Handle navigation based on payload
      },
    );
    
    // Create notification channel for Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'trabab_notifications',
        'Trabab Notifications',
        description: 'Auction updates, bids, and messages',
        importance: Importance.high,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }
  
  /// Register FCM token with backend (public method to call after login)
  Future<void> registerTokenIfNeeded() async {
    if (_fcmToken == null) {
      debugPrint('🔔 No FCM token available to register');
      return;
    }
    await _registerTokenWithBackend(_fcmToken!);
  }
  
  /// Register FCM token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      // Check if we have an auth token before trying to register
      final storageService = _ref.read(storageServiceProvider);
      final authToken = await storageService.getToken();
      if (authToken == null || authToken.isEmpty) {
        debugPrint('🔔 Skipping FCM registration - user not authenticated');
        return;
      }
      
      final client = _ref.read(dioClientProvider);
      await client.put('/users/me', data: {
        'fcm_token': token,
      });
      debugPrint('🔔 FCM token registered with backend');
    } catch (e) {
      debugPrint('🔔 Failed to register FCM token: $e');
    }
  }
  
  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Foreground message: ${message.notification?.title}');
    
    final notification = message.notification;
    if (notification == null) return;
    
    // Show local notification
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'trabab_notifications',
          'Trabab Notifications',
          channelDescription: 'Auction updates, bids, and messages',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['route'], // For navigation on tap
    );
  }
  
  /// Handle notification tap (app in background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped: ${message.data}');
    
    // Handle navigation based on message data
    final route = message.data['route'];
    final auctionId = message.data['auction_id'];
    final chatId = message.data['chat_id'];
    
    // Navigation would be handled by the app's router
    // This is typically done via a callback or stream
    debugPrint('🔔 Navigate to: $route, auctionId: $auctionId, chatId: $chatId');
  }
  
  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('🔔 Subscribed to topic: $topic');
  }
  
  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('🔔 Unsubscribed from topic: $topic');
  }
}
