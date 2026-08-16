import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';

/// A snapshot of device health data collected at ticket-creation time.
class TelemetrySnapshot {
  final String deviceModel;
  final String osVersion;
  final int batteryLevel;
  final String batteryState;
  final int freeMemoryMb;
  final int totalMemoryMb;
  final int freeStorageMb;
  final int totalStorageMb;
  final DateTime collectedAt;

  const TelemetrySnapshot({
    required this.deviceModel,
    required this.osVersion,
    required this.batteryLevel,
    required this.batteryState,
    required this.freeMemoryMb,
    required this.totalMemoryMb,
    required this.freeStorageMb,
    required this.totalStorageMb,
    required this.collectedAt,
  });

  Map<String, dynamic> toJson() => {
        'deviceModel': deviceModel,
        'osVersion': osVersion,
        'batteryLevel': batteryLevel,
        'batteryState': batteryState,
        'freeMemoryMb': freeMemoryMb,
        'totalMemoryMb': totalMemoryMb,
        'freeStorageMb': freeStorageMb,
        'totalStorageMb': totalStorageMb,
        'collectedAt': collectedAt.toIso8601String(),
      };
}

class TelemetryCollectionService {
  TelemetryCollectionService._();
  static final TelemetryCollectionService instance =
      TelemetryCollectionService._();

  final _deviceInfo = DeviceInfoPlugin();
  final _battery = Battery();

  /// Collect a snapshot of device telemetry right now.
  /// Returns null if collection fails (e.g. permissions denied).
  Future<TelemetrySnapshot?> collectSnapshot() async {
    try {
      String deviceModel = 'Unknown';
      String osVersion = 'Unknown';

      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        deviceModel = '${info.manufacturer} ${info.model}';
        osVersion = 'Android ${info.version.release} (SDK ${info.version.sdkInt})';
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        deviceModel = info.utsname.machine;
        osVersion = '${info.systemName} ${info.systemVersion}';
      }

      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;

      return TelemetrySnapshot(
        deviceModel: deviceModel,
        osVersion: osVersion,
        batteryLevel: batteryLevel,
        batteryState: batteryState.name,
        freeMemoryMb: 0, // Requires platform-specific channels
        totalMemoryMb: 0,
        freeStorageMb: 0,
        totalStorageMb: 0,
        collectedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
