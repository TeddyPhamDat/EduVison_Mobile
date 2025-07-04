class ApiResponse<T> {
  final int code;
  final String message;
  final T? result;

  ApiResponse({required this.code, required this.message, this.result});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    return ApiResponse<T>(
      code: json['code'] as int,
      message: json['message'] as String,
      result: json['result'] != null && fromJson != null
          ? fromJson(json['result'] as Map<String, dynamic>)
          : json['result'] as T?,
    );
  }

  bool get isSuccess => code == 200;

  /// Create a successful response
  static ApiResponse<T> success<T>(T data, [String? message]) {
    return ApiResponse<T>(
      code: 200,
      message: message ?? 'Success',
      result: data,
    );
  }

  /// Create a failed response
  static ApiResponse<T> fail<T>(String message, int code) {
    return ApiResponse<T>(code: code, message: message, result: null);
  }

  /// Get the data from result
  T? get data => result;
}

class LoginResult {
  final int? userId;
  final String token;
  final String? refreshToken;
  final DateTime? tokenExpiresAt;
  final DateTime? refreshTokenExpiresAt;
  final String username;
  final String fullName;
  final String email;
  final String role;

  LoginResult({
    this.userId,
    required this.token,
    this.refreshToken,
    this.tokenExpiresAt,
    this.refreshTokenExpiresAt,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      userId: json['userId'] as int?,
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String?,
      tokenExpiresAt: json['tokenExpiresAt'] != null
          ? DateTime.parse(json['tokenExpiresAt'])
          : null,
      refreshTokenExpiresAt: json['refreshTokenExpiresAt'] != null
          ? DateTime.parse(json['refreshTokenExpiresAt'])
          : null,
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
    return {'email': email};
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

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }
}

class GoogleLoginRequest {
  final String idToken;

  GoogleLoginRequest({required this.idToken});

  Map<String, dynamic> toJson() {
    return {'idToken': idToken};
  }
}

class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

class ResetPasswordRequest {
  final String email;
  final String otpToken;
  final String newPassword;

  ResetPasswordRequest({
    required this.email,
    required this.otpToken,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {'email': email, 'otpToken': otpToken, 'newPassword': newPassword};
  }
}

class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {'refreshToken': refreshToken};
  }
}

class GoogleAccessTokenRequest {
  final String accessToken;

  GoogleAccessTokenRequest({required this.accessToken});

  Map<String, dynamic> toJson() {
    return {'accessToken': accessToken};
  }
}
