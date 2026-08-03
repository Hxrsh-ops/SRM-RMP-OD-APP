# SRM RMP OD - On Duty Workflow Platform

A production-grade workflow platform designed to digitize the On Duty approval process for SRM Institute of Science and Technology, Ramapuram.

---

## 🏛️ Project Architecture Overview

This project is built as a single shared Flutter codebase targeting **Android** and **Flutter Web**, communicating with a **FastAPI (Python 3.11)** backend powered by **PostgreSQL** and **SQLAlchemy 2.0 ORM**.

### Technology Stack
- **Frontend**: Flutter (Material Design 3, Riverpod 2.5, GoRouter 14, Dio 5.4, Flutter Secure Storage)
- **Backend**: FastAPI (Python 3.11+), Pydantic v2, SQLAlchemy 2.0, Alembic Migrations
- **Database**: PostgreSQL (`srm_od`)
- **Authentication**: JWT Access & Refresh Tokens, BCrypt Hashing, Role-Based Access Control (RBAC)

---

## 🔑 Demo & Test Credentials

| Role | Username | Password | Full Name | Primary View |
| :--- | :--- | :--- | :--- | :--- |
| **Student** | `RA2511026020400` | `student123` | K.M. Harshanth | Student Home, My Requests, Submit OD Form |
| **Faculty Advisor** | `FA1001` | `faculty123` | Dr. Karthik B | Faculty Advisor Queue, Recommendation Notes |
| **Department Coordinator** | `CO1001` | `coord123` | Prof. Ramesh Kumar | Coordinator Queue, Department Analytics |

---

## ⚙️ Environment Configuration

### Frontend Build-time Variables (`--dart-define`)
- `API_BASE_URL`: Override base backend URL (e.g. `http://192.168.1.14:8000/api/v1` or `https://api.srm-od.edu`).
- `PC_LAN_IP`: Set host PC LAN IP for physical device development (e.g. `192.168.1.14`).
- `ENVIRONMENT`: Set runtime environment (`dev`, `staging`, `prod`).

---

## 🚀 How to Run

### 1. Backend Setup & Database Migrations

```bash
cd backend

# Create & Activate Virtual Environment
python -m venv venv
.\venv\Scripts\Activate.ps1   # Windows PowerShell
source venv/bin/activate      # Linux / macOS

# Install Dependencies
pip install -r requirements.txt

# Run Alembic Database Migrations
alembic upgrade head

# Start FastAPI Development Server
uvicorn app.main:app --reload --port 8000
```

- OpenAPI Interactive Docs: `http://127.0.0.1:8000/api/v1/docs`

---

### 2. Frontend Execution & Release Builds

```bash
cd frontend

# Fetch Dependencies
flutter pub get

# Run Web Development
flutter run -d chrome

# Run Android Physical Device (LAN Development)
flutter run --dart-define=PC_LAN_IP=192.168.1.14

# Run Android Emulator
flutter run

# Build Release Web Bundle
flutter build web --release

# Build Release APK
flutter build apk --release
```

---

## 🧪 Verification & Testing Commands

```bash
# Run Frontend Static Analysis
flutter analyze

# Run Frontend Unit Test Suite
flutter test

# Run Backend Pytest Suite
cd backend
python -m pytest tests
```
