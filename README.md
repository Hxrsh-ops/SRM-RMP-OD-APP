# SRM RMP OD - On Duty Workflow Platform

A production-grade workflow platform designed to digitize the On Duty approval process for SRM Institute of Science and Technology, Ramapuram.

---

## 🏛️ Project Architecture Overview

This project is built as a monorepo adhering to **SOLID principles**, **Clean Architecture**, and **Feature-First Architecture**.

### Technology Stack
- **Frontend**: Flutter (Latest Stable), Material Design 3, Dart
- **State Management**: Riverpod (`flutter_riverpod`)
- **Routing**: GoRouter (`go_router`)
- **Networking**: Dio (`dio`)
- **Backend**: FastAPI, Python 3.11+, Uvicorn
- **Database**: PostgreSQL (SQLAlchemy Async Engine)

---

## 📂 Project Structure

```
SRM RMP OD/
├── frontend/             # Flutter Web & Mobile Client Application
│   ├── assets/           # App fonts, icons, images, illustrations, animations
│   ├── lib/
│   │   ├── core/
│   │   │   ├── config/   # Environment configurations (dev, staging, prod)
│   │   │   ├── constants/# Application-wide constants
│   │   │   ├── network/  # Dio HTTP client, interceptors & error mapping
│   │   │   ├── routing/  # GoRouter setup
│   │   │   ├── services/ # Local storage & logging services
│   │   │   ├── theme/    # M3 Color tokens, typography, dimensions & ThemeExtensions
│   │   │   ├── ui/       # Reusable UI component foundations (buttons, cards, etc.)
│   │   │   └── utils/    # Failures, Exceptions, Error Mapper
│   │   ├── features/     # Feature-first domain modules
│   │   └── main.dart     # Entry point initializing core providers & router
│   └── pubspec.yaml
├── backend/              # FastAPI Server Application
│   ├── app/
│   │   ├── api/          # Route handlers (/health, /version)
│   │   ├── config/       # Environment & Database settings (pydantic-settings)
│   │   ├── core/         # Application lifespan & core utilities
│   │   ├── database/     # Async SQLAlchemy session factory & configuration
│   │   ├── middleware/   # Request logging & CORS middleware
│   │   ├── repositories/ # Repository layer
│   │   ├── schemas/      # Pydantic request & response schemas
│   │   ├── security/     # Reserved for future Auth/JWT/RBAC modules
│   │   ├── services/     # Health & system services
│   │   ├── utils/        # Structured JSON logging formatter
│   │   └── main.py       # FastAPI application factory
│   ├── requirements.txt
│   └── .env.example
├── docs/                 # Documentation & Architecture Decision Records (ADRs)
│   ├── adr/              # ADR-001, ADR-002, ADR-003
│   └── architecture.md
├── database/             # Future migration scripts & SQL files
├── scripts/              # Setup, development, and deployment scripts
├── assets/               # Monorepo static assets
├── README.md             # Project documentation
├── .gitignore            # Version control exclusions
└── LICENSE               # Software License
```

---

## 🚀 How to Run

### Prerequisites
- Flutter SDK (Channel Stable)
- Python 3.11+
- Git

---

### Running the Backend

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Create and activate a Python virtual environment:
   ```bash
   # Windows (PowerShell)
   python -m venv venv
   .\venv\Scripts\Activate.ps1

   # Linux / macOS
   python3 -m venv venv
   source venv/bin/activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Copy the environment configuration:
   ```bash
   cp .env.example .env
   ```
5. Start the FastAPI development server:
   ```bash
   uvicorn app.main:app --reload --port 8000
   ```
6. Access endpoints:
   - Health Check: `http://127.0.0.1:8000/health`
   - Version: `http://127.0.0.1:8000/version`
   - Interactive OpenAPI Docs: `http://127.0.0.1:8000/docs`

---

### Running the Frontend

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   # Web
   flutter run -d chrome

   # Mobile (iOS/Android emulator)
   flutter run
   ```

---

## 🔮 Future Milestones

- **Milestone 2**: Authentication & Role-Based Access Control (RBAC) - Student, Faculty, Coordinator.
- **Milestone 3**: Database Schemas, Migrations & User Profiles.
- **Milestone 4**: OD Request Creation, Digital Signatures, and Workflow Approval Pipeline.
- **Milestone 5**: Real-time Notifications & Operations Dashboard.
