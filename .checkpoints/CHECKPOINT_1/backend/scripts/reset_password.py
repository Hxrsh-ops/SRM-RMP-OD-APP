"""
Production Administrator Recovery CLI Tool — SRM RMP OD Platform

Allows administrators to securely reset any user's password directly from CLI.
Generates bcrypt hash and updates PostgreSQL immediately.

Usage:
    python scripts/reset_password.py [username_or_email] [new_password]
    (or run interactively)
"""

import os
import sys
import getpass

# Ensure backend directory is on Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.core.database import SessionLocal, Base, engine
from app.core.security import get_password_hash
from app.models.user import User

def reset_password(identifier=None, new_password=None):
    print("=" * 60)
    print(" SRM RMP OD PLATFORM — ADMINISTRATOR PASSWORD RESET TOOL")
    print("=" * 60)

    db = SessionLocal()

    try:
        if not identifier:
            identifier = input("Enter Register Number, Employee ID, or Email: ").strip()

        if not identifier:
            print("[ERROR] Identifier cannot be empty.")
            sys.exit(1)

        user = db.query(User).filter(
            (User.username == identifier) | (User.email == identifier)
        ).first()

        if not user:
            print(f"[ERROR] No user found matching identifier '{identifier}'.")
            sys.exit(1)

        print(f"Target Account Found:")
        print(f"  • Full Name : {user.full_name}")
        print(f"  • Username  : {user.username}")
        print(f"  • Email     : {user.email}")
        print(f"  • Role      : {user.role.value}")

        if not new_password:
            new_password = getpass.getpass("Enter New Password (min 6 chars): ").strip()
            confirm = getpass.getpass("Confirm New Password: ").strip()

            if new_password != confirm:
                print("[ERROR] Passwords do not match.")
                sys.exit(1)

        if len(new_password) < 6:
            print("[ERROR] Password must be at least 6 characters long.")
            sys.exit(1)

        print("\nUpdating password hash in PostgreSQL...")
        user.hashed_password = get_password_hash(new_password)
        user.is_active = True
        user.is_locked = False
        user.failed_login_attempts = 0
        user.force_password_change = False
        db.commit()

        print("-" * 60)
        print(f"[SUCCESS] Password for user '{user.username}' successfully reset!")
        print("Account is unlocked and password updated in PostgreSQL.")
        print("-" * 60)

    except Exception as e:
        db.rollback()
        print(f"[ERROR] Failed to reset password: {e}")
        sys.exit(1)
    finally:
        db.close()

if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else None
    pwd = sys.argv[2] if len(sys.argv) > 2 else None
    reset_password(target, pwd)
