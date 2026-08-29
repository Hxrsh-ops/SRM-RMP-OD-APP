import 'package:flutter/material.dart';
import '../../theme/tokens/theme_tokens.dart';

class AppClickableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const AppClickableCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.paddingCard,
    this.backgroundColor,
  });

  @override
  State<AppClickableCard> createState() => _AppClickableCardState();
}

class _AppClickableCardState extends State<AppClickableCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveColor = widget.backgroundColor ?? colorScheme.surface;
    final hoverOverlay = _isHovered ? colorScheme.onSurface.withValues(alpha: 0.04) : Colors.transparent;

    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: widget.onTap == null ? null : (_) => setState(() => _isPressed = true),
          onTapUp: widget.onTap == null ? null : (_) => setState(() => _isPressed = false),
          onTapCancel: widget.onTap == null ? null : () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: AppDuration.fast,
            child: AnimatedContainer(
              duration: AppDuration.fast,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: Color.alphaBlend(hoverOverlay, effectiveColor),
                borderRadius: AppRadius.borderLg,
                border: Border.all(
                  color: _isHovered
                      ? colorScheme.primary.withValues(alpha: 0.4)
                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: _isHovered ? 1.5 : 1.0,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
