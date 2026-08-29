"""
CLI utility to initialize a fresh production database with the primary Department and Master Admin account.
This script is executed manually during deployment setup (never run automatically on application startup).
"""
import sys
from app.core.database import SessionLocal, Base, engine
from app.core.security import get_password_hash
from app.models.department import Department
from app.models.user import User
from app.models.enums import UserRole

def init_db():
    print("Initializing database tables...")
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        # Check if users already exist
        user_count = db.query(User).count()
        if user_count > 0:
            print("Database already contains users. Skipping initialization.")
            return

        print("Creating default CSE Department...")
        dept = Department(name="Computer Science & Engineering", code="CSE")
        db.add(dept)
        db.commit()
        db.refresh(dept)

        print("Creating initial Master Admin account...")
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
        print("Successfully created initial Master Admin (ADMIN1001 / Admin@123456).")
    except Exception as e:
        db.rollback()
        print(f"Failed to initialize database: {e}")
        sys.exit(1)
    finally:
        db.close()

if __name__ == "__main__":
    init_db()
