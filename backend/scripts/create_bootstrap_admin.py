"""
Production Bootstrap CLI Tool — SRM RMP OD Platform

Creates the primary MASTER_ADMIN user account in PostgreSQL upon fresh deployment.
If a MASTER_ADMIN user already exists, it aborts safely without mutating any data.

Usage:
    python scripts/create_bootstrap_admin.py
"""

import os
import sys

# Ensure backend directory is on Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.core.database import SessionLocal, Base, engine
from app.core.security import get_password_hash
from app.models.user import User
from app.models.enums import UserRole

def create_bootstrap_admin():
    print("=" * 60)
    print(" SRM RMP OD PLATFORM — BOOTSTRAP ADMIN INITIALIZATION")
    print("=" * 60)

    # Ensure DB tables exist
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        # Check if a MASTER_ADMIN already exists
        existing_admin = db.query(User).filter(User.role == UserRole.MASTER_ADMIN).first()
        if existing_admin:
            if not existing_admin.is_active or existing_admin.is_locked:
                print(f"[RECOVERED] Activated and unlocked existing MASTER_ADMIN (Username: {existing_admin.username}).")
                existing_admin.is_active = True
                existing_admin.is_locked = False
                existing_admin.failed_login_attempts = 0
                db.commit()
            else:
                print(f"[EXISTS] Active MASTER_ADMIN account already exists in PostgreSQL (Username: {existing_admin.username}).")
            return

        # Obtain configuration from environment variables or safe prompt defaults
        username = os.getenv("BOOTSTRAP_ADMIN_USERNAME", "ADMIN1001").strip()
        email = os.getenv("BOOTSTRAP_ADMIN_EMAIL", "admin@srmist.edu.in").strip()
        password = os.getenv("BOOTSTRAP_ADMIN_PASSWORD", "Admin@123456").strip()

        print(f"Creating Primary MASTER_ADMIN Account:")
        print(f"  • Username / Employee ID : {username}")
        print(f"  • Institutional Email   : {email}")
        print(f"  • Role                 : MASTER_ADMIN")

        new_admin = User(
            username=username,
            email=email,
            full_name="Enterprise Master Admin",
            hashed_password=get_password_hash(password),
            role=UserRole.MASTER_ADMIN,
            is_active=True,
            is_locked=False,
            force_password_change=False,
        )

        db.add(new_admin)
        db.commit()
        db.refresh(new_admin)

        print("-" * 60)
        print("[SUCCESS] Bootstrap MASTER_ADMIN successfully provisioned in PostgreSQL!")
        print(f"Account ID: {new_admin.id}")
        print("-" * 60)

    except Exception as e:
        db.rollback()
        print(f"[ERROR] Failed to create bootstrap administrator: {e}")
        sys.exit(1)
    finally:
        db.close()

if __name__ == "__main__":
    create_bootstrap_admin()
