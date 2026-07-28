import 'package:flutter/material.dart';

abstract class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // Insets
  static const EdgeInsets paddingScreen = EdgeInsets.symmetric(horizontal: lg, vertical: xl);
  static const EdgeInsets paddingCard = EdgeInsets.all(lg);
  static const EdgeInsets paddingButtonSmall = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets paddingButtonMedium = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets paddingButtonLarge = EdgeInsets.symmetric(horizontal: xl, vertical: lg);
}
