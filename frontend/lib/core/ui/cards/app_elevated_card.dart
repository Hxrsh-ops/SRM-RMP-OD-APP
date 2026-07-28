import 'package:flutter/material.dart';
import '../../theme/tokens/theme_tokens.dart';

class AppElevatedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final Color? backgroundColor;

  const AppElevatedCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.paddingCard,
    this.elevation = AppElevation.low,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: elevation,
      margin: EdgeInsets.zero,
      color: backgroundColor ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.borderLg,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
