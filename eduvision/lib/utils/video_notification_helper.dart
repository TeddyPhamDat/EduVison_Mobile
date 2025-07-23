import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/fcm_service.dart';
import '../models/lecture_video.dart';

class VideoNotificationHelper {
  final FCMService _fcmService = FCMService();
  final Function(String) onVideoUrlReceived;
  final Function(String) onErrorReceived;

  VideoNotificationHelper({
    required this.onVideoUrlReceived,
    required this.onErrorReceived,
  }) {
    _setupFCMCallbacks();
  }

  void _setupFCMCallbacks() {
    // Setup FCM callback for video generation completion
    _fcmService.onVideoGenerated = (data) {
      final String? videoUrl = data['videoUrl'] as String?;
      if (videoUrl != null) {
        onVideoUrlReceived(videoUrl);
      }
    };

    // Setup FCM callback for generation failure
    _fcmService.onGenerationFailed = (error, details) {
      onErrorReceived(error ?? 'Không thể tạo video');
    };
  }

  void dispose() {
    // Clear FCM callbacks to avoid memory leaks
    _fcmService.onVideoGenerated = null;
    _fcmService.onGenerationFailed = null;
  }
  
  // Helper to display a notification in the UI
  static void showNotification(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  // Helper to integrate FCM with CreateVideoScreen
  static void setupCreateVideoScreen({
    required BuildContext context,
    required FCMService fcmService,
    required Function() onSuccess,
    required Function(String) onError,
  }) {
    fcmService.onVideoGenerated = (data) {
      showNotification(context, 'Video đã được tạo thành công!');
      onSuccess();
    };
    
    fcmService.onGenerationFailed = (error, details) {
      showNotification(context, error ?? 'Không thể tạo video', isError: true);
      onError(error ?? 'Không thể tạo video');
    };
  }

  // Helper to integrate FCM with VideoResultScreen
  static void setupVideoResultScreen({
    required BuildContext context,
    required FCMService fcmService,
    required Function(String) onVideoReady,
  }) {
    fcmService.onVideoGenerated = (data) {
      final String? videoUrl = data['videoUrl'] as String?;
      if (videoUrl != null) {
        showNotification(context, 'Video đã sẵn sàng để xem!');
        onVideoReady(videoUrl);
      }
    };
  }
}
