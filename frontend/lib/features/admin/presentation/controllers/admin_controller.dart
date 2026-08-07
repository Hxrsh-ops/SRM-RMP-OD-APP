import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers/dio_provider.dart';
import '../../data/repositories/admin_repository.dart';
import '../../domain/models/admin_models.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminRepository(apiClient: apiClient);
});

// -----------------------------------------------------------------------------
// DASHBOARD CONTROLLER
// -----------------------------------------------------------------------------
final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardMetrics>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getDashboardMetrics();
});

// -----------------------------------------------------------------------------
// USER MANAGEMENT CONTROLLER & PARAMS
// -----------------------------------------------------------------------------
class UserQueryParams {
  final int page;
  final int limit;
  final String? query;
  final String? role;
  final String? departmentId;
  final bool? isActive;

  UserQueryParams({
    this.page = 1,
    this.limit = 20,
    this.query,
    this.role,
    this.departmentId,
    this.isActive,
  });

  UserQueryParams copyWith({
    int? page,
    int? limit,
    String? query,
    String? role,
    String? departmentId,
    bool? isActive,
  }) {
    return UserQueryParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      query: query ?? this.query,
      role: role ?? this.role,
      departmentId: departmentId ?? this.departmentId,
      isActive: isActive ?? this.isActive,
    );
  }
}

final userQueryParamsProvider = StateProvider<UserQueryParams>((ref) => UserQueryParams());

final adminUsersProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final params = ref.watch(userQueryParamsProvider);
  return repo.getUsers(
    page: params.page,
    limit: params.limit,
    query: params.query,
    role: params.role,
    departmentId: params.departmentId,
    isActive: params.isActive,
  );
});

// -----------------------------------------------------------------------------
// DEPARTMENTS CONTROLLER
// -----------------------------------------------------------------------------
final adminDepartmentsProvider = FutureProvider.autoDispose<List<AdminDepartment>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getDepartments();
});

// -----------------------------------------------------------------------------
// FACULTY WORKLOAD CONTROLLER
// -----------------------------------------------------------------------------
final adminFacultyWorkloadProvider = FutureProvider.autoDispose<List<FacultyWorkload>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getFacultyWorkload();
});

// -----------------------------------------------------------------------------
// ORGANIZATION SETTINGS CONTROLLER
// -----------------------------------------------------------------------------
final adminSettingsProvider = FutureProvider.autoDispose<OrganizationSettings>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getOrganizationSettings();
});

// -----------------------------------------------------------------------------
// AUDIT LOGS CONTROLLER
// -----------------------------------------------------------------------------
final auditLogPageProvider = StateProvider<int>((ref) => 1);
final auditLogActionFilterProvider = StateProvider<String?>((ref) => null);

final adminAuditLogsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final page = ref.watch(auditLogPageProvider);
  final action = ref.watch(auditLogActionFilterProvider);
  return repo.getAuditLogs(page: page, action: action);
});

// -----------------------------------------------------------------------------
// SYSTEM MONITORING CONTROLLER
// -----------------------------------------------------------------------------
final adminMonitoringProvider = FutureProvider.autoDispose<SystemHealthMetrics>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getSystemMonitoring();
});

// -----------------------------------------------------------------------------
// SECURITY CENTER CONTROLLER
// -----------------------------------------------------------------------------
final adminSecuritySummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getSecurityCenterSummary();
});
