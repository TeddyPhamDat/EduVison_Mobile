import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:url_launcher/url_launcher.dart';

/// Helper class để xử lý các lỗi phổ biến với Google Services
class GoogleServicesErrorHandler {
  /// Kiểm tra và xử lý lỗi liên quan đến Google Play Services
  static Future<void> handlePossiblePlayServicesIssue(
    BuildContext context,
    Exception error,
  ) async {
    final String errorMsg = error.toString().toLowerCase();

    // Kiểm tra lỗi phổ biến liên quan đến Google Play Services
    if (errorMsg.contains('platformexception(sign_in_failed') ||
        errorMsg.contains('gms.common.api') ||
        errorMsg.contains('com.google.android.gms') ||
        errorMsg.contains('10:') ||
        errorMsg.contains('google play services')) {
      developer.log(
        'Possible Google Play Services issue detected: $error',
        name: 'GoogleServicesErrorHandler',
      );

      // Hiển thị dialog cho người dùng
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Lỗi Dịch vụ Google'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Không thể kết nối với Google. Điều này thường do một trong các nguyên nhân sau:',
                ),
                SizedBox(height: 16),
                Text('• Dịch vụ Google Play không được cập nhật'),
                Text('• Thiết bị không có Google Play Services'),
                Text('• Tài khoản Google đã bị đăng xuất'),
                SizedBox(height: 16),
                Text(
                  'Bạn có muốn kiểm tra và cập nhật Google Play Services không?',
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Bỏ qua'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Kiểm tra Google Play'),
                onPressed: () async {
                  Navigator.of(context).pop();

                  // Mở Google Play để cập nhật Google Play Services
                  try {
                    final Uri url = Uri.parse(
                      'market://details?id=com.google.android.gms',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      // Fallback
                      launchUrl(
                        Uri.parse(
                          'https://play.google.com/store/apps/details?id=com.google.android.gms',
                        ),
                      );
                    }
                  } catch (e) {
                    developer.log(
                      'Failed to open Play Store: $e',
                      name: 'GoogleServicesErrorHandler',
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    }
  }

  /// Kiểm tra và hiển thị các hướng dẫn cài đặt cho nhà phát triển
  static void logDeveloperSetupInstructions() {
    if (!Platform.isAndroid) return;

    developer.log(
      'Android Google Sign-In Developer Setup:\n' +
          '-----------------------------------\n' +
          '1. Ensure google-services.json is up-to-date\n' +
          '2. Check that SHA-1 and SHA-256 fingerprints are added in Firebase console\n' +
          '3. Command to get debug keys: keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android\n' +
          '4. For signed APKs, get key from your keystore\n' +
          '5. Make sure Google Sign-In API is enabled in Google Cloud Console\n',
      name: 'GoogleServicesErrorHandler',
    );
  }
}
