# ADR-003: Design System Foundation & Tokenization

## Status
Accepted

## Context
To ensure visual consistency, accessibility, and brand identity across light/dark modes and responsive screen sizes, UI components must rely on single-source-of-truth tokens rather than hardcoded visual properties.

## Decision
- Centralize all color tokens, typography scales, spacing scales, border radii, elevations, animation durations, icon sizes, and padding scales inside `lib/core/theme/`.
- Utilize Flutter Material 3 `ThemeData` along with `ThemeExtension` for custom domain visual properties.
- Reusable UI component foundations reside in `lib/core/ui/`.
- Avoid `google_fonts` package to prevent runtime network loading dependencies; default to Flutter system typography with support for local asset fonts.

## Consequences
- Guaranteed zero hardcoded color or spacing values across feature widgets.
- Instant dark mode / light mode theme switching capability.
- Predictable visual scaling across desktop, tablet, and mobile layouts.
