class AuthResponse {
  final int code;
  final String message;
  final AuthResult? result;

  AuthResponse({
    required this.code,
    required this.message,
    this.result,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      code: json['code'],
      message: json['message'],
      result: json['result'] != null && json['result'] != "" 
          ? AuthResult.fromJson(json['result']) 
          : null,
    );
  }
}

class AuthResult {
  final String token;
  final String username;
  final String fullName;
  final String email;
  final String role;

  AuthResult({
    required this.token,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'],
      username: json['username'],
      fullName: json['fullName'],
      email: json['email'],
      role: json['role'],
    );
  }
}
