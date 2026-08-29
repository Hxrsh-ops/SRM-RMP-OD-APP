import 'package:flutter/material.dart';

class AppAvatarPlaceholder extends StatelessWidget {
  final String? name;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppAvatarPlaceholder({
    super.key,
    this.name,
    this.size = 40.0,
    this.backgroundColor,
    this.foregroundColor,
  });

  String get _initials {
    if (name == null || name!.trim().isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bg = backgroundColor ?? colorScheme.primaryContainer;
    final fg = foregroundColor ?? colorScheme.onPrimaryContainer;

    return Semantics(
      label: 'Avatar ${name ?? 'User'}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: name != null && name!.trim().isNotEmpty
            ? Text(
                _initials,
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: fg,
                ),
              )
            : Icon(
                Icons.person_rounded,
                size: size * 0.6,
                color: fg,
              ),
      ),
    );
  }
}
