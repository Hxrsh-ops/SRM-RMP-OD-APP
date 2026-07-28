import 'package:flutter/material.dart';
import 'color_tokens.dart';
import 'custom_theme_extensions.dart';
import 'dimension_tokens.dart';
import 'typography_tokens.dart';

abstract class AppTheme {
  static ThemeData get lightTheme {
    final ColorScheme colorScheme = const ColorScheme.light(
      primary: AppColors.primaryBlue,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.onPrimary,
      tertiary: AppColors.accentYellow,
      onTertiary: AppColors.onAccentYellow,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      error: AppColors.danger,
      onError: AppColors.onDanger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.buildTextTheme(AppColors.textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: AppDimensions.elevationNone,
        centerTitle: false,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        StatusColorsExtension(
          pending: AppColors.warning,
          approved: AppColors.success,
          rejected: AppColors.danger,
          cancelled: AppColors.textSecondary,
        ),
      ],
    );
  }

  static ThemeData get darkTheme => lightTheme; // UI Kit Specification is Light-First
}
