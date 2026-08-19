from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field, ConfigDict
from uuid import UUID
from ..models.enums import UserRole, OdStatus

# -----------------------------------------------------------------------------
# DASHBOARD METRICS SCHEMAS
# -----------------------------------------------------------------------------
class AdminDashboardMetricsResponse(BaseModel):
    total_users: int
    students_count: int
    faculty_count: int
    coordinators_count: int
    departments_count: int
    
    total_od_requests: int
    pending_requests: int
    completed_requests: int
    rejected_requests: int
    evidence_pending_requests: int
    
    today_requests: int
    requests_this_week: int
    requests_this_month: int
    
    approval_rate: float
    avg_processing_time_hours: float
    most_active_department: str
    most_active_faculty: str
    
    storage_usage_mb: float
    daily_login_count: int
    active_sessions: int
    
    recent_activity: List[Dict[str, Any]]

# -----------------------------------------------------------------------------
# USER MANAGEMENT SCHEMAS
# -----------------------------------------------------------------------------
class UserResponseSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    username: str
    email: EmailStr
    full_name: str
    role: UserRole
    department_id: Optional[UUID] = None
    department_name: Optional[str] = None
    program: Optional[str] = None
    year_section: Optional[str] = None
    assigned_faculty_id: Optional[UUID] = None
    assigned_faculty_name: Optional[str] = None
    is_active: bool
    is_locked: bool
    force_password_change: bool = False
    failed_login_attempts: int
    last_login_at: Optional[datetime] = None
    created_at: Optional[datetime] = None

class UserCreateSchema(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    full_name: str = Field(..., min_length=2, max_length=100)
    password: str = Field(..., min_length=6)
    role: UserRole
    department_id: Optional[UUID] = None
    program: Optional[str] = None
    year_section: Optional[str] = None
    assigned_faculty_id: Optional[UUID] = None

class UserUpdateSchema(BaseModel):
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None
    role: Optional[UserRole] = None
    department_id: Optional[UUID] = None
    program: Optional[str] = None
    year_section: Optional[str] = None
    assigned_faculty_id: Optional[UUID] = None

class UserStatusUpdateSchema(BaseModel):
    is_active: Optional[bool] = None
    is_locked: Optional[bool] = None

class ResetPasswordSchema(BaseModel):
    new_password: str = Field(..., min_length=6)

class BulkUserActionSchema(BaseModel):
    user_ids: List[UUID]
    action: str # "deactivate", "activate", "delete", "assign_department", "assign_faculty"
    department_id: Optional[UUID] = None
    assigned_faculty_id: Optional[UUID] = None

class PaginatedUsersResponse(BaseModel):
    items: List[UserResponseSchema]
    total: int
    page: int
    limit: int
    total_pages: int

# -----------------------------------------------------------------------------
# DEPARTMENT SCHEMAS
# -----------------------------------------------------------------------------
class DepartmentResponseSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    code: str
    coordinator_id: Optional[UUID] = None
    coordinator_name: Optional[str] = None
    student_count: int = 0
    faculty_count: int = 0
    total_od_requests: int = 0
    approval_rate: float = 0.0

class DepartmentCreateSchema(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    code: str = Field(..., min_length=2, max_length=10)
    coordinator_id: Optional[UUID] = None

class DepartmentUpdateSchema(BaseModel):
    name: Optional[str] = None
    code: Optional[str] = None
    coordinator_id: Optional[UUID] = None

# -----------------------------------------------------------------------------
# FACULTY SCHEMAS
# -----------------------------------------------------------------------------
class FacultyWorkloadSchema(BaseModel):
    faculty_id: UUID
    faculty_name: str
    email: str
    department_name: Optional[str] = None
    assigned_students_count: int
    pending_approvals_count: int
    total_approved_count: int
    total_rejected_count: int
    avg_turnaround_hours: float

class FacultyTransferSchema(BaseModel):
    source_faculty_id: UUID
    target_faculty_id: UUID
    student_ids: Optional[List[UUID]] = None # If empty, transfers all students

# -----------------------------------------------------------------------------
# ORGANIZATION SETTINGS SCHEMAS
# -----------------------------------------------------------------------------
class OrganizationSettingsSchema(BaseModel):
    academic_year: str = "2025-2026"
    current_semester: str = "Even Semester"
    max_file_size_mb: int = 10
    allowed_file_types: List[str] = ["pdf", "jpg", "jpeg", "png", "docx"]
    require_evidence: bool = True
    jwt_expiration_minutes: int = 1440
    notification_email_enabled: bool = True
    system_branding_title: str = "SRM RMP OD Platform"
    primary_color_hex: str = "#1A365D"
    maintenance_mode: bool = False
    environment_info: str = "Production-Ready Enterprise"

# -----------------------------------------------------------------------------
# AUDIT LOG SCHEMAS
# -----------------------------------------------------------------------------
class AuditLogResponseSchema(BaseModel):
    id: UUID
    actor_id: Optional[UUID] = None
    actor_name: Optional[str] = None
    actor_role: Optional[str] = None
    action: str
    resource_type: str
    resource_id: Optional[str] = None
    request_id: Optional[str] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    details: Optional[Dict[str, Any]] = None
    timestamp: datetime

class PaginatedAuditLogsResponse(BaseModel):
    items: List[AuditLogResponseSchema]
    total: int
    page: int
    limit: int
    total_pages: int

# -----------------------------------------------------------------------------
# SYSTEM MONITORING SCHEMAS
# -----------------------------------------------------------------------------
class SystemHealthResponseSchema(BaseModel):
    status: str
    api_status: str
    database_status: str
    db_connection_count: int
    storage_used_mb: float
    storage_free_mb: float
    cpu_usage_percent: float
    memory_usage_percent: float
    avg_response_time_ms: float
    total_requests_24h: int
    failed_requests_24h: int
    active_connected_users: int
    version: str = "v1.0-enterprise"
    environment: str

# -----------------------------------------------------------------------------
# SECURITY CENTER SCHEMAS
# -----------------------------------------------------------------------------
class SecurityEventResponseSchema(BaseModel):
    id: UUID
    event_type: str
    severity: str
    username: Optional[str] = None
    user_id: Optional[UUID] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    endpoint: Optional[str] = None
    details: Optional[Dict[str, Any]] = None
    timestamp: datetime

class SecurityCenterSummaryResponse(BaseModel):
    failed_logins_24h: int
    locked_accounts_count: int
    expired_jwt_count_24h: int
    role_violations_24h: int
    upload_violations_24h: int
    recent_events: List[SecurityEventResponseSchema]

# -----------------------------------------------------------------------------
# ANALYTICS SCHEMAS
# -----------------------------------------------------------------------------
class AnalyticsSummarySchema(BaseModel):
    monthly_trends: List[Dict[str, Any]]
    department_comparisons: List[Dict[str, Any]]
    faculty_performance: List[Dict[str, Any]]
    status_distribution: Dict[str, int]

class AssignFacultyRequestSchema(BaseModel):
    faculty_id: UUID
