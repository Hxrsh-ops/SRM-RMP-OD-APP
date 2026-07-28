import 'package:flutter/material.dart';
import '../../theme/tokens/theme_tokens.dart';
import 'app_button_size.dart';

class AppPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final AppButtonSize size;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.prefixIcon,
    this.suffixIcon,
    this.size = AppButtonSize.medium,
  });

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _isPressed = false;

  bool get _effectiveDisabled => widget.isDisabled || widget.isLoading || widget.onPressed == null;

  EdgeInsets get _padding {
    switch (widget.size) {
      case AppButtonSize.small:
        return AppSpacing.paddingButtonSmall;
      case AppButtonSize.medium:
        return AppSpacing.paddingButtonMedium;
      case AppButtonSize.large:
        return AppSpacing.paddingButtonLarge;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case AppButtonSize.small:
        return 13.0;
      case AppButtonSize.medium:
        return 15.0;
      case AppButtonSize.large:
        return 16.0;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case AppButtonSize.small:
        return 16.0;
      case AppButtonSize.medium:
        return 18.0;
      case AppButtonSize.large:
        return 20.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = _effectiveDisabled
        ? colorScheme.onSurface.withValues(alpha: 0.12)
        : colorScheme.primary;

    final foregroundColor = _effectiveDisabled
        ? colorScheme.onSurface.withValues(alpha: 0.38)
        : colorScheme.onPrimary;

    return Semantics(
      button: true,
      enabled: !_effectiveDisabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _effectiveDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: _effectiveDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: _effectiveDisabled ? null : () => setState(() => _isPressed = false),
        onTap: _effectiveDisabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: AppDuration.fast,
          child: AnimatedContainer(
            duration: AppDuration.fast,
            constraints: const BoxConstraints(minHeight: 48.0, minWidth: 48.0),
            padding: _padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppRadius.borderMd,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: _iconSize,
                    height: _iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ] else if (widget.prefixIcon != null) ...[
                  Icon(widget.prefixIcon, size: _iconSize, color: foregroundColor),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontWeight: FontWeight.w600,
                        color: foregroundColor,
                      ),
                    ),
                  ),
                ),
                if (!widget.isLoading && widget.suffixIcon != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(widget.suffixIcon, size: _iconSize, color: foregroundColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
