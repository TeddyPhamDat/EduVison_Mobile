import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'dart:async';
import '../config/api_config.dart';

/// Class that holds Google Sign In result information
class GoogleSignInResult {
  final String idToken;
  final String? accessToken;
  final GoogleUser user;
  final Map<String, dynamic> rawPayload;

  GoogleSignInResult({
    required this.idToken,
    this.accessToken,
    required this.user,
    required this.rawPayload,
  });
}

/// Class that holds Google user information
class GoogleUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  
  GoogleUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });
}

/// Service to handle Google Sign In process
class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();
  
  GoogleSignIn? _googleSignIn;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    
    // Use appropriate configuration for each platform
    String serverClientId = ApiConfig.googleClientId;
    
    _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'profile',
      ],
      serverClientId: serverClientId,
    );
    
    _isInitialized = true;
  }

  /// Check if Google Play Services are available
  Future<bool> checkPlayServices() async {
    try {
      bool? isSignedIn = await _googleSignIn?.isSignedIn();
      return isSignedIn != null;
    } catch (e) {
      return false;
    }
  }

  /// Sign in with Google and return user info and tokens
  Future<GoogleSignInResult> signIn() async {
    if (!_isInitialized) {
      initialize();
    }
    
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn?.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign In cancelled by user');
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        throw Exception('Failed to get ID token from Google');
      }
      
      // Extract payload from JWT
      final String idToken = googleAuth.idToken!;
      final payload = _decodeToken(idToken);
      
      final GoogleUser user = GoogleUser(
        id: googleUser.id,
        email: googleUser.email,
        displayName: googleUser.displayName ?? 'User',
        photoUrl: googleUser.photoUrl,
      );
      
      return GoogleSignInResult(
        idToken: idToken,
        accessToken: googleAuth.accessToken,
        user: user,
        rawPayload: payload,
      );
    } catch (e) {
      throw Exception('Google Sign In error: $e');
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();
    } catch (e) {
      // Handle error silently
    }
  }
  
  /// Disconnect Google account (revokes access)
  Future<void> disconnect() async {
    try {
      await _googleSignIn?.disconnect();
    } catch (e) {
      // Handle error silently
    }
  }
  
  /// Decode JWT token and return payload
  Map<String, dynamic> _decodeToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return {};
    }
    
    final payload = parts[1];
    var normalized = base64Url.normalize(payload);
    var resp = utf8.decode(base64Url.decode(normalized));
    final payloadMap = json.decode(resp);
    if (payloadMap is Map<String, dynamic>) {
      return payloadMap;
    } else {
      return {};
    }
  }
}
