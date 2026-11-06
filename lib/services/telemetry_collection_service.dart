import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/storage/secure_storage_service.dart';
import 'telemetry_platform/telemetry_platform.dart';
import 'telemetry_platform/telemetry_platform_stats.dart';

/// Trims a string to the maximum length the backend accepts for that field
/// (see the `telemetry` schema in tickets.routes.js). Without this, one overly
/// long value makes the whole create-ticket request fail with 400.
String _clip(String value, int max) =>
    value.length <= max ? value : value.substring(0, max);

/// A backend-compatible snapshot of device health data collected at
/// ticket-creation time. Unsupported metrics are omitted rather than sent as
/// zero so the server never interprets "not available" as a real reading.
///
/// Anything that could not be captured is listed, with a reason, under
/// `metadata.unavailableMetrics` so the gap is explicit and auditable.
class TelemetrySnapshot {
  final String deviceId;
  final String platform;
  final String deviceModel;
  final String osVersion;
  final double? cpuUsage;
  final int? ramTotal;
  final int? ramAvailable;
  final double? batteryLevel;
  final int? storageTotal;
  final int? storageAvailable;
  final String networkStatus;
  final String networkType;
  final Map<String, dynamic> metadata;
  final DateTime collectedAt;

  const TelemetrySnapshot({
    required this.deviceId,
    required this.platform,
    required this.deviceModel,
    required this.osVersion,
    this.cpuUsage,
    this.ramTotal,
    this.ramAvailable,
    this.batteryLevel,
    this.storageTotal,
    this.storageAvailable,
    required this.networkStatus,
    required this.networkType,
    required this.metadata,
    required this.collectedAt,
  });

  /// True when at least one hardware health reading was captured, as opposed
  /// to identity and network information only.
  bool get hasHealthMetrics =>
      cpuUsage != null ||
      ramTotal != null ||
      storageTotal != null ||
      batteryLevel != null;

  Map<String, dynamic> toJson() => {
        'deviceId': _clip(deviceId, 200),
        'platform': platform,
        'deviceModel': _clip(deviceModel, 200),
        'osVersion': _clip(osVersion, 100),
        if (cpuUsage != null) 'cpuUsage': cpuUsage,
        if (ramTotal != null && ramTotal! > 0) 'ramTotal': ramTotal,
        if (ramAvailable != null && ramAvailable! >= 0)
          'ramAvailable': ramAvailable,
        if (batteryLevel != null) 'batteryLevel': batteryLevel,
        if (storageTotal != null && storageTotal! > 0)
          'storageTotal': storageTotal,
        if (storageAvailable != null && storageAvailable! >= 0)
          'storageAvailable': storageAvailable,
        'networkStatus': networkStatus,
        'networkType': networkType,
        'metadata': metadata,
        'recordedAt': collectedAt.toUtc().toIso8601String(),
      };
}

class TelemetryCollectionService {
  TelemetryCollectionService._();
  static final TelemetryCollectionService instance =
      TelemetryCollectionService._();

  final _deviceInfo = DeviceInfoPlugin();
  final _battery = Battery();
  final _connectivity = Connectivity();

  static const _shortTimeout = Duration(seconds: 3);
  static const _statsTimeout = Duration(seconds: 12);

  /// Used only if secure storage fails, so one session still correlates.
  String? _sessionDeviceId;

  /// Collect a best-effort telemetry snapshot at ticket-creation time.
  ///
  /// Each stage (identity, battery, network, CPU/RAM/storage) is guarded and
  /// time-boxed on its own, so one failing metric never discards the rest and
  /// a hanging native call can never block ticket submission. Returns a
  /// snapshot even when every optional metric failed; `metadata` then explains
  /// what is missing.
  Future<TelemetrySnapshot?> collectSnapshot() async {
    final stopwatch = Stopwatch()..start();
    final collectedAt = DateTime.now();
    final metadata = <String, dynamic>{};
    final unavailable = <String, String>{};

    final deviceId = await _resolveDeviceId(metadata);

    // ---- Identity (and, on Android/iOS, RAM + storage from the OS) --------
    var platform = 'unknown';
    var deviceModel = 'Unknown device';
    var osVersion = 'Unknown';
    int? pluginRamTotal;
    int? pluginRamAvailable;
    int? pluginStorageTotal;
    int? pluginStorageAvailable;

    try {
      if (kIsWeb) {
        platform = 'web';
        final info = await _deviceInfo.webBrowserInfo.timeout(_shortTimeout);
        deviceModel = info.browserName.name;
        // The backend caps osVersion at 100 characters, and a real user-agent
        // is longer (Chrome ~111, Edge ~125, Safari ~135), which made every
        // web ticket fail with 400. Send the short platform here and keep the
        // full user-agent in metadata, which has no length limit.
        osVersion = info.platform ?? 'Web browser';
        metadata.addAll({
          'userAgent': info.userAgent,
          'browserName': info.browserName.name,
          'appName': info.appName,
          'browserVersion': info.appVersion,
          'browserPlatform': info.platform,
        });
      } else if (TelemetryPlatform.isAndroid) {
        platform = 'android';
        final info = await _deviceInfo.androidInfo.timeout(_shortTimeout);
        deviceModel = '${info.manufacturer} ${info.model}'.trim();
        osVersion =
            'Android ${info.version.release} (SDK ${info.version.sdkInt})';
        metadata.addAll({
          'manufacturer': info.manufacturer,
          'brand': info.brand,
          'product': info.product,
          'hardware': info.hardware,
          'isPhysicalDevice': info.isPhysicalDevice,
          'androidBuildId': info.id,
        });
        // device_info_plus: RAM sizes are in MB, disk sizes are in bytes.
        pluginRamTotal = _mbToBytes(info.physicalRamSize);
        pluginRamAvailable = _mbToBytes(info.availableRamSize);
        pluginStorageTotal = _positive(info.totalDiskSize);
        pluginStorageAvailable = _nonNegative(info.freeDiskSize);
      } else if (TelemetryPlatform.isIOS) {
        platform = 'ios';
        final info = await _deviceInfo.iosInfo.timeout(_shortTimeout);
        deviceModel = info.model;
        osVersion = '${info.systemName} ${info.systemVersion}';
        metadata.addAll({
          'machine': info.utsname.machine,
          'name': info.name,
          'isPhysicalDevice': info.isPhysicalDevice,
        });
        pluginRamTotal = _mbToBytes(info.physicalRamSize);
        pluginRamAvailable = _mbToBytes(info.availableRamSize);
        pluginStorageTotal = _positive(info.totalDiskSize);
        pluginStorageAvailable = _nonNegative(info.freeDiskSize);
      } else if (TelemetryPlatform.isWindows) {
        platform = 'windows';
        deviceModel = TelemetryPlatform.hostname;
        osVersion = TelemetryPlatform.operatingSystemVersion;
      } else if (TelemetryPlatform.isLinux) {
        platform = 'linux';
        deviceModel = TelemetryPlatform.hostname;
        osVersion = TelemetryPlatform.operatingSystemVersion;
      } else if (TelemetryPlatform.isMacOS) {
        platform = 'macos';
        deviceModel = TelemetryPlatform.hostname;
        osVersion = TelemetryPlatform.operatingSystemVersion;
      }
    } catch (e) {
      // Keep whatever identity was filled in before the failure.
      _log('device info', e);
    }

    // ---- Battery ----------------------------------------------------------
    double? batteryLevel;
    try {
      batteryLevel = (await _battery.batteryLevel.timeout(_shortTimeout))
          .toDouble();
    } catch (e) {
      // Normal on desktops without a battery and on browsers.
      _log('battery level', e);
      unavailable['battery'] = 'Not reported by this device';
    }
    try {
      metadata['batteryState'] =
          (await _battery.batteryState.timeout(_shortTimeout)).name;
    } catch (_) {}

    // ---- Network ----------------------------------------------------------
    var networkStatus = 'offline';
    var networkType = 'unknown';
    try {
      final connectivity =
          await _connectivity.checkConnectivity().timeout(_shortTimeout);
      final active = connectivity
          .where((result) => result != ConnectivityResult.none)
          .toList();
      networkStatus = active.isEmpty ? 'offline' : 'online';
      if (active.contains(ConnectivityResult.wifi)) {
        networkType = 'wifi';
      } else if (active.contains(ConnectivityResult.mobile)) {
        networkType = 'cellular';
      } else if (active.contains(ConnectivityResult.ethernet)) {
        networkType = 'ethernet';
      }
    } catch (e) {
      _log('connectivity', e);
      networkStatus = 'limited';
    }

    // ---- CPU / RAM / storage ---------------------------------------------
    PlatformStats stats;
    try {
      stats = await TelemetryPlatform.readStats().timeout(_statsTimeout);
    } catch (e) {
      _log('platform stats', e);
      stats = const PlatformStats();
    }

    // Prefer the OS-provided Android/iOS values; fall back to /proc and df.
    // RAM and storage are each taken as a matched (total, available) pair so
    // two different sources are never mixed.
    int? ramTotal;
    int? ramAvailable;
    if (pluginRamTotal != null && pluginRamAvailable != null) {
      ramTotal = pluginRamTotal;
      ramAvailable = pluginRamAvailable;
    } else if (stats.ramTotalBytes != null &&
        stats.ramAvailableBytes != null) {
      ramTotal = stats.ramTotalBytes;
      ramAvailable = stats.ramAvailableBytes;
    }

    int? storageTotal;
    int? storageAvailable;
    if (pluginStorageTotal != null && pluginStorageAvailable != null) {
      storageTotal = pluginStorageTotal;
      storageAvailable = pluginStorageAvailable;
    } else if (stats.storageTotalBytes != null &&
        stats.storageAvailableBytes != null) {
      storageTotal = stats.storageTotalBytes;
      storageAvailable = stats.storageAvailableBytes;
    }

    final cpuUsage = stats.cpuPercent;

    if (cpuUsage == null) {
      unavailable['cpu'] =
          stats.unavailable['cpu'] ?? _defaultReason('cpu', platform);
    }
    if (ramTotal == null) {
      unavailable['memory'] =
          stats.unavailable['memory'] ?? _defaultReason('memory', platform);
    }
    if (storageTotal == null) {
      unavailable['storage'] =
          stats.unavailable['storage'] ?? _defaultReason('storage', platform);
    }

    // ---- Metadata ---------------------------------------------------------
    // localHostname is just "localhost" on Android/iOS and meaningless in a
    // browser, so only report it where it identifies the machine.
    final hostname = TelemetryPlatform.hostname;
    final isMobileOrWeb =
        platform == 'android' || platform == 'ios' || platform == 'web';
    if (hostname.isNotEmpty && !isMobileOrWeb) {
      metadata['hostname'] = hostname;
    }
    if (unavailable.isNotEmpty) metadata['unavailableMetrics'] = unavailable;
    metadata['collectionSource'] = 'ticket_creation';
    metadata['collectorVersion'] = 2;
    metadata['collectionMs'] = stopwatch.elapsedMilliseconds;

    if (kDebugMode) {
      debugPrint(
        '[TELEMETRY] $platform captured in ${stopwatch.elapsedMilliseconds} ms '
        '(cpu=${cpuUsage?.toStringAsFixed(0) ?? 'n/a'}, '
        'ram=${ramTotal != null}, storage=${storageTotal != null}, '
        'battery=${batteryLevel != null}, missing=${unavailable.keys.toList()})',
      );
    }

    return TelemetrySnapshot(
      deviceId: deviceId,
      platform: platform,
      deviceModel: deviceModel,
      osVersion: osVersion,
      cpuUsage: cpuUsage,
      ramTotal: ramTotal,
      ramAvailable: ramAvailable,
      batteryLevel: batteryLevel,
      storageTotal: storageTotal,
      storageAvailable: storageAvailable,
      networkStatus: networkStatus,
      networkType: networkType,
      metadata: metadata,
      collectedAt: collectedAt,
    );
  }

  Future<String> _resolveDeviceId(Map<String, dynamic> metadata) async {
    try {
      return await SecureStorageService.instance
          .getOrCreateTelemetryDeviceId()
          .timeout(_shortTimeout);
    } catch (e) {
      // A keystore hiccup must not cost the whole snapshot.
      _log('device id', e);
      metadata['deviceIdPersisted'] = false;
      return _sessionDeviceId ??= 'session-${const Uuid().v4()}';
    }
  }

  String _defaultReason(String metric, String platform) {
    switch (platform) {
      case 'web':
        return 'Not exposed by browsers';
      case 'ios':
        return metric == 'cpu'
            ? 'Not exposed to apps by iOS'
            : 'Could not be read';
      case 'android':
        return metric == 'cpu'
            ? 'Blocked for apps on Android 8+'
            : 'Could not be read';
      default:
        return 'Could not be read';
    }
  }

  int? _mbToBytes(int mb) => mb > 0 ? mb * 1024 * 1024 : null;
  int? _positive(int v) => v > 0 ? v : null;
  int? _nonNegative(int v) => v >= 0 ? v : null;

  void _log(String stage, Object error) {
    if (kDebugMode) debugPrint('[TELEMETRY] $stage failed: $error');
  }
}
