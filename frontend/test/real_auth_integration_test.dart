import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srm_rmp_od_frontend/core/network/api_client.dart';
import 'package:srm_rmp_od_frontend/core/network/api_constants.dart';
import 'package:srm_rmp_od_frontend/core/security/memory_secure_storage.dart';
import 'package:srm_rmp_od_frontend/features/authentication/data/repositories/api_authentication_repository.dart';

void main() {
  group('Milestone 6.2 - Real FastAPI Authentication Integration Tests', () {
    late MemorySecureStorage storage;
    late Dio dio;
    late ApiClient apiClient;
    late ApiAuthenticationRepository repo;

    setUp(() {
      storage = MemorySecureStorage();
      dio = Dio(BaseOptions(
        baseUrl: ApiConstants.desktopBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ));
      apiClient = ApiClient(dio);
      repo = ApiAuthenticationRepository(apiClient: apiClient, storageService: storage);
    });

    test('1. Student Login (RA2511026020400) succeeds and persists JWT token', () async {
      final session = await repo.login(username: 'RA2511026020400', password: 'student123');

      expect(session.username, 'RA2511026020400');
      expect(session.name, 'K.M. Harshanth');
      expect(session.role, 'STUDENT');

      final savedToken = await storage.read(key: ApiConstants.tokenKey);
      expect(savedToken, isNotNull);
      expect(savedToken, session.token.accessToken);
    });

    test('2. Faculty Advisor Login (FA1001) succeeds', () async {
      final session = await repo.login(username: 'FA1001', password: 'faculty123');

      expect(session.username, 'FA1001');
      expect(session.name, 'Dr. Karthik B (Mock)');
      expect(session.role, 'FACULTY_ADVISOR');
    });

    test('3. Coordinator Login (CO1001) succeeds', () async {
      final session = await repo.login(username: 'CO1001', password: 'coord123');

      expect(session.username, 'CO1001');
      expect(session.name, 'Prof. Ramesh Kumar (Coordinator)');
      expect(session.role, 'COORDINATOR');
    });

    test('4. Invalid credentials rejected with exception', () async {
      expect(
        () async => await repo.login(username: 'RA2511026020400', password: 'invalidpassword'),
        throwsA(anything),
      );
    });

    test('5. Session restoration via GET /api/v1/auth/me succeeds', () async {
      final loginSession = await repo.login(username: 'RA2511026020400', password: 'student123');

      // Attach token
      dio.options.headers['Authorization'] = 'Bearer ${loginSession.token.accessToken}';

      final restored = await repo.restoreSession();
      expect(restored, isNotNull);
      expect(restored?.username, 'RA2511026020400');
      expect(restored?.name, 'K.M. Harshanth');
    });

    test('6. Logout clears JWT access token from storage', () async {
      final loginSession = await repo.login(username: 'RA2511026020400', password: 'student123');
      dio.options.headers['Authorization'] = 'Bearer ${loginSession.token.accessToken}';

      await repo.logout();

      final savedToken = await storage.read(key: ApiConstants.tokenKey);
      expect(savedToken, isNull);
    });
  });
}
