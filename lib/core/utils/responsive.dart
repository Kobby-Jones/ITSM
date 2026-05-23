import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum DeviceType { mobile, tablet, desktop }

class Responsive {
  static DeviceType deviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < AppConstants.mobileBreakpoint) return DeviceType.mobile;
    if (width < AppConstants.tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext context) =>
      deviceType(context) == DeviceType.mobile;
  static bool isTablet(BuildContext context) =>
      deviceType(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) =>
      deviceType(context) == DeviceType.desktop;

  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final type = deviceType(context);
    switch (type) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  static EdgeInsets pagePadding(BuildContext context) {
    return value<EdgeInsets>(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }
}
