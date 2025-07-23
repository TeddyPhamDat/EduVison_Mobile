import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

class PlayServicesChecker {
  static const MethodChannel _channel = MethodChannel('com.example.eduvision/debug');

  // Check if Google Play Services is available
  static Future<bool> checkPlayServices() async {
    try {
      final Map<String, dynamic>? result = await _channel.invokeMapMethod<String, dynamic>('checkPlayServices');
      bool isAvailable = result?['isAvailable'] ?? false;
      return isAvailable;
    } catch (e) {
      developer.log('Error checking Play Services: $e', name: 'PlayServicesChecker');
      return false;
    }
  }

  // Open Google Play Services in Play Store
  static Future<void> openPlayServicesInStore() async {
    const String playServicesUrl = 'https://play.google.com/store/apps/details?id=com.google.android.gms';
    
    try {
      if (await canLaunch(playServicesUrl)) {
        await launch(playServicesUrl);
      } else {
        developer.log('Could not launch Google Play Services URL', name: 'PlayServicesChecker');
      }
    } catch (e) {
      developer.log('Error launching Play Services URL: $e', name: 'PlayServicesChecker');
    }
  }
  
  // Show dialog to update Google Play Services
  static Future<void> showPlayServicesDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cập nhật Google Play Services'),
          content: const Text(
              'Ứng dụng cần Google Play Services phiên bản mới nhất để đăng nhập với Google. '
              'Vui lòng cập nhật Google Play Services và thử lại.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cập nhật ngay'),
              onPressed: () {
                Navigator.of(context).pop();
                openPlayServicesInStore();
              },
            ),
            TextButton(
              child: const Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
