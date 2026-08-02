import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String desktopBaseUrl = 'http://127.0.0.1:8000/api/v1';

  // Support --dart-define=API_BASE_URL=http://<PC-LAN-IP>:8000/api/v1
  static String get baseUrl {
    const overrideUrl = String.fromEnvironment('API_BASE_URL');
    if (overrideUrl.isNotEmpty) {
      return overrideUrl.endsWith('/api/v1') ? overrideUrl : '$overrideUrl/api/v1';
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    }

    final isTest = Platform.environment.containsKey('FLUTTER_TEST') ||
        bool.fromEnvironment('FLUTTER_TEST');

    // Default to 10.0.2.2 ONLY when executing on physical device / emulator outside test environment
    if (defaultTargetPlatform == TargetPlatform.android && !isTest) {
      return 'http://10.0.2.2:8000/api/v1';
    }

    return 'http://127.0.0.1:8000/api/v1';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

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
