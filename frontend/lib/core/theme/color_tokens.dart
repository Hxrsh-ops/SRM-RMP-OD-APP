import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand Primary (Deep SRM Blue & Royal Light Blue)
  static const Color primaryBlue = Color(0xFF00296B); // Deep SRM Blue
  static const Color primaryLight = Color(0xFF1E4FC9); // Royal Light Blue
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE7F0FF); // Light Blue Container
  static const Color onPrimaryContainer = Color(0xFF00296B);

  // Brand Accent (Warm Gold / Amber)
  static const Color accentYellow = Color(0xFFF5B400); // Warm Gold
  static const Color onAccentYellow = Color(0xFF111827);

  // Semantic Status Tokens (Light-First UI Kit Specification)
  static const Color success = Color(0xFF16A34A); // Emerald Green
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFDCFCE7);

  static const Color warning = Color(0xFFF59E0B); // Amber Warning
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFEF3C7);

  static const Color danger = Color(0xFFDC2626); // Red Danger
  static const Color onDanger = Color(0xFFFFFFFF);
  static const Color dangerContainer = Color(0xFFFEE2E2);

  static const Color info = Color(0xFF2563EB); // Royal Blue Info
  static const Color infoContainer = Color(0xFFDBEAFE);

  // Background & Surface (Light-First Specification)
  static const Color background = Color(0xFFF8F9FA); // Soft Gray Background
  static const Color surface = Color(0xFFFFFFFF); // Pure White Surface
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE5E7EB); // Light Gray Border

  // Text Colors
  static const Color textPrimary = Color(0xFF111827); // Dark Slate Text
  static const Color textSecondary = Color(0xFF6B7280); // Muted Gray Text
  static const Color textDisabled = Color(0xFF9CA3AF);
}
