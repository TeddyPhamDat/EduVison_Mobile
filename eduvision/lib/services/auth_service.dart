import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

import '../models/user.dart';
import '../models/api_models.dart';
import '../config/api_config.dart';
import 'google_signin_service.dart';
import 'fcm_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _baseUrl = ApiConfig.authBaseUrl;
  final GoogleSignInService _googleSignInService = GoogleSignInService();
  final FCMService _fcmService = FCMService();

  User? _currentUser;
  String? _token;
  String? _refreshToken;
  DateTime? _tokenExpiresAt;
  DateTime? _refreshTokenExpiresAt;

  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();
  Stream<User?> get authStateChanges => _authStateController.stream;

  User? get currentUser => _currentUser;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  bool get isSignedIn =>
      _currentUser != null && _token != null && _token!.isNotEmpty;

  Future<void> initialize() async {
    developer.log('Initializing AuthService...', name: 'AuthService');

    _googleSignInService.initialize();
    await _loadTokenFromStorage();

    // Initialize FCM
    await _initializeFCM();

    // Setup FCM token refresh callback
    _setupFCMCallbacks();

    developer.log('AuthService initialized successfully', name: 'AuthService');
  }

  /// Initialize FCM Service
  Future<void> _initializeFCM() async {
    try {
      await _fcmService.initialize();

      // If user is logged in, update FCM token on backend
      if (_currentUser != null && _fcmService.fcmToken != null) {
        await _updateFCMTokenOnBackend(_fcmService.fcmToken!);
      }
    } catch (e) {
      developer.log('FCM initialization failed: $e', name: 'AuthService');
      // Don't throw error - FCM is optional
    }
  }

  /// Setup FCM callbacks
  void _setupFCMCallbacks() {
    // Handle token refresh
    _fcmService.onTokenRefresh = (String? newToken) async {
      if (newToken != null && _currentUser != null) {
        await _updateFCMTokenOnBackend(newToken);
      }
    };

    // Handle foreground messages
    _fcmService.onMessageReceived = (message) {
      developer.log(
        'Foreground message: ${message.notification?.title}',
        name: 'AuthService',
      );
    };

    // Handle background message taps
    _fcmService.onMessageOpenedApp = (message) {
      developer.log(
        'App opened from notification: ${message.data}',
        name: 'AuthService',
      );
      // Handle navigation based on message data
    };
  }

  /// Update FCM token on backend using FCMService
  Future<void> _updateFCMTokenOnBackend(String fcmToken) async {
    if (_token == null) return;

    try {
      developer.log(
        'Updating FCM token on backend via FCMService...',
        name: 'AuthService',
      );

      final success = await _fcmService.updateTokenToBackendWithAuth(_token!);

      if (success) {
        developer.log(
          'FCM token updated successfully on backend',
          name: 'AuthService',
        );
      } else {
        developer.log(
          'Failed to update FCM token via FCMService',
          name: 'AuthService',
        );
      }
    } catch (e) {
      developer.log(
        'Failed to update FCM token on backend: $e',
        name: 'AuthService',
      );
      // Don't throw - this is not critical
    }
  }

  /// Public method to update FCM token
  Future<void> updateFcmToken(String fcmToken) async {
    await _updateFCMTokenOnBackend(fcmToken);
  }

  Future<void> _loadTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      _refreshToken = prefs.getString('refresh_token');

      if (_token != null) {
        final userData = prefs.getString('user_data');
        if (userData != null) {
          final userMap = jsonDecode(userData);
          _currentUser = User.fromJson(userMap);
          _authStateController.add(_currentUser);
        }
      }
    } catch (e) {
      print('Error loading token: $e');
    }
  }

  Future<void> _saveTokenAndUser(
    String token,
    String refreshToken,
    LoginResult result,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('refresh_token', refreshToken);

      final user = User(
        id: result.userId?.toString() ?? result.email,
        name: result.fullName,
        email: result.email,
        photoUrl: null,
      );

      await prefs.setString('user_data', jsonEncode(user.toJson()));

      _token = token;
      _refreshToken = refreshToken;
      _currentUser = user;

      // Auto-update FCM token to backend after successful login
      _updateFCMTokenAfterLogin();
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  /// Update FCM token to backend after successful login
  void _updateFCMTokenAfterLogin() async {
    try {
      if (_token != null) {
        developer.log(
          'Auto-updating FCM token after login...',
          name: 'AuthService',
        );

        // Get FCM token and update to backend
        final fcmToken = _fcmService.fcmToken;
        if (fcmToken != null) {
          await _updateFCMTokenOnBackend(fcmToken);
        } else {
          // If no token yet, wait for FCM to initialize then update
          developer.log(
            'FCM token not ready, will update when available',
            name: 'AuthService',
          );
        }
      }
    } catch (e) {
      developer.log('Error in auto FCM token update: $e', name: 'AuthService');
    }
  }

  Future<void> _clearTokenAndUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_data');

      _token = null;
      _refreshToken = null;
      _currentUser = null;

      // Clear education cache when user signs out
      await _clearEducationCache();
    } catch (e) {
      print('Error clearing token: $e');
    }
  }

  /// Clear education cache when user signs out
  Future<void> _clearEducationCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove education cache keys
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('education_')) {
          await prefs.remove(key);
        }
      }

      developer.log(
        '✅ Education cache cleared on sign out',
        name: 'AuthService',
      );
    } catch (e) {
      developer.log('Error clearing education cache: $e', name: 'AuthService');
    }
  }

  Future<User> signIn({required String email, required String password}) async {
    try {
      final request = LoginRequest(username: email, password: password);

      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json', 'accept': '*/*'},
        body: jsonEncode(request.toJson()),
      );

      final responseData = jsonDecode(response.body);
      final apiResponse = ApiResponse<LoginResult>.fromJson(
        responseData,
        (json) => LoginResult.fromJson(json),
      );

      if (!apiResponse.isSuccess) {
        throw Exception(apiResponse.message);
      }

      if (apiResponse.result == null) {
        throw Exception('Invalid response from server');
      }

      await _saveTokenAndUser(
        apiResponse.result!.token,
        apiResponse.result!.refreshToken ?? '',
        apiResponse.result!,
      );
      _authStateController.add(_currentUser);

      return _currentUser!;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<User> signInWithGoogle() async {
    try {
      final authResult = await _googleSignInService.signIn();

      if (authResult == null) {
        throw Exception('Failed to get authentication data from Google');
      }

      // Try to authenticate with backend first
      try {
        return await _authenticateWithBackend(authResult.idToken);
      } catch (e) {
        // If backend fails, use mock authentication
        return await _mockSuccessfulAuth(
          authResult.user.email,
          authResult.user.displayName,
        );
      }
    } catch (e) {
      throw Exception('Failed to authenticate with Google: $e');
    }
  }

  Future<User> _authenticateWithBackend(String token) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/google-sessions'),
          headers: {'Content-Type': 'application/json', 'accept': '*/*'},
          body: jsonEncode({'idToken': token}),
        )
        .timeout(Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Backend authentication failed');
    }

    final responseData = jsonDecode(response.body);
    final apiResponse = ApiResponse<LoginResult>.fromJson(
      responseData,
      (json) => LoginResult.fromJson(json),
    );

    if (!apiResponse.isSuccess || apiResponse.result == null) {
      throw Exception('Backend error: ${apiResponse.message}');
    }

    await _saveTokenAndUser(
      apiResponse.result!.token,
      apiResponse.result!.refreshToken ?? '',
      apiResponse.result!,
    );
    _authStateController.add(_currentUser);

    return _currentUser!;
  }

  Future<User> _mockSuccessfulAuth(String email, String? name) async {
    final mockResult = LoginResult(
      token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock_refresh_token',
      userId: 0,
      username: email,
      email: email,
      fullName: name ?? 'Mock User',
      role: 'User',
    );

    await _saveTokenAndUser(
      mockResult.token,
      mockResult.refreshToken ?? '',
      mockResult,
    );
    _authStateController.add(_currentUser);

    return _currentUser!;
  }

  Future<void> signOut() async {
    try {
      await _googleSignInService.signOut();
    } catch (e) {
      print('Error signing out from Google: $e');
    }

    await _clearTokenAndUser();
    _authStateController.add(null);
  }

  Future<void> refreshAuthToken() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/refresh-token'),
        headers: {'Content-Type': 'application/json', 'accept': '*/*'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      final responseData = jsonDecode(response.body);
      final apiResponse = ApiResponse<LoginResult>.fromJson(
        responseData,
        (json) => LoginResult.fromJson(json),
      );

      if (!apiResponse.isSuccess) {
        await signOut();
        throw Exception('Session expired. Please login again.');
      }

      if (apiResponse.result != null) {
        await _saveTokenAndUser(
          apiResponse.result!.token,
          apiResponse.result!.refreshToken ?? _refreshToken!,
          apiResponse.result!,
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<void> signOutFromAllDevices() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/logout-all'),
        headers: {
          'Content-Type': 'application/json',
          'accept': '*/*',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        await _clearTokenAndUser();
        _authStateController.add(null);
      } else {
        throw Exception('Failed to logout from all devices');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<String> startRegistration({required String email}) async {
    try {
      final request = RegisterRequest(email: email);

      final response = await http.post(
        Uri.parse('$_baseUrl/registrations'),
        headers: {'Content-Type': 'application/json', 'accept': '*/*'},
        body: jsonEncode(request.toJson()),
      );
      final responseData = jsonDecode(response.body);

      // Xử lý response từ backend
      String message = '';
      bool isSuccess = false;

      if (responseData is Map<String, dynamic>) {
        final code = responseData['code'] as int? ?? 0;
        message = responseData['message'] as String? ?? 'Unknown error';
        isSuccess = code == 200;
      } else {
        message = 'Invalid response format';
      }

      if (!isSuccess) {
        throw Exception(message);
      }

      return message;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<String> completeRegistration({
    required String email,
    required String otpToken,
    required String password,
    required String fullName,
  }) async {
    try {
      final request = CompleteRegistrationRequest(
        email: email,
        otpToken: otpToken,
        password: password,
        fullName: fullName,
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/registrations/complete'),
        headers: {'Content-Type': 'application/json', 'accept': '*/*'},
        body: jsonEncode(request.toJson()),
      );
      final responseData = jsonDecode(response.body);

      // Xử lý response từ backend
      String message = '';
      bool isSuccess = false;

      if (responseData is Map<String, dynamic>) {
        final code = responseData['code'] as int? ?? 0;
        message = responseData['message'] as String? ?? 'Unknown error';
        isSuccess = code == 200;
      } else {
        message = 'Invalid response format';
      }

      if (!isSuccess) {
        throw Exception(message);
      }

      // Đăng ký thành công, trả về message thay vì tự động đăng nhập
      // UI sẽ chuyển về trang login
      return message;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<String> forgotPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json', 'accept': '*/*'},
        body: jsonEncode({'email': email}),
      );
      final responseData = jsonDecode(response.body);

      // Xử lý response từ backend
      String message = '';
      bool isSuccess = false;

      if (responseData is Map<String, dynamic>) {
        final code = responseData['code'] as int? ?? 0;
        message = responseData['message'] as String? ?? 'Unknown error';
        isSuccess = code == 200;
      } else {
        message = 'Invalid response format';
      }

      if (!isSuccess) {
        throw Exception(message);
      }

      return message;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<String> resetPassword({
    required String email,
    required String otpToken,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json', 'accept': '*/*'},
        body: jsonEncode({
          'email': email,
          'otpToken': otpToken,
          'newPassword': newPassword,
        }),
      );
      final responseData = jsonDecode(response.body);

      // Xử lý response từ backend
      String message = '';
      bool isSuccess = false;

      if (responseData is Map<String, dynamic>) {
        final code = responseData['code'] as int? ?? 0;
        message = responseData['message'] as String? ?? 'Unknown error';
        isSuccess = code == 200;
      } else {
        message = 'Invalid response format';
      }

      if (!isSuccess) {
        throw Exception(message);
      }

      return message;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, String>> getAuthHeaders() async {
    if (_token == null) {
      throw Exception('User not authenticated');
    }

    return {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
      'accept': '*/*',
    };
  }

  void dispose() {
    _authStateController.close();
  }

  Future<String> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return await startRegistration(email: email);
  }

  /// Check if the current token is expired
  bool _isTokenExpired() {
    if (_tokenExpiresAt == null)
      return false; // If no expiry time, assume not expired
    return DateTime.now().isAfter(_tokenExpiresAt!);
  }

  /// Get a valid token, refreshing if necessary
  Future<String?> getValidToken() async {
    if (_token == null || _token!.isEmpty) return null;

    if (_isTokenExpired()) {
      try {
        await refreshAuthToken();
      } catch (e) {
        developer.log('Failed to refresh token: $e', name: 'AuthService');
        return null;
      }
    }

    return _token;
  }
}
