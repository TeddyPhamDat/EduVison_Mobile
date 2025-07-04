import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  GoogleSignIn? _googleSignIn;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;

    _googleSignIn = GoogleSignIn(
      clientId:
          '413334004170-dk2csovpjrnmsthqqtb2ad6iseh0n4bt.apps.googleusercontent.com',
      scopes: ['email', 'profile', 'openid'],
      // Force server auth code to ensure we get ID token like ReactJS
      signInOption: SignInOption.standard,
      // This helps force ID token generation
      hostedDomain: '', // Empty string to allow all domains but force ID token
    );
    _isInitialized = true;
  }

  Future<GoogleSignInResult?> signIn() async {
    try {
      if (!_isInitialized || _googleSignIn == null) {
        initialize();
      }

      developer.log(
        '🚀 Starting Google Sign In (Flutter equivalent of ReactJS GIS)...',
        name: 'GoogleSignInService',
      );

      // Clear any existing sessions to force fresh token (like ReactJS popup)
      await _googleSignIn!.signOut();

      // Force interactive sign in to get fresh ID token
      final GoogleSignInAccount? account = await _googleSignIn!.signIn();

      if (account == null) {
        developer.log(
          '❌ User cancelled Google Sign In',
          name: 'GoogleSignInService',
        );
        return null;
      }

      developer.log(
        '✅ Google account selected: ${account.email}',
        name: 'GoogleSignInService',
      );

      // Get authentication details - this should include ID token
      final GoogleSignInAuthentication auth = await account.authentication;

      // Log what we received (like ReactJS response.credential)
      developer.log('📝 Auth tokens received:', name: 'GoogleSignInService');
      developer.log(
        '   - Access Token: ${auth.accessToken?.substring(0, 20)}...',
        name: 'GoogleSignInService',
      );
      developer.log(
        '   - ID Token: ${auth.idToken?.substring(0, 20)}...',
        name: 'GoogleSignInService',
      );
      developer.log(
        '   - ID Token available: ${auth.idToken != null}',
        name: 'GoogleSignInService',
      );

      // Check if we got real ID token (JWT starting with eyJ)
      if (auth.idToken != null && auth.idToken!.startsWith('eyJ')) {
        developer.log(
          '🎉 SUCCESS! Got real ID Token (JWT) like ReactJS frontend!',
          name: 'GoogleSignInService',
        );
        developer.log(
          '   - Token type: JWT ID Token',
          name: 'GoogleSignInService',
        );
        developer.log(
          '   - Token length: ${auth.idToken!.length}',
          name: 'GoogleSignInService',
        );

        // Parse JWT payload like ReactJS does
        Map<String, dynamic> payload = {};
        try {
          payload = _parseJwtPayload(auth.idToken!);
          developer.log(
            '✅ JWT payload parsed successfully',
            name: 'GoogleSignInService',
          );
          developer.log(
            '   - Email: ${payload['email']}',
            name: 'GoogleSignInService',
          );
          developer.log(
            '   - Name: ${payload['name']}',
            name: 'GoogleSignInService',
          );
        } catch (e) {
          developer.log(
            '⚠️ Failed to parse JWT: $e',
            name: 'GoogleSignInService',
          );
        }

        return GoogleSignInResult(
          idToken: auth.idToken!,
          accessToken: auth.accessToken,
          user: GoogleUser(
            id: account.id,
            email: account.email,
            displayName: account.displayName ?? '',
            photoUrl: account.photoUrl,
          ),
          rawPayload: payload,
        );
      }

      // If we only got access token (not ideal)
      if (auth.accessToken != null) {
        developer.log(
          '⚠️  Only got access token (ya29...), not ID token',
          name: 'GoogleSignInService',
        );
        developer.log(
          '   - Token preview: ${auth.accessToken!.substring(0, 30)}...',
          name: 'GoogleSignInService',
        );
        developer.log(
          '   - We need ID token like ReactJS gets from response.credential',
          name: 'GoogleSignInService',
        );

        // Return access token as fallback but mark it clearly
        return GoogleSignInResult(
          idToken: auth.accessToken!, // Using access token as fallback
          accessToken: auth.accessToken,
          user: GoogleUser(
            id: account.id,
            email: account.email,
            displayName: account.displayName ?? '',
            photoUrl: account.photoUrl,
          ),
          rawPayload: {
            'tokenType': 'access_token',
            'note': 'This is NOT an ID token',
          },
        );
      }

      throw Exception('No tokens received from Google authentication');
    } catch (e) {
      developer.log('❌ Google Sign In Error: $e', name: 'GoogleSignInService');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
    } catch (e) {
      developer.log('Google Sign Out Error: $e', name: 'GoogleSignInService');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      if (_googleSignIn != null) {
        await _googleSignIn!.disconnect();
      }
    } catch (e) {
      developer.log('Google Disconnect Error: $e', name: 'GoogleSignInService');
      rethrow;
    }
  }

  bool get isSignedIn => _googleSignIn?.currentUser != null;

  GoogleSignInAccount? get currentUser => _googleSignIn?.currentUser;

  // Parse JWT payload without verification (for client-side use only)
  Map<String, dynamic> _parseJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid JWT token');
    }

    final payload = parts[1];
    final normalizedPayload = base64Url.normalize(payload);
    final decodedPayload = utf8.decode(base64Url.decode(normalizedPayload));

    return jsonDecode(decodedPayload);
  }
}

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }
}
