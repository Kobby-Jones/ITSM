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
}
