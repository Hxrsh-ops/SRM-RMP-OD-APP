import 'package:flutter_test/flutter_test.dart';
import 'package:srm_rmp_od_frontend/features/od_workflow/domain/entities/od_status.dart';
import 'mocks/mock_workflow_repository.dart';

void main() {
  group('E2E Workflow State Transitions Tests', () {
    late MockWorkflowRepository workflowRepo;

    setUp(() {
      workflowRepo = MockWorkflowRepository();
    });

    test('Complete E2E Flow: Student Submit -> Faculty Approve -> Coordinator Final Approve', () async {
      // 1. Submit OD Request
      final createdOd = await workflowRepo.submitOdRequest(
        studentId: 'usr_harshanth',
        studentName: 'K M Harshanth',
        registerNumber: 'RA2511026020400',
        reason: 'Technical Symposium',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 2)),
        durationDays: 3,
        purpose: 'Participating in event',
        venue: 'Main Auditorium',
        organizer: 'IEEE Student Branch',
        residenceType: 'Day Scholar',
      );

      expect(createdOd.id, isNotEmpty);
      expect(createdOd.status, OdStatus.pendingFaculty);

      // 2. Faculty Action
      final facultyApproved = await workflowRepo.facultyAction(
        requestId: createdOd.id,
        facultyId: 'usr_faculty',
        facultyName: 'Dr. Karthik B',
        approve: true,
        comment: 'Verified attendance eligibility',
      );
      expect(facultyApproved.status, OdStatus.pendingCoordinator);

      // 3. Coordinator Action
      final coordApproved = await workflowRepo.coordinatorAction(
        requestId: createdOd.id,
        coordinatorId: 'usr_coord',
        coordinatorName: 'Prof. Ramesh Kumar',
        approve: true,
        comment: 'Initial approval granted',
      );
      expect(coordApproved.status, OdStatus.approvedAwaitingEvidence);
    });
  });
}
