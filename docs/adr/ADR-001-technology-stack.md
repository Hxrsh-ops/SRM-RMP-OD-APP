# ADR-001: Technology Stack Selection

## Status
Accepted

## Context
The SRM RMP OD application requires a scalable, cross-platform frontend and a performant, asynchronous backend capable of supporting thousands of students and faculty members.

## Decision
- **Frontend**: Flutter with Dart using Material 3 guidelines.
- **Backend**: FastAPI (Python 3.11+) with Uvicorn.
- **Database**: PostgreSQL with async SQLAlchemy.
- **State Management**: Riverpod (`flutter_riverpod`).
- **Routing**: GoRouter (`go_router`).
- **Networking**: Dio (`dio`).

## Consequences
- High development velocity across web and mobile from a single codebase.
- Asynchronous non-blocking backend operations with automatic OpenAPI specification generation.
- Strong type safety across both frontend (Dart) and backend (Pydantic/Python type hints).
