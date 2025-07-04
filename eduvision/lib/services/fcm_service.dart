import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../utils/notification_utils.dart';
import '../firebase_options.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  FirebaseMessaging? _firebaseMessaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  String? _fcmToken;
  bool _isInitialized = false;

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  // Callback functions (like JavaScript onMessage)
  Function(RemoteMessage)? onMessageReceived;
  Function(RemoteMessage)? onMessageOpenedApp;
  Function(String?)? onTokenRefresh;

  // Content generation callbacks (like JavaScript useEffect)
  Function(Map<String, dynamic>)? onSlideGenerated;
  Function(Map<String, dynamic>)? onVideoGenerated;
  Function(Map<String, dynamic>)? onSlideAndVideoGenerated;
  Function(String?, String?)? onGenerationFailed;

  // UI notification callback (like notify.success/info in JavaScript)
  Function(String title, String message, {bool isSuccess})?
  onShowUINotification;

  /// Initialize Firebase and FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log('Initializing Firebase...', name: 'FCMService');

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Firebase Messaging
      _firebaseMessaging = FirebaseMessaging.instance;

      // Initialize Local Notifications
      await _initializeLocalNotifications();

      // Request permissions
      await _requestPermissions();

      // Get FCM token
      await _getFCMToken();

      // Setup message handlers
      _setupMessageHandlers();

      // Setup token refresh listener
      _setupTokenRefreshListener();

      _isInitialized = true;
      developer.log('FCM Service initialized successfully', name: 'FCMService');
    } catch (e) {
      developer.log(
        'FCM Service initialization failed: $e',
        name: 'FCMService',
      );
      rethrow;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize
    await _localNotifications!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    developer.log('Local notifications initialized', name: 'FCMService');
  }

  /// Request FCM permissions
  Future<void> _requestPermissions() async {
    if (_firebaseMessaging == null) return;

    try {
      NotificationSettings settings = await _firebaseMessaging!
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      developer.log(
        'FCM Permission status: ${settings.authorizationStatus}',
        name: 'FCMService',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        developer.log('User granted permission', name: 'FCMService');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        developer.log(
          'User granted provisional permission',
          name: 'FCMService',
        );
      } else {
        developer.log(
          'User declined or has not accepted permission',
          name: 'FCMService',
        );
      }
    } catch (e) {
      developer.log('Error requesting permissions: $e', name: 'FCMService');
    }
  }

  /// Get FCM token
  Future<String?> _getFCMToken() async {
    if (_firebaseMessaging == null) {
      developer.log('Firebase Messaging is null', name: 'FCMService');
      return null;
    }

    try {
      developer.log('Requesting FCM token...', name: 'FCMService');

      // Use VAPID key like in JavaScript implementation
      _fcmToken = await _firebaseMessaging!.getToken(
        vapidKey:
            "BGqKQv-rcqMy49IjdzreFTnI2Lnd09Ff9v6fB8_6f9x3IXdme_UZzwb47vVbcQPvii1adYsVJR1u-E8HCNBxM70",
      );

      if (_fcmToken != null) {
        developer.log(
          'FCM Token received: ${_fcmToken!.substring(0, 20)}...',
          name: 'FCMService',
        );
        await _saveFCMToken(_fcmToken!);
        return _fcmToken;
      } else {
        developer.log('FCM Token is null after request', name: 'FCMService');
        return null;
      }
    } catch (e) {
      developer.log('Error getting FCM token: $e', name: 'FCMService');
      developer.log('Error type: ${e.runtimeType}', name: 'FCMService');
      return null;
    }
  }

  /// Save FCM token to local storage
  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      developer.log('FCM token saved to storage', name: 'FCMService');
    } catch (e) {
      developer.log('Error saving FCM token: $e', name: 'FCMService');
    }
  }

  /// Load FCM token from local storage
  Future<String?> loadFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fcm_token');
      if (token != null) {
        _fcmToken = token;
        developer.log('FCM token loaded from storage', name: 'FCMService');
      }
      return token;
    } catch (e) {
      developer.log('Error loading FCM token: $e', name: 'FCMService');
      return null;
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    if (_firebaseMessaging == null) return;

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log(
        'Received foreground message: ${message.messageId}',
        name: 'FCMService',
      );

      _handleForegroundMessage(message);

      // Call custom callback
      if (onMessageReceived != null) {
        onMessageReceived!(message);
      }
    });

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
        'App opened from background message: ${message.messageId}',
        name: 'FCMService',
      );

      // Process notification data and call appropriate callbacks
      _processNotificationData(message.data);

      // Call custom callback
      if (onMessageOpenedApp != null) {
        onMessageOpenedApp!(message);
      }
    });

    developer.log('Message handlers setup complete', name: 'FCMService');
  }

  /// Setup token refresh listener
  void _setupTokenRefreshListener() {
    if (_firebaseMessaging == null) return;

    _firebaseMessaging!.onTokenRefresh.listen((String newToken) {
      developer.log('FCM Token refreshed: $newToken', name: 'FCMService');

      _fcmToken = newToken;
      _saveFCMToken(newToken);

      // Call custom callback
      if (onTokenRefresh != null) {
        onTokenRefresh!(newToken);
      }
    });
  }

  /// Handle foreground messages by showing local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (_localNotifications == null) return;

    try {
      // Process notification data and call appropriate callbacks (like JavaScript useEffect)
      _processNotificationData(message.data);

      // Show UI notification (like notify.success/info in JavaScript)
      final title = message.notification?.title ?? 'EduVision';
      final body = message.notification?.body ?? 'You have a new notification';
      _showUINotification(title, body, isSuccess: true);

      // Create notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'edu_vision_channel',
            'EduVision Notifications',
            channelDescription: 'Notifications from EduVision app',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification
      await _localNotifications!.show(
        message.hashCode,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );

      developer.log('Local notification shown', name: 'FCMService');
    } catch (e) {
      developer.log('Error showing local notification: $e', name: 'FCMService');
    }
  }

  /// Process notification data and call appropriate callbacks (like JavaScript useEffect)
  void _processNotificationData(Map<String, dynamic> data) {
    try {
      developer.log('Processing notification data: $data', name: 'FCMService');

      final type = data['type'] as String?;
      final error = data['error'] as String?;

      switch (type) {
        case 'slide_generated':
          developer.log(
            'Calling onSlideGenerated callback',
            name: 'FCMService',
          );
          if (onSlideGenerated != null) {
            onSlideGenerated!(data);
          }
          break;

        case 'video_generated':
          developer.log(
            'Calling onVideoGenerated callback',
            name: 'FCMService',
          );
          if (onVideoGenerated != null) {
            onVideoGenerated!(data);
          }
          break;

        case 'slide_and_video_generated':
          developer.log(
            'Calling onSlideAndVideoGenerated callback',
            name: 'FCMService',
          );
          if (onSlideAndVideoGenerated != null) {
            onSlideAndVideoGenerated!(data);
          }
          break;

        case 'generation_failed':
          developer.log(
            'Calling onGenerationFailed callback',
            name: 'FCMService',
          );
          if (onGenerationFailed != null) {
            onGenerationFailed!(error, data.toString());
          }
          break;

        default:
          developer.log(
            'Unknown notification type for callback: $type',
            name: 'FCMService',
          );
      }
    } catch (e) {
      developer.log(
        'Error processing notification data: $e',
        name: 'FCMService',
      );
    }
  }

  /// Show UI notification (like notify.success/info in JavaScript)
  void _showUINotification(
    String title,
    String message, {
    bool isSuccess = true,
  }) {
    try {
      developer.log(
        'Showing UI notification: $title - $message',
        name: 'FCMService',
      );

      // Use NotificationUtils for UI feedback (like notify.success/info in JavaScript)
      NotificationUtils.showNotification(title, message, isSuccess: isSuccess);

      // Also call custom callback if set
      if (onShowUINotification != null) {
        onShowUINotification!(title, message, isSuccess: isSuccess);
      }
    } catch (e) {
      developer.log('Error showing UI notification: $e', name: 'FCMService');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    developer.log(
      'Notification tapped: ${response.payload}',
      name: 'FCMService',
    );

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        // Handle notification data - navigate to specific screen, etc.
        _handleNotificationData(data);
      } catch (e) {
        developer.log(
          'Error parsing notification payload: $e',
          name: 'FCMService',
        );
      }
    }
  }

  /// Handle notification data
  void _handleNotificationData(Map<String, dynamic> data) {
    developer.log('Handling notification data: $data', name: 'FCMService');

    // Extract notification data
    final type = data['type'] as String?;
    final subjectId = data['subjectId'] as String?;
    final chapterId = data['chapterId'] as String?;
    final slideUrl = data['slideUrl'] as String?;
    final videoUrl = data['videoUrl'] as String?;
    final error = data['error'] as String?;

    switch (type) {
      case 'slide_generated':
        developer.log(
          'Slide generated - Subject: $subjectId, Chapter: $chapterId',
          name: 'FCMService',
        );
        if (slideUrl != null) {
          developer.log('Slide URL: $slideUrl', name: 'FCMService');
          // Navigate to slide or open URL
        }
        break;

      case 'video_generated':
        developer.log(
          'Video generated - Subject: $subjectId, Chapter: $chapterId',
          name: 'FCMService',
        );
        if (videoUrl != null) {
          developer.log('Video URL: $videoUrl', name: 'FCMService');
          // Navigate to video or open URL
        }
        break;

      case 'slide_and_video_generated':
        developer.log(
          'Slide and Video generated - Subject: $subjectId, Chapter: $chapterId',
          name: 'FCMService',
        );
        if (slideUrl != null)
          developer.log('Slide URL: $slideUrl', name: 'FCMService');
        if (videoUrl != null)
          developer.log('Video URL: $videoUrl', name: 'FCMService');
        // Navigate to content page with both slide and video
        break;

      case 'generation_failed':
        developer.log('Generation failed - Error: $error', name: 'FCMService');
        // Show error dialog or navigate to retry page
        break;

      // Legacy support for old notification types
      case 'video_complete':
        developer.log('Legacy: Navigate to video', name: 'FCMService');
        break;
      case 'slide_ready':
        developer.log('Legacy: Navigate to slides', name: 'FCMService');
        break;
      case 'new_lesson':
        developer.log('Legacy: Navigate to lesson', name: 'FCMService');
        break;

      default:
        developer.log('Unknown notification type: $type', name: 'FCMService');
        // Default action - navigate to education screen or main screen
        if (subjectId != null || chapterId != null) {
          developer.log(
            'Navigate to education - Subject: $subjectId, Chapter: $chapterId',
            name: 'FCMService',
          );
        }
    }
  }

  /// Test method to process notification data (for debug purposes)
  void processNotificationDataTest(Map<String, dynamic> data) {
    _processNotificationData(data);
  }

  /// Handle notification navigation from web service worker
  void handleNotificationNavigation(Map<String, dynamic> data) {
    developer.log(
      'Handling notification navigation: $data',
      name: 'FCMService',
    );
    _handleNotificationData(data);
  }

  /// Set up web message listener (for Flutter Web)
  void setupWebMessageListener() {
    // This will be called when service worker sends message to main app
    // Note: This is a placeholder for web-specific implementation
    developer.log('Web message listener setup (web only)', name: 'FCMService');
  }

  /// Show local notification manually (useful for testing)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (_localNotifications == null) return;

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'edu_vision_channel',
            'EduVision Notifications',
            channelDescription: 'Notifications from EduVision app',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications!.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
        payload: data != null ? jsonEncode(data) : null,
      );

      developer.log('Local notification shown manually', name: 'FCMService');
    } catch (e) {
      developer.log(
        'Error showing manual notification: $e',
        name: 'FCMService',
      );
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    if (_firebaseMessaging == null) return;

    try {
      await _firebaseMessaging!.subscribeToTopic(topic);
      developer.log('Subscribed to topic: $topic', name: 'FCMService');
    } catch (e) {
      developer.log(
        'Error subscribing to topic $topic: $e',
        name: 'FCMService',
      );
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_firebaseMessaging == null) return;

    try {
      await _firebaseMessaging!.unsubscribeFromTopic(topic);
      developer.log('Unsubscribed from topic: $topic', name: 'FCMService');
    } catch (e) {
      developer.log(
        'Error unsubscribing from topic $topic: $e',
        name: 'FCMService',
      );
    }
  }

  /// Get initial message (when app is opened from terminated state)
  Future<RemoteMessage?> getInitialMessage() async {
    if (_firebaseMessaging == null) return null;

    try {
      final message = await _firebaseMessaging!.getInitialMessage();
      if (message != null) {
        developer.log(
          'App opened from terminated state with message: ${message.messageId}',
          name: 'FCMService',
        );
      }
      return message;
    } catch (e) {
      developer.log('Error getting initial message: $e', name: 'FCMService');
      return null;
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    if (_localNotifications == null) return;

    try {
      await _localNotifications!.cancelAll();
      developer.log('All notifications cleared', name: 'FCMService');
    } catch (e) {
      developer.log('Error clearing notifications: $e', name: 'FCMService');
    }
  }

  /// Delete FCM token (for logout)
  Future<void> deleteToken() async {
    if (_firebaseMessaging == null) return;

    try {
      await _firebaseMessaging!.deleteToken();
      _fcmToken = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');

      developer.log('FCM token deleted', name: 'FCMService');
    } catch (e) {
      developer.log('Error deleting FCM token: $e', name: 'FCMService');
    }
  }

  /// Refresh FCM token
  Future<String?> refreshToken() async {
    if (_firebaseMessaging == null) return null;

    try {
      await _firebaseMessaging!.deleteToken();
      return await _getFCMToken();
    } catch (e) {
      developer.log('Error refreshing FCM token: $e', name: 'FCMService');
      return null;
    }
  }

  /// Update FCM token to backend
  Future<bool> updateTokenToBackend() async {
    try {
      final token = _fcmToken ?? await _getFCMToken();
      if (token == null) {
        developer.log('No FCM token to update', name: 'FCMService');
        return false;
      }

      // Get auth token (you'll need to import auth service)
      // For now, we'll assume the auth token is passed from outside
      developer.log(
        'FCM token ready for backend update: ${token.substring(0, 20)}...',
        name: 'FCMService',
      );

      // This method should be called from AuthService after login
      // with the auth token as parameter
      return true;
    } catch (e) {
      developer.log(
        'Error updating FCM token to backend: $e',
        name: 'FCMService',
      );
      return false;
    }
  }

  /// Update FCM token to backend with auth token
  Future<bool> updateTokenToBackendWithAuth(String authToken) async {
    try {
      final fcmToken = _fcmToken ?? await _getFCMToken();
      if (fcmToken == null) {
        developer.log('No FCM token to update', name: 'FCMService');
        return false;
      }

      final response = await http.post(
        Uri.parse('https://localhost:7258/api/authentication/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'FcmToken': fcmToken}),
      );

      if (response.statusCode == 200) {
        developer.log(
          'FCM token updated to backend successfully',
          name: 'FCMService',
        );
        return true;
      } else {
        developer.log(
          'Failed to update FCM token: ${response.statusCode} - ${response.body}',
          name: 'FCMService',
        );
        return false;
      }
    } catch (e) {
      developer.log(
        'Error updating FCM token to backend: $e',
        name: 'FCMService',
      );
      return false;
    }
  }

  /// Debug method to check FCM initialization status
  Map<String, dynamic> getDebugStatus() {
    return {
      'isInitialized': _isInitialized,
      'hasFirebaseMessaging': _firebaseMessaging != null,
      'hasLocalNotifications': _localNotifications != null,
      'fcmTokenExists': _fcmToken != null,
      'fcmTokenLength': _fcmToken?.length ?? 0,
      'fcmTokenPrefix':
          _fcmToken?.substring(
            0,
            _fcmToken!.length > 20 ? 20 : _fcmToken!.length,
          ) ??
          'null',
    };
  }

  /// Force reinitialize FCM (for debugging)
  Future<void> forceReinitialize() async {
    try {
      _isInitialized = false;
      _fcmToken = null;
      _firebaseMessaging = null;
      _localNotifications = null;

      developer.log('Force reinitializing FCM...', name: 'FCMService');
      await initialize();
    } catch (e) {
      developer.log('Force reinitialize failed: $e', name: 'FCMService');
      rethrow;
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  developer.log(
    'Background message received: ${message.messageId}',
    name: 'FCMService',
  );

  // Handle background message
  // Note: Don't call setState or update UI here
}
