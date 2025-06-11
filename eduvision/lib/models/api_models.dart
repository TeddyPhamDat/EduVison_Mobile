class ApiResponse<T> {
  final int code;
  final String message;
  final T? result;

  ApiResponse({
    required this.code,
    required this.message,
    this.result,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>)? fromJson) {
    return ApiResponse<T>(
      code: json['code'] as int,
      message: json['message'] as String,
      result: json['result'] != null && fromJson != null 
          ? fromJson(json['result'] as Map<String, dynamic>)
          : json['result'] as T?,
    );
  }

  bool get isSuccess => code == 200;
}

class LoginResult {
  final String token;
  final String username;
  final String fullName;
  final String email;
  final String role;

  LoginResult({
    required this.token,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: json['token'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }
}

class RegisterRequest {
  final String email;

  RegisterRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

class CompleteRegistrationRequest {
  final String email;
  final String otpToken;
  final String password;
  final String fullName;

  CompleteRegistrationRequest({
    required this.email,
    required this.otpToken,
    required this.password,
    required this.fullName,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otpToken': otpToken,
      'password': password,
      'fullName': fullName,
    };
  }
}

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}
