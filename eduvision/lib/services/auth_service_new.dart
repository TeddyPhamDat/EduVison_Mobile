import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/api_models.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  
  factory AuthService() => _instance;
  
  AuthService._internal();

  // API base URL
  static const String _baseUrl = 'https://eduvision-api-accscqa6f5d6dha5.southeastasia-01.azurewebsites.net/api/Auth';

  // Người dùng đang đăng nhập
  User? _currentUser;
  String? _token;

  // Stream để theo dõi thay đổi trạng thái đăng nhập
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();
  Stream<User?> get authStateChanges => _authStateController.stream;

  // Trả về người dùng hiện tại
  User? get currentUser => _currentUser;
  String? get token => _token;

  // Khởi tạo service và load token từ storage
  Future<void> initialize() async {
    await _loadTokenFromStorage();
  }

  // Load token từ SharedPreferences
  Future<void> _loadTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      
      if (_token != null) {
        // Nếu có token, tạo user từ thông tin đã lưu
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

  // Lưu token và user data vào SharedPreferences
  Future<void> _saveTokenAndUser(String token, LoginResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      
      final user = User(
        id: result.email, // Sử dụng email làm ID tạm thời
        name: result.fullName,
        email: result.email,
        photoUrl: null, // API không trả về photo URL
      );
      
      await prefs.setString('user_data', jsonEncode(user.toJson()));
      
      _token = token;
      _currentUser = user;
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  // Xóa token và user data
  Future<void> _clearTokenAndUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      
      _token = null;
      _currentUser = null;
    } catch (e) {
      print('Error clearing token: $e');
    }
  }

  // Đăng nhập với email và mật khẩu
  Future<User> signIn({required String email, required String password}) async {
    try {
      final request = LoginRequest(username: email, password: password);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
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

      // Lưu token và user data
      await _saveTokenAndUser(apiResponse.result!.token, apiResponse.result!);
      _authStateController.add(_currentUser);

      return _currentUser!;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Bước 1: Đăng ký - gửi email để nhận OTP
  Future<String> startRegistration({required String email}) async {
    try {
      final request = RegisterRequest(email: email);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
        body: jsonEncode(request.toJson()),
      );

      final responseData = jsonDecode(response.body);
      final apiResponse = ApiResponse<String>.fromJson(responseData, null);

      if (!apiResponse.isSuccess) {
        throw Exception(apiResponse.message);
      }

      return apiResponse.message; // "OTP sent to email"
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Bước 2: Hoàn thành đăng ký với OTP
  Future<User> completeRegistration({
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
        Uri.parse('$_baseUrl/complete-registration'),
        headers: {
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
        body: jsonEncode(request.toJson()),
      );

      final responseData = jsonDecode(response.body);
      final apiResponse = ApiResponse<String>.fromJson(responseData, null);

      if (!apiResponse.isSuccess) {
        throw Exception(apiResponse.message);
      }

      // Sau khi đăng ký thành công, tự động đăng nhập
      return await signIn(email: email, password: password);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Phương thức signUp cũ cho tương thích ngược (sẽ chỉ gửi OTP)
  Future<String> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return await startRegistration(email: email);
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _clearTokenAndUser();
    _authStateController.add(null);
  }

  // Đóng stream khi không cần thiết
  void dispose() {
    _authStateController.close();
  }

  // Kiểm tra người dùng đã đăng nhập chưa
  bool get isSignedIn => _currentUser != null && _token != null;
}
