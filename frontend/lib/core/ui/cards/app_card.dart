import 'package:flutter/material.dart';
import '../../theme/color_tokens.dart';
import '../../theme/tokens/theme_tokens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final BorderSide? borderSide;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.backgroundColor,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.fromBorderSide(
          borderSide ?? const BorderSide(color: AppColors.border, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
