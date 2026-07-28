class ApiConstants {
  // Localhost IP for Android Emulator (10.0.2.2) or local desktop (127.0.0.1 / localhost)
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  // Environment fallback for Desktop/Web testing
  static const String desktopBaseUrl = 'http://127.0.0.1:8000/api/v1';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Authentication Endpoints
  static const String login = '/auth/login/json';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // Workflow Endpoints
  static const String odRequests = '/od-requests';
  static String facultyAction(String id) => '/od-requests/$id/faculty-action';
  static String coordinatorAction(String id) => '/od-requests/$id/coordinator-action';

  // Attachment Endpoints
  static const String uploadAttachment = '/attachments/upload';

  // Notification Endpoints
  static const String notifications = '/notifications';
  static const String markNotificationsRead = '/notifications/mark-read';

  // Storage Keys
  static const String tokenKey = 'srm_rmp_od_access_token';
  static const String refreshTokenKey = 'srm_rmp_od_refresh_token';
  static const String userKey = 'srm_rmp_od_user_profile';
}
