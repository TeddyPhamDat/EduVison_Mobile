import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../utils/notification_utils.dart';
import '../config/api_config.dart';
import 'auth_service.dart' show HttpHelper;
import 'package:firebase_core/firebase_core.dart';
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
      // Initialize FCM Service

      // Firebase should already be initialized in main.dart
      // await Firebase.initializeApp(
      //   options: DefaultFirebaseOptions.currentPlatform,
      // );

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
      // FCM Service initialized successfully
    } catch (e) {
      // FCM Service initialization failed
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

    // Log removed for production;
  }

  /// Request FCM permissions
  Future<void> _requestPermissions() async {
    if (_firebaseMessaging == null) return;

    try {
      // Log removed for production;
      
      // Check current authorization status first
      final initialSettings = await _firebaseMessaging!.getNotificationSettings();
      developer.log(
        'Initial FCM Permission status: ${initialSettings.authorizationStatus}',
        name: 'FCMService',
      );
      
      // Request permissions
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
        'FCM Permission status after request: ${settings.authorizationStatus}',
        name: 'FCMService',
      );
      
      // Check if permissions are denied
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        // Log removed for production;
      } else if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Log removed for production;
      } else {
        // Log removed for production;
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Log removed for production;
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
      // Log removed for production;
    }
  }

  /// Get FCM token
  Future<String?> _getFCMToken() async {
    if (_firebaseMessaging == null) {
      // Log removed for production;
      return null;
    }

    try {
      // Log removed for production;

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
        // Log removed for production;
        return null;
      }
    } catch (e) {
      // Log removed for production;
      // Log removed for production;
      return null;
    }
  }

  /// Save FCM token to local storage
  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      // Log removed for production;
    } catch (e) {
      // Log removed for production;
    }
  }

  /// Load FCM token from local storage
  Future<String?> loadFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fcm_token');
      if (token != null) {
        _fcmToken = token;
        // Log removed for production;
      }
      return token;
    } catch (e) {
      // Log removed for production;
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

    // Log removed for production;
  }

  /// Setup token refresh listener
  void _setupTokenRefreshListener() {
    if (_firebaseMessaging == null) return;

    _firebaseMessaging!.onTokenRefresh.listen((String newToken) {
      // Log removed for production;

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

      // Log removed for production;
    } catch (e) {
      // Log removed for production;
    }
  }

  /// Process notification data and call appropriate callbacks (like JavaScript useEffect)
  void _processNotificationData(Map<String, dynamic> data) {
    try {
      // Log removed for production;

      final type = data['type'] as String?;
      final error = data['error'] as String?;
      final slideUrl = data['slideUrl'] as String?;
      final videoUrl = data['videoUrl'] as String?;

      developer.log(
        'Notification details - Type: $type, SlideUrl: $slideUrl, VideoUrl: $videoUrl',
        name: 'FCMService',
      );

      switch (type) {
        case 'slide_generated':
          developer.log(
            'Calling onSlideGenerated callback with slideUrl: $slideUrl',
            name: 'FCMService',
          );
          
          // Show UI notification if not already shown by foreground handler
          _showUINotification(
            "Slide đã sẵn sàng!",
            "Slide mới đã được tạo thành công. Nhấn để xem chi tiết.",
            isSuccess: true,
          );
          
          if (onSlideGenerated != null) {
            Map<String, dynamic> enrichedData = Map.from(data);
            if (!enrichedData.containsKey('slideUrl') && slideUrl != null) {
              enrichedData['slideUrl'] = slideUrl;
            }
            onSlideGenerated!(enrichedData);
          }
          break;

        case 'video_generated':
          developer.log(
            'Calling onVideoGenerated callback with videoUrl: $videoUrl',
            name: 'FCMService',
          );
          
          // Show UI notification if not already shown by foreground handler
          _showUINotification(
            "Video đã sẵn sàng!",
            "Video mới đã được tạo thành công. Nhấn để xem chi tiết.",
            isSuccess: true,
          );
          
          if (onVideoGenerated != null) {
            Map<String, dynamic> enrichedData = Map.from(data);
            if (!enrichedData.containsKey('videoUrl') && videoUrl != null) {
              enrichedData['videoUrl'] = videoUrl;
            }
            onVideoGenerated!(enrichedData);
          }
          break;

        case 'slide_and_video_generated':
          developer.log(
            'Calling onSlideAndVideoGenerated callback with slideUrl: $slideUrl, videoUrl: $videoUrl',
            name: 'FCMService',
          );
          
          // Show UI notification if not already shown by foreground handler
          _showUINotification(
            "Nội dung đã sẵn sàng!",
            "Slide và video mới đã được tạo thành công. Nhấn để xem chi tiết.",
            isSuccess: true,
          );
          
          if (onSlideAndVideoGenerated != null) {
            Map<String, dynamic> enrichedData = Map.from(data);
            if (!enrichedData.containsKey('slideUrl') && slideUrl != null) {
              enrichedData['slideUrl'] = slideUrl;
            }
            if (!enrichedData.containsKey('videoUrl') && videoUrl != null) {
              enrichedData['videoUrl'] = videoUrl;
            }
            onSlideAndVideoGenerated!(enrichedData);
          }
          break;

        case 'generation_failed':
          developer.log(
            'Calling onGenerationFailed callback with error: $error',
            name: 'FCMService',
          );
          
          // Show UI notification for failure
          _showUINotification(
            "Tạo nội dung thất bại",
            error ?? "Không thể tạo nội dung. Vui lòng thử lại sau.",
            isSuccess: false,
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
      // Log removed for production;
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
    // Log removed for production;

    // Extract notification data
    final type = data['type'] as String?;
    final subject = data['subject'] as String?;
    final chapter = data['chapter'] as String?;
    final slideUrl = data['slideUrl'] as String?;
    final videoUrl = data['videoUrl'] as String?;
    final error = data['error'] as String?;
    // promptId is available in data['promptId'] if needed

    // Log removed for production;
    // Log removed for production;
    // Log removed for production;

    switch (type) {
      case 'slide_generated':
        developer.log(
          'Slide generated - Subject: $subject, Chapter: $chapter',
          name: 'FCMService',
        );
        if (slideUrl != null) {
          // Log removed for production;
          
          // TODO: Navigation to content viewer screen with slideUrl
          // Example: Navigator.of(context).pushNamed('/content-viewer', arguments: {'slideUrl': slideUrl});
          
          // For now, just show a notification
          _showUINotification(
            'Slide đã được tạo',
            'Nhấn vào để xem slide mới của bạn: $subject - Bài $chapter',
            isSuccess: true,
          );
        }
        break;

      case 'video_generated':
        developer.log(
          'Video generated - Subject: $subject, Chapter: $chapter',
          name: 'FCMService',
        );
        if (videoUrl != null) {
          // Log removed for production;
          
          // TODO: Navigation to video viewer screen with videoUrl
          // Example: Navigator.of(context).pushNamed('/video-viewer', arguments: {'videoUrl': videoUrl});
          
          // For now, just show a notification
          _showUINotification(
            'Video đã được tạo',
            'Nhấn vào để xem video mới của bạn: $subject - Bài $chapter',
            isSuccess: true,
          );
        }
        break;

      case 'slide_and_video_generated':
        developer.log(
          'Slide and Video generated - Subject: $subject, Chapter: $chapter',
          name: 'FCMService',
        );
        
        var contentAvailable = [];
        if (slideUrl != null) {
          contentAvailable.add("slide");
          // Log removed for production;
        }
        if (videoUrl != null) {
          contentAvailable.add("video");
          // Log removed for production;
        }
        
        // TODO: Navigation to combined content viewer with both URLs
        // Example: Navigator.of(context).pushNamed('/content-viewer', 
        //          arguments: {'slideUrl': slideUrl, 'videoUrl': videoUrl});
        
        // For now, just show a notification
        _showUINotification(
          'Nội dung đã sẵn sàng',
          'Nhấn vào để xem ${contentAvailable.join(" và ")} mới: $subject - Bài $chapter',
          isSuccess: true,
        );
        break;

      case 'generation_failed':
        // Log removed for production;
        
        // Show error notification
        _showUINotification(
          'Tạo nội dung thất bại',
          error ?? 'Đã có lỗi xảy ra khi tạo nội dung. Vui lòng thử lại.',
          isSuccess: false,
        );
        
        // TODO: Navigation to retry screen
        // Example: Navigator.of(context).pushNamed('/content-generation', 
        //          arguments: {'error': error, 'retryData': {'subject': subject, 'chapter': chapter}});
        break;

      default:
        // Log removed for production;
        
        // For unknown types, just show a generic notification
        if (subject != null || chapter != null) {
          _showUINotification(
            'Thông báo mới',
            'Có thông báo mới về nội dung $subject${chapter != null ? " - Bài $chapter" : ""}',
            isSuccess: true,
          );
        } else {
          _showUINotification(
            'Thông báo mới',
            'Bạn có thông báo mới từ EduVision',
            isSuccess: true,
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
    // Log removed for production;
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

      // Also show UI notification
      _showUINotification(title, body, isSuccess: true);

      // Log removed for production;
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
      // Log removed for production;
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
      // Log removed for production;
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
      // Log removed for production;
      return null;
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    if (_localNotifications == null) return;

    try {
      await _localNotifications!.cancelAll();
      // Log removed for production;
    } catch (e) {
      // Log removed for production;
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

      // Log removed for production;
    } catch (e) {
      // Log removed for production;
    }
  }

  /// Refresh FCM token
  Future<String?> refreshToken() async {
    if (_firebaseMessaging == null) return null;

    try {
      await _firebaseMessaging!.deleteToken();
      return await _getFCMToken();
    } catch (e) {
      // Log removed for production;
      return null;
    }
  }

  /// Update FCM token to backend
  Future<bool> updateTokenToBackend() async {
    try {
      final token = _fcmToken ?? await _getFCMToken();
      if (token == null) {
        // Log removed for production;
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
        // Log removed for production;
        return false;
      }

      final response = await HttpHelper.post(
        Uri.parse('${ApiConfig.authBaseUrl}/${ApiConfig.fcmTokenEndpoint}'),
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

      // Log removed for production;
      await initialize();
    } catch (e) {
      // Log removed for production;
      rethrow;
    }
  }

  /// Test method để gửi FCM token lên backend và test notification
  Future<void> testFCMTokenAndCreateSlide([int template = 1]) async {
    try {
      // Log removed for production;
      
      // Show UI notification for starting the process
      _showUINotification(
        'Bắt đầu tạo slide',
        'Đang chuẩn bị tạo slide mới với mẫu $template...',
        isSuccess: true,
      );
      
      // 1. Đảm bảo có FCM token
      final token = _fcmToken ?? await _getFCMToken();
      if (token == null) {
        // Log removed for production;
        _showUINotification(
          'Lỗi FCM Token',
          'Không thể lấy FCM token. Vui lòng khởi động lại ứng dụng.',
          isSuccess: false,
        );
        return;
      }
      
      // Log removed for production;
      
      // 2. Gửi FCM token lên backend (nếu chưa có endpoint, cần thêm)
      await _sendTokenToBackend(token);
      
      // 3. Test tạo slide để trigger notification
      final authToken = await _getAuthToken();
      if (authToken == null) {
        // Log removed for production;
        _showUINotification(
          'Lỗi xác thực',
          'Không tìm thấy token xác thực. Vui lòng đăng nhập lại.',
          isSuccess: false,
        );
        return;
      }

      _showUINotification(
        'Đang tạo slide',
        'Yêu cầu tạo slide đang được gửi đến máy chủ...',
        isSuccess: true,
      );
      
      // Log all details before making the request
      // Log removed for production;
      // Log removed for production;
      // Log removed for production;
      // Log removed for production;
      
      // Gửi request đến API để tạo slide
      final response = await HttpHelper.post(
        Uri.parse('${ApiConfig.slidesBaseUrl}'),
        headers: {
          'accept': 'text/plain',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          "subject": "GDCD",
          "chapter": "1", 
          "grade": 12,
          "imageCategory": "GDCD",
          "template": template
        }),
      );
      
      // Log removed for production;
      // Log removed for production;
      
      if (response.statusCode == 202) {
        // Log removed for production;
        
        // Parse response to get the promptId
        Map<String, dynamic> responseData = jsonDecode(response.body);
        String? promptId;
        
        if (responseData.containsKey('result')) {
          promptId = responseData['result'].toString();
          // Log removed for production;
        }
        
        _showUINotification(
          'Yêu cầu đã được chấp nhận',
          'Máy chủ đang tạo slide. Bạn sẽ nhận được thông báo khi hoàn thành.',
          isSuccess: true,
        );

        // Simulate notification for testing purposes
        Future.delayed(Duration(seconds: 5), () {
          // Simulate notification from backend for immediate feedback during development
          showLocalNotification(
            title: 'Slide đã sẵn sàng!',
            body: 'Slide mẫu $template đã được tạo thành công',
            data: {
              'type': 'slide_generated',
              'slideUrl': 'https://example.com/slides/sample_$template.html',
              'subject': 'GDCD',
              'chapter': '1',
              'promptId': promptId ?? DateTime.now().millisecondsSinceEpoch.toString(),
              'template': template.toString(),
            },
          );
        });
        
      } else {
        // Log removed for production;
        _showUINotification(
          'Tạo slide thất bại',
          'Lỗi ${response.statusCode}: Không thể tạo slide. Vui lòng thử lại sau.',
          isSuccess: false,
        );
      }
    } catch (e) {
      // Log removed for production;
      _showUINotification(
        'Lỗi khi tạo slide',
        'Đã xảy ra lỗi: ${e.toString()}',
        isSuccess: false,
      );
    }
  }

  /// Gửi FCM token lên backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final authToken = await _getAuthToken();
      if (authToken == null) {
        // Log removed for production;
        return;
      }

      final response = await HttpHelper.post(
        Uri.parse('${ApiConfig.authBaseUrl}/${ApiConfig.fcmTokenEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'FcmToken': token}),
      );

      // Log removed for production;
      if (response.statusCode != 200) {
        // Log removed for production;
      } else {
        // Log removed for production;
      }
    } catch (e) {
      // Log removed for production;
    }
  }

  /// Lấy auth token từ storage
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      // Log removed for production;
      return null;
    }
  }

  /// Test all 4 templates
  Future<void> testAllTemplates() async {
    // Log removed for production;
    
    for (int template = 1; template <= 4; template++) {
      // Log removed for production;
      await testFCMTokenAndCreateSlide(template);
      
      // Wait a bit between requests
      await Future.delayed(Duration(seconds: 2));
    }
    
    // Log removed for production;
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Log removed for production;
  }

  developer.log(
    'Background message received: ${message.messageId}',
    name: 'FCMService',
  );
  // Log removed for production;

  // Store notification data in shared preferences for retrieval when app opens
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Store latest notification
    await prefs.setString('latest_fcm_notification', jsonEncode({
      'type': message.data['type'],
      'time': DateTime.now().toIso8601String(),
      'data': message.data,
    }));
    
    // Add to notification history
    final historyJson = prefs.getStringList('fcm_notification_history') ?? [];
    historyJson.add(jsonEncode({
      'type': message.data['type'],
      'time': DateTime.now().toIso8601String(),
      'data': message.data,
    }));
    
    // Limit history to last 20 notifications
    if (historyJson.length > 20) {
      historyJson.removeAt(0);
    }
    
    await prefs.setStringList('fcm_notification_history', historyJson);
  } catch (e) {
    // Log removed for production;
  }
}
