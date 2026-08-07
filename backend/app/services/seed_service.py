import datetime
from sqlalchemy.orm import Session
from ..core.database import engine, SessionLocal
from ..core.logging import logger
from ..core.security import get_password_hash
from ..core.config import settings
from ..models.department import Department
from ..models.user import User
from ..models.od_request import OdRequest
from ..models.attachment import Attachment
from ..models.timeline import TimelineEvent
from ..models.enums import UserRole, OdStatus

def seed_production_ready_dataset():
    """Seed structured, realistic demonstration dataset into development database."""
    if settings.ENVIRONMENT.lower() not in ("development", "dev"):
        logger.info("Non-development environment detected; skipping demo seeding.")
        return

    db: Session = SessionLocal()
    try:
        # 1. Department
        dept = db.query(Department).filter(Department.code == "CSE").first()
        if not dept:
            dept = Department(name="Computer Science & Engineering", code="CSE")
            db.add(dept)
            db.commit()
            db.refresh(dept)

        # 2. Faculty Advisor (Dr. Karthik B)
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
        else:
            faculty.full_name = "Dr. Karthik B"
            db.commit()

        # 3. Coordinator (Prof. Ramesh Kumar)
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
            db.refresh(coord)
        else:
            coord.full_name = "Prof. Ramesh Kumar"
            db.commit()

        # 3b. Master Admin (Enterprise System Authority)
        master_admin = db.query(User).filter(User.username == "ADMIN1001").first()
        if not master_admin:
            master_admin = User(
                username="ADMIN1001",
                email="admin@srmist.edu.in",
                full_name="Enterprise Master Admin",
                hashed_password=get_password_hash("Admin@123456"),
                role=UserRole.MASTER_ADMIN,
                department_id=dept.id,
            )
            db.add(master_admin)
            db.commit()
            db.refresh(master_admin)
        else:
            master_admin.full_name = "Enterprise Master Admin"
            db.commit()

        # 4. Primary Student (K.M. Harshanth)
        student = db.query(User).filter(User.username == "RA2511026020400").first()
        if not student:
            student = User(
                username="RA2511026020400",
                email="hk7793@srmist.edu.in",
                full_name="K.M. Harshanth",
                hashed_password=get_password_hash("student123"),
                role=UserRole.STUDENT,
                department_id=dept.id,
                program="B.Tech CSE (AI & ML)",
                year_section="2nd Year - Sec G",
                assigned_faculty_id=faculty.id,
            )
            db.add(student)
            db.commit()
            db.refresh(student)

        # 5. Additional Students for realistic queues
        student_priya = db.query(User).filter(User.username == "RA2511026020405").first()
        if not student_priya:
            student_priya = User(
                username="RA2511026020405",
                email="priya.s@srmist.edu.in",
                full_name="Priya S",
                hashed_password=get_password_hash("student123"),
                role=UserRole.STUDENT,
                department_id=dept.id,
                program="B.Tech CSE",
                year_section="3rd Year - Sec A",
                assigned_faculty_id=faculty.id,
            )
            db.add(student_priya)
            db.commit()
            db.refresh(student_priya)

        student_ananya = db.query(User).filter(User.username == "RA2511026020410").first()
        if not student_ananya:
            student_ananya = User(
                username="RA2511026020410",
                email="ananya.r@srmist.edu.in",
                full_name="Ananya R",
                hashed_password=get_password_hash("student123"),
                role=UserRole.STUDENT,
                department_id=dept.id,
                program="B.Tech IT",
                year_section="3rd Year - Sec B",
                assigned_faculty_id=faculty.id,
            )
            db.add(student_ananya)
            db.commit()
            db.refresh(student_ananya)

        student_vikram = db.query(User).filter(User.username == "RA2511026020415").first()
        if not student_vikram:
            student_vikram = User(
                username="RA2511026020415",
                email="vikram.m@srmist.edu.in",
                full_name="Vikram M",
                hashed_password=get_password_hash("student123"),
                role=UserRole.STUDENT,
                department_id=dept.id,
                program="B.Tech CSE (Cyber Security)",
                year_section="4th Year - Sec C",
                assigned_faculty_id=faculty.id,
            )
            db.add(student_vikram)
            db.commit()
            db.refresh(student_vikram)

        student_suresh = db.query(User).filter(User.username == "RA2511026020420").first()
        if not student_suresh:
            student_suresh = User(
                username="RA2511026020420",
                email="suresh.k@srmist.edu.in",
                full_name="Suresh K",
                hashed_password=get_password_hash("student123"),
                role=UserRole.STUDENT,
                department_id=dept.id,
                program="B.Tech ECE",
                year_section="2nd Year - Sec D",
                assigned_faculty_id=faculty.id,
            )
            db.add(student_suresh)
            db.commit()
            db.refresh(student_suresh)

        # 6. OD Requests Seeding (Ensure exact counts: Student: 1 Pending, 4 Completed, 1 Rejected; Faculty: 2 Pending; Coordinator: 3 Pending)
        today = datetime.date.today()

        def create_or_update_request(req_id, student_obj, reason, start_d, end_d, days, purpose, venue, organizer, res_type, status_val, summary=None):
            existing = db.query(OdRequest).filter(OdRequest.id == req_id).first()
            if not existing:
                req = OdRequest(
                    id=req_id,
                    student_id=student_obj.id,
                    faculty_id=faculty.id,
                    reason=reason,
                    start_date=start_d,
                    end_date=end_d,
                    duration_days=days,
                    purpose=purpose,
                    venue=venue,
                    organizer=organizer,
                    cgpa=8.8,
                    attendance_percentage=92.5,
                    residence_type=res_type,
                    status=status_val,
                    completion_summary=summary,
                )
                db.add(req)
                db.commit()

                # Add initial timeline event
                t_event = TimelineEvent(
                    od_request_id=req_id,
                    title="OD Request Created",
                    actor_name=student_obj.full_name,
                    actor_role="STUDENT",
                    status=OdStatus.SUBMITTED,
                    note=f"Submitted application for {reason}",
                )
                db.add(t_event)
                db.commit()

        # Student K.M. Harshanth Requests (1 Pending, 4 Completed, 1 Rejected)
        create_or_update_request(
            "OD-2026-101", student, "National AI Hackathon 2026",
            today + datetime.timedelta(days=5), today + datetime.timedelta(days=7), 3,
            "Build Generative AI Prototype for Smart Cities", "IIT Madras Research Park", "Google Developers Group",
            "Hosteller", OdStatus.PENDING_FACULTY
        )
        create_or_update_request(
            "OD-2026-102", student, "Smart India Hackathon Finals",
            today - datetime.timedelta(days=60), today - datetime.timedelta(days=58), 3,
            "National Finals Competition", "Persistent Systems, Pune", "Ministry of Education",
            "Day Scholar", OdStatus.COMPLETED, "Secured First Prize in Smart Automation Track."
        )
        create_or_update_request(
            "OD-2026-103", student, "IIT Madras Technical Symposium",
            today - datetime.timedelta(days=45), today - datetime.timedelta(days=44), 2,
            "Paper Presentation on Quantum ML", "IIT Madras", "Shaastra Tech Team",
            "Day Scholar", OdStatus.COMPLETED, "Presented research paper and received Certificate of Merit."
        )
        create_or_update_request(
            "OD-2026-104", student, "SRM IEEE Conference",
            today - datetime.timedelta(days=30), today - datetime.timedelta(days=30), 1,
            "Delegate & Technical Workshop", "SRM Tech Park", "IEEE Student Branch",
            "Hosteller", OdStatus.COMPLETED, "Attended workshop on Edge AI."
        )
        create_or_update_request(
            "OD-2026-105", student, "ACM ICPC Regional Contest",
            today - datetime.timedelta(days=15), today - datetime.timedelta(days=13), 3,
            "Competitive Programming Regionals", "Amrita Vishwa Vidyapeetham", "ACM ICPC Council",
            "Day Scholar", OdStatus.COMPLETED, "Solved 6 problems and qualified for national finals."
        )
        create_or_update_request(
            "OD-2026-106", student, "Unapproved Personal Travel",
            today - datetime.timedelta(days=90), today - datetime.timedelta(days=88), 3,
            "Off-campus Personal Event", "Bangalore", "Private Club",
            "Hosteller", OdStatus.REJECTED, None
        )

        # Faculty Queue (2 Pending Initial: OD-2026-101, OD-2026-107 + 1 Pending Evidence: OD-2026-111)
        create_or_update_request(
            "OD-2026-107", student_priya, "State Robotics Championship",
            today + datetime.timedelta(days=8), today + datetime.timedelta(days=10), 3,
            "Autonomous Robot Challenge", "Anna University, Chennai", "Tamil Nadu Robotics Society",
            "Day Scholar", OdStatus.PENDING_FACULTY
        )
        create_or_update_request(
            "OD-2026-111", student_priya, "National Coding Olympiad",
            today - datetime.timedelta(days=4), today - datetime.timedelta(days=2), 3,
            "Competitive Programming Competition", "IIT Hyderabad", "CodeChef India",
            "Day Scholar", OdStatus.PENDING_EVIDENCE_FACULTY, "Achieved Global Rank 42 in Finals."
        )

        # Coordinator Queue (3 Pending Initial: OD-2026-108, OD-2026-109, OD-2026-112 + 1 Pending Evidence: OD-2026-110)
        create_or_update_request(
            "OD-2026-108", student_ananya, "Inter-College Cricket Tournament",
            today + datetime.timedelta(days=12), today + datetime.timedelta(days=14), 3,
            "Representing SRM University Team", "Loyola College Grounds", "TNCA Sports Association",
            "Hosteller", OdStatus.PENDING_COORDINATOR
        )
        create_or_update_request(
            "OD-2026-109", student_vikram, "National Cyber Security Summit",
            today + datetime.timedelta(days=18), today + datetime.timedelta(days=19), 2,
            "CTF Cybersecurity Challenge", "SSN College of Engineering", "ISACA Chennai Chapter",
            "Day Scholar", OdStatus.PENDING_COORDINATOR
        )
        create_or_update_request(
            "OD-2026-112", student_vikram, "Deep Learning Symposium",
            today + datetime.timedelta(days=22), today + datetime.timedelta(days=24), 3,
            "Computer Vision Workshop", "NIT Trichy", "IEEE Computer Society",
            "Day Scholar", OdStatus.PENDING_COORDINATOR
        )
        create_or_update_request(
            "OD-2026-110", student_suresh, "Global Student Innovation Challenge",
            today - datetime.timedelta(days=5), today - datetime.timedelta(days=3), 3,
            "IoT Product Prototype Demo", "Vellore Institute of Technology", "IEEE Innovation Council",
            "Hosteller", OdStatus.PENDING_EVIDENCE_COORDINATOR, "Demonstrated prototype and won Best UI/UX award."
        )

        logger.info("Successfully populated realistic demonstration dataset.")
    except Exception as e:
        logger.critical(f"Error seeding database: {e}")
        db.rollback()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    seed_production_ready_dataset()
