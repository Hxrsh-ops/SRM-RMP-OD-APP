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
    # Ensure database tables exist, perform column migrations and seed pilot accounts
    try:
        from .services.seed_service import run_db_migrations_and_seed
        run_db_migrations_and_seed()
    except Exception as e:
        logger.warning(f"Database startup initialization notice: {e}")
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

@app.get("/debug-db")
def debug_db():
    try:
        from .core.database import engine
        from sqlalchemy import text
        with engine.connect() as conn:
            result = conn.execute(text("SELECT current_database(), current_user;")).fetchall()
            tables = conn.execute(text("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")).fetchall()
            users_count = conn.execute(text("SELECT count(*) FROM users;")).scalar() if any(t[0] == 'users' for t in tables) else 'no users table'
            return {
                "db_info": [list(r) for r in result],
                "tables": [t[0] for t in tables],
                "users_count": users_count,
                "status": "connected"
            }
    except Exception as e:
        import traceback
        return {"error": str(e), "traceback": traceback.format_exc()}
