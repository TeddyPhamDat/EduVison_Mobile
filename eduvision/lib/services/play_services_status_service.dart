import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'dart:io';

class PlayServicesStatusService {
  // Private constructor for singleton
  PlayServicesStatusService._();
  
  // Singleton instance
  static final PlayServicesStatusService _instance = PlayServicesStatusService._();
  
  // Factory method to return instance
  factory PlayServicesStatusService() => _instance;
  
  // Method channel for native communication
  static const MethodChannel _channel = MethodChannel('com.example.eduvision/debug');
  
  // Check if Google Play Services is available and up to date
  Future<bool> isPlayServicesAvailable() async {
    if (!Platform.isAndroid) {
      // Not relevant for iOS and other platforms
      return true;
    }
    
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('checkPlayServices');
      final bool isAvailable = result?['isAvailable'] == true;
      
      developer.log(
        'Play Services availability check result: $isAvailable',
        name: 'PlayServicesStatusService',
      );
      
      return isAvailable;
    } catch (e) {
      developer.log(
        'Error checking Play Services availability: $e',
        name: 'PlayServicesStatusService',
      );
      // If we can't check, assume it's not available to be safe
      return false;
    }
  }
  
  // Check if the error is related to Google Play Services
  bool isPlayServicesError(Exception error) {
    if (!Platform.isAndroid) {
      return false;
    }
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('platformexception(sign_in_failed') ||
           errorString.contains('apiexception: 10') ||
           errorString.contains('com.google.android.gms') ||
           errorString.contains('gms.common.api') ||
           errorString.contains('play services');
  }
  
  // Get detailed diagnostic info about Play Services
  Future<Map<String, dynamic>> getPlayServicesDiagnostics() async {
    if (!Platform.isAndroid) {
      return {'platform': 'not_android'};
    }
    
    try {
      final Map<String, dynamic> result = {};
      
      try {
        final packageInfo = await _channel.invokeMapMethod<String, dynamic>('getPlayServicesVersion');
        result['version'] = packageInfo?['version'];
        result['versionCode'] = packageInfo?['versionCode'];
        result['isUpdated'] = packageInfo?['isUpdated'];
      } catch (e) {
        result['versionError'] = e.toString();
      }
      
      try {
        final status = await _channel.invokeMapMethod<String, dynamic>('getPlayServicesStatus');
        result['isAvailable'] = status?['isAvailable'];
        result['statusCode'] = status?['statusCode'];
        result['statusMessage'] = status?['statusMessage'];
      } catch (e) {
        result['statusError'] = e.toString();
      }
      
      return result;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
