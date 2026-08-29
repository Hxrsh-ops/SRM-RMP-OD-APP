import 'package:flutter/material.dart';

abstract class AppBreakpoints {
  static const double mobile = 768.0;
  static const double tablet = 1024.0;
  static const double desktop = 1280.0;
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? laptop;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.laptop,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppBreakpoints.mobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppBreakpoints.mobile && width < AppBreakpoints.tablet;
  }

  static bool isLaptop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppBreakpoints.tablet && width < AppBreakpoints.desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppBreakpoints.desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.desktop && desktop != null) {
          return desktop!;
        }
        if (constraints.maxWidth >= AppBreakpoints.tablet && laptop != null) {
          return laptop!;
        }
        if (constraints.maxWidth >= AppBreakpoints.mobile && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}

extension ResponsiveContextExtension on BuildContext {
  bool get isMobile => ResponsiveLayout.isMobile(this);
  bool get isTablet => ResponsiveLayout.isTablet(this);
  bool get isLaptop => ResponsiveLayout.isLaptop(this);
  bool get isDesktop => ResponsiveLayout.isDesktop(this);
}
