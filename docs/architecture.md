# SRM RMP OD Architecture Blueprint

## Architectural Principles

1. **Feature-First Architecture**
   The frontend is organized by feature modules rather than layer-first. Each feature contains its own UI, providers, models, and repositories, keeping related code close together and minimizing cross-feature coupling.

2. **Clean Separation of Concerns**
   - **Data Layer**: Network clients, local storage, DTOs, and raw data mapping.
   - **Domain/State Layer**: State Management using Riverpod providers and application failures/exceptions.
   - **Presentation Layer**: Material 3 UI widgets consuming theme tokens and routing definitions.

3. **Centralized Design System**
   All visual styling (colors, typography, spacing, elevations, animation durations, border radii) is tokenized in `core/theme`. Direct hardcoding of values in UI widgets is strictly forbidden.

4. **Robust Error Handling & Logging**
   Network and business errors map to uniform `Failure` and `AppException` types. Application state transitions and external requests pass through structured logging layers.
