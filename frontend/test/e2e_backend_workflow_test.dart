import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srm_rmp_od_frontend/core/network/api_client.dart';
import 'package:srm_rmp_od_frontend/core/network/api_constants.dart';
import 'package:srm_rmp_od_frontend/core/security/memory_secure_storage.dart';
import 'package:srm_rmp_od_frontend/features/authentication/data/repositories/api_authentication_repository.dart';
import 'package:srm_rmp_od_frontend/features/od_workflow/data/repositories/api_workflow_repository.dart';
import 'package:srm_rmp_od_frontend/features/od_workflow/domain/entities/od_status.dart';

void main() {
  group('Milestone 6.3.2 - End-to-End Live Workflow Integration Tests against PostgreSQL', () {
    late MemorySecureStorage storage;
    late Dio dio;
    late ApiClient apiClient;
    late ApiAuthenticationRepository authRepo;
    late ApiWorkflowRepository workflowRepo;

    setUp(() {
      storage = MemorySecureStorage();
      dio = Dio(BaseOptions(
        baseUrl: ApiConstants.desktopBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ));
      apiClient = ApiClient(dio);
      authRepo = ApiAuthenticationRepository(apiClient: apiClient, storageService: storage);
      workflowRepo = ApiWorkflowRepository(apiClient: apiClient);
    });

    test('Complete E2E Approval Workflow: Student Submit -> Faculty Approve -> Coordinator Final Approve', () async {
      // 1. Student Login (RA2510026020400)
      final studentSession = await authRepo.login(username: 'RA2510026020400', password: 'student123');
      expect(studentSession.role, 'STUDENT');
      dio.options.headers['Authorization'] = 'Bearer ${studentSession.token.accessToken}';

      // 2. Student Submits OD Request to PostgreSQL
      final createdOd = await workflowRepo.submitOdRequest(
        studentId: studentSession.userId,
        studentName: studentSession.name,
        registerNumber: studentSession.username,
        reason: 'National Hackathon 2026',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 2)),
        durationDays: 3,
        purpose: 'Participating in finals',
        venue: 'Main Auditorium',
        organizer: 'IEEE Student Branch',
        additionalNotes: 'Project prototype presentation',
      );

      expect(createdOd.id, startsWith('OD-2026-'));
      expect(createdOd.reason, 'National Hackathon 2026');
      expect(createdOd.status, OdStatus.pendingFaculty);

      // 3. Faculty Advisor Login (FA1001)
      final facultySession = await authRepo.login(username: 'FA1001', password: 'faculty123');
      expect(facultySession.role, 'FACULTY_ADVISOR');
      dio.options.headers['Authorization'] = 'Bearer ${facultySession.token.accessToken}';

      // 4. Faculty Views Pending Queue from PostgreSQL
      final facultyPending = await workflowRepo.getFacultyPendingRequests(facultySession.userId);
      final facultyTargetReq = facultyPending.firstWhere((r) => r.id == createdOd.id);
      expect(facultyTargetReq, isNotNull);

      // 5. Faculty Approves Request in PostgreSQL
      await workflowRepo.facultyAction(
        requestId: createdOd.id,
        facultyId: facultySession.userId,
        facultyName: facultySession.name,
        approve: true,
        comment: 'Verified registration. Recommended.',
      );

      // 6. Coordinator Login (CO1001)
      final coordSession = await authRepo.login(username: 'CO1001', password: 'coord123');
      expect(coordSession.role, 'COORDINATOR');
      dio.options.headers['Authorization'] = 'Bearer ${coordSession.token.accessToken}';

      // 7. Coordinator Views Approval Queue from PostgreSQL
      final coordPending = await workflowRepo.getCoordinatorPendingRequests();
      final coordTargetReq = coordPending.firstWhere((r) => r.id == createdOd.id);
      expect(coordTargetReq, isNotNull);

      // 8. Coordinator Final Approves Request in PostgreSQL
      await workflowRepo.coordinatorAction(
        requestId: createdOd.id,
        coordinatorId: coordSession.userId,
        coordinatorName: coordSession.name,
        approve: true,
        comment: 'Final approval granted for department records.',
      );

      // 9. Student Logs In & Checks Updated Status
      dio.options.headers['Authorization'] = 'Bearer ${studentSession.token.accessToken}';
      final studentRequests = await workflowRepo.getStudentRequests(studentSession.userId);
      final finalStudentReq = studentRequests.firstWhere((r) => r.id == createdOd.id);

      expect(finalStudentReq.status, OdStatus.completed);
      expect(finalStudentReq.timeline.length, greaterThanOrEqualTo(3));
    });
  });
}
