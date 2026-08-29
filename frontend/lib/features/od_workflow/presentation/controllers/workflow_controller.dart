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
  final Map<String, int>? analytics;
  final bool isLoading;
  final String? errorMessage;

  const WorkflowState({
    this.requests = const [],
    this.notifications = const [],
    this.analytics,
    this.isLoading = false,
    this.errorMessage,
  });

  WorkflowState copyWith({
    List<OdRequest>? requests,
    List<NotificationItem>? notifications,
    Map<String, int>? analytics,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WorkflowState(
      requests: requests ?? this.requests,
      notifications: notifications ?? this.notifications,
      analytics: analytics ?? this.analytics,
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

  Future<void> loadAllData({bool includeHistory = true}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final requests = await _repository.getMyRequests(includeHistory: includeHistory);
      final notifications = await _repository.getNotifications(_currentUserId);
      Map<String, int>? analytics;
      try {
        analytics = await _repository.getCoordinatorAnalytics();
      } catch (_) {}
      state = state.copyWith(
        requests: requests,
        notifications: notifications,
        analytics: analytics,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refreshSingleRequest(String requestId) async {
    try {
      final updated = await _repository.getRequestById(requestId);
      final updatedRequests = state.requests.map((r) => r.id == requestId ? updated : r).toList();
      state = state.copyWith(requests: updatedRequests);
    } catch (_) {}
  }

  Future<bool> submitRequest({
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
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newReq = await _repository.submitOdRequest(
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
      state = state.copyWith(
        requests: [newReq, ...state.requests],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> submitCompletionEvidence({
    required String requestId,
    required String completionSummary,
    required List<List<int>> filesBytes,
    required List<String> fileNames,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repository.submitCompletionEvidence(
        requestId: requestId,
        completionSummary: completionSummary,
        filesBytes: filesBytes,
        fileNames: fileNames,
      );
      final updatedRequests = state.requests.map((r) => r.id == requestId ? updated : r).toList();
      state = state.copyWith(requests: updatedRequests, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<AttachmentItem?> uploadAttachment({
    required List<int> fileBytes,
    required String fileName,
    required String documentCategory,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final item = await _repository.uploadAttachment(
        fileBytes: fileBytes,
        fileName: fileName,
        documentCategory: documentCategory,
      );
      state = state.copyWith(isLoading: false);
      return item;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<bool> processFacultyAction({
    required String requestId,
    required String facultyId,
    required String facultyName,
    required bool approve,
    String? comment,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repository.facultyAction(
        requestId: requestId,
        facultyId: facultyId,
        facultyName: facultyName,
        approve: approve,
        comment: comment,
      );
      final updatedRequests = state.requests.map((r) => r.id == requestId ? updated : r).toList();
      Map<String, int>? analytics;
      try {
        analytics = await _repository.getCoordinatorAnalytics();
      } catch (_) {}
      state = state.copyWith(requests: updatedRequests, analytics: analytics, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> processCoordinatorAction({
    required String requestId,
    required String coordinatorId,
    required String coordinatorName,
    required bool approve,
    bool returnForCorrection = false,
    String? escalateTo,
    String? comment,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repository.coordinatorAction(
        requestId: requestId,
        coordinatorId: coordinatorId,
        coordinatorName: coordinatorName,
        approve: approve,
        returnForCorrection: returnForCorrection,
        escalateTo: escalateTo,
        comment: comment,
      );
      final updatedRequests = state.requests.map((r) => r.id == requestId ? updated : r).toList();
      Map<String, int>? analytics;
      try {
        analytics = await _repository.getCoordinatorAnalytics();
      } catch (_) {}
      state = state.copyWith(requests: updatedRequests, analytics: analytics, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> markNotificationsRead() async {
    final updatedNotifications = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updatedNotifications);
    try {
      await _repository.markNotificationsRead(_currentUserId);
    } catch (_) {}
  }

  Future<bool> deleteNotification(String notificationId) async {
    final updatedNotifications = state.notifications.where((n) => n.id != notificationId).toList();
    state = state.copyWith(notifications: updatedNotifications);
    try {
      await _repository.deleteNotification(notificationId);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteNotificationsBulk({List<String>? ids}) async {
    final updatedNotifications = ids != null
        ? state.notifications.where((n) => !ids.contains(n.id)).toList()
        : <NotificationItem>[];
    state = state.copyWith(notifications: updatedNotifications);
    try {
      await _repository.deleteNotificationsBulk(ids: ids);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final workflowControllerProvider = StateNotifierProvider<WorkflowController, WorkflowState>((ref) {
  final repo = ref.watch(workflowRepositoryProvider);
  final session = ref.watch(authControllerProvider).session;
  final userId = session?.userId ?? '';
  return WorkflowController(repo, userId);
});
