import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers/dio_provider.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../data/repositories/api_workflow_repository.dart';
import '../../domain/entities/attachment_item.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/entities/od_request.dart';
import '../../domain/repositories/workflow_repository.dart';

final workflowRepositoryProvider = Provider<WorkflowRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiWorkflowRepository(apiClient: apiClient);
});

class WorkflowState {
  final List<OdRequest> requests;
  final List<NotificationItem> notifications;
  final bool isLoading;
  final String? errorMessage;

  const WorkflowState({
    this.requests = const [],
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  WorkflowState copyWith({
    List<OdRequest>? requests,
    List<NotificationItem>? notifications,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WorkflowState(
      requests: requests ?? this.requests,
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class WorkflowController extends StateNotifier<WorkflowState> {
  final WorkflowRepository _repository;
  final String _currentUserId;

  WorkflowController(this._repository, this._currentUserId) : super(const WorkflowState()) {
    loadAllData();
  }

  Future<void> loadAllData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final requests = await _repository.getAllRequests();
      final notifications = await _repository.getNotifications(_currentUserId);
      state = state.copyWith(
        requests: requests,
        notifications: notifications,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> submitRequest({
    required String studentId,
    required String studentName,
    required String registerNumber,
    required String reason,
    required DateTime startDate,
    required DateTime endDate,
    required int durationDays,
    required String purpose,
    required String venue,
    required String organizer,
    String? additionalNotes,
    double? cgpa,
    double? attendancePercentage,
    String? residenceType,
    String? parentConsentUrl,
    List<AttachmentItem>? attachments,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.submitOdRequest(
        studentId: studentId,
        studentName: studentName,
        registerNumber: registerNumber,
        reason: reason,
        startDate: startDate,
        endDate: endDate,
        durationDays: durationDays,
        purpose: purpose,
        venue: venue,
        organizer: organizer,
        additionalNotes: additionalNotes,
        cgpa: cgpa,
        attendancePercentage: attendancePercentage,
        residenceType: residenceType,
        parentConsentUrl: parentConsentUrl,
        attachments: attachments,
      );
      await loadAllData();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> processFacultyAction({
    required String requestId,
    required String facultyId,
    required String facultyName,
    required bool approve,
    String? comment,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.facultyAction(
        requestId: requestId,
        facultyId: facultyId,
        facultyName: facultyName,
        approve: approve,
        comment: comment,
      );
      await loadAllData();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> processCoordinatorAction({
    required String requestId,
    required String coordinatorId,
    required String coordinatorName,
    required bool approve,
    bool returnForCorrection = false,
    String? comment,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.coordinatorAction(
        requestId: requestId,
        coordinatorId: coordinatorId,
        coordinatorName: coordinatorName,
        approve: approve,
        returnForCorrection: returnForCorrection,
        comment: comment,
      );
      await loadAllData();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final workflowControllerProvider = StateNotifierProvider<WorkflowController, WorkflowState>((ref) {
  final repo = ref.watch(workflowRepositoryProvider);
  final session = ref.watch(authControllerProvider).session;
  final userId = session?.userId ?? '';
  return WorkflowController(repo, userId);
});
