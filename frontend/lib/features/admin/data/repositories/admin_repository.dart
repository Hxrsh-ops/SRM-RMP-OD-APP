import '../../../../core/network/api_client.dart';
import '../../domain/models/admin_models.dart';

class AdminRepository {
  final ApiClient apiClient;

  AdminRepository({required this.apiClient});

  Future<AdminDashboardMetrics> getDashboardMetrics() async {
    final response = await apiClient.get('/admin/dashboard/metrics');
    return AdminDashboardMetrics.fromJson(response);
  }

  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String? query,
    String? role,
    String? departmentId,
    bool? isActive,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (query != null && query.isNotEmpty) queryParams['query'] = query;
    if (role != null && role.isNotEmpty) queryParams['role'] = role;
    if (departmentId != null && departmentId.isNotEmpty) queryParams['department_id'] = departmentId;
    if (isActive != null) queryParams['is_active'] = isActive;

    final data = await apiClient.get('/admin/users', queryParameters: queryParams);
    final items = (data['items'] as List).map((e) => AdminUser.fromJson(e)).toList();
    return {
      'items': items,
      'total': data['total'],
      'page': data['page'],
      'total_pages': data['total_pages'],
    };
  }

  Future<AdminUser> createUser(Map<String, dynamic> userData) async {
    final response = await apiClient.post('/admin/users', data: userData);
    return AdminUser.fromJson(response);
  }

  Future<AdminUser> updateUser(String userId, Map<String, dynamic> userData) async {
    final response = await apiClient.put('/admin/users/$userId', data: userData);
    return AdminUser.fromJson(response);
  }

  Future<AdminUser> updateUserStatus(String userId, {bool? isActive, bool? isLocked}) async {
    final payload = <String, dynamic>{};
    if (isActive != null) payload['is_active'] = isActive;
    if (isLocked != null) payload['is_locked'] = isLocked;

    final response = await apiClient.patch('/admin/users/$userId/status', data: payload);
    return AdminUser.fromJson(response);
  }

  Future<void> resetPassword(String userId, String newPassword) async {
    await apiClient.post('/admin/users/$userId/reset-password', data: {'new_password': newPassword});
  }

  Future<void> deleteUser(String userId) async {
    await apiClient.delete('/admin/users/$userId');
  }

  Future<void> bulkUserAction(List<String> userIds, String action, {String? departmentId, String? assignedFacultyId}) async {
    final payload = <String, dynamic>{
      'user_ids': userIds,
      'action': action,
      if (departmentId != null) 'department_id': departmentId,
      if (assignedFacultyId != null) 'assigned_faculty_id': assignedFacultyId,
    };
    await apiClient.post('/admin/users/bulk', data: payload);
  }

  Future<List<AdminDepartment>> getDepartments() async {
    final List response = await apiClient.get('/admin/departments');
    return response.map((e) => AdminDepartment.fromJson(e)).toList();
  }

  Future<AdminDepartment> createDepartment(Map<String, dynamic> deptData) async {
    final response = await apiClient.post('/admin/departments', data: deptData);
    return AdminDepartment.fromJson(response);
  }

  Future<AdminDepartment> updateDepartment(String deptId, Map<String, dynamic> deptData) async {
    final response = await apiClient.put('/admin/departments/$deptId', data: deptData);
    return AdminDepartment.fromJson(response);
  }

  Future<List<FacultyWorkload>> getFacultyWorkload() async {
    final List response = await apiClient.get('/admin/faculty');
    return response.map((e) => FacultyWorkload.fromJson(e)).toList();
  }

  Future<void> transferFacultyStudents(String sourceId, String targetId, List<String>? studentIds) async {
    final payload = <String, dynamic>{
      'source_faculty_id': sourceId,
      'target_faculty_id': targetId,
      if (studentIds != null) 'student_ids': studentIds,
    };
    await apiClient.post('/admin/faculty/transfer', data: payload);
  }

  Future<OrganizationSettings> getOrganizationSettings() async {
    final response = await apiClient.get('/admin/settings');
    return OrganizationSettings.fromJson(response);
  }

  Future<OrganizationSettings> updateOrganizationSettings(OrganizationSettings settings) async {
    final response = await apiClient.put('/admin/settings', data: settings.toJson());
    return OrganizationSettings.fromJson(response);
  }

  Future<Map<String, dynamic>> getAuditLogs({int page = 1, int limit = 20, String? action, String? resourceType}) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (action != null && action.isNotEmpty) queryParams['action'] = action;
    if (resourceType != null && resourceType.isNotEmpty) queryParams['resource_type'] = resourceType;

    final data = await apiClient.get('/admin/audit-logs', queryParameters: queryParams);
    final items = (data['items'] as List).map((e) => AuditLogEntry.fromJson(e)).toList();
    return {
      'items': items,
      'total': data['total'],
      'page': data['page'],
      'total_pages': data['total_pages'],
    };
  }

  Future<SystemHealthMetrics> getSystemMonitoring() async {
    final response = await apiClient.get('/admin/monitoring');
    return SystemHealthMetrics.fromJson(response);
  }

  Future<Map<String, dynamic>> getSecurityCenterSummary() async {
    final data = await apiClient.get('/admin/security/summary');
    final events = (data['recent_events'] as List).map((e) => SecurityEventEntry.fromJson(e)).toList();
    return {
      'failed_logins_24h': data['failed_logins_24h'] ?? 0,
      'locked_accounts_count': data['locked_accounts_count'] ?? 0,
      'expired_jwt_count_24h': data['expired_jwt_count_24h'] ?? 0,
      'role_violations_24h': data['role_violations_24h'] ?? 0,
      'upload_violations_24h': data['upload_violations_24h'] ?? 0,
      'recent_events': events,
    };
  }

  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    final response = await apiClient.get('/admin/analytics');
    return response as Map<String, dynamic>;
  }

  Future<List<AdminUser>> getAvailableFaculty(String studentId) async {
    final response = await apiClient.get('/admin/students/$studentId/available-faculty');
    final list = response as List;
    return list.map((json) => AdminUser.fromJson(json)).toList();
  }

  Future<AdminUser> assignFaculty(String studentId, String facultyId) async {
    final response = await apiClient.put('/admin/students/$studentId/assign-faculty', data: {
      'faculty_id': facultyId,
    });
    return AdminUser.fromJson(response);
  }

  Future<AdminUser> unassignFaculty(String studentId) async {
    final response = await apiClient.delete('/admin/students/$studentId/assign-faculty');
    return AdminUser.fromJson(response);
  }

  Future<List<AdminUser>> getAssignedStudents(String facultyId) async {
    final response = await apiClient.get('/admin/faculty/$facultyId/students');
    final list = response as List;
    return list.map((json) => AdminUser.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getUserProfileAndRecords(String userId) async {
    final response = await apiClient.get('/admin/users/$userId/records');
    return response as Map<String, dynamic>;
  }

  Future<void> deleteOdRequest(String requestId) async {
    await apiClient.delete('/admin/od-requests/$requestId');
  }

  Future<void> deleteAllUserOdRequests(String userId) async {
    await apiClient.delete('/admin/users/$userId/od-requests');
  }

  Future<void> deleteSecurityEvent(String eventId) async {
    await apiClient.delete('/admin/security/events/$eventId');
  }

  Future<void> clearAllSecurityEvents() async {
    await apiClient.delete('/admin/security/events');
  }

  Future<List<ClassSectionModel>> getClassSections({String? departmentId, int? academicYear}) async {
    final queryParams = <String, dynamic>{};
    if (departmentId != null && departmentId.isNotEmpty) queryParams['department_id'] = departmentId;
    if (academicYear != null) queryParams['academic_year'] = academicYear;

    final List response = await apiClient.get('/class-sections', queryParameters: queryParams);
    return response.map((e) => ClassSectionModel.fromJson(e)).toList();
  }

  Future<ClassSectionModel> createClassSection(Map<String, dynamic> data) async {
    final response = await apiClient.post('/class-sections', data: data);
    return ClassSectionModel.fromJson(response);
  }

  Future<ClassSectionModel> assignClassSectionFA(String sectionId, {String? facultyAdvisorId, String? section, int? academicYear, String? batch}) async {
    final payload = <String, dynamic>{};
    if (facultyAdvisorId != null) payload['faculty_advisor_id'] = facultyAdvisorId;
    if (section != null) payload['section'] = section;
    if (academicYear != null) payload['academic_year'] = academicYear;
    if (batch != null) payload['batch'] = batch;

    final response = await apiClient.put('/class-sections/$sectionId/assign-fa', data: payload);
    return ClassSectionModel.fromJson(response);
  }

  Future<void> deleteClassSection(String sectionId) async {
    await apiClient.delete('/class-sections/$sectionId');
  }

  Future<List<SharedClearanceModel>> getSharedClearances() async {
    final List response = await apiClient.get('/od-requests/shared-clearances');
    return response.map((e) => SharedClearanceModel.fromJson(e)).toList();
  }

  Future<SharedClearanceModel> shareClearance(String odRequestId, String facultyEmail, {String? notes}) async {
    final response = await apiClient.post(
      '/od-requests/$odRequestId/share-clearance',
      data: {
        'faculty_email': facultyEmail,
        if (notes != null) 'notes': notes,
      },
    );
    return SharedClearanceModel.fromJson(response);
  }

  Future<SharedClearanceModel> acknowledgeClearance(String shareId) async {
    final response = await apiClient.post('/od-requests/shared-clearances/$shareId/acknowledge');
    return SharedClearanceModel.fromJson(response);
  }
}
