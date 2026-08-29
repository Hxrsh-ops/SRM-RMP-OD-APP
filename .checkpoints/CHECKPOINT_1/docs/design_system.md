# SRM RMP OD - Permanent Product Design System Guidelines

## 1. Brand & Design Philosophy

The **SRM RMP OD** design language establishes a calm, modern, and production-grade enterprise SaaS interface inspired by platforms like **Linear, Stripe, Supabase, Vercel, and GitHub**.

### Key Principles
- **Dark-First Surface Hierarchy**: Uses deep obsidian charcoal tones (`#0B0F17` base, `#111827` surface, `#1F2937` card container) rather than harsh pure blacks or generic Material Blue.
- **Petrol Cyan Accent**: Utilizes electric Petrol Cyan (`#0EA5E9` / `#0284C7`) as the primary brand accent for clear focus indicators and primary actions.
- **Crisp 1px Borders**: Replaces heavy shadows with subtle 1px border outlines (`rgba(255, 255, 255, 0.08)` in dark mode).
- **Subtle Micro-Interactions**: Button press scales (`0.98`) and fast transition durations (150ms–200ms) that never delay user interaction.
- **Strict Tokenization**: Zero hardcoded hex colors or arbitrary pixel padding numbers in feature widgets.

---

## 2. Color System & Brand Direction

### Evaluated Directions
1. **Direction 1: Obsidian & Petrol Cyan (Selected)**: Deep obsidian charcoal foundation with Petrol Cyan (`#0EA5E9`). Ultra-sleek, calm, accessible (contrast > 6.5:1), and distinctive.
2. **Direction 2: Charcoal & Emerald Green**: Terminal-style developer palette. High contrast, but feels like a developer tool rather than an academic workflow platform.
3. **Direction 3: Slate & Indigo**: Standard Stripe/GitHub indigo. High quality, but common and slightly generic.

### Color Tokens Map
```
Background Dark: #0B0F17 (Obsidian Base)
Surface Dark:    #111827 (Dark Charcoal Slate)
Card Container:  #1F2937 (Card Surface)
Border Outline:  #374151 (1px Subtle Border)

Primary Accent:  #0EA5E9 (Petrol Cyan)
Secondary Accent:#10B981 (Emerald Green)

Status Tokens:
- Approved / Success: #10B981 (Emerald)
- Pending / Warning:  #F59E0B (Amber)
- Rejected / Error:    #EF4444 (Rose)
- Info:               #3B82F6 (Sky Blue)
```

---

## 3. Typography Hierarchy

11 intentional typography scales in `AppTypography`:
- **Display**: 48px, bold, -1.0 letterSpacing
- **Heading XL**: 32px, bold, -0.5 letterSpacing
- **Heading L**: 24px, semi-bold, -0.25 letterSpacing
- **Heading M**: 20px, semi-bold
- **Heading S**: 16px, semi-bold
- **Body Large**: 16px, regular
- **Body**: 14px, regular
- **Body Small**: 12px, regular
- **Caption**: 11px, medium, +0.2 letterSpacing
- **Label**: 12px, semi-bold, uppercase
- **Monospace**: 13px, w500

---

## 4. Spacing & Elevation Tokens

- **AppSpacing**: `xxs` (2dp), `xs` (4dp), `sm` (8dp), `md` (12dp), `lg` (16dp), `xl` (24dp), `xxl` (32dp), `xxxl` (48dp).
- **AppRadius**: `none` (0), `xs` (2dp), `sm` (4dp), `md` (8dp), `lg` (12dp), `xl` (16dp), `full` (999dp).
- **AppDuration**: `fast` (150ms), `normal` (200ms), `slow` (300ms).

---

## 5. UI Components & Usage Guidelines

- **Buttons (`core/ui/buttons/`)**: `AppPrimaryButton`, `AppSecondaryButton`, `AppTextButton`, `AppDestructiveButton`. Always include loading state & minimum 48x48dp touch targets.
- **Inputs (`core/ui/inputs/`)**: `AppTextField`, `AppPasswordField`, `AppSearchField`, `AppMultilineField`. Always display helper or error text when validation fails.
- **Cards (`core/ui/cards/`)**: `AppCard`, `AppClickableCard`, `AppElevatedCard`. Use 1px border outlines.
- **Status Chips (`core/ui/chips/`)**: `AppStatusChip`. Use for OD workflow states (`Approved`, `Pending`, `Rejected`, `Success`, `Warning`).
- **Product Mark (`core/ui/layout/app_brand_logo.dart`)**: Geometric shield badge with cyan stroke and "SRM RMP OD" wordmark subtext.
