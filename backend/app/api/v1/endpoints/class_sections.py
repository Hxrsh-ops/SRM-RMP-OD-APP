from typing import List, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ....core.database import get_db
from ...dependencies import get_current_user, require_roles
from ....models.user import User
from ....models.enums import UserRole
from ....models.department import Department
from ....models.class_section import ClassSection
from ....schemas.class_section import ClassSectionCreate, ClassSectionUpdate, ClassSectionResponse

router = APIRouter()

def _build_section_response(s: ClassSection, db: Session) -> ClassSectionResponse:
    fa_user = db.query(User).filter(User.id == s.faculty_advisor_id).first() if s.faculty_advisor_id else None
    dept = db.query(Department).filter(Department.id == s.department_id).first() if s.department_id else None
    student_count = db.query(User).filter(User.class_section_id == s.id, User.is_deleted == False).count()
    
    return ClassSectionResponse(
        id=s.id,
        department_id=s.department_id,
        academic_year=s.academic_year,
        section=s.section,
        batch=s.batch,
        program=s.program,
        faculty_advisor_id=s.faculty_advisor_id,
        created_at=s.created_at,
        faculty_advisor_name=fa_user.full_name if fa_user else None,
        faculty_advisor_email=fa_user.email if fa_user else None,
        department_name=dept.name if dept else None,
        student_count=student_count
    )

@router.get("", response_model=List[ClassSectionResponse])
def get_class_sections(
    department_id: Optional[UUID] = None,
    academic_year: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(ClassSection).filter(ClassSection.is_deleted == False)
    if department_id:
        query = query.filter(ClassSection.department_id == department_id)
    elif current_user.role in (UserRole.HOD, UserRole.COORDINATOR, UserRole.FACULTY_ADVISOR) and current_user.department_id:
        query = query.filter(ClassSection.department_id == current_user.department_id)
    
    if academic_year:
        query = query.filter(ClassSection.academic_year == academic_year)
    
    sections = query.order_by(ClassSection.academic_year.asc(), ClassSection.section.asc()).all()
    return [_build_section_response(s, db) for s in sections]

@router.post("", response_model=ClassSectionResponse, status_code=status.HTTP_201_CREATED)
def create_class_section(
    section_in: ClassSectionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.MASTER_ADMIN, UserRole.HOD, UserRole.COORDINATOR])),
):
    dept = db.query(Department).filter(Department.id == section_in.department_id, Department.is_deleted == False).first()
    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")
    
    # Check duplicate section in same year/department
    existing = db.query(ClassSection).filter(
        ClassSection.department_id == section_in.department_id,
        ClassSection.academic_year == section_in.academic_year,
        ClassSection.section == section_in.section.strip(),
        ClassSection.is_deleted == False
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail=f"Section '{section_in.section}' already exists for Year {section_in.academic_year} in this department.")

    sec = ClassSection(
        department_id=section_in.department_id,
        academic_year=section_in.academic_year,
        section=section_in.section.strip(),
        batch=section_in.batch,
        program=section_in.program or dept.name,
        faculty_advisor_id=section_in.faculty_advisor_id,
    )
    db.add(sec)
    db.commit()
    db.refresh(sec)
    return _build_section_response(sec, db)

@router.put("/{section_id}/assign-fa", response_model=ClassSectionResponse)
def assign_faculty_advisor(
    section_id: UUID,
    update_in: ClassSectionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.MASTER_ADMIN, UserRole.HOD, UserRole.COORDINATOR])),
):
    sec = db.query(ClassSection).filter(ClassSection.id == section_id, ClassSection.is_deleted == False).first()
    if not sec:
        raise HTTPException(status_code=404, detail="Class Section not found")

    if update_in.faculty_advisor_id is not None:
        if update_in.faculty_advisor_id:
            fa_user = db.query(User).filter(User.id == update_in.faculty_advisor_id, User.is_deleted == False).first()
            if not fa_user or fa_user.role not in (UserRole.FACULTY_ADVISOR, UserRole.COORDINATOR, UserRole.HOD):
                raise HTTPException(status_code=400, detail="Selected user is not a valid Faculty Advisor")
            sec.faculty_advisor_id = update_in.faculty_advisor_id
            # Also update all enrolled students in this section to point to this FA
            db.query(User).filter(User.class_section_id == sec.id).update({"assigned_faculty_id": sec.faculty_advisor_id})
        else:
            sec.faculty_advisor_id = None
            db.query(User).filter(User.class_section_id == sec.id).update({"assigned_faculty_id": None})

    if update_in.section:
        sec.section = update_in.section.strip()
    if update_in.academic_year:
        sec.academic_year = update_in.academic_year
    if update_in.batch:
        sec.batch = update_in.batch
    if update_in.program:
        sec.program = update_in.program

    db.commit()
    db.refresh(sec)
    return _build_section_response(sec, db)

@router.delete("/{section_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_class_section(
    section_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.MASTER_ADMIN, UserRole.HOD])),
):
    sec = db.query(ClassSection).filter(ClassSection.id == section_id, ClassSection.is_deleted == False).first()
    if not sec:
        raise HTTPException(status_code=404, detail="Class Section not found")
    sec.is_deleted = True
    db.commit()
    return None
