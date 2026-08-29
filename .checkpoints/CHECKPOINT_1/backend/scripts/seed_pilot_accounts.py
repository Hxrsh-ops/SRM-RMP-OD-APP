"""
Seed Pilot Accounts for Testing & Deployment
Provisions genuine user accounts across all privilege tiers without injecting ANY dummy OD requests.
"""
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.core.database import SessionLocal, Base, engine
from app.core.security import get_password_hash
from app.models.department import Department
from app.models.user import User
from app.models.enums import UserRole

def seed_pilot_accounts():
    print("=" * 65)
    print(" SRM RMP OD PLATFORM — SEEDING CLEAN PILOT ACCOUNTS")
    print("=" * 65)

    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        # 1. Departments
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

        # 2. Master Admin
        admin = db.query(User).filter(User.username == "ADMIN1001").first()
        if not admin:
            admin = User(
                username="ADMIN1001",
                email="admin@srmist.edu.in",
                full_name="Enterprise Master Admin",
                hashed_password=get_password_hash("Admin@123456"),
                role=UserRole.MASTER_ADMIN,
                is_active=True,
            )
            db.add(admin)
        else:
            admin.hashed_password = get_password_hash("Admin@123456")
            admin.is_active = True
            admin.is_locked = False
        db.commit()

        # 3. Dean (Campus-wide)
        dean = db.query(User).filter(User.username == "DEAN1001").first()
        if not dean:
            dean = User(
                username="DEAN1001",
                email="dean.cet@srmist.edu.in",
                full_name="Dr. Kailash",
                hashed_password=get_password_hash("Dean@123456"),
                role=UserRole.DEAN,
                is_active=True,
            )
            db.add(dean)
        else:
            dean.hashed_password = get_password_hash("Dean@123456")
            dean.is_active = True
            dean.is_locked = False
        db.commit()

        # 4. HOD (AI Department)
        hod = db.query(User).filter(User.username == "HOD1001").first()
        if not hod:
            hod = User(
                username="HOD1001",
                email="hod.ai@srmist.edu.in",
                full_name="Dr. Krishna",
                hashed_password=get_password_hash("Hod@123456"),
                role=UserRole.HOD,
                department_id=ai_dept.id,
                is_active=True,
            )
            db.add(hod)
        else:
            hod.hashed_password = get_password_hash("Hod@123456")
            hod.is_active = True
            hod.is_locked = False
            hod.department_id = ai_dept.id
        db.commit()

        # 5. Coordinator (AI Department)
        coord = db.query(User).filter(User.username == "CO1001").first()
        if not coord:
            coord = User(
                username="CO1001",
                email="kamalesh@srmist.edu.in",
                full_name="Kamalesh",
                hashed_password=get_password_hash("Coord@123"),
                role=UserRole.COORDINATOR,
                department_id=ai_dept.id,
                is_active=True,
            )
            db.add(coord)
        else:
            coord.hashed_password = get_password_hash("Coord@123")
            coord.is_active = True
            coord.is_locked = False
            coord.department_id = ai_dept.id
        db.commit()

        # 6. Faculty Advisor (AI Department)
        fa = db.query(User).filter(User.username == "FA1001").first()
        if not fa:
            fa = User(
                username="FA1001",
                email="karthik@srmist.edu.in",
                full_name="Karthik",
                hashed_password=get_password_hash("Faculty@123"),
                role=UserRole.FACULTY_ADVISOR,
                department_id=ai_dept.id,
                is_active=True,
            )
            db.add(fa)
        else:
            fa.hashed_password = get_password_hash("Faculty@123")
            fa.is_active = True
            fa.is_locked = False
            fa.department_id = ai_dept.id
        db.commit()
        db.refresh(fa)

        # 7. Student (Harshanth)
        student = db.query(User).filter(User.username == "RA2511026020400").first()
        if not student:
            student = User(
                username="RA2511026020400",
                email="hk7793@srmist.edu.in",
                full_name="K M HARSHANTH",
                hashed_password=get_password_hash("Student@123"),
                role=UserRole.STUDENT,
                department_id=ai_dept.id,
                program="B Tech CSE AI/ML",
                year_section="2nd Year - Sec G",
                assigned_faculty_id=fa.id,
                is_active=True,
            )
            db.add(student)
        else:
            student.hashed_password = get_password_hash("Student@123")
            student.is_active = True
            student.is_locked = False
            student.department_id = ai_dept.id
            student.assigned_faculty_id = fa.id
        db.commit()

        print("[SUCCESS] Provisioned Clean Pilot Accounts (0 OD Requests created):")
        print("  1. Student     : RA2511026020400 / Student@123 (K M HARSHANTH)")
        print("  2. Faculty Adv : FA1001          / Faculty@123 (Karthik)")
        print("  3. Coordinator : CO1001          / Coord@123   (Kamalesh)")
        print("  4. HOD         : HOD1001         / Hod@123456  (Dr. Krishna)")
        print("  5. Dean        : DEAN1001        / Dean@123456 (Dr. Kailash)")
        print("  6. Master Admin: ADMIN1001       / Admin@123456 (Enterprise Master Admin)")
        print("=" * 65)

    except Exception as e:
        db.rollback()
        print(f"[ERROR] Failed to seed accounts: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_pilot_accounts()
