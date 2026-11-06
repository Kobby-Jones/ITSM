import 'telemetry_platform_stats.dart';

/// Web/non-IO fallback for platform telemetry. Browsers do not expose CPU,
/// RAM-in-use, or disk figures, so everything is reported as unavailable.
class TelemetryPlatform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isWindows => false;
  static bool get isLinux => false;
  static bool get isMacOS => false;

  static String get hostname => '';
  static String get operatingSystemVersion => '';

  static Future<PlatformStats> readStats() async => const PlatformStats();
}
