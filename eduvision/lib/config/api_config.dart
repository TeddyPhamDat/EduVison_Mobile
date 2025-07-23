// Define API environments
enum ApiEnvironment {
  development,
  testing,
  production
}

class ApiConfig {
  // Backend environment (change this when switching environments)
  static const ApiEnvironment environment = ApiEnvironment.production;
  
  // Base URL configuration - will automatically choose the right one based on environment
  static String get baseUrl => _getBaseUrl();
  
  // Auth API base URL
  static String get authBaseUrl => '$baseUrl/api/authentication';
  
  // Education API base URL
  static String get educationBaseUrl => '$baseUrl/api/education';
  
  // Media API base URLs
  static String get slidesBaseUrl => '$baseUrl/api/slides';
  static String get videosBaseUrl => '$baseUrl/api/videos';
  
  // Returns the appropriate base URL based on current environment setting
  static String _getBaseUrl() {
    switch (environment) {
      case ApiEnvironment.production:
        return 'https://eduvision-bsg0f8eqhnbwavbv.southeastasia-01.azurewebsites.net';
      case ApiEnvironment.development:
        return 'https://eduvision-bsg0f8eqhnbwavbv.southeastasia-01.azurewebsites.net'; // Now using production URL for all environments
      case ApiEnvironment.testing:
        return 'https://eduvision-bsg0f8eqhnbwavbv.southeastasia-01.azurewebsites.net';
    }
  }

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
      '859564462424-a81d1ieeimchlh52a2mcmdriip828ju2.apps.googleusercontent.com'; // Web client ID
  static const String googleAndroidClientId =
      '859564462424-o8iufugaok7ap1t0mrqg31k85odp4icr.apps.googleusercontent.com'; // Android client ID

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

  // Education API endpoints
  static const String getSlidesEndpoint = 'slides';
  static const String getVideosEndpoint = 'videos';
  static const String generateVideoEndpoint = 'videos';
  static const String subjectsEndpoint = 'subjects';
  static const String chaptersEndpoint = 'chapters';
}
