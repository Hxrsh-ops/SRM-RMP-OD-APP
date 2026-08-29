import logging
from sqlalchemy import text
from ..core.database import SessionLocal, Base, engine
from ..core.security import get_password_hash
from ..models.department import Department
from ..models.user import User
from ..models.enums import UserRole

logger = logging.getLogger(__name__)

def run_db_migrations_and_seed():
    """Applies column migrations and provisions pilot accounts on server startup."""
    try:
        Base.metadata.create_all(bind=engine)
    except Exception as e:
        logger.warning(f"Base metadata create notice: {e}")

    try:
        with engine.connect() as conn:
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS class_section_id UUID;"))
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS assigned_faculty_id UUID;"))
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS is_locked BOOLEAN DEFAULT FALSE;"))
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS force_password_change BOOLEAN DEFAULT FALSE;"))
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS failed_login_attempts INTEGER DEFAULT 0;"))
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE;"))
            
            conn.execute(text("ALTER TABLE od_requests ADD COLUMN IF NOT EXISTS cgpa DOUBLE PRECISION;"))
            conn.execute(text("ALTER TABLE od_requests ADD COLUMN IF NOT EXISTS attendance_percentage DOUBLE PRECISION;"))
            conn.execute(text("ALTER TABLE od_requests ADD COLUMN IF NOT EXISTS parent_consent_url VARCHAR(500);"))
            conn.execute(text("ALTER TABLE od_requests ADD COLUMN IF NOT EXISTS rejection_reason VARCHAR(500);"))
            conn.commit()
    except Exception as e:
        logger.warning(f"Table migration notice: {e}")

    db = SessionLocal()
    try:
        cse_dept = db.query(Department).filter((Department.code == "CSE") | (Department.name == "Computer Science & Engineering")).first()
        if not cse_dept:
            cse_dept = Department(name="Computer Science & Engineering", code="CSE")
            db.add(cse_dept)
            db.commit()
            db.refresh(cse_dept)

        ai_dept = db.query(Department).filter((Department.code == "AI") | (Department.name.ilike("%Artificial%"))).first()
        if not ai_dept:
            ai_dept = Department(name="Artificial Intelligence & Machine Learning", code="AI")
            db.add(ai_dept)
            db.commit()
            db.refresh(ai_dept)

        # Master Admin (Only create if missing - Never overwrite existing password)
        admin = db.query(User).filter(User.username == "ADMIN1001").first()
        if not admin:
            admin = User(
                username="ADMIN1001",
                email="admin@srmist.edu.in",
                full_name="Enterprise Master Admin",
                hashed_password=get_password_hash("Admin@123456"),
                role=UserRole.MASTER_ADMIN,
                is_active=True,
                is_locked=False,
                force_password_change=False,
            )
            db.add(admin)
            db.commit()

        # Dean
        dean = db.query(User).filter(User.username == "DEAN1001").first()
        if not dean:
            dean = User(
                username="DEAN1001",
                email="dean.cet@srmist.edu.in",
                full_name="Dr. C. Sundar (Dean CET)",
                hashed_password=get_password_hash("Dean@123456"),
                role=UserRole.DEAN,
                is_active=True,
                is_locked=False,
                force_password_change=False,
            )
            db.add(dean)
            db.commit()

        # HOD
        hod = db.query(User).filter(User.username == "HOD1001").first()
        if not hod:
            hod = User(
                username="HOD1001",
                email="hod.cse@srmist.edu.in",
                full_name="Dr. K. Vijayakumar (HOD CSE)",
                hashed_password=get_password_hash("Hod@123456"),
                role=UserRole.HOD,
                department_id=cse_dept.id,
                is_active=True,
                is_locked=False,
                force_password_change=False,
            )
            db.add(hod)
            db.commit()

        # Coordinator
        coord = db.query(User).filter(User.username == "COORD1001").first()
        if not coord:
            coord = User(
                username="COORD1001",
                email="coord.cse@srmist.edu.in",
                full_name="Prof. R. Rajesh (OD Coordinator CSE)",
                hashed_password=get_password_hash("Coord@123456"),
                role=UserRole.COORDINATOR,
                department_id=cse_dept.id,
                is_active=True,
                is_locked=False,
                force_password_change=False,
            )
            db.add(coord)
            db.commit()

        # Faculty Advisor
        fa = db.query(User).filter(User.username == "FA1001").first()
        if not fa:
            fa = User(
                username="FA1001",
                email="fa.cse1@srmist.edu.in",
                full_name="Dr. S. Anitha (Faculty Advisor Sec G)",
                hashed_password=get_password_hash("Faculty@123456"),
                role=UserRole.FACULTY_ADVISOR,
                department_id=cse_dept.id,
                is_active=True,
                is_locked=False,
                force_password_change=False,
            )
            db.add(fa)
            db.commit()
            db.refresh(fa)

        # Student
        stu = db.query(User).filter((User.username == "STU1001") | (User.username == "RA2311003010001")).first()
        if not stu:
            stu = User(
                username="RA2311003010001",
                email="harshanth.k@srmist.edu.in",
                full_name="K.M. Harshanth",
                hashed_password=get_password_hash("Student@123456"),
                role=UserRole.STUDENT,
                department_id=cse_dept.id,
                assigned_faculty_id=fa.id if fa else None,
                program="B.Tech Computer Science & Engineering",
                year_section="3rd Year - Section G",
                is_active=True,
                is_locked=False,
                force_password_change=False,
            )
            db.add(stu)
            db.commit()

        logger.info("Database schema and pilot accounts verified.")
    except Exception as e:
        logger.error(f"Seed service error: {e}")
        db.rollback()
    finally:
        db.close()
