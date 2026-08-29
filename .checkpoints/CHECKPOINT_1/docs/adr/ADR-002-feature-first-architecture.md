# ADR-002: Feature-First Architecture

## Status
Accepted

## Context
As the SRM RMP OD platform expands across multiple roles (Student, Class Counselor, HOD, Dean) and workflows, a traditional layer-first directory structure (all screens in one folder, all controllers in another) creates file clutter and merge conflicts.

## Decision
Adopt a **Feature-First Architecture** structure for the frontend application.
- Global shared abstractions, theme, network, and utilities reside in `lib/core/`.
- Domain modules (e.g., future `auth`, `od_request`, `approvals`) encapsulate their own presentation, logic, and data layers inside `lib/features/<feature_name>/`.

## Consequences
- Highly modular codebase where features can be developed, tested, or refactored independently.
- Minimal cross-feature coupling and easier onboarding for developer teams.
