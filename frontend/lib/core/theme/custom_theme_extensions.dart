import 'package:flutter/material.dart';

@immutable
class StatusColorsExtension extends ThemeExtension<StatusColorsExtension> {
  final Color pending;
  final Color approved;
  final Color rejected;
  final Color cancelled;

  const StatusColorsExtension({
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.cancelled,
  });

  @override
  StatusColorsExtension copyWith({
    Color? pending,
    Color? approved,
    Color? rejected,
    Color? cancelled,
  }) {
    return StatusColorsExtension(
      pending: pending ?? this.pending,
      approved: approved ?? this.approved,
      rejected: rejected ?? this.rejected,
      cancelled: cancelled ?? this.cancelled,
    );
  }

  @override
  StatusColorsExtension lerp(
    ThemeExtension<StatusColorsExtension>? other,
    double t,
  ) {
    if (other is! StatusColorsExtension) return this;
    return StatusColorsExtension(
      pending: Color.lerp(pending, other.pending, t)!,
      approved: Color.lerp(approved, other.approved, t)!,
      rejected: Color.lerp(rejected, other.rejected, t)!,
      cancelled: Color.lerp(cancelled, other.cancelled, t)!,
    );
  }
}
