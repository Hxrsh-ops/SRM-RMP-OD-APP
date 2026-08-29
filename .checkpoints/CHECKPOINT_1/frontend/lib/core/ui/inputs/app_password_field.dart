import 'package:flutter/material.dart';
import '../../theme/tokens/theme_tokens.dart';

class AppPasswordField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const AppPasswordField({
    super.key,
    this.labelText = 'Password',
    this.hintText = 'Enter password',
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      textField: true,
      obscured: _obscureText,
      enabled: widget.enabled,
      label: widget.labelText ?? 'Password Field',
      child: TextFormField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        validator: widget.validator,
        onFieldSubmitted: widget.onFieldSubmitted,
        textInputAction: widget.textInputAction,
        obscureText: _obscureText,
        enabled: widget.enabled,
        focusNode: widget.focusNode,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: widget.enabled ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.38),
        ),
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          helperText: widget.helperText,
          errorText: widget.errorText,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: widget.enabled
                ? () => setState(() => _obscureText = !_obscureText)
                : null,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          filled: true,
          fillColor: widget.enabled ? colorScheme.surface : colorScheme.onSurface.withValues(alpha: 0.04),
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
