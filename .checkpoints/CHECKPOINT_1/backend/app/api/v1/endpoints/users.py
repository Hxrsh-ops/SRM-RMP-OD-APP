import uuid
from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from ....core.database import get_db
from ....core.exceptions import NotFoundException, PermissionDeniedException
from ....schemas.user import UserResponse
from ...dependencies import get_current_user, require_roles
from ....models.user import User
from ....models.enums import UserRole, OdStatus
from ....models.od_request import OdRequest
from ....repositories.user_repository import UserRepository
from ....repositories.od_request_repository import OdRequestRepository
from .od_requests import _build_od_response

router = APIRouter()

@router.get("/profile", response_model=UserResponse)
def get_user_profile(current_user: User = Depends(get_current_user)):
    return current_user

@router.get("/advisees", dependencies=[Depends(require_roles([UserRole.FACULTY_ADVISOR, UserRole.MASTER_ADMIN, UserRole.HOD, UserRole.COORDINATOR]))])
def get_faculty_advisees(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> List[Dict[str, Any]]:
    # Get all students assigned to this faculty advisor
    if current_user.role == UserRole.FACULTY_ADVISOR:
        students = db.query(User).filter(
            User.assigned_faculty_id == current_user.id,
            User.role == UserRole.STUDENT,
            User.is_deleted == False
        ).order_by(User.full_name.asc()).all()
    elif current_user.department_id:
        students = db.query(User).filter(
            User.department_id == current_user.department_id,
            User.role == UserRole.STUDENT,
            User.is_deleted == False
        ).order_by(User.full_name.asc()).all()
    else:
        students = db.query(User).filter(
            User.role == UserRole.STUDENT,
            User.is_deleted == False
        ).order_by(User.full_name.asc()).all()

    od_repo = OdRequestRepository(db)
    result = []
    for st in students:
        st_reqs = od_repo.list_by_student(st.id)
        active_count = sum(1 for r in st_reqs if r.status not in (OdStatus.COMPLETED, OdStatus.REJECTED, OdStatus.FACULTY_REJECTED))
        dept_name = st.department.name if st.department else "General"

        result.append({
            "id": str(st.id),
            "full_name": st.full_name,
            "username": st.username,
            "email": st.email,
            "program": st.program or "B.Tech CSE",
            "year_section": st.year_section or "2nd Year",
            "department_name": dept_name,
            "cgpa": st.cgpa if hasattr(st, "cgpa") else 8.5,
            "attendance_percentage": st.attendance_percentage if hasattr(st, "attendance_percentage") else 88.0,
            "residence_type": st.residence_type if hasattr(st, "residence_type") else "Day Scholar",
            "is_active": st.is_active,
            "active_od_count": active_count,
            "total_od_count": len(st_reqs),
        })

    return result

@router.get("/advisees/{student_id}/records", dependencies=[Depends(require_roles([UserRole.FACULTY_ADVISOR, UserRole.MASTER_ADMIN, UserRole.HOD, UserRole.COORDINATOR]))])
def get_advisee_records(
    student_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    return _get_student_records_internal(student_id, current_user, db)

@router.get("/students/directory", dependencies=[Depends(require_roles([UserRole.COORDINATOR, UserRole.HOD, UserRole.DEAN, UserRole.MASTER_ADMIN]))])
def get_department_student_directory(
    limit: int = 30,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> List[Dict[str, Any]]:
    """
    Returns unique students who have submitted OD requests routed to or in the department of the approver.
    Sorted with latest OD request at the top, de-duplicated, limited to top 30 students.
    """
    user_repo = UserRepository(db)
    od_repo = OdRequestRepository(db)

    # 1. Fetch OD requests in descending order of creation/update
    all_reqs = od_repo.list_all()
    # Sort newest first
    all_reqs.sort(key=lambda r: r.created_at, reverse=True)

    # Filter to department if user has department_id
    if current_user.department_id and current_user.role in [UserRole.COORDINATOR, UserRole.HOD]:
        from .od_requests import _get_student_dept
        target_dept = str(current_user.department_id)
        relevant_reqs = [r for r in all_reqs if _get_student_dept(r, user_repo) == target_dept]
    else:
        relevant_reqs = all_reqs

    # 2. De-duplicate students in order of latest OD request
    seen_students = set()
    directory_students = []

    for req in relevant_reqs:
        st_id = req.student_id
        if not st_id or st_id in seen_students:
            continue
        seen_students.add(st_id)

        student = user_repo.get_by_id(st_id)
        if not student or student.role != UserRole.STUDENT or student.is_deleted:
            continue

        # Get all OD requests for this student to compute totals
        st_all_reqs = od_repo.list_by_student(student.id)
        active_count = sum(1 for r in st_all_reqs if r.status not in (OdStatus.COMPLETED, OdStatus.REJECTED, OdStatus.FACULTY_REJECTED))
        dept_name = student.department.name if student.department else "General"

        fac_name = None
        if student.assigned_faculty:
            fac_name = student.assigned_faculty.full_name
        elif student.assigned_faculty_id:
            fa = user_repo.get_by_id(student.assigned_faculty_id)
            fac_name = fa.full_name if fa else None

        is_overdue = False
        days_past = 0
        if req.status == OdStatus.APPROVED_AWAITING_EVIDENCE:
            today = datetime.date.today()
            if today > req.end_date:
                is_overdue = True
                days_past = (today - req.end_date).days

        directory_students.append({
            "id": str(student.id),
            "full_name": student.full_name,
            "username": student.username,
            "email": student.email,
            "program": student.program or "B.Tech CSE",
            "year_section": student.year_section or "2nd Year",
            "department_name": dept_name,
            "assigned_faculty_name": fac_name,
            "cgpa": student.cgpa if hasattr(student, "cgpa") else 8.5,
            "attendance_percentage": student.attendance_percentage if hasattr(student, "attendance_percentage") else 88.0,
            "residence_type": student.residence_type if hasattr(student, "residence_type") else "Day Scholar",
            "active_od_count": active_count,
            "total_od_count": len(st_all_reqs),
            "latest_od_request": {
                "id": req.id,
                "reason": req.reason,
                "purpose": req.purpose,
                "duration_days": req.duration_days,
                "start_date": str(req.start_date),
                "end_date": str(req.end_date),
                "status": req.status.value if hasattr(req.status, "value") else str(req.status),
                "is_evidence_overdue": is_overdue,
                "days_past_event": days_past,
                "created_at": req.created_at.isoformat() if req.created_at else None,
            }
        })

        if len(directory_students) >= limit:
            break

    # If fewer than limit, also include department students without requests if available
    if len(directory_students) < limit and current_user.department_id and current_user.role in [UserRole.COORDINATOR, UserRole.HOD]:
        dept_students = db.query(User).filter(
            User.department_id == current_user.department_id,
            User.role == UserRole.STUDENT,
            User.is_deleted == False
        ).all()
        for st in dept_students:
            if st.id not in seen_students:
                seen_students.add(st.id)
                st_all_reqs = od_repo.list_by_student(st.id)
                dept_name = st.department.name if st.department else "General"
                fac_name = st.assigned_faculty.full_name if st.assigned_faculty else None
                directory_students.append({
                    "id": str(st.id),
                    "full_name": st.full_name,
                    "username": st.username,
                    "email": st.email,
                    "program": st.program or "B.Tech CSE",
                    "year_section": st.year_section or "2nd Year",
                    "department_name": dept_name,
                    "assigned_faculty_name": fac_name,
                    "cgpa": st.cgpa if hasattr(st, "cgpa") else 8.5,
                    "attendance_percentage": st.attendance_percentage if hasattr(st, "attendance_percentage") else 88.0,
                    "residence_type": st.residence_type if hasattr(st, "residence_type") else "Day Scholar",
                    "active_od_count": 0,
                    "total_od_count": 0,
                    "latest_od_request": None,
                })
                if len(directory_students) >= limit:
                    break

    return directory_students

@router.get("/students/search", dependencies=[Depends(require_roles([UserRole.COORDINATOR, UserRole.HOD, UserRole.DEAN, UserRole.MASTER_ADMIN, UserRole.FACULTY_ADVISOR]))])
def search_students(
    q: str = "",
    limit: int = 30,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> List[Dict[str, Any]]:
    """
    Global search for any student across the institution by Register Number, Name, Email, Program, Section.
    """
    if not q or not q.strip():
        return []

    user_repo = UserRepository(db)
    od_repo = OdRequestRepository(db)
    query_str = f"%{q.strip()}%"

    matched_students = db.query(User).filter(
        User.role == UserRole.STUDENT,
        User.is_deleted == False,
        (
            User.username.ilike(query_str) |
            User.full_name.ilike(query_str) |
            User.email.ilike(query_str) |
            User.program.ilike(query_str) |
            User.year_section.ilike(query_str)
        )
    ).limit(limit).all()

    result = []
    for st in matched_students:
        st_reqs = od_repo.list_by_student(st.id)
        st_reqs.sort(key=lambda r: r.created_at, reverse=True)
        active_count = sum(1 for r in st_reqs if r.status not in (OdStatus.COMPLETED, OdStatus.REJECTED, OdStatus.FACULTY_REJECTED))
        dept_name = st.department.name if st.department else "General"
        fac_name = st.assigned_faculty.full_name if st.assigned_faculty else None

        latest_req = None
        if st_reqs:
            lr = st_reqs[0]
            is_overdue = False
            days_past = 0
            if lr.status == OdStatus.APPROVED_AWAITING_EVIDENCE:
                today = datetime.date.today()
                if today > lr.end_date:
                    is_overdue = True
                    days_past = (today - lr.end_date).days

            latest_req = {
                "id": lr.id,
                "reason": lr.reason,
                "purpose": lr.purpose,
                "duration_days": lr.duration_days,
                "start_date": str(lr.start_date),
                "end_date": str(lr.end_date),
                "status": lr.status.value if hasattr(lr.status, "value") else str(lr.status),
                "is_evidence_overdue": is_overdue,
                "days_past_event": days_past,
                "created_at": lr.created_at.isoformat() if lr.created_at else None,
            }

        result.append({
            "id": str(st.id),
            "full_name": st.full_name,
            "username": st.username,
            "email": st.email,
            "program": st.program or "B.Tech CSE",
            "year_section": st.year_section or "2nd Year",
            "department_name": dept_name,
            "assigned_faculty_name": fac_name,
            "cgpa": st.cgpa if hasattr(st, "cgpa") else 8.5,
            "attendance_percentage": st.attendance_percentage if hasattr(st, "attendance_percentage") else 88.0,
            "residence_type": st.residence_type if hasattr(st, "residence_type") else "Day Scholar",
            "active_od_count": active_count,
            "total_od_count": len(st_reqs),
            "latest_od_request": latest_req,
        })

    return result

@router.get("/students/{student_id}/records", dependencies=[Depends(require_roles([UserRole.COORDINATOR, UserRole.HOD, UserRole.DEAN, UserRole.MASTER_ADMIN, UserRole.FACULTY_ADVISOR]))])
def get_student_records(
    student_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    return _get_student_records_internal(student_id, current_user, db)

def _get_student_records_internal(student_id: uuid.UUID, current_user: User, db: Session) -> Dict[str, Any]:
    user_repo = UserRepository(db)
    od_repo = OdRequestRepository(db)
    student = user_repo.get_by_id(student_id)
    if not student or student.role != UserRole.STUDENT:
        raise NotFoundException("Student record not found")

    requests = od_repo.list_by_student(student.id)
    requests.sort(key=lambda r: r.created_at, reverse=True)
    serialized_reqs = [_build_od_response(r, user_repo).model_dump(mode="json") for r in requests]

    dept_name = student.department.name if student.department else "General"
    fac_name = student.assigned_faculty.full_name if student.assigned_faculty else None

    student_info = {
        "id": str(student.id),
        "full_name": student.full_name,
        "username": student.username,
        "email": student.email,
        "program": student.program,
        "year_section": student.year_section,
        "department_name": dept_name,
        "assigned_faculty_name": fac_name,
        "cgpa": student.cgpa if hasattr(student, "cgpa") else 8.5,
        "attendance_percentage": student.attendance_percentage if hasattr(student, "attendance_percentage") else 88.0,
        "residence_type": student.residence_type if hasattr(student, "residence_type") else "Day Scholar",
    }

    return {
        "student": student_info,
        "records": serialized_reqs,
        "total_records": len(serialized_reqs),
    }
