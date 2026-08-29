import 'package:flutter/material.dart';
import '../../theme/tokens/theme_tokens.dart';

class AppMultilineField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final int minLines;
  final int maxLines;
  final bool enabled;

  const AppMultilineField({
    super.key,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.validator,
    this.minLines = 3,
    this.maxLines = 6,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      textField: true,
      multiline: true,
      enabled: enabled,
      label: labelText ?? hintText ?? 'Multiline Input',
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        validator: validator,
        minLines: minLines,
        maxLines: maxLines,
        enabled: enabled,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.38),
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          helperText: helperText,
          errorText: errorText,
          alignLabelWithHint: true,
          contentPadding: const EdgeInsets.all(AppSpacing.lg),
          filled: true,
          fillColor: enabled ? colorScheme.surface : colorScheme.onSurface.withValues(alpha: 0.04),
          border: OutlineInputBorder(
            borderRadius: AppRadius.borderMd,
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderMd,
            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderMd,
            borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderMd,
            borderSide: BorderSide(color: colorScheme.error),
          ),
        ),
      ),
    );
  }
}
