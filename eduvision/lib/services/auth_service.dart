import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

import '../models/user.dart';
import '../models/api_models.dart';
import '../config/api_config.dart';
import 'google_signin_service_new.dart';
import 'fcm_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static String get _baseUrl => ApiConfig.authBaseUrl;
  final GoogleSignInService _googleSignInService = GoogleSignInService();
  final FCMService _fcmService = FCMService();

  User? _currentUser;
  String? _token;
  String? _refreshToken;
  DateTime? _tokenExpiresAt;

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

    // Thêm kiểm tra để ngăn chặn vòng lặp vô tận
    if (_currentUser != null && _token != null && _token!.isNotEmpty) {
      try {
        // Initialize FCM với timeout để tránh bị treo
        await _initializeFCM().timeout(
          Duration(seconds: 5),
          onTimeout: () {
            developer.log(
              'FCM initialization timed out, continuing without it',
              name: 'AuthService',
            );
            return;
          },
        );

        // Setup FCM token refresh callback
        _setupFCMCallbacks();
      } catch (e) {
        // Bắt lỗi nhưng không dừng ứng dụng
        developer.log('Error in FCM initialization: $e', name: 'AuthService');
      }
    } else {
      developer.log(
        'Skipping FCM initialization - user not logged in',
        name: 'AuthService',
      );
    }

    developer.log('AuthService initialized successfully', name: 'AuthService');
  }

  /// Initialize FCM Service
  Future<void> _initializeFCM() async {
    try {
      // Sử dụng timeout bổ sung để đảm bảo không bị treo
      await _fcmService.initialize().timeout(
        Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException(
            'FCM initialization timed out after 3 seconds',
          );
        },
      );

      // If user is logged in, update FCM token on backend
      if (_currentUser != null && _fcmService.fcmToken != null) {
        // Không chờ cập nhật token FCM để tránh làm chậm quá trình khởi tạo
        _updateFCMTokenOnBackend(_fcmService.fcmToken!).catchError((error) {
          developer.log(
            'Error updating FCM token: $error',
            name: 'AuthService',
          );
        });
      }
    } catch (e) {
      developer.log('FCM initialization failed: $e', name: 'AuthService');
      // Don't throw error - FCM is optional
    }
  }

  /// Setup FCM callbacks
  void _setupFCMCallbacks() {
    // Handle token refresh - không chặn luồng chính
    _fcmService.onTokenRefresh = (String? newToken) {
      if (newToken != null && _currentUser != null) {
        // Sử dụng không đồng bộ để không chặn
        _updateFCMTokenOnBackend(newToken)
            .timeout(
              Duration(seconds: 3),
              onTimeout: () {
                developer.log('Token refresh timed out', name: 'AuthService');
                return;
              },
            )
            .catchError((error) {
              developer.log(
                'Error in token refresh: $error',
                name: 'AuthService',
              );
            });
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

      // Sử dụng timeout để tránh việc gọi API kéo dài
      final success = await _fcmService
          .updateTokenToBackendWithAuth(_token!)
          .timeout(
            Duration(seconds: 5),
            onTimeout: () {
              developer.log('FCM token update timed out', name: 'AuthService');
              return false;
            },
          );

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
      // Error handled gracefully
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
      // Error handled gracefully
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
          // Thực hiện không đồng bộ để không chặn luồng chính
          _updateFCMTokenOnBackend(fcmToken).catchError((error) {
            developer.log(
              'Error updating FCM token after login: $error',
              name: 'AuthService',
            );
          });
        } else {
          // If no token yet, wait for FCM to initialize then update
          developer.log(
            'FCM token not ready, will update when available',
            name: 'AuthService',
          );

          // Không chờ FCM token vô thời hạn
          Future.delayed(Duration(seconds: 2), () {
            final delayedToken = _fcmService.fcmToken;
            if (delayedToken != null) {
              _updateFCMTokenOnBackend(delayedToken).catchError((error) {
                developer.log(
                  'Error in delayed FCM update: $error',
                  name: 'AuthService',
                );
              });
            }
          });
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
      // Error handled gracefully
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

      // Sử dụng HttpHelper để xử lý chứng chỉ không an toàn
      developer.log(
        'Attempting to login with ${request.username}',
        name: 'AuthService',
      );
      developer.log('Auth endpoint: $_baseUrl/login', name: 'AuthService');

      // Sử dụng URL chính xác cho Android emulator (10.0.2.2 trỏ đến localhost của máy host)
      final url = '${ApiConfig.authBaseUrl}/${ApiConfig.loginEndpoint}';
      developer.log('Using emulator-compatible URL: $url', name: 'AuthService');

      final response = await HttpHelper.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': '*/*'},
        body: jsonEncode(request.toJson()),
      );

      developer.log(
        'Response status code: ${response.statusCode}',
        name: 'AuthService',
      );
      developer.log(
        'Response headers: ${response.headers}',
        name: 'AuthService',
      );

      if (response.statusCode >= 400) {
        throw Exception(
          'Login failed with status code: ${response.statusCode}, body: ${response.body}',
        );
      }

      // Phân tích dữ liệu phản hồi
      developer.log('Parsing response JSON', name: 'AuthService');
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
        developer.log('JSON parse successful', name: 'AuthService');
        developer.log(
          'Response structure: ${responseData.keys.join(', ')}',
          name: 'AuthService',
        );

        // Debug deeper into the structure
        if (responseData.containsKey('result')) {
          developer.log(
            'Result structure: ${responseData['result']?.keys?.join(', ') ?? 'null'}',
            name: 'AuthService',
          );
        }
      } catch (e) {
        developer.log('JSON parse error: $e', name: 'AuthService');
        developer.log('Raw response: ${response.body}', name: 'AuthService');
        throw Exception('Invalid JSON response: $e');
      }

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

      // Khởi tạo FCM sau khi đăng nhập nhưng không chờ đợi
      _initFCMAfterLogin();

      return _currentUser!;
    } catch (e) {
      developer.log('Login error: $e', name: 'AuthService');
      developer.log(
        'Error stack trace: ${StackTrace.current}',
        name: 'AuthService',
      );

      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<User> signInWithGoogle() async {
    try {
      developer.log('Starting Google Sign In process', name: 'AuthService');

      // Kiểm tra kết nối backend trước khi bắt đầu
      bool isBackendConnected = await checkBackendConnection();
      if (!isBackendConnected) {
        developer.log('Backend connection check failed', name: 'AuthService');
        developer.log(
          'Continuing with Google Sign-In but backend auth may fail',
          name: 'AuthService',
        );
      } else {
        developer.log(
          'Backend connection check successful',
          name: 'AuthService',
        );
      }

      // Thêm xử lý lỗi chi tiết hơn cho Google Sign-In
      GoogleSignInResult? authResult;
      try {
        authResult = await _googleSignInService.signIn();

        // Google sign-in flow removed

        developer.log(
          'Google Sign In successful, email: ${authResult.user.email}',
          name: 'AuthService',
        );
        developer.log(
          'Token available: ${authResult.idToken.isNotEmpty}',
          name: 'AuthService',
        );
      } catch (signInError) {
        developer.log(
          'Google Sign-In error details: $signInError',
          name: 'AuthService',
        );

        // Xử lý cụ thể cho lỗi PlatformException
        if (signInError.toString().contains(
          'PlatformException(sign_in_failed',
        )) {
          developer.log(
            'Detected Google Sign-In PlatformException',
            name: 'AuthService',
          );
          developer.log(
            'Possible solutions: 1) Check SHA-1 fingerprint in Firebase console, 2) Update google-services.json, 3) Check Play Services',
            name: 'AuthService',
          );
          throw Exception(
            'Không thể kết nối với dịch vụ Google. Vui lòng thử lại sau.',
          );
        }

        // Các lỗi khác, chuyển tiếp
        rethrow;
      }

      // Hiển thị thông báo cho người dùng nếu backend không kết nối được
      if (!isBackendConnected) {
        developer.log(
          'WARNING: Backend appears to be offline or unreachable',
          name: 'AuthService',
        );
        // Mặc dù vẫn tiếp tục nhưng hiển thị cảnh báo để debug
        developer.log(
          'Will try backend auth anyway but may fail with network error',
          name: 'AuthService',
        );
      }

      try {
        // Luôn thử kết nối đến backend trước
        developer.log(
          'Attempting backend authentication with Google token',
          name: 'AuthService',
        );

        // Hiển thị độ dài token để debug
        developer.log(
          'Google token length: ${authResult.idToken.length} characters',
          name: 'AuthService',
        );

        // In vài ký tự đầu và cuối của token để debug (không in toàn bộ vì lý do bảo mật)
        if (authResult.idToken.length > 10) {
          developer.log(
            'Token prefix: ${authResult.idToken.substring(0, 5)}..., suffix: ...${authResult.idToken.substring(authResult.idToken.length - 5)}',
            name: 'AuthService',
          );
        }

        return await _authenticateWithBackend(authResult.idToken);
      } catch (e) {
        // Phân tích chi tiết lỗi để quyết định có nên sử dụng mock auth hay không
        developer.log('Backend authentication failed: $e', name: 'AuthService');

        // Nếu lỗi liên quan đến mạng, hãy sử dụng mock auth
        if (e.toString().contains('SocketException') ||
            e.toString().contains('TimeoutException') ||
            e.toString().contains('HttpException') ||
            e.toString().contains('Lỗi kết nối') ||
            e.toString().contains('Không thể kết nối')) {
          developer.log(
            'Network error detected, using mock auth as fallback',
            name: 'AuthService',
          );

          // Thông báo rõ ràng cho người dùng
          developer.log(
            'App will work in offline mode with limited functionality',
            name: 'AuthService',
          );

          return await _mockSuccessfulAuth(
            authResult.user.email,
            authResult.user.displayName,
          );
        } else {
          // Nếu là lỗi API hoặc xác thực, không sử dụng mock mà chuyển tiếp lỗi
          developer.log(
            'Authentication error (not network related), forwarding error',
            name: 'AuthService',
          );
          rethrow;
        }
      }
    } catch (e) {
      developer.log('Google Sign In process failed: $e', name: 'AuthService');
      developer.log(
        'Error stack trace: ${StackTrace.current}',
        name: 'AuthService',
      );

      // Nếu phát hiện lỗi liên quan đến Google Play Services, thử phương thức đơn giản
      if (e.toString().contains('PlatformException') ||
          e.toString().contains('sign_in_failed') ||
          e.toString().contains('GoogleSignIn') ||
          e.toString().contains('Play Services')) {
        developer.log(
          'Detected Google Play Services issue, trying simplified method...',
          name: 'AuthService',
        );

        // Thử phương thức đơn giản hóa
        try {
          return await signInWithGoogleSimple();
        } catch (simpleError) {
          developer.log(
            'Simplified method also failed: $simpleError',
            name: 'AuthService',
          );
          // Báo lỗi gốc
          throw Exception(
            'Lỗi đăng nhập Google: Vui lòng kiểm tra Google Play Services và kết nối mạng',
          );
        }
      }

      throw Exception('Failed to authenticate with Google: $e');
    }
  }

  Future<User> signInWithGoogleSimple() async {
    try {
      developer.log(
        'Starting simplified Google Sign In process with updated config',
        name: 'AuthService',
      );

      // 1. Lấy Google token
      GoogleSignInResult? authResult;
      try {
        // Đảm bảo khởi tạo lại để áp dụng cấu hình cập nhật
        _googleSignInService.initialize();

        authResult = await _googleSignInService.signIn();

        if (authResult == null) {
          throw Exception('Đăng nhập Google đã bị hủy bởi người dùng');
        }

        developer.log(
          'Google Sign In successful: ${authResult.user.email}',
          name: 'AuthService',
        );
        developer.log(
          'Token received with length: ${authResult.idToken.length}',
          name: 'AuthService',
        );
      } catch (signInError) {
        developer.log(
          'Google Sign In Error: $signInError',
          name: 'AuthService',
        );

        // Xử lý lỗi dịch vụ Google
        if (signInError.toString().contains('PlatformException') ||
            signInError.toString().contains('sign_in_failed') ||
            signInError.toString().contains('SocketException')) {
          throw Exception(
            'Lỗi Dịch vụ Google: Vui lòng kiểm tra Google Play Services',
          );
        }

        rethrow;
      }

      // Đơn giản hóa để demo - sử dụng mock data
      try {
        developer.log('Sử dụng mock auth cho demo', name: 'AuthService');
        
        // Đi thẳng vào mock auth để demo
        return await _mockSuccessfulAuth(
          authResult.user.email,
          authResult.user.displayName,
        );
      } catch (e) {
        developer.log('Error creating mock auth: $e', name: 'AuthService');

        // Fallback to mock auth
        developer.log(
          'Using mock authentication as fallback',
          name: 'AuthService',
        );
        return await _mockSuccessfulAuth(
          authResult.user.email,
          authResult.user.displayName,
        );
      } finally {
        // No client to close
      }
    } catch (e) {
      developer.log(
        'Overall error in simplified Google auth: $e',
        name: 'AuthService',
      );
      throw Exception('Không thể đăng nhập với Google: $e');
    }
  }

  Future<User> _authenticateWithBackend(String token) async {
    try {
      developer.log(
        'Attempting to authenticate with Google token',
        name: 'AuthService',
      );

      // Kiểm tra API trước khi thử xác thực
      bool apiAvailable = await testGoogleSessionsApi();
      developer.log(
        'API Google Sessions sẵn sàng: $apiAvailable',
        name: 'AuthService',
      );

      // Lấy URL dựa trên nền tảng
      final baseUrl = await getCurrentApiBaseUrl();
      final url = '$baseUrl/api/authentication/google-sessions';

      developer.log('Using URL for Google auth: $url', name: 'AuthService');

      // Chuẩn bị request body CHÍNH XÁC như trong curl command
      final Map<String, dynamic> requestBody = {"idToken": token};

      developer.log(
        'Google auth request body: ${jsonEncode(requestBody)}',
        name: 'AuthService',
      );

      // Thêm logic retry và timeout
      http.Response? response;
      Exception? lastError;
      bool success = false;

      // Thử tối đa 2 lần
      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          developer.log(
            'Attempt #$attempt to authenticate with Google token',
            name: 'AuthService',
          );

          response =
              await HttpHelper.post(
                Uri.parse(url),
                headers: {'Content-Type': 'application/json', 'accept': '*/*'},
                body: jsonEncode(requestBody),
              ).timeout(
                Duration(seconds: 10),
                onTimeout: () {
                  developer.log(
                    'Google auth request timed out after 10 seconds',
                    name: 'AuthService',
                  );
                  throw TimeoutException('Request timed out');
                },
              );

          success = true;
          break; // Thành công, thoát khỏi vòng lặp
        } catch (e) {
          lastError = Exception('Lỗi kết nối: $e');
          developer.log('Attempt #$attempt failed: $e', name: 'AuthService');

          // Nếu không phải lần cuối, đợi một chút trước khi thử lại
          if (attempt < 2) {
            developer.log(
              'Waiting 2 seconds before retry',
              name: 'AuthService',
            );
            await Future.delayed(Duration(seconds: 2));
          }
        }
      }

      // Kiểm tra kết quả sau khi đã thử hết số lần
      if (!success || response == null) {
        // Nếu thất bại khi cố gắng kết nối đến server, hãy cung cấp thông báo chi tiết hơn
        developer.log(
          'Failed to connect to server after multiple attempts',
          name: 'AuthService',
        );

        // Kiểm tra kết nối mạng
        try {
          final result = await InternetAddress.lookup('google.com');
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            developer.log(
              'Internet connection is working, but failed to connect to server',
              name: 'AuthService',
            );
            throw Exception(
              'Không thể kết nối đến máy chủ. Vui lòng thử lại sau.',
            );
          }
        } catch (_) {
          developer.log(
            'No internet connection available',
            name: 'AuthService',
          );
          throw Exception(
            'Không có kết nối internet. Vui lòng kiểm tra mạng và thử lại.',
          );
        }

        throw lastError ?? Exception('Không thể kết nối đến server');
      }

      developer.log(
        'Google auth response status: ${response.statusCode}',
        name: 'AuthService',
      );

      // Kiểm tra cả trạng thái HTTP và nội dung phản hồi
      if (response.statusCode != 200) {
        developer.log(
          'Google auth failed with status ${response.statusCode}: ${response.body}',
          name: 'AuthService',
        );

        // Thử phân tích phản hồi lỗi để hiển thị thông báo rõ ràng hơn
        String errorDetail = 'Unknown error';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic>) {
            errorDetail =
                errorData['message'] ?? errorData['error'] ?? response.body;
          } else {
            errorDetail = response.body;
          }
        } catch (e) {
          errorDetail = response.body;
        }

        developer.log('Error detail: $errorDetail', name: 'AuthService');
        throw Exception(
          'Không thể xác thực với Google. Chi tiết: $errorDetail',
        );
      }

      developer.log(
        'Google auth response received, parsing...',
        name: 'AuthService',
      );

      // Log the raw response first for debugging
      if (response.body.length < 1000) {
        developer.log(
          'Raw response body: ${response.body}',
          name: 'AuthService',
        );
      } else {
        developer.log(
          'Raw response body (truncated): ${response.body.substring(0, 1000)}...',
          name: 'AuthService',
        );
      }

      final responseData = jsonDecode(response.body);
      developer.log(
        'Google auth response structure: ${responseData.keys.join(", ")}',
        name: 'AuthService',
      );

      final apiResponse = ApiResponse<LoginResult>.fromJson(
        responseData,
        (json) => LoginResult.fromJson(json),
      );

      if (!apiResponse.isSuccess || apiResponse.result == null) {
        developer.log(
          'Google auth API response not successful: ${apiResponse.message}',
          name: 'AuthService',
        );
        throw Exception('Backend error: ${apiResponse.message}');
      }

      developer.log(
        'Google auth successful, saving token and user data',
        name: 'AuthService',
      );
      await _saveTokenAndUser(
        apiResponse.result!.token,
        apiResponse.result!.refreshToken ?? '',
        apiResponse.result!,
      );
      _authStateController.add(_currentUser);

      // Khởi tạo FCM sau khi đăng nhập nhưng không chờ đợi
      _initFCMAfterLogin();

      return _currentUser!;
    } catch (e) {
      developer.log(
        'Error in Google backend authentication: $e',
        name: 'AuthService',
      );
      developer.log(
        'Error stack trace: ${StackTrace.current}',
        name: 'AuthService',
      );
      rethrow;
    }
  }

  // Public method for demo purposes
  Future<User> mockSuccessfulLogin(String email, String name) async {
    return _mockSuccessfulAuth(email, name);
  }

  Future<User> _mockSuccessfulAuth(String email, String? name) async {
    developer.log(
      'Creating mock authentication as fallback',
      name: 'AuthService',
    );
    developer.log('Mock auth for email: $email', name: 'AuthService');

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

    // Khởi tạo FCM sau khi đăng nhập nhưng không chờ đợi
    _initFCMAfterLogin();

    developer.log(
      'Mock authentication successful, user created with email: $email',
      name: 'AuthService',
    );
    developer.log(
      'Note: This is a FALLBACK authentication. Backend integration failed.',
      name: 'AuthService',
    );
    developer.log(
      'The user can use the app, but backend-specific features may not work.',
      name: 'AuthService',
    );

    return _currentUser!;
  }

  Future<void> signOut() async {
    try {
      await _googleSignInService.signOut();
    } catch (e) {
      // Error handled gracefully
    }

    await _clearTokenAndUser();
    _authStateController.add(null);
  }

  Future<void> refreshAuthToken() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      final response = await HttpHelper.post(
        Uri.parse('${ApiConfig.authBaseUrl}/${ApiConfig.refreshTokenEndpoint}'),
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
      final response = await HttpHelper.post(
        Uri.parse('${ApiConfig.authBaseUrl}/${ApiConfig.logoutEndpoint}'),
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

      final response = await HttpHelper.post(
        Uri.parse('${ApiConfig.authBaseUrl}/${ApiConfig.registrationsEndpoint}'),
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

      final response = await HttpHelper.post(
        Uri.parse('${ApiConfig.authBaseUrl}/${ApiConfig.completeRegistrationEndpoint}'),
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
      final response = await HttpHelper.post(
        Uri.parse('${ApiConfig.authBaseUrl}/${ApiConfig.forgotPasswordEndpoint}'),
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
      final response = await HttpHelper.post(
        Uri.parse('${ApiConfig.authBaseUrl}/${ApiConfig.resetPasswordEndpoint}'),
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

  /// Khởi tạo FCM sau khi đăng nhập một cách an toàn
  void _initFCMAfterLogin() {
    // Sử dụng Future.delayed để đảm bảo UI đã được cập nhật trước
    Future.delayed(Duration(milliseconds: 500), () {
      if (_currentUser != null && _token != null && _token!.isNotEmpty) {
        try {
          // Initialize FCM với timeout để tránh bị treo
          _initializeFCM()
              .timeout(
                Duration(seconds: 3),
                onTimeout: () {
                  developer.log(
                    'FCM post-login initialization timed out',
                    name: 'AuthService',
                  );
                  return;
                },
              )
              .catchError((error) {
                developer.log(
                  'Error in post-login FCM init: $error',
                  name: 'AuthService',
                );
              });

          // Setup FCM token refresh callback
          _setupFCMCallbacks();
        } catch (e) {
          developer.log('Post-login FCM setup error: $e', name: 'AuthService');
        }
      }
    });
  }

  /// Lấy base URL hiện tại dựa trên nền tảng
  Future<String> getCurrentApiBaseUrl() async {
    // Sử dụng Azure deployment URL
    return ApiConfig.baseUrl;
  }

  /// Kiểm tra kết nối với backend API
  Future<bool> checkBackendConnection() async {
    try {
      final baseUrl = await getCurrentApiBaseUrl();

      developer.log(
        'Testing connection to backend: $baseUrl',
        name: 'AuthService',
      );

      // Thử thực hiện OPTIONS request để kiểm tra kết nối đến Google Sessions API
      final testUrl = '$baseUrl/api/authentication/google-sessions';
      developer.log(
        'Testing specific Google auth endpoint: $testUrl',
        name: 'AuthService',
      );

      try {
        // Thử ping endpoint Google Sessions trước
        final response =
            await HttpHelper.get(
              Uri.parse(testUrl),
              headers: {'accept': '*/*'},
            ).timeout(
              Duration(seconds: 5),
              onTimeout: () {
                developer.log(
                  'Google endpoint test timed out',
                  name: 'AuthService',
                );
                throw TimeoutException('Kết nối đến Google endpoint timed out');
              },
            );

        developer.log(
          'Google endpoint test result: ${response.statusCode}',
          name: 'AuthService',
        );

        // 200, 404, 405 đều chấp nhận được, chứng tỏ server đang hoạt động
        if (response.statusCode != 404 &&
            response.statusCode != 405 &&
            !(response.statusCode >= 200 && response.statusCode < 300)) {
          developer.log(
            'Google endpoint connection test failed with status: ${response.statusCode}',
            name: 'AuthService',
          );
          return false;
        }

        return true;
      } catch (specificError) {
        // Nếu thất bại với endpoint cụ thể, thử với health check hoặc root endpoint
        developer.log(
          'Failed to connect to Google endpoint, trying health check: $specificError',
          name: 'AuthService',
        );

        // Thử thực hiện request đơn giản để kiểm tra kết nối cơ bản
        final response =
            await HttpHelper.get(
              Uri.parse('$baseUrl/api/health'),
              headers: {'accept': '*/*'},
            ).timeout(
              Duration(seconds: 5),
              onTimeout: () {
                developer.log('Connection test timed out', name: 'AuthService');
                throw TimeoutException('Kết nối đến backend timed out');
              },
            );

        developer.log(
          'Backend health check result: ${response.statusCode}',
          name: 'AuthService',
        );

        return response.statusCode >= 200 && response.statusCode < 300;
      }
    } catch (e) {
      developer.log('Backend connection test failed: $e', name: 'AuthService');
      return false;
    }
  }

  /// Phương thức debug để kiểm tra trực tiếp kết nối đến Google Sessions API
  Future<bool> testGoogleSessionsApi() async {
    try {
      developer.log(
        'TEST: Kiểm tra kết nối Google Sessions API',
        name: 'AuthService',
      );

      // Xác định URL dựa trên nền tảng
      final baseUrl = await getCurrentApiBaseUrl();
      final url = '$baseUrl/api/authentication/google-sessions';

      developer.log('TEST: Thử kết nối đến $url', name: 'AuthService');

      // Gửi một OPTIONS request để kiểm tra kết nối
      final response =
          await HttpHelper.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json', 'accept': '*/*'},
            body: jsonEncode({
              "idToken": "test_token",
            }), // Token test không hợp lệ
          ).timeout(
            Duration(seconds: 5),
            onTimeout: () {
              developer.log('TEST: Request timed out', name: 'AuthService');
              throw TimeoutException('Request timed out');
            },
          );

      developer.log(
        'TEST: Kết nối thành công - Status code: ${response.statusCode}',
        name: 'AuthService',
      );
      developer.log(
        'TEST: Response body: ${response.body}',
        name: 'AuthService',
      );

      // Bất kỳ phản hồi nào cũng được coi là kết nối thành công (vì token test sẽ không hợp lệ)
      return true;
    } catch (e) {
      developer.log('TEST: Lỗi kết nối: $e', name: 'AuthService');
      developer.log(
        'TEST: Stack trace: ${StackTrace.current}',
        name: 'AuthService',
      );
      return false;
    }
  }
}

/// Helper class to create HTTP client that accepts self-signed certificates
class HttpHelper {
  /// Tạo HttpClient chấp nhận mọi chứng chỉ SSL
  static HttpClient createUnsafeClient() {
    HttpClient client = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        developer.log(
          'Accepting bad certificate for $host:$port',
          name: 'HttpHelper',
        );
        return true; // Chấp nhận tất cả các chứng chỉ, kể cả self-signed
      };
    return client;
  }

  /// Gửi GET request và bỏ qua lỗi chứng chỉ
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final client = createUnsafeClient();
    try {
      developer.log(
        'Making GET request to: ${url.toString()}',
        name: 'HttpHelper',
      );
      developer.log('Headers: $headers', name: 'HttpHelper');

      // Tạo request
      final request = await client.getUrl(url);

      // Thêm headers
      if (headers != null) {
        headers.forEach((key, value) {
          request.headers.add(key, value);
        });
      }

      // Gửi request và nhận response
      final httpResponse = await request.close().timeout(Duration(seconds: 30));

      // Đọc response body
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      developer.log(
        'Response status: ${httpResponse.statusCode}',
        name: 'HttpHelper',
      );

      // Log body với limit độ dài
      if (responseBody.isNotEmpty) {
        if (responseBody.length > 500) {
          developer.log(
            'Response body (truncated): ${responseBody.substring(0, 500)}...',
            name: 'HttpHelper',
          );
        } else {
          developer.log('Response body: $responseBody', name: 'HttpHelper');
        }
      } else {
        developer.log('Response body is empty', name: 'HttpHelper');
      }

      // Chuyển đổi sang http.Response
      Map<String, String> responseHeaders = {};
      httpResponse.headers.forEach((name, values) {
        responseHeaders[name] = values.join(", ");
      });

      return http.Response(
        responseBody,
        httpResponse.statusCode,
        headers: responseHeaders,
        reasonPhrase: httpResponse.reasonPhrase,
      );
    } catch (e) {
      developer.log('Error in GET request: $e', name: 'HttpHelper');
      developer.log(
        'Error stack trace: ${StackTrace.current}',
        name: 'HttpHelper',
      );

      // Cung cấp thông tin lỗi chi tiết hơn
      if (e is SocketException) {
        developer.log(
          'Socket error: ${e.address?.address}, ${e.port}, ${e.osError?.message}',
          name: 'HttpHelper',
        );
      } else if (e is TimeoutException) {
        developer.log('Request timed out', name: 'HttpHelper');
      } else if (e is HandshakeException) {
        developer.log('SSL handshake failed: ${e.message}', name: 'HttpHelper');
      }

      rethrow;
    } finally {
      client.close();
    }
  }

  /// Gửi POST request và bỏ qua lỗi chứng chỉ
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final client = createUnsafeClient();
    try {
      developer.log(
        'Making POST request to: ${url.toString()}',
        name: 'HttpHelper',
      );
      developer.log('Headers: $headers', name: 'HttpHelper');
      developer.log('Body: $body', name: 'HttpHelper');

      // Tạo request
      final request = await client.postUrl(url);

      // Thêm headers
      if (headers != null) {
        headers.forEach((key, value) {
          request.headers.add(key, value);
        });
      }

      // Thêm body
      if (body != null) {
        List<int> bodyBytes = utf8.encode(body.toString());
        request.contentLength = bodyBytes.length;
        request.add(bodyBytes);
      }

      // Gửi request và nhận response
      final httpResponse = await request.close().timeout(Duration(seconds: 30));

      // Đọc response body
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      developer.log(
        'Response status: ${httpResponse.statusCode}',
        name: 'HttpHelper',
      );

      // Log body với limit độ dài
      if (responseBody.isNotEmpty) {
        if (responseBody.length > 500) {
          developer.log(
            'Response body (truncated): ${responseBody.substring(0, 500)}...',
            name: 'HttpHelper',
          );
        } else {
          developer.log('Response body: $responseBody', name: 'HttpHelper');
        }
      } else {
        developer.log('Response body is empty', name: 'HttpHelper');
      }

      // Chuyển đổi sang http.Response
      Map<String, String> responseHeaders = {};
      httpResponse.headers.forEach((name, values) {
        responseHeaders[name] = values.join(", ");
      });

      return http.Response(
        responseBody,
        httpResponse.statusCode,
        headers: responseHeaders,
        reasonPhrase: httpResponse.reasonPhrase,
      );
    } catch (e) {
      developer.log('Error in POST request: $e', name: 'HttpHelper');
      developer.log(
        'Error stack trace: ${StackTrace.current}',
        name: 'HttpHelper',
      );

      // Cung cấp thông tin lỗi chi tiết hơn
      if (e is SocketException) {
        developer.log(
          'Socket error: ${e.address?.address}, ${e.port}, ${e.osError?.message}',
          name: 'HttpHelper',
        );
      } else if (e is TimeoutException) {
        developer.log('Request timed out', name: 'HttpHelper');
      } else if (e is HandshakeException) {
        developer.log('SSL handshake failed: ${e.message}', name: 'HttpHelper');
      }

      rethrow;
    } finally {
      client.close();
    }
  }

  /// Test trực tiếp API Google Sessions với token thật
  static Future<void> testGoogleAuthWithRealToken(String idToken) async {
    try {
      // Sử dụng Azure deployment URL
      String url = '${ApiConfig.authBaseUrl}/${ApiConfig.googleSessionsEndpoint}';

      developer.log(
        'Starting direct API test with real token',
        name: 'HttpHelper',
      );
      developer.log('URL: $url', name: 'HttpHelper');

      // Không hiển thị token đầy đủ vì lý do bảo mật
      if (idToken.length > 10) {
        developer.log(
          'Token prefix: ${idToken.substring(0, 5)}..., suffix: ...${idToken.substring(idToken.length - 5)}',
          name: 'HttpHelper',
        );
      }

      // Gửi request trực tiếp
      developer.log('Preparing request...', name: 'HttpHelper');

      final client = createUnsafeClient();
      final request = await client.postUrl(Uri.parse(url));

      // Thêm headers
      request.headers.add('Content-Type', 'application/json');
      request.headers.add('accept', '*/*');

      // Thêm body
      final Map<String, dynamic> requestBody = {"idToken": idToken};
      List<int> bodyBytes = utf8.encode(jsonEncode(requestBody));
      request.contentLength = bodyBytes.length;
      request.add(bodyBytes);

      developer.log('Sending request...', name: 'HttpHelper');

      // Gửi request và nhận response
      final httpResponse = await request.close().timeout(Duration(seconds: 30));
      final responseBody = await httpResponse.transform(utf8.decoder).join();

      developer.log(
        'Response status: ${httpResponse.statusCode}',
        name: 'HttpHelper',
      );

      // Log body
      if (responseBody.isNotEmpty) {
        if (responseBody.length > 500) {
          developer.log(
            'Response body (truncated): ${responseBody.substring(0, 500)}...',
            name: 'HttpHelper',
          );
        } else {
          developer.log('Response body: $responseBody', name: 'HttpHelper');
        }
      }

      developer.log('Direct API test completed', name: 'HttpHelper');
    } catch (e) {
      developer.log('Error in direct API test: $e', name: 'HttpHelper');
      developer.log(
        'Error stack trace: ${StackTrace.current}',
        name: 'HttpHelper',
      );
      rethrow;
    }
  }
}
