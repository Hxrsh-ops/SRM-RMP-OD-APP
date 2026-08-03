import '../config/env_config.dart';

class ApiConstants {
  static const String desktopBaseUrl = 'http://127.0.0.1:8000/api/v1';

  static String get baseUrl => EnvConfig.apiBaseUrl;
  static String get serverRootUrl => EnvConfig.serverRootUrl;

  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 5);

  // Authentication Endpoints
  static const String login = '/auth/login/json';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';
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
