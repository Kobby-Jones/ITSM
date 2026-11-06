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
  // Metrics below are null when the client could not capture them. They are
  // never defaulted to zero, so the UI can show "N/A" instead of a fake reading.
  final int? ramTotalMb;
  final int? ramUsedMb;
  final double? cpuUsage; // 0..1
  final int? storageTotalGb;
  final int? storageUsedGb;
  final String networkStatus; // Online, Offline, Limited
  final String networkType; // Wi-Fi, Ethernet, 4G
  final int? batteryPercent; // null for desktop
  final bool charging;
  final double? cpuTemperature;
  final List<TelemetryLog> logs;
  final DateTime collectedAt;
  final String publicIp;
  final String macAddress;
  final List<({String name, double cpu, double mem})> topProcesses;

  /// Metric key (`cpu`, `memory`, `storage`, `battery`) -> why it was not
  /// captured, as reported by the client collector.
  final Map<String, String> unavailable;

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
    this.unavailable = const {},
  });

  /// 0..1, or null when RAM figures were not captured.
  double? get ramUsage {
    final total = ramTotalMb;
    final used = ramUsedMb;
    if (total == null || used == null || total <= 0) return null;
    return used / total;
  }

  /// 0..1, or null when storage figures were not captured.
  double? get storageUsage {
    final total = storageTotalGb;
    final used = storageUsedGb;
    if (total == null || used == null || total <= 0) return null;
    return used / total;
  }

  /// Builds a telemetry view from either the backend ticket/device telemetry
  /// row or the locally-captured snapshot cached with an offline ticket.
  factory DeviceTelemetry.fromJson(
    Map<String, dynamic> json, {
    String? deviceId,
  }) {
    final device = json['device'] is Map
        ? Map<String, dynamic>.from(json['device'] as Map)
        : const <String, dynamic>{};
    final metadata = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : const <String, dynamic>{};

    // A missing or non-positive total means "not captured" -> null, never 0.
    int? bytesToMb(num? value) => (value == null || value <= 0)
        ? null
        : (value.toDouble() / (1024 * 1024)).round();
    int? bytesToGb(num? value) => (value == null || value <= 0)
        ? null
        : (value.toDouble() / (1024 * 1024 * 1024)).round();

    final ramTotalBytes = (json['ramTotal'] as num?)?.toDouble();
    final ramAvailableBytes = (json['ramAvailable'] as num?)?.toDouble();
    final storageTotalBytes = (json['storageTotal'] as num?)?.toDouble();
    final storageAvailableBytes =
        (json['storageAvailable'] as num?)?.toDouble();

    final logs = <TelemetryLog>[];
    final errorLogs = json['errorLogs'];
    if (errorLogs is List) {
      for (final entry in errorLogs) {
        if (entry is! Map) continue;
        final map = Map<String, dynamic>.from(entry);
        logs.add(TelemetryLog(
          timestamp: DateTime.tryParse(
                map['timestamp']?.toString() ??
                    json['recordedAt']?.toString() ??
                    '',
              ) ??
              DateTime.now(),
          level: map['level']?.toString().toUpperCase() ?? 'ERROR',
          tag: map['tag']?.toString() ?? 'device',
          message: map['message']?.toString() ?? map.toString(),
        ));
      }
    }
    final crash = json['crashLogs'];
    if (crash is Map) {
      final map = Map<String, dynamic>.from(crash);
      logs.add(TelemetryLog(
        timestamp: DateTime.tryParse(
              map['timestamp']?.toString() ??
                  json['recordedAt']?.toString() ??
                  '',
            ) ??
            DateTime.now(),
        level: 'CRASH',
        tag: map['tag']?.toString() ?? 'application',
        message: map['message']?.toString() ?? map.toString(),
      ));
    }

    final processes = <({String name, double cpu, double mem})>[];
    final rawProcesses = metadata['topProcesses'];
    if (rawProcesses is List) {
      for (final raw in rawProcesses) {
        if (raw is! Map) continue;
        processes.add((
          name: raw['name']?.toString() ?? 'process',
          cpu: (raw['cpu'] as num?)?.toDouble() ?? 0,
          mem: (raw['mem'] as num?)?.toDouble() ?? 0,
        ));
      }
    }

    final batteryState = metadata['batteryState']?.toString().toLowerCase();
    final publicDeviceId = deviceId ??
        device['deviceId']?.toString() ??
        json['publicDeviceId']?.toString() ??
        json['deviceId']?.toString() ??
        '';

    final ramTotalMb = bytesToMb(ramTotalBytes);
    final ramUsedMb = (ramTotalBytes != null &&
            ramTotalBytes > 0 &&
            ramAvailableBytes != null)
        ? ((ramTotalBytes - ramAvailableBytes).clamp(0.0, ramTotalBytes) /
                (1024 * 1024))
            .round()
        : null;
    final storageTotalGb = bytesToGb(storageTotalBytes);
    final storageUsedGb = (storageTotalBytes != null &&
            storageTotalBytes > 0 &&
            storageAvailableBytes != null)
        ? ((storageTotalBytes - storageAvailableBytes)
                    .clamp(0.0, storageTotalBytes) /
                (1024 * 1024 * 1024))
            .round()
        : null;

    final cpuRaw = (json['cpuUsage'] as num?)?.toDouble();
    final cpuFraction =
        cpuRaw == null ? null : (cpuRaw / 100).clamp(0.0, 1.0).toDouble();

    final unavailable = <String, String>{};
    final unavailableRaw = metadata['unavailableMetrics'];
    if (unavailableRaw is Map) {
      unavailableRaw.forEach((key, value) {
        unavailable[key.toString()] = value.toString();
      });
    }

    return DeviceTelemetry(
      deviceId: publicDeviceId,
      deviceModel: json['deviceModel'] as String? ??
          device['model']?.toString() ??
          'Unknown device',
      osVersion: json['osVersion'] as String? ??
          device['osVersion']?.toString() ??
          '',
      hostname: metadata['hostname']?.toString() ?? '',
      ramTotalMb: ramTotalMb,
      ramUsedMb: ramUsedMb,
      cpuUsage: cpuFraction,
      storageTotalGb: storageTotalGb,
      storageUsedGb: storageUsedGb,
      networkStatus: _normalizeNetworkStatus(json['networkStatus']),
      networkType: _normalizeNetworkType(json['networkType']),
      batteryPercent: (json['batteryLevel'] as num?)?.round(),
      charging: batteryState == 'charging' || batteryState == 'full',
      cpuTemperature: (metadata['cpuTemperature'] as num?)?.toDouble(),
      logs: logs,
      collectedAt: DateTime.tryParse(json['recordedAt']?.toString() ?? '') ??
          DateTime.now(),
      publicIp: metadata['publicIp']?.toString() ?? '',
      macAddress: metadata['macAddress']?.toString() ?? '',
      topProcesses: processes,
      unavailable: unavailable,
    );
  }

  /// The collector sends lowercase values (`online`, `wifi`); the UI and the
  /// backend-facing labels use display casing. Accept either form.
  static String _normalizeNetworkStatus(Object? raw) {
    switch (raw?.toString().trim().toLowerCase()) {
      case 'online':
        return 'Online';
      case 'offline':
        return 'Offline';
      case 'limited':
        return 'Limited';
      default:
        return 'Unknown';
    }
  }

  static String _normalizeNetworkType(Object? raw) {
    final original = raw?.toString().trim() ?? '';
    final key = original.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    switch (key) {
      case 'wifi':
        return 'Wi-Fi';
      case 'ethernet':
        return 'Ethernet';
      case 'cellular':
      case 'mobile':
        return 'Cellular';
      case '':
      case 'unknown':
        return 'Unknown';
      default:
        return original; // e.g. "4G" from an older backend row
    }
  }
}
