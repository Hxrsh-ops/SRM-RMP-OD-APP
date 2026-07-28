import 'package:flutter/material.dart';
import '../../theme/tokens/theme_tokens.dart';

class AppSearchField extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool enabled;

  const AppSearchField({
    super.key,
    this.hintText = 'Search...',
    this.controller,
    this.onChanged,
    this.onClear,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      textField: true,
      enabled: enabled,
      label: hintText ?? 'Search Field',
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        enabled: enabled,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: enabled
              ? colorScheme.onSurface
              : colorScheme.onSurface.withValues(alpha: 0.38),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon:
              Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant),
          suffixIcon: controller != null && controller!.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      color: colorScheme.onSurfaceVariant),
                  onPressed: () {
                    controller!.clear();
                    onChanged?.call('');
                    onClear?.call();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          filled: true,
          fillColor: enabled
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : colorScheme.onSurface.withValues(alpha: 0.04),
          border: const OutlineInputBorder(
            borderRadius: AppRadius.borderFull,
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: AppRadius.borderFull,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderFull,
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
