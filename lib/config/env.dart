import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Which backend environment the app is pointed at.
///
/// Selected at build/run time via `--dart-define`, e.g.:
///   flutter run --dart-define=ENV=dev
///   flutter build apk --dart-define=ENV=prod --dart-define=API_BASE_URL=https://api.yourcompany.com
enum AppEnvironment { dev, staging, prod }

class Env {
  Env._();

  static const String _envName = String.fromEnvironment('ENV', defaultValue: 'dev');

  static AppEnvironment get current {
    switch (_envName) {
      case 'prod':
        return AppEnvironment.prod;
      case 'staging':
        return AppEnvironment.staging;
      default:
        return AppEnvironment.dev;
    }
  }

  /// Explicit override, e.g. `--dart-define=API_BASE_URL=https://api.example.com/api/v1`.
  /// Takes precedence over everything else — always set this for staging/prod builds.
  static const String _explicitBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// API version prefix used by the backend (matches `API_PREFIX` server-side, default `/api/v1`).
  static const String apiVersion = String.fromEnvironment('API_VERSION', defaultValue: 'v1');

  /// Resolves the base URL to hit for the current platform/environment.
  ///
  /// Local development notes:
  /// - Android emulator can't reach `localhost` on the host machine; it must use
  ///   the special alias `10.0.2.2`.
  /// - iOS simulator, desktop (Windows/macOS/Linux), and web can all reach
  ///   `localhost` directly since they share the host's network stack.
  /// - A **physical device** (Android/iOS) cannot reach `localhost` OR
  ///   `10.0.2.2` — you must pass your machine's LAN IP explicitly:
  ///     flutter run --dart-define=API_BASE_URL=http://192.168.1.23:3000/api/v1
  static String get baseUrl {
    if (_explicitBaseUrl.isNotEmpty) return _explicitBaseUrl;

    if (current == AppEnvironment.prod || current == AppEnvironment.staging) {
      throw StateError(
        'No API_BASE_URL provided for a ${current.name} build. '
        'Pass one explicitly: --dart-define=API_BASE_URL=https://your-api.example.com/api/v1',
      );
    }

    const port = 3000;
    const path = '/api/$apiVersion';

    if (kIsWeb) return 'http://localhost:$port$path';

    if (Platform.isAndroid) return 'http://10.0.2.2:$port$path';

    // iOS simulator, macOS, Windows, Linux desktop.
    return 'http://localhost:$port$path';
  }

  /// Timeouts are intentionally generous for slower/offline-first mobile networks.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
