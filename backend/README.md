# SRM RMP OD — Production Backend Service

Production FastAPI + SQLAlchemy 2.x + PostgreSQL backend powering the **SRM RMP OD** digitized workflow platform.

---

## 🚀 Quick Start Guide (100% Free Development)

### 1. Setup Virtual Environment
```bash
cd backend
python -m venv venv
# On Windows PowerShell:
.\venv\Scripts\Activate.ps1
# On Linux/macOS:
source venv/bin/activate
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Run Pytest Suite
```bash
pytest -v
```

### 4. Database Migrations (Alembic)
```bash
# Generate initial migration
alembic revision --autogenerate -m "Initial production schema with native UUIDs and Enums"

# Apply migration
alembic upgrade head
```

### 5. Launch FastAPI Server
```bash
uvicorn app.main:app --reload --port 8000
```

---

## 📚 API Documentation (OpenAPI / Swagger)

Once running, interactive API documentation is accessible at:
- **Swagger UI**: [http://localhost:8000/api/v1/docs](http://localhost:8000/api/v1/docs)
- **ReDoc**: [http://localhost:8000/api/v1/redoc](http://localhost:8000/api/v1/redoc)

---

## 🔑 Default Seed Accounts (Demo)

| Role | Username (Reg No / Emp ID) | Password |
| :--- | :--- | :--- |
| **Student** | `RA2510026020400` | `student123` |
| **Faculty Advisor** | `FA1001` | `faculty123` |
| **Coordinator** | `CO1001` | `coord123` |

---

## 🏗️ Architecture & Layer Enforcements

- **API Routes (`app/api/v1/`)**: Pure route handlers with dependency injection.
- **Service Layer (`app/services/`)**: `AuthService`, `WorkflowService`, `NotificationService`, `StorageService`.
- **Repository Layer (`app/repositories/`)**: Encapsulates all SQLAlchemy queries with soft-delete filtering.
- **Storage Abstraction (`StorageProvider`)**: `LocalStorageProvider` for development with seamless migration to S3/Cloud Storage.
