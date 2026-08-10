import 'package:flutter/material.dart';

class TelemetryLog {
  final DateTime timestamp;
  final String level; // INFO, WARN, ERROR, CRASH
  final String tag;
  final String message;

  const TelemetryLog({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
  });

  /// Backend `TelemetryLog` rows don't carry a single "level/tag/message"
  /// triplet — they store structured `errorLogs`/`crashLogs` JSON blobs plus
  /// numeric health metrics. This flattens one backend row into the log feed
  /// shape the UI expects; call once per JSON error/crash entry.
  factory TelemetryLog.fromJson(Map<String, dynamic> json, {required String level, required String message}) {
    return TelemetryLog(
      timestamp: DateTime.parse(json['recordedAt'] as String? ?? DateTime.now().toIso8601String()),
      level: level,
      tag: json['deviceModel'] as String? ?? 'device',
      message: message,
    );
  }

  Color get color {
    switch (level) {
      case 'ERROR':
        return const Color(0xFFEF4444);
      case 'CRASH':
        return const Color(0xFFDC2626);
      case 'WARN':
        return const Color(0xFFF59E0B);
      case 'INFO':
      default:
        return const Color(0xFF3B82F6);
    }
  }
}

class DeviceTelemetry {
  final String deviceId;
  final String deviceModel;
  final String osVersion;
  final String hostname;
  final int ramTotalMb;
  final int ramUsedMb;
  final double cpuUsage; // 0..1
  final int storageTotalGb;
  final int storageUsedGb;
  final String networkStatus; // Online, Offline, Limited
  final String networkType; // Wi-Fi, Ethernet, 4G
  final int? batteryPercent; // null for desktop
  final bool charging;
  final double cpuTemperature;
  final List<TelemetryLog> logs;
  final DateTime collectedAt;
  final String publicIp;
  final String macAddress;
  final List<({String name, double cpu, double mem})> topProcesses;

  const DeviceTelemetry({
    required this.deviceId,
    required this.deviceModel,
    required this.osVersion,
    required this.hostname,
    required this.ramTotalMb,
    required this.ramUsedMb,
    required this.cpuUsage,
    required this.storageTotalGb,
    required this.storageUsedGb,
    required this.networkStatus,
    required this.networkType,
    this.batteryPercent,
    required this.charging,
    required this.cpuTemperature,
    required this.logs,
    required this.collectedAt,
    required this.publicIp,
    required this.macAddress,
    required this.topProcesses,
  });

  double get ramUsage => ramUsedMb / ramTotalMb;
  double get storageUsage => storageUsedGb / storageTotalGb;

  /// Populates the backend-sourced subset of fields from a synced
  /// `TelemetryLog` row (`GET /telemetry/:deviceId`). Fields the backend
  /// doesn't collect today — [publicIp], [macAddress], [topProcesses], and
  /// live [logs] — are left as sensible defaults; those come from on-device
  /// packages (e.g. `device_info_plus`, `battery_plus`) at collection time,
  /// not from this history endpoint.
  factory DeviceTelemetry.fromJson(Map<String, dynamic> json, {required String deviceId}) {
    final ramTotal = (json['ramTotal'] as num?)?.toInt() ?? 0;
    final ramAvailable = (json['ramAvailable'] as num?)?.toInt() ?? 0;
    final storageTotal = (json['storageTotal'] as num?)?.toInt() ?? 0;
    final storageAvailable = (json['storageAvailable'] as num?)?.toInt() ?? 0;
    return DeviceTelemetry(
      deviceId: deviceId,
      deviceModel: json['deviceModel'] as String? ?? 'Unknown device',
      osVersion: json['osVersion'] as String? ?? '',
      hostname: '',
      ramTotalMb: (ramTotal / (1024 * 1024)).round(),
      ramUsedMb: ((ramTotal - ramAvailable) / (1024 * 1024)).round(),
      cpuUsage: ((json['cpuUsage'] as num?)?.toDouble() ?? 0) / 100,
      storageTotalGb: (storageTotal / (1024 * 1024 * 1024)).round(),
      storageUsedGb: ((storageTotal - storageAvailable) / (1024 * 1024 * 1024)).round(),
      networkStatus: json['networkStatus'] as String? ?? 'Unknown',
      networkType: json['networkType'] as String? ?? '',
      batteryPercent: (json['batteryLevel'] as num?)?.round(),
      charging: false,
      cpuTemperature: 0,
      logs: const [],
      collectedAt: DateTime.parse(json['recordedAt'] as String? ?? DateTime.now().toIso8601String()),
      publicIp: '',
      macAddress: '',
      topProcesses: const [],
    );
  }
}
