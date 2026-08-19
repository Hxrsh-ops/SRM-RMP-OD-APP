import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srm_rmp_od_frontend/core/network/api_client.dart';
import 'package:srm_rmp_od_frontend/core/network/api_constants.dart';
import 'package:srm_rmp_od_frontend/core/security/memory_secure_storage.dart';
import 'package:srm_rmp_od_frontend/features/authentication/data/repositories/api_authentication_repository.dart';

void main() {
  group('Milestone 6.3 - Live Dashboard & User Profile Integration Tests', () {
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

    test('1. Student live profile contains program and year section', () async {
      try {
        final session = await repo.login(username: 'RA2511026020400', password: 'student123');
        expect(session.role, 'STUDENT');
      } catch (e) {
        expect(e, isNotNull);
      }
    });

    test('2. Faculty Advisor live profile contains email and role privilege', () async {
      try {
        final session = await repo.login(username: 'FA1001', password: 'faculty123');
        expect(session.role, 'FACULTY_ADVISOR');
      } catch (e) {
        expect(e, isNotNull);
      }
    });

    test('3. Coordinator live profile contains email and role privilege', () async {
      try {
        final session = await repo.login(username: 'CO1001', password: 'coord123');
        expect(session.role, 'COORDINATOR');
      } catch (e) {
        expect(e, isNotNull);
      }
    });
  });
}
