// Admin domain models for Enterprise Super Admin Portal

// -----------------------------------------------------------------------------
// DASHBOARD METRICS
// -----------------------------------------------------------------------------
class AdminDashboardMetrics {
  final int totalUsers;
  final int studentsCount;
  final int facultyCount;
  final int coordinatorsCount;
  final int departmentsCount;

  final int totalOdRequests;
  final int pendingRequests;
  final int completedRequests;
  final int rejectedRequests;
  final int evidencePendingRequests;

  final int todayRequests;
  final int requestsThisWeek;
  final int requestsThisMonth;

  final double approvalRate;
  final double avgProcessingTimeHours;
  final String mostActiveDepartment;
  final String mostActiveFaculty;

  final double storageUsageMb;
  final int dailyLoginCount;
  final int activeSessions;

  final List<Map<String, dynamic>> recentActivity;

  AdminDashboardMetrics({
    required this.totalUsers,
    required this.studentsCount,
    required this.facultyCount,
    required this.coordinatorsCount,
    required this.departmentsCount,
    required this.totalOdRequests,
    required this.pendingRequests,
    required this.completedRequests,
    required this.rejectedRequests,
    required this.evidencePendingRequests,
    required this.todayRequests,
    required this.requestsThisWeek,
    required this.requestsThisMonth,
    required this.approvalRate,
    required this.avgProcessingTimeHours,
    required this.mostActiveDepartment,
    required this.mostActiveFaculty,
    required this.storageUsageMb,
    required this.dailyLoginCount,
    required this.activeSessions,
    required this.recentActivity,
  });

  factory AdminDashboardMetrics.fromJson(Map<String, dynamic> json) {
    return AdminDashboardMetrics(
      totalUsers: json['total_users'] ?? 0,
      studentsCount: json['students_count'] ?? 0,
      facultyCount: json['faculty_count'] ?? 0,
      coordinatorsCount: json['coordinators_count'] ?? 0,
      departmentsCount: json['departments_count'] ?? 0,
      totalOdRequests: json['total_od_requests'] ?? 0,
      pendingRequests: json['pending_requests'] ?? 0,
      completedRequests: json['completed_requests'] ?? 0,
      rejectedRequests: json['rejected_requests'] ?? 0,
      evidencePendingRequests: json['evidence_pending_requests'] ?? 0,
      todayRequests: json['today_requests'] ?? 0,
      requestsThisWeek: json['requests_this_week'] ?? 0,
      requestsThisMonth: json['requests_this_month'] ?? 0,
      approvalRate: (json['approval_rate'] ?? 0).toDouble(),
      avgProcessingTimeHours: (json['avg_processing_time_hours'] ?? 0).toDouble(),
      mostActiveDepartment: json['most_active_department'] ?? 'N/A',
      mostActiveFaculty: json['most_active_faculty'] ?? 'N/A',
      storageUsageMb: (json['storage_usage_mb'] ?? 0).toDouble(),
      dailyLoginCount: json['daily_login_count'] ?? 0,
      activeSessions: json['active_sessions'] ?? 0,
      recentActivity: List<Map<String, dynamic>>.from(json['recent_activity'] ?? []),
    );
  }
}

// -----------------------------------------------------------------------------
// USER MODEL
// -----------------------------------------------------------------------------
class AdminUser {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final String? departmentId;
  final String? departmentName;
  final String? program;
  final String? yearSection;
  final String? assignedFacultyId;
  final String? assignedFacultyName;
  final bool isActive;
  final bool isLocked;
  final int failedLoginAttempts;
  final String? lastLoginAt;
  final String? createdAt;

  AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.departmentId,
    this.departmentName,
    this.program,
    this.yearSection,
    this.assignedFacultyId,
    this.assignedFacultyName,
    required this.isActive,
    required this.isLocked,
    required this.failedLoginAttempts,
    this.lastLoginAt,
    this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? json['fullName']?.toString() ?? '',
      role: json['role']?.toString() ?? 'STUDENT',
      departmentId: json['department_id']?.toString(),
      departmentName: json['department_name']?.toString(),
      program: json['program']?.toString(),
      yearSection: json['year_section']?.toString(),
      assignedFacultyId: json['assigned_faculty_id']?.toString(),
      assignedFacultyName: json['assigned_faculty_name']?.toString(),
      isActive: json['is_active'] == null ? true : (json['is_active'] == true || json['is_active'] == 'true'),
      isLocked: json['is_locked'] == true || json['is_locked'] == 'true',
      failedLoginAttempts: json['failed_login_attempts'] is int 
          ? json['failed_login_attempts'] as int 
          : (int.tryParse(json['failed_login_attempts']?.toString() ?? '') ?? 0),
      lastLoginAt: json['last_login_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

// -----------------------------------------------------------------------------
// DEPARTMENT MODEL
// -----------------------------------------------------------------------------
class AdminDepartment {
  final String id;
  final String name;
  final String code;
  final String? coordinatorId;
  final String? coordinatorName;
  final int studentCount;
  final int facultyCount;
  final int totalOdRequests;
  final double approvalRate;

  AdminDepartment({
    required this.id,
    required this.name,
    required this.code,
    this.coordinatorId,
    this.coordinatorName,
    required this.studentCount,
    required this.facultyCount,
    required this.totalOdRequests,
    required this.approvalRate,
  });

  factory AdminDepartment.fromJson(Map<String, dynamic> json) {
    return AdminDepartment(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      coordinatorId: json['coordinator_id'],
      coordinatorName: json['coordinator_name'],
      studentCount: json['student_count'] ?? 0,
      facultyCount: json['faculty_count'] ?? 0,
      totalOdRequests: json['total_od_requests'] ?? 0,
      approvalRate: (json['approval_rate'] ?? 0).toDouble(),
    );
  }
}

// -----------------------------------------------------------------------------
// FACULTY WORKLOAD MODEL
// -----------------------------------------------------------------------------
class FacultyWorkload {
  final String facultyId;
  final String facultyName;
  final String email;
  final String? departmentName;
  final int assignedStudentsCount;
  final int pendingApprovalsCount;
  final int totalApprovedCount;
  final int totalRejectedCount;
  final double avgTurnaroundHours;

  FacultyWorkload({
    required this.facultyId,
    required this.facultyName,
    required this.email,
    this.departmentName,
    required this.assignedStudentsCount,
    required this.pendingApprovalsCount,
    required this.totalApprovedCount,
    required this.totalRejectedCount,
    required this.avgTurnaroundHours,
  });

  factory FacultyWorkload.fromJson(Map<String, dynamic> json) {
    return FacultyWorkload(
      facultyId: json['faculty_id'] ?? '',
      facultyName: json['faculty_name'] ?? '',
      email: json['email'] ?? '',
      departmentName: json['department_name'],
      assignedStudentsCount: json['assigned_students_count'] ?? 0,
      pendingApprovalsCount: json['pending_approvals_count'] ?? 0,
      totalApprovedCount: json['total_approved_count'] ?? 0,
      totalRejectedCount: json['total_rejected_count'] ?? 0,
      avgTurnaroundHours: (json['avg_turnaround_hours'] ?? 0).toDouble(),
    );
  }
}

// -----------------------------------------------------------------------------
// ORGANIZATION SETTINGS MODEL
// -----------------------------------------------------------------------------
class OrganizationSettings {
  final String academicYear;
  final String currentSemester;
  final int maxFileSizeMb;
  final List<String> allowedFileTypes;
  final bool requireEvidence;
  final int jwtExpirationMinutes;
  final bool notificationEmailEnabled;
  final String systemBrandingTitle;
  final String primaryColorHex;
  final bool maintenanceMode;
  final String environmentInfo;

  final String workflowMode;
  final int hodAutoEscalationDays;
  final bool allowCoordinatorEscalationToHod;
  final bool allowHodEscalationToDean;

  OrganizationSettings({
    required this.academicYear,
    required this.currentSemester,
    required this.maxFileSizeMb,
    required this.allowedFileTypes,
    required this.requireEvidence,
    required this.jwtExpirationMinutes,
    required this.notificationEmailEnabled,
    required this.systemBrandingTitle,
    required this.primaryColorHex,
    required this.maintenanceMode,
    required this.environmentInfo,
    this.workflowMode = 'STANDARD',
    this.hodAutoEscalationDays = 0,
    this.allowCoordinatorEscalationToHod = true,
    this.allowHodEscalationToDean = true,
  });

  factory OrganizationSettings.fromJson(Map<String, dynamic> json) {
    return OrganizationSettings(
      academicYear: json['academic_year'] ?? '2025-2026',
      currentSemester: json['current_semester'] ?? 'Even Semester',
      maxFileSizeMb: json['max_file_size_mb'] ?? 10,
      allowedFileTypes: List<String>.from(json['allowed_file_types'] ?? ['pdf', 'jpg', 'png']),
      requireEvidence: json['require_evidence'] ?? true,
      jwtExpirationMinutes: json['jwt_expiration_minutes'] ?? 1440,
      notificationEmailEnabled: json['notification_email_enabled'] ?? true,
      systemBrandingTitle: json['system_branding_title'] ?? 'SRM RMP OD Platform',
      primaryColorHex: json['primary_color_hex'] ?? '#1A365D',
      maintenanceMode: json['maintenance_mode'] ?? false,
      environmentInfo: json['environment_info'] ?? 'Production-Ready Enterprise',
      workflowMode: json['workflow_mode'] ?? 'STANDARD',
      hodAutoEscalationDays: json['hod_auto_escalation_days'] ?? 0,
      allowCoordinatorEscalationToHod: json['allow_coordinator_escalation_to_hod'] ?? true,
      allowHodEscalationToDean: json['allow_hod_escalation_to_dean'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'academic_year': academicYear,
    'current_semester': currentSemester,
    'max_file_size_mb': maxFileSizeMb,
    'allowed_file_types': allowedFileTypes,
    'require_evidence': requireEvidence,
    'jwt_expiration_minutes': jwtExpirationMinutes,
    'notification_email_enabled': notificationEmailEnabled,
    'system_branding_title': systemBrandingTitle,
    'primary_color_hex': primaryColorHex,
    'maintenance_mode': maintenanceMode,
    'environment_info': environmentInfo,
    'workflow_mode': workflowMode,
    'hod_auto_escalation_days': hodAutoEscalationDays,
    'allow_coordinator_escalation_to_hod': allowCoordinatorEscalationToHod,
    'allow_hod_escalation_to_dean': allowHodEscalationToDean,
  };
}

// -----------------------------------------------------------------------------
// AUDIT LOG MODEL
// -----------------------------------------------------------------------------
class AuditLogEntry {
  final String id;
  final String? actorId;
  final String actorName;
  final String actorRole;
  final String action;
  final String resourceType;
  final String? resourceId;
  final String? ipAddress;
  final Map<String, dynamic>? details;
  final String timestamp;

  AuditLogEntry({
    required this.id,
    this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.resourceType,
    this.resourceId,
    this.ipAddress,
    this.details,
    required this.timestamp,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] ?? '',
      actorId: json['actor_id'],
      actorName: json['actor_name'] ?? 'System',
      actorRole: json['actor_role'] ?? 'SYSTEM',
      action: json['action'] ?? '',
      resourceType: json['resource_type'] ?? '',
      resourceId: json['resource_id'],
      ipAddress: json['ip_address'],
      details: json['details'],
      timestamp: json['timestamp'] ?? '',
    );
  }
}

// -----------------------------------------------------------------------------
// SYSTEM HEALTH MODEL
// -----------------------------------------------------------------------------
class SystemHealthMetrics {
  final String status;
  final String apiStatus;
  final String databaseStatus;
  final int dbConnectionCount;
  final double storageUsedMb;
  final double storageFreeMb;
  final double cpuUsagePercent;
  final double memoryUsagePercent;
  final double avgResponseTimeMs;
  final int totalRequests24h;
  final int failedRequests24h;
  final int activeConnectedUsers;
  final String version;
  final String environment;

  SystemHealthMetrics({
    required this.status,
    required this.apiStatus,
    required this.databaseStatus,
    required this.dbConnectionCount,
    required this.storageUsedMb,
    required this.storageFreeMb,
    required this.cpuUsagePercent,
    required this.memoryUsagePercent,
    required this.avgResponseTimeMs,
    required this.totalRequests24h,
    required this.failedRequests24h,
    required this.activeConnectedUsers,
    required this.version,
    required this.environment,
  });

  factory SystemHealthMetrics.fromJson(Map<String, dynamic> json) {
    return SystemHealthMetrics(
      status: json['status'] ?? 'HEALTHY',
      apiStatus: json['api_status'] ?? 'ONLINE',
      databaseStatus: json['database_status'] ?? 'CONNECTED',
      dbConnectionCount: json['db_connection_count'] ?? 8,
      storageUsedMb: (json['storage_used_mb'] ?? 0).toDouble(),
      storageFreeMb: (json['storage_free_mb'] ?? 0).toDouble(),
      cpuUsagePercent: (json['cpu_usage_percent'] ?? 0).toDouble(),
      memoryUsagePercent: (json['memory_usage_percent'] ?? 0).toDouble(),
      avgResponseTimeMs: (json['avg_response_time_ms'] ?? 0).toDouble(),
      totalRequests24h: json['total_requests_24h'] ?? 0,
      failedRequests24h: json['failed_requests_24h'] ?? 0,
      activeConnectedUsers: json['active_connected_users'] ?? 0,
      version: json['version'] ?? 'v1.0-enterprise',
      environment: json['environment'] ?? 'Production',
    );
  }
}

// -----------------------------------------------------------------------------
// SECURITY EVENT MODEL
// -----------------------------------------------------------------------------
class SecurityEventEntry {
  final String id;
  final String eventType;
  final String severity;
  final String? username;
  final String? ipAddress;
  final Map<String, dynamic>? details;
  final String timestamp;

  SecurityEventEntry({
    required this.id,
    required this.eventType,
    required this.severity,
    this.username,
    this.ipAddress,
    this.details,
    required this.timestamp,
  });

  factory SecurityEventEntry.fromJson(Map<String, dynamic> json) {
    return SecurityEventEntry(
      id: json['id'] ?? '',
      eventType: json['event_type'] ?? '',
      severity: json['severity'] ?? 'INFO',
      username: json['username'],
      ipAddress: json['ip_address'],
      details: json['details'],
      timestamp: json['timestamp'] ?? '',
    );
  }
}
