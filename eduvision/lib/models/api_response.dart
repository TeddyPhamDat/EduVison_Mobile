class LoginResponse {
  final int code;
  final String message;
  final LoginResult? result;

  LoginResponse({
    required this.code,
    required this.message,
    this.result,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      result: json['result'] != null && json['result'] != ""
          ? LoginResult.fromJson(json['result'] as Map<String, dynamic>)
          : null,
    );
  }
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

class RegisterResponse {
  final int code;
  final String message;
  final String result;

  RegisterResponse({
    required this.code,
    required this.message,
    required this.result,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      result: json['result'] as String,
    );
  }
}

class CompleteRegistrationResponse {
  final int code;
  final String message;
  final String result;

  CompleteRegistrationResponse({
    required this.code,
    required this.message,
    required this.result,
  });

  factory CompleteRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return CompleteRegistrationResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      result: json['result'] as String,
    );
  }
}
