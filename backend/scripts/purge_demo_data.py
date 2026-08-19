"""
Live PostgreSQL Database Purging Tool — SRM RMP OD Platform

Safely purges all legacy demo OD requests, notifications, timeline events, attachments,
audit logs, security events, and demo users from PostgreSQL srm_od.

Preserves / provisions ONLY the active MASTER_ADMIN user account.

Usage:
    python scripts/purge_demo_data.py
"""

import os
import sys

# Ensure backend directory is on Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.core.database import SessionLocal, Base, engine
from app.core.security import get_password_hash
from app.models.user import User
from app.models.department import Department
from app.models.od_request import OdRequest
from app.models.notification import Notification
from app.models.timeline import TimelineEvent
from app.models.attachment import Attachment
from app.models.audit_log import AuditLog
from app.models.security_event import SecurityEvent
from app.models.comment import Comment
from app.models.enums import UserRole

def purge_demo_data():
    print("=" * 70)
    print(" SRM RMP OD PLATFORM — LIVE POSTGRESQL DEMO DATA PURGE TOOL")
    print("=" * 70)

    db = SessionLocal()

    try:
        # 1. Truncate / Delete all workflow data (child tables first)
        c_count = db.query(Comment).delete()
        att_count = db.query(Attachment).delete()
        t_count = db.query(TimelineEvent).delete()
        n_count = db.query(Notification).delete()
        od_count = db.query(OdRequest).delete()
        audit_count = db.query(AuditLog).delete()
        sec_count = db.query(SecurityEvent).delete()

        print(f"Purged Workflow Tables:")
        print(f"  • Deleted Comments        : {c_count}")
        print(f"  • Deleted Attachments     : {att_count}")
        print(f"  • Deleted Timeline Events : {t_count}")
        print(f"  • Deleted Notifications   : {n_count}")
        print(f"  • Deleted OD Requests     : {od_count}")
        print(f"  • Deleted Audit Logs      : {audit_count}")
        print(f"  • Deleted Security Events : {sec_count}")

        # 2. Delete non-admin users
        demo_users_count = db.query(User).filter(User.role != UserRole.MASTER_ADMIN).delete()
        print(f"  • Deleted Non-Admin Users : {demo_users_count}")

        # 3. Ensure Master Admin exists and is ACTIVE
        admin = db.query(User).filter(User.role == UserRole.MASTER_ADMIN).first()
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
            print("  • Created Fresh Active MASTER_ADMIN Account (ADMIN1001)")
        else:
            admin.is_active = True
            admin.is_locked = False
            admin.failed_login_attempts = 0
            admin.force_password_change = False
            admin.hashed_password = get_password_hash("Admin@123456")
            print("  • Reactivated & Reset MASTER_ADMIN Account (ADMIN1001 / Admin@123456)")

        db.commit()

        print("-" * 70)
        print("[SUCCESS] Live PostgreSQL database successfully purged of all demo data!")
        print("Remaining Database Inventory:")
        print(f"  • Users       : {db.query(User).count()} (MASTER_ADMIN)")
        print(f"  • OD Requests : {db.query(OdRequest).count()}")
        print(f"  • Notifications: {db.query(Notification).count()}")
        print(f"  • Timeline    : {db.query(TimelineEvent).count()}")
        print("-" * 70)

    except Exception as e:
        db.rollback()
        print(f"[ERROR] Failed to purge demo data: {e}")
        sys.exit(1)
    finally:
        db.close()

if __name__ == "__main__":
    purge_demo_data()
