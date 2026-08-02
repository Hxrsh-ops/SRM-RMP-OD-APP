import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srm_rmp_od_frontend/core/network/api_client.dart';
import 'package:srm_rmp_od_frontend/core/network/api_constants.dart';
import 'package:srm_rmp_od_frontend/core/security/memory_secure_storage.dart';
import 'package:srm_rmp_od_frontend/features/authentication/data/repositories/api_authentication_repository.dart';

void main() {
  group('Live FastAPI Backend Integration Test (Milestone 6.1)', () {
    late MemorySecureStorage storage;
    late Dio dio;
    late ApiClient apiClient;
    late ApiAuthenticationRepository repo;

    setUp(() {
      storage = MemorySecureStorage();
      dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ));
      apiClient = ApiClient(dio);
      repo = ApiAuthenticationRepository(apiClient: apiClient, storageService: storage);
    });

    test('Authenticate against FastAPI backend and call GET /api/v1/auth/me', () async {
      // 1. Perform login
      final session = await repo.login(username: 'RA2511026020400', password: 'student123');
      expect(session, isNotNull);
      expect(session.username, 'RA2511026020400');
      expect(session.name, 'K.M. Harshanth');
      expect(session.role, 'STUDENT');

      // 2. Attach Bearer Token to Dio headers
      dio.options.headers['Authorization'] = 'Bearer ${session.token.accessToken}';

      // 3. Call GET /api/v1/auth/me
      final meSession = await repo.restoreSession();
      expect(meSession, isNotNull);
      expect(meSession?.username, 'RA2511026020400');
      expect(meSession?.name, 'K.M. Harshanth');
    });
  });
}
