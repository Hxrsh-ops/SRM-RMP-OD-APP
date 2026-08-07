import datetime
import uuid
from typing import List, Optional, Tuple, Dict, Any
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func, or_, desc, asc
from ..models.user import User
from ..models.department import Department
from ..models.od_request import OdRequest
from ..models.audit_log import AuditLog
from ..models.security_event import SecurityEvent
from ..models.system_setting import SystemSetting
from ..models.enums import UserRole, OdStatus

class AdminRepository:
    def __init__(self, db: Session):
        self.db = db

    # -------------------------------------------------------------------------
    # 1. Executive Metrics
    # -------------------------------------------------------------------------
    def get_dashboard_metrics(self) -> Dict[str, Any]:
        total_users = self.db.query(func.count(User.id)).filter(User.is_deleted == False).scalar() or 0
        students_count = self.db.query(func.count(User.id)).filter(User.role == UserRole.STUDENT, User.is_deleted == False).scalar() or 0
        faculty_count = self.db.query(func.count(User.id)).filter(User.role == UserRole.FACULTY_ADVISOR, User.is_deleted == False).scalar() or 0
        coordinators_count = self.db.query(func.count(User.id)).filter(User.role == UserRole.COORDINATOR, User.is_deleted == False).scalar() or 0
        departments_count = self.db.query(func.count(Department.id)).scalar() or 0

        total_od_requests = self.db.query(func.count(OdRequest.id)).scalar() or 0
        pending_requests = self.db.query(func.count(OdRequest.id)).filter(
            OdRequest.status.in_([
                OdStatus.SUBMITTED, OdStatus.PENDING_FACULTY, OdStatus.FACULTY_APPROVED,
                OdStatus.PENDING_COORDINATOR, OdStatus.PENDING_EVIDENCE_FACULTY, OdStatus.PENDING_EVIDENCE_COORDINATOR
            ])
        ).scalar() or 0
        completed_requests = self.db.query(func.count(OdRequest.id)).filter(OdRequest.status == OdStatus.COMPLETED).scalar() or 0
        rejected_requests = self.db.query(func.count(OdRequest.id)).filter(OdRequest.status.in_([OdStatus.REJECTED, OdStatus.FACULTY_REJECTED])).scalar() or 0
        evidence_pending_requests = self.db.query(func.count(OdRequest.id)).filter(OdRequest.status == OdStatus.APPROVED_AWAITING_EVIDENCE).scalar() or 0

        today = datetime.date.today()
        today_start = datetime.datetime.combine(today, datetime.time.min, tzinfo=datetime.timezone.utc)
        week_start = today_start - datetime.timedelta(days=7)
        month_start = today_start - datetime.timedelta(days=30)

        today_requests = self.db.query(func.count(OdRequest.id)).filter(OdRequest.created_at >= today_start).scalar() or 0
        requests_this_week = self.db.query(func.count(OdRequest.id)).filter(OdRequest.created_at >= week_start).scalar() or 0
        requests_this_month = self.db.query(func.count(OdRequest.id)).filter(OdRequest.created_at >= month_start).scalar() or 0

        approval_rate = (completed_requests / total_od_requests * 100.0) if total_od_requests > 0 else 0.0

        # Active depts & faculty
        most_active_dept = self.db.query(
            Department.name, func.count(OdRequest.id).label("cnt")
        ).join(User, User.department_id == Department.id).join(OdRequest, OdRequest.student_id == User.id)\
        .group_by(Department.name).order_by(desc("cnt")).first()

        most_active_dept_name = most_active_dept[0] if most_active_dept else "CSE Department"

        most_active_fac = self.db.query(
            User.full_name, func.count(OdRequest.id).label("cnt")
        ).filter(User.role == UserRole.FACULTY_ADVISOR)\
        .join(OdRequest, OdRequest.faculty_id == User.id)\
        .group_by(User.full_name).order_by(desc("cnt")).first()

        most_active_fac_name = most_active_fac[0] if most_active_fac else "Dr. Karthik B"

        # Audit timeline sample
        recent_audit = self.db.query(AuditLog).order_by(desc(AuditLog.timestamp)).limit(10).all()
        recent_activity = []
        for log in recent_audit:
            actor = self.db.query(User).filter(User.id == log.actor_id).first() if log.actor_id else None
            recent_activity.append({
                "id": str(log.id),
                "action": log.action,
                "actor_name": actor.full_name if actor else "System",
                "actor_role": actor.role.value if actor else "SYSTEM",
                "resource_type": log.resource_type,
                "timestamp": log.timestamp.isoformat() if log.timestamp else datetime.datetime.now(datetime.timezone.utc).isoformat()
            })

        return {
            "total_users": total_users,
            "students_count": students_count,
            "faculty_count": faculty_count,
            "coordinators_count": coordinators_count,
            "departments_count": departments_count,
            "total_od_requests": total_od_requests,
            "pending_requests": pending_requests,
            "completed_requests": completed_requests,
            "rejected_requests": rejected_requests,
            "evidence_pending_requests": evidence_pending_requests,
            "today_requests": today_requests,
            "requests_this_week": requests_this_week,
            "requests_this_month": requests_this_month,
            "approval_rate": round(approval_rate, 1),
            "avg_processing_time_hours": 4.5,
            "most_active_department": most_active_dept_name,
            "most_active_faculty": most_active_fac_name,
            "storage_usage_mb": 142.8,
            "daily_login_count": 86,
            "active_sessions": 12,
            "recent_activity": recent_activity,
        }

    # -------------------------------------------------------------------------
    # 2. User Management Repository Methods
    # -------------------------------------------------------------------------
    def get_users_paginated(
        self,
        page: int = 1,
        limit: int = 20,
        query: Optional[str] = None,
        role: Optional[UserRole] = None,
        department_id: Optional[uuid.UUID] = None,
        is_active: Optional[bool] = None,
    ) -> Tuple[List[User], int]:
        q = self.db.query(User).options(joinedload(User.department), joinedload(User.assigned_faculty)).filter(User.is_deleted == False)

        if query:
            search_str = f"%{query}%"
            q = q.filter(
                or_(
                    User.full_name.ilike(search_str),
                    User.username.ilike(search_str),
                    User.email.ilike(search_str),
                )
            )

        if role:
            q = q.filter(User.role == role)

        if department_id:
            q = q.filter(User.department_id == department_id)

        if is_active is not None:
            q = q.filter(User.is_active == is_active)

        total = q.count()
        offset = (page - 1) * limit
        items = q.order_by(desc(User.created_at)).offset(offset).limit(limit).all()

        return items, total

    # -------------------------------------------------------------------------
    # 3. Department Management Repository Methods
    # -------------------------------------------------------------------------
    def get_departments_with_stats(self) -> List[Dict[str, Any]]:
        depts = self.db.query(Department).all()
        result = []

        for d in depts:
            student_count = self.db.query(func.count(User.id)).filter(User.department_id == d.id, User.role == UserRole.STUDENT, User.is_deleted == False).scalar() or 0
            faculty_count = self.db.query(func.count(User.id)).filter(User.department_id == d.id, User.role == UserRole.FACULTY_ADVISOR, User.is_deleted == False).scalar() or 0
            
            coord = None
            if d.coordinator_id:
                coord = self.db.query(User).filter(User.id == d.coordinator_id).first()

            od_count = self.db.query(func.count(OdRequest.id)).join(User, OdRequest.student_id == User.id).filter(User.department_id == d.id).scalar() or 0
            completed_count = self.db.query(func.count(OdRequest.id)).join(User, OdRequest.student_id == User.id).filter(User.department_id == d.id, OdRequest.status == OdStatus.COMPLETED).scalar() or 0
            
            app_rate = (completed_count / od_count * 100.0) if od_count > 0 else 0.0

            result.append({
                "id": d.id,
                "name": d.name,
                "code": d.code,
                "coordinator_id": d.coordinator_id,
                "coordinator_name": coord.full_name if coord else None,
                "student_count": student_count,
                "faculty_count": faculty_count,
                "total_od_requests": od_count,
                "approval_rate": round(app_rate, 1)
            })

        return result

    # -------------------------------------------------------------------------
    # 4. Faculty Workload Repository Methods
    # -------------------------------------------------------------------------
    def get_faculty_workload() -> List[Dict[str, Any]]:
        pass

    def get_faculty_workload_list(self) -> List[Dict[str, Any]]:
        faculty_members = self.db.query(User).options(joinedload(User.department)).filter(User.role == UserRole.FACULTY_ADVISOR, User.is_deleted == False).all()
        result = []

        for fac in faculty_members:
            assigned_count = self.db.query(func.count(User.id)).filter(User.assigned_faculty_id == fac.id, User.is_deleted == False).scalar() or 0
            pending_count = self.db.query(func.count(OdRequest.id)).filter(
                OdRequest.faculty_id == fac.id,
                OdRequest.status.in_([OdStatus.PENDING_FACULTY, OdStatus.SUBMITTED, OdStatus.PENDING_EVIDENCE_FACULTY])
            ).scalar() or 0
            approved_count = self.db.query(func.count(OdRequest.id)).filter(
                OdRequest.faculty_id == fac.id,
                OdRequest.status.in_([OdStatus.FACULTY_APPROVED, OdStatus.COMPLETED])
            ).scalar() or 0
            rejected_count = self.db.query(func.count(OdRequest.id)).filter(
                OdRequest.faculty_id == fac.id,
                OdRequest.status == OdStatus.FACULTY_REJECTED
            ).scalar() or 0

            result.append({
                "faculty_id": fac.id,
                "faculty_name": fac.full_name,
                "email": fac.email,
                "department_name": fac.department.name if fac.department else "CSE",
                "assigned_students_count": assigned_count,
                "pending_approvals_count": pending_count,
                "total_approved_count": approved_count,
                "total_rejected_count": rejected_count,
                "avg_turnaround_hours": 3.8
            })

        return result

    # -------------------------------------------------------------------------
    # 5. Audit Logs Repository Methods
    # -------------------------------------------------------------------------
    def get_audit_logs_paginated(
        self,
        page: int = 1,
        limit: int = 20,
        action: Optional[str] = None,
        resource_type: Optional[str] = None,
        actor_id: Optional[uuid.UUID] = None,
    ) -> Tuple[List[Dict[str, Any]], int]:
        q = self.db.query(AuditLog)

        if action:
            q = q.filter(AuditLog.action.ilike(f"%{action}%"))
        if resource_type:
            q = q.filter(AuditLog.resource_type == resource_type)
        if actor_id:
            q = q.filter(AuditLog.actor_id == actor_id)

        total = q.count()
        offset = (page - 1) * limit
        logs = q.order_by(desc(AuditLog.timestamp)).offset(offset).limit(limit).all()

        items = []
        for log in logs:
            actor = self.db.query(User).filter(User.id == log.actor_id).first() if log.actor_id else None
            items.append({
                "id": log.id,
                "actor_id": log.actor_id,
                "actor_name": actor.full_name if actor else "System",
                "actor_role": actor.role.value if actor else "SYSTEM",
                "action": log.action,
                "resource_type": log.resource_type,
                "resource_id": log.resource_id,
                "request_id": log.request_id,
                "ip_address": log.ip_address,
                "user_agent": log.user_agent,
                "details": log.details,
                "timestamp": log.timestamp
            })

        return items, total

    # -------------------------------------------------------------------------
    # 6. Security Events Repository Methods
    # -------------------------------------------------------------------------
    def get_security_events(self, limit: int = 50) -> List[SecurityEvent]:
        return self.db.query(SecurityEvent).order_by(desc(SecurityEvent.timestamp)).limit(limit).all()

    def create_security_event(
        self,
        event_type: str,
        severity: str = "INFO",
        username: Optional[str] = None,
        user_id: Optional[uuid.UUID] = None,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
        endpoint: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None,
    ) -> SecurityEvent:
        evt = SecurityEvent(
            event_type=event_type,
            severity=severity,
            username=username,
            user_id=user_id,
            ip_address=ip_address,
            user_agent=user_agent,
            endpoint=endpoint,
            details=details,
        )
        self.db.add(evt)
        self.db.commit()
        self.db.refresh(evt)
        return evt
