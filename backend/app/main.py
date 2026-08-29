import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text
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

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Log database engine startup details
    logger.info(f"PostgreSQL Engine Active: {engine.url.render_as_string(hide_password=True)}")
    # Ensure database tables exist (migrations handle schema updates)
    Base.metadata.create_all(bind=engine)

    # Apply safe column checks for cloud databases
    try:
        with engine.connect() as conn:
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS failed_login_attempts INTEGER DEFAULT 0;"))
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS is_locked BOOLEAN DEFAULT FALSE;"))
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS force_password_change BOOLEAN DEFAULT FALSE;"))
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE;"))
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS assigned_faculty_id UUID;"))
            conn.execute(text("ALTER TABLE od_requests ADD COLUMN IF NOT EXISTS cgpa DOUBLE PRECISION;"))
            conn.execute(text("ALTER TABLE od_requests ADD COLUMN IF NOT EXISTS attendance_percentage DOUBLE PRECISION;"))
            conn.execute(text("ALTER TABLE od_requests ADD COLUMN IF NOT EXISTS parent_consent_url VARCHAR(500);"))
            conn.execute(text("ALTER TABLE od_requests ADD COLUMN IF NOT EXISTS rejection_reason VARCHAR(500);"))
            conn.commit()
    except Exception as e:
        logger.warning(f"Schema column check notice: {e}")

    # Auto-seed clean pilot accounts on startup
    try:
        from .scripts.seed_pilot_accounts import seed_pilot_accounts
        seed_pilot_accounts()
    except Exception as e:
        logger.warning(f"Pilot accounts seeding notice: {e}")

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
    allow_origins=["*"],
    allow_credentials=False,
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
