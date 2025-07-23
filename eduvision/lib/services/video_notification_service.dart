import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'fcm_service.dart';
import 'dart:developer' as developer;

class VideoNotification {
  final int? generateVideoId;
  final String type;
  final String? videoUrl;
  final String? errorMessage;
  final DateTime receivedAt;

  VideoNotification({
    required this.type,
    this.generateVideoId,
    this.videoUrl,
    this.errorMessage,
    required this.receivedAt,
  });

  factory VideoNotification.fromJson(Map<String, dynamic> json) {
    return VideoNotification(
      type: json['type'] as String,
      generateVideoId: json['generateVideoId'] is String 
          ? int.tryParse(json['generateVideoId']) 
          : json['generateVideoId'] as int?,
      videoUrl: json['videoUrl'] as String?,
      errorMessage: json['error'] as String?,
      receivedAt: json['receivedAt'] != null 
          ? DateTime.parse(json['receivedAt'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'generateVideoId': generateVideoId,
      'videoUrl': videoUrl,
      'error': errorMessage,
      'receivedAt': receivedAt.toIso8601String(),
    };
  }
}

class VideoNotificationService {
  static final VideoNotificationService _instance = VideoNotificationService._internal();
  factory VideoNotificationService() => _instance;
  
  final FCMService _fcmService = FCMService();
  final List<VideoNotification> _notifications = [];
  final String _storageKey = 'video_notifications';

  // Callbacks
  Function(VideoNotification)? onVideoNotification;
  
  VideoNotificationService._internal() {
    _loadNotifications();
    _setupFCMHandlers();
  }
  
  void _setupFCMHandlers() {
    _fcmService.onVideoGenerated = (data) {
      final notification = VideoNotification(
        type: 'video_generated',
        generateVideoId: data['generateVideoId'] is String 
            ? int.tryParse(data['generateVideoId']) 
            : data['generateVideoId'] as int?,
        videoUrl: data['videoUrl'] as String?,
        receivedAt: DateTime.now(),
      );
      
      _addNotification(notification);
      
      // Call callback if registered
      if (onVideoNotification != null) {
        onVideoNotification!(notification);
      }
    };
    
    _fcmService.onGenerationFailed = (error, details) {
      final notification = VideoNotification(
        type: 'generation_failed',
        errorMessage: error,
        receivedAt: DateTime.now(),
      );
      
      _addNotification(notification);
      
      // Call callback if registered
      if (onVideoNotification != null) {
        onVideoNotification!(notification);
      }
    };
  }
  
  void _addNotification(VideoNotification notification) {
    _notifications.add(notification);
    _saveNotifications();
    developer.log('Video notification added: ${notification.type}', name: 'VideoNotificationService');
  }
  
  // Get all notifications
  List<VideoNotification> getNotifications() {
    return List.unmodifiable(_notifications);
  }
  
  // Get notifications for a specific video ID
  List<VideoNotification> getNotificationsForVideo(int videoId) {
    return _notifications
        .where((notification) => notification.generateVideoId == videoId)
        .toList();
  }
  
  // Get the latest notification
  VideoNotification? getLatestNotification() {
    if (_notifications.isEmpty) return null;
    return _notifications.last;
  }
  
  // Load notifications from local storage
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_storageKey);
      
      if (notificationsJson != null) {
        final loadedNotifications = notificationsJson
            .map((json) => VideoNotification.fromJson(jsonDecode(json)))
            .toList();
        
        _notifications.clear();
        _notifications.addAll(loadedNotifications);
        
        developer.log(
          'Loaded ${_notifications.length} video notifications from storage',
          name: 'VideoNotificationService',
        );
      }
    } catch (e) {
      developer.log(
        'Error loading video notifications: $e',
        name: 'VideoNotificationService',
      );
    }
  }
  
  // Save notifications to local storage
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications
          .map((notification) => jsonEncode(notification.toJson()))
          .toList();
      
      await prefs.setStringList(_storageKey, notificationsJson);
      
      developer.log(
        'Saved ${_notifications.length} video notifications to storage',
        name: 'VideoNotificationService',
      );
    } catch (e) {
      developer.log(
        'Error saving video notifications: $e',
        name: 'VideoNotificationService',
      );
    }
  }
  
  // Check if there's a notification for a specific video ID
  bool hasNotificationForVideo(int videoId) {
    return _notifications.any((notification) => 
        notification.generateVideoId == videoId);
  }
  
  // Clear all notifications
  Future<void> clearNotifications() async {
    _notifications.clear();
    await _saveNotifications();
  }
}
