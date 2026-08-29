import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'color_tokens.dart';
import 'custom_theme_extensions.dart';
import 'dimension_tokens.dart';
import 'typography_tokens.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

abstract class AppTheme {
  static ThemeData get lightTheme {
    const ColorScheme colorScheme = ColorScheme.light(
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

  static ThemeData get darkTheme => lightTheme;
}
