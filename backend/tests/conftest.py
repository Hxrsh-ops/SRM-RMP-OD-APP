import os
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.database import Base, get_db
from app.core.security import get_password_hash
from app.main import app
from app.models.user import User
from app.models.department import Department
from app.models.enums import UserRole

SQLALCHEMY_TEST_DATABASE_URL = "sqlite:///./test_srm_rmp_od.db"

engine = create_engine(
    SQLALCHEMY_TEST_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="session", autouse=True)
def setup_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    
    db = TestingSessionLocal()
    
    # Check or seed department
    dept = db.query(Department).filter(Department.code == "CSE").first()
    if not dept:
        dept = Department(name="Computer Science & Engineering", code="CSE")
        db.add(dept)
        db.commit()
        db.refresh(dept)

    # Seed Faculty Advisor
    faculty = db.query(User).filter(User.username == "FA1001").first()
    if not faculty:
        faculty = User(
            username="FA1001",
            email="faculty@srmist.edu.in",
            full_name="Dr. Karthik B",
            hashed_password=get_password_hash("Faculty@123"),
            role=UserRole.FACULTY_ADVISOR,
            department_id=dept.id,
        )
        db.add(faculty)
        db.commit()
        db.refresh(faculty)

    # Seed Coordinator
    coord = db.query(User).filter(User.username == "CO1001").first()
    if not coord:
        coord = User(
            username="CO1001",
            email="coord@srmist.edu.in",
            full_name="Prof. Ramesh Kumar",
            hashed_password=get_password_hash("Coord@123"),
            role=UserRole.COORDINATOR,
            department_id=dept.id,
        )
        db.add(coord)
        db.commit()

    # Seed Master Admin
    admin = db.query(User).filter(User.username == "ADMIN1001").first()
    if not admin:
        admin = User(
            username="ADMIN1001",
            email="admin@srmist.edu.in",
            full_name="Enterprise Master Admin",
            hashed_password=get_password_hash("Admin@123456"),
            role=UserRole.MASTER_ADMIN,
            department_id=dept.id,
        )
        db.add(admin)
        db.commit()

    # Seed HOD
    hod = db.query(User).filter(User.username == "HOD1001").first()
    if not hod:
        hod = User(
            username="HOD1001",
            email="hod@srmist.edu.in",
            full_name="Dr. Krishna HOD",
            hashed_password=get_password_hash("Hod@123456"),
            role=UserRole.HOD,
            department_id=dept.id,
        )
        db.add(hod)
        db.commit()

    # Seed Dean
    dean = db.query(User).filter(User.username == "DEAN1001").first()
    if not dean:
        dean = User(
            username="DEAN1001",
            email="dean@srmist.edu.in",
            full_name="Dr. S. Dean",
            hashed_password=get_password_hash("Dean@123456"),
            role=UserRole.DEAN,
            department_id=dept.id,
        )
        db.add(dean)
        db.commit()

    # Seed Student 1
    student = db.query(User).filter(User.username == "RA2511026020400").first()
    if not student:
        student = User(
            username="RA2511026020400",
            email="hk7793@srmist.edu.in",
            full_name="K.M. Harshanth",
            hashed_password=get_password_hash("Student@123"),
            role=UserRole.STUDENT,
            department_id=dept.id,
            program="B.Tech CSE (AI & ML)",
            year_section="2nd Year - Sec G",
            assigned_faculty_id=faculty.id,
        )
        db.add(student)
        db.commit()

    # Seed Student 2
    student2 = db.query(User).filter(User.username == "RA2511026020401").first()
    if not student2:
        student2 = User(
            username="RA2511026020401",
            email="student2@srmist.edu.in",
            full_name="John Doe",
            hashed_password=get_password_hash("Student@123"),
            role=UserRole.STUDENT,
            department_id=dept.id,
            program="B.Tech CSE (AI & ML)",
            year_section="2nd Year - Sec G",
            assigned_faculty_id=faculty.id,
        )
        db.add(student2)
        db.commit()

    db.close()

    yield

    Base.metadata.drop_all(bind=engine)
    engine.dispose()
    if os.path.exists("test_srm_rmp_od.db"):
        try:
            os.remove("test_srm_rmp_od.db")
        except Exception:
            pass

@pytest.fixture
def db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

@pytest.fixture
def client(db):
    def _override_get_db():
        try:
            yield db
        finally:
            pass

    app.dependency_overrides[get_db] = _override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
