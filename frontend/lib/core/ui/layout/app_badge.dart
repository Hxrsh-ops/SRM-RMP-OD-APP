import 'package:flutter/material.dart';
import '../../theme/tokens/theme_tokens.dart';

class AppBadge extends StatelessWidget {
  final String? label;
  final Widget? child;
  final Color? color;
  final Color? textColor;

  const AppBadge({
    super.key,
    this.label,
    this.child,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final badgeColor = color ?? colorScheme.primary;
    final badgeTextColor = textColor ?? colorScheme.onPrimary;

    final badgeWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2.0),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: AppRadius.borderFull,
      ),
      constraints: const BoxConstraints(minWidth: 16.0, minHeight: 16.0),
      child: label != null
          ? Text(
              label!,
              style: TextStyle(
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
                color: badgeTextColor,
              ),
              textAlign: TextAlign.center,
            )
          : null,
    );

    if (child == null) {
      return badgeWidget;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child!,
        Positioned(
          top: -4,
          right: -4,
          child: badgeWidget,
        ),
      ],
    );
  }
}
