import 'package:flutter/material.dart';

enum AppDividerAxis { horizontal, vertical }

class AppDivider extends StatelessWidget {
  final AppDividerAxis axis;
  final double thickness;
  final EdgeInsetsGeometry indent;

  const AppDivider({
    super.key,
    this.axis = AppDividerAxis.horizontal,
    this.thickness = 1.0,
    this.indent = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5);

    if (axis == AppDividerAxis.vertical) {
      return Container(
        margin: indent,
        width: thickness,
        color: color,
      );
    }

    return Padding(
      padding: indent,
      child: Divider(
        height: thickness,
        thickness: thickness,
        color: color,
      ),
    );
  }
}
