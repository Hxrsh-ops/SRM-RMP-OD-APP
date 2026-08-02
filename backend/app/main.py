import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from .core.config import settings
from .core.database import Base, engine, SessionLocal
from .core.logging import setup_logging, logger
from .core.security import get_password_hash
from .api.v1.api_router import api_router
from .models.user import User
from .models.department import Department
from .models.enums import UserRole

# Initialize Logging
setup_logging()

def seed_demo_users():
    """Seed default development accounts if environment is development."""
    if settings.ENVIRONMENT.lower() not in ("development", "dev"):
        return

    db: Session = SessionLocal()
    try:
        # Seed Department
        dept = db.query(Department).filter(Department.code == "CSE").first()
        if not dept:
            dept = Department(name="Computer Science & Engineering", code="CSE")
            db.add(dept)
            db.commit()
            db.refresh(dept)

        # Faculty Advisor (Dr. Karthik B)
        faculty = db.query(User).filter(User.username == "FA1001").first()
        if not faculty:
            faculty = User(
                username="FA1001",
                email="karthikb@srmist.edu.in",
                full_name="Dr. Karthik B",
                hashed_password=get_password_hash("faculty123"),
                role=UserRole.FACULTY_ADVISOR,
                department_id=dept.id,
            )
            db.add(faculty)
            db.commit()
            db.refresh(faculty)
        elif "Mock" in faculty.full_name:
            faculty.full_name = "Dr. Karthik B"
            db.commit()

        # Coordinator (Prof. Ramesh Kumar)
        coord = db.query(User).filter(User.username == "CO1001").first()
        if not coord:
            coord = User(
                username="CO1001",
                email="rameshk@srmist.edu.in",
                full_name="Prof. Ramesh Kumar",
                hashed_password=get_password_hash("coord123"),
                role=UserRole.COORDINATOR,
                department_id=dept.id,
            )
            db.add(coord)
            db.commit()
        elif "Coordinator" in coord.full_name:
            coord.full_name = "Prof. Ramesh Kumar"
            db.commit()

        # Student (K.M. Harshanth) - RA2511026020400
        student = db.query(User).filter(User.username == "RA2511026020400").first()
        if not student:
            old_student = db.query(User).filter(User.username == "RA2510026020400").first()
            if old_student:
                old_student.username = "RA2511026020400"
                db.commit()
            else:
                student = User(
                    username="RA2511026020400",
                    email="hk7793@srmist.edu.in",
                    full_name="K.M. Harshanth",
                    hashed_password=get_password_hash("student123"),
                    role=UserRole.STUDENT,
                    department_id=dept.id,
                    program="B.Tech CSE (AI & ML)",
                    year_section="2nd Year - Sec G",
                    assigned_faculty_id=faculty.id if faculty else None,
                )
                db.add(student)
                db.commit()

        logger.info("Development seed data successfully initialized.")
    except Exception as e:
        logger.error(f"Error seeding database: {e}")
    finally:
        db.close()

@asynccontextmanager
async def lifespan(app: FastAPI):
    seed_demo_users()
    yield

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url=f"{settings.API_V1_STR}/docs",
    redoc_url=f"{settings.API_V1_STR}/redoc",
    lifespan=lifespan
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ensure upload directory exists before static mounting
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

# Include Central API Router
app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/")
def root():
    return {
        "title": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "docs": f"{settings.API_V1_STR}/docs",
        "status": "healthy"
    }
