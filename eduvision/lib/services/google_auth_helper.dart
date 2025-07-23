import '../services/simple_google_signin.dart';
import '../models/user.dart';
import '../config/api_config.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

/// A simplified version of the Google sign-in part of your auth service
class GoogleAuthHelper {
  final SimpleGoogleSignIn _googleSignIn = SimpleGoogleSignIn();
  
  /// Sign in with Google and authenticate with your backend
  /// Returns the user from your backend if successful
  Future<User?> signInWithGoogle() async {
    try {
      developer.log('Starting Google Sign In process', name: 'GoogleAuthHelper');
      
      // Make sure Google Sign-In is initialized
      _googleSignIn.initialize();
      
      // Get Google authentication data
      final googleAuthData = await _googleSignIn.signIn();
      
      // User cancelled the sign-in
      if (googleAuthData == null) {
        developer.log('Google Sign In was cancelled by the user', name: 'GoogleAuthHelper');
        return null;
      }
      
      // Successfully got Google ID token
      final idToken = googleAuthData['idToken'];
      final email = googleAuthData['email'];
      
      developer.log('Got ID token for $email, sending to backend...', name: 'GoogleAuthHelper');
      
      // Send ID token to your backend for verification and authentication
      return await _authenticateWithBackend(idToken, email);
      
    } catch (e) {
      developer.log('Google Sign In error: $e', name: 'GoogleAuthHelper');
      rethrow;
    }
  }
  
  /// Send the Google ID token to your backend for verification
  Future<User> _authenticateWithBackend(String idToken, String email) async {
    try {
      // Create the request body
      final body = {
        'token': idToken,
        'email': email,
        'provider': 'google'
      };
      
      // Send the request to your backend
      final response = await http.post(
        Uri.parse('${ApiConfig.authBaseUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      // Parse the response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Create a User object from the response data
        // Adjust this to match your User class structure
        return User.fromJson(data['user']);
      } else {
        // Handle server-side errors
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        throw Exception('Authentication failed: $error');
      }
    } catch (e) {
      developer.log('Backend authentication error: $e', name: 'GoogleAuthHelper');
      throw Exception('Failed to authenticate with backend: $e');
    }
  }
  
  /// Sign out from Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
