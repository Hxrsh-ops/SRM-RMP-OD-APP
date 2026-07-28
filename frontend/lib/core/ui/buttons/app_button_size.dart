import 'package:flutter/material.dart';
import '../../theme/tokens/theme_tokens.dart';

enum AppButtonSize {
  small,
  medium,
  large,
}

extension AppButtonSizeX on AppButtonSize {
  double get height {
    switch (this) {
      case AppButtonSize.small:
        return 36.0;
      case AppButtonSize.medium:
        return 44.0;
      case AppButtonSize.large:
        return 52.0;
    }
  }

  double get iconSize {
    switch (this) {
      case AppButtonSize.small:
        return 16.0;
      case AppButtonSize.medium:
        return 20.0;
      case AppButtonSize.large:
        return 22.0;
    }
  }

  EdgeInsetsGeometry get padding {
    switch (this) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md);
    }
  }

  TextStyle? textStyle(ThemeData theme) {
    switch (this) {
      case AppButtonSize.small:
        return theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold);
      case AppButtonSize.medium:
        return theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold);
      case AppButtonSize.large:
        return theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    }
  }
}
