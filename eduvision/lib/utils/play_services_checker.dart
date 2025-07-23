import 'package:flutter/material.dart';
import '../widgets/play_services_updater.dart';
import '../services/play_services_status_service.dart';
import 'dart:developer' as developer;

// PlayServicesChecker is a utility class to check Google Play Services status
class PlayServicesChecker {
  // The service that handles Play Services status checks
  static final PlayServicesStatusService _service = PlayServicesStatusService();
  
  // Shows the play services updater UI if needed, returns whether Google Sign-In should proceed
  static Future<bool> checkAndShowResolver(BuildContext context) async {
    developer.log('Checking Play Services status before sign-in', name: 'PlayServicesChecker');
    
    if (await _hasPlayServicesIssue()) {
      developer.log('Play Services issue detected, showing resolver UI', name: 'PlayServicesChecker');
      
      if (context.mounted) {
        // Show the updater widget in a full-screen dialog for better user experience
        bool shouldRetry = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Cập nhật dịch vụ Google'),
            content: SizedBox(
              width: double.maxFinite,
              child: PlayServicesUpdater(
                onRetry: () {
                  Navigator.of(context).pop(true); // true means retry sign-in
                },
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // false means cancel sign-in
                child: const Text('Hủy đăng nhập'),
              ),
            ],
          ),
        ) ?? false;
        
        if (shouldRetry) {
          // If retry requested, check Play Services again before proceeding
          developer.log('Retry requested, checking Play Services again', name: 'PlayServicesChecker');
          return !(await _hasPlayServicesIssue());
        }
        return false;
      }
      return false;
    }
    
    // No issue detected, proceed with sign-in
    developer.log('No Play Services issues detected, proceeding with sign-in', name: 'PlayServicesChecker');
    return true;
  }
  
  // Direct method to handle a Google Sign-In error
  static Future<bool> handleSignInError(BuildContext context, Exception error) async {
    if (_service.isPlayServicesError(error)) {
      developer.log('Google Sign-In error related to Play Services detected', name: 'PlayServicesChecker');
      return await checkAndShowResolver(context);
    }
    return false;
  }
  
  // Checks if there's an issue with Google Play Services
  static Future<bool> _hasPlayServicesIssue() async {
    // For demo, always return false (no issue)
    return false;
  }
}
