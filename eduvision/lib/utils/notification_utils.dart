import 'package:flutter/material.dart';

class NotificationUtils {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Show success notification (like notify.success in JavaScript)
  static void showSuccess(String title, String message) {
    _showSnackBar(
      title: title,
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  /// Show info notification (like notify.info in JavaScript)
  static void showInfo(String title, String message) {
    _showSnackBar(
      title: title,
      message: message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
    );
  }

  /// Show error notification (like notify.error in JavaScript)
  static void showError(String title, String message) {
    _showSnackBar(
      title: title,
      message: message,
      backgroundColor: Colors.red,
      icon: Icons.error,
    );
  }

  /// Show warning notification (like notify.warning in JavaScript)
  static void showWarning(String title, String message) {
    _showSnackBar(
      title: title,
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
    );
  }

  /// Internal method to show snackbar
  static void _showSnackBar({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    final scaffoldMessenger = scaffoldMessengerKey.currentState;
    if (scaffoldMessenger == null) return;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Close',
          textColor: Colors.white,
          onPressed: () {
            scaffoldMessenger.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show notification with custom UI feedback (called from FCMService)
  static void showNotification(
    String title,
    String message, {
    bool isSuccess = true,
  }) {
    if (isSuccess) {
      showSuccess(title, message);
    } else {
      showError(title, message);
    }
  }
}
