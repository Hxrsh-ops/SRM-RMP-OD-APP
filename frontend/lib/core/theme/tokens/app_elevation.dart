import 'package:flutter/material.dart';

abstract class AppElevation {
  static const double none = 0.0;
  static const double low = 2.0;
  static const double medium = 4.0;
  static const double high = 8.0;
}

abstract class AppShadows {
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> hover = [
    BoxShadow(
      color: Color(0x1400296B),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}
