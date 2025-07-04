class ApiConfig {
  // Backend URLs
  static const String baseUrl =
      'https://localhost:7258'; // Thay đổi theo backend của bạn
  static const String authBaseUrl = '$baseUrl/api/authentication';

  // API Endpoints
  static const String loginEndpoint = 'login';
  static const String googleSessionsEndpoint = 'google-sessions';
  static const String registrationsEndpoint = 'registrations';
  static const String completeRegistrationEndpoint = 'registrations/complete';
  static const String forgotPasswordEndpoint = 'forgot-password';
  static const String resetPasswordEndpoint = 'reset-password';
  static const String refreshTokenEndpoint = 'refresh-token';
  static const String fcmTokenEndpoint = 'fcm-token';
  static const String logoutEndpoint = 'logout';

  // Google OAuth Configuration
  static const String googleClientId =
      '413334004170-dk2csovpjrnmsthqqtb2ad6iseh0n4bt.apps.googleusercontent.com';

  // Request timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);

  // Storage keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String tokenExpiresAtKey = 'token_expires_at';
  static const String refreshTokenExpiresAtKey = 'refresh_token_expires_at';
  static const String currentUserKey = 'current_user';

  // OTP Configuration
  static const int otpLength = 6;
  static const Duration otpValidityDuration = Duration(minutes: 5);

  // Token refresh configuration
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
}
