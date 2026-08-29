import 'package:flutter/material.dart';

class AppInitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Border? border;

  const AppInitialsAvatar({
    super.key,
    required this.name,
    this.size = 40.0,
    this.backgroundColor,
    this.foregroundColor,
    this.border,
  });

  static String getInitials(String rawName) {
    if (rawName.trim().isEmpty) return '?';
    final cleaned = rawName
        .replaceAll(RegExp(r'^(Dr\.|Prof\.|Mr\.|Mrs\.|Ms\.)\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .trim();

    if (cleaned.isEmpty) return rawName[0].toUpperCase();

    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(name);

    final defaultBg = Theme.of(context).primaryColor.withValues(alpha: 0.15);
    final defaultFg = Theme.of(context).primaryColor;

    final bg = backgroundColor ?? defaultBg;
    final fg = foregroundColor ?? defaultFg;

    return Semantics(
      label: 'Avatar initials $initials for $name',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: border,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: fg,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
