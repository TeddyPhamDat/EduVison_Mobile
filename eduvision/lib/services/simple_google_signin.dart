import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;
import '../config/api_config.dart';

/// A simplified Google Sign In service that just focuses on getting ID tokens
class SimpleGoogleSignIn {
  static final SimpleGoogleSignIn _instance = SimpleGoogleSignIn._internal();
  factory SimpleGoogleSignIn() => _instance;
  SimpleGoogleSignIn._internal();

  GoogleSignIn? _googleSignIn;

  /// Initialize the Google Sign-In with required scopes
  void initialize() {
    developer.log('Initializing Simple Google Sign In', name: 'SimpleGoogleSignIn');
    
    // Use the web client ID for server auth
    String serverClientId = ApiConfig.googleClientId;
    
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: serverClientId,
    );
  }

  /// Sign in with Google and get the ID token
  /// Returns a Map with token, email, displayName, and photoUrl if successful
  /// Returns null if user cancels
  /// Throws exceptions for errors
  Future<Map<String, dynamic>?> signIn() async {
    try {
      // Make sure we're initialized
      if (_googleSignIn == null) {
        initialize();
      }
      
      developer.log('Starting Google Sign In flow', name: 'SimpleGoogleSignIn');
      
      // Sign in and get account info
      final GoogleSignInAccount? account = await _googleSignIn!.signIn();
      
      // User canceled sign in
      if (account == null) {
        developer.log('User cancelled Google Sign In', name: 'SimpleGoogleSignIn');
        return null;
      }
      
      developer.log('Google account selected: ${account.email}', name: 'SimpleGoogleSignIn');
      
      // Get authentication details with ID token
      final GoogleSignInAuthentication auth = await account.authentication;
      
      if (auth.idToken == null) {
        throw Exception('No ID token received from Google');
      }
      
      developer.log('Successfully received ID token', name: 'SimpleGoogleSignIn');
      
      // Return all data needed for backend authentication
      return {
        'idToken': auth.idToken!,
        'email': account.email,
        'displayName': account.displayName ?? '',
        'photoUrl': account.photoUrl,
      };
    } catch (e) {
      developer.log('Google Sign In Error: $e', name: 'SimpleGoogleSignIn');
      
      // Provide more specific error messages
      if (e.toString().contains('ApiException: 10')) {
        throw Exception('Google Play Services không đúng cấu hình. Kiểm tra SHA-1 và Google Play Services.');
      }
      
      rethrow;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();
    } catch (e) {
      developer.log('Google Sign Out error: $e', name: 'SimpleGoogleSignIn');
    }
  }

  /// Check if user is signed in with Google
  Future<bool> isSignedIn() async {
    return await _googleSignIn?.isSignedIn() ?? false;
  }
}
