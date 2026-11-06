import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'telemetry_platform_stats.dart';

/// Native platform helpers used by the shared telemetry collector.
///
/// Every read is individually guarded and time-boxed: a failing or hanging
/// metric yields `null` for that metric only, never an exception and never a
/// fake zero.
class TelemetryPlatform {
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isWindows => Platform.isWindows;
  static bool get isLinux => Platform.isLinux;
  static bool get isMacOS => Platform.isMacOS;

  static String get hostname {
    try {
      return Platform.localHostname;
    } catch (_) {
      return '';
    }
  }

  static String get operatingSystemVersion => Platform.operatingSystemVersion;

  /// Reads CPU, RAM and storage for the current platform.
  ///
  /// iOS is intentionally not handled here (the sandbox exposes none of these
  /// through dart:io); the collector fills RAM/storage from device_info_plus.
  static Future<PlatformStats> readStats() async {
    try {
      if (Platform.isLinux) return await _linux();
      if (Platform.isAndroid) return await _android();
      if (Platform.isWindows) return await _windows();
      if (Platform.isMacOS) return await _macos();
    } catch (_) {
      // Fall through to "nothing captured".
    }
    return const PlatformStats();
  }

  // ---------------------------------------------------------------- Linux

  static Future<PlatformStats> _linux() async {
    final memFuture = _procMemory();
    final cpuFuture = _procCpu();
    final storageFuture = _dfStorage('df', const ['-kP', '/']);
    final mem = await memFuture;
    final cpu = await cpuFuture;
    final storage = await storageFuture;
    return PlatformStats(
      ramTotalBytes: mem?.$1,
      ramAvailableBytes: mem?.$2,
      cpuPercent: cpu,
      storageTotalBytes: storage?.$1,
      storageAvailableBytes: storage?.$2,
    );
  }

  // -------------------------------------------------------------- Android

  /// Fallback only: the collector prefers device_info_plus (ActivityManager /
  /// StatFs) on Android. /proc/meminfo is still readable by apps, but
  /// /proc/stat is blocked for ordinary apps on Android 8+, so CPU will
  /// normally come back null here.
  static Future<PlatformStats> _android() async {
    final memFuture = _procMemory();
    final cpuFuture = _procCpu();
    final storageFuture = _dfStorage('/system/bin/df', const ['-k', '/data']);
    final mem = await memFuture;
    final cpu = await cpuFuture;
    final storage = await storageFuture;
    return PlatformStats(
      ramTotalBytes: mem?.$1,
      ramAvailableBytes: mem?.$2,
      cpuPercent: cpu,
      storageTotalBytes: storage?.$1,
      storageAvailableBytes: storage?.$2,
    );
  }

  // -------------------------------------------------------------- Windows

  // One PowerShell start-up (the slow part) for all three metrics. Passed via
  // -EncodedCommand so there is no quoting/escaping to get wrong.
  static const _windowsScript = r'''
$ErrorActionPreference = 'SilentlyContinue'
$os = Get-CimInstance Win32_OperatingSystem
$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$drv = $env:SystemDrive
if (-not $drv) { $drv = 'C:' }
$disk = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='" + $drv + "'")
[pscustomobject]@{
  ramTotalKb = $os.TotalVisibleMemorySize
  ramFreeKb  = $os.FreePhysicalMemory
  cpu        = $cpu
  diskTotal  = $disk.Size
  diskFree   = $disk.FreeSpace
} | ConvertTo-Json -Compress
''';

  static String _encodePowerShell(String script) {
    // -EncodedCommand expects base64 of UTF-16LE.
    final bytes = <int>[];
    for (final unit in script.codeUnits) {
      bytes
        ..add(unit & 0xFF)
        ..add((unit >> 8) & 0xFF);
    }
    return base64.encode(bytes);
  }

  static Future<PlatformStats> _windows() async {
    const failed = PlatformStats(unavailable: {
      'cpu': 'PowerShell query failed',
      'memory': 'PowerShell query failed',
      'storage': 'PowerShell query failed',
    });

    final out = await _run(
      'powershell.exe',
      ['-NoProfile', '-NonInteractive', '-EncodedCommand', _encodePowerShell(_windowsScript)],
      const Duration(seconds: 8),
    );
    if (out == null || out.trim().isEmpty) return failed;

    try {
      final decoded = jsonDecode(out.trim());
      if (decoded is! Map) return failed;

      int? asInt(Object? v) => v is num ? v.toInt() : null;
      final ramTotalKb = asInt(decoded['ramTotalKb']);
      final ramFreeKb = asInt(decoded['ramFreeKb']);
      final cpuRaw = decoded['cpu'];
      final diskTotal = asInt(decoded['diskTotal']);
      final diskFree = asInt(decoded['diskFree']);

      return PlatformStats(
        ramTotalBytes:
            ramTotalKb != null && ramTotalKb > 0 ? ramTotalKb * 1024 : null,
        ramAvailableBytes: ramFreeKb != null && ramFreeKb >= 0 ? ramFreeKb * 1024 : null,
        cpuPercent:
            cpuRaw is num ? cpuRaw.toDouble().clamp(0.0, 100.0).toDouble() : null,
        storageTotalBytes: diskTotal != null && diskTotal > 0 ? diskTotal : null,
        storageAvailableBytes: diskFree != null && diskFree >= 0 ? diskFree : null,
      );
    } catch (_) {
      return failed;
    }
  }

  // ---------------------------------------------------------------- macOS

  static Future<PlatformStats> _macos() async {
    final totalFuture =
        _run('sysctl', const ['-n', 'hw.memsize'], const Duration(seconds: 3));
    final vmFuture = _run('vm_stat', const [], const Duration(seconds: 3));
    // Two samples one second apart; the first sample alone is "since boot".
    final topFuture = _run(
      'top',
      const ['-l', '2', '-n', '0', '-s', '1'],
      const Duration(seconds: 6),
    );
    final storageFuture = _dfStorage('df', const ['-kP', '/']);

    final totalOut = await totalFuture;
    final vmOut = await vmFuture;
    final topOut = await topFuture;
    final storage = await storageFuture;

    final total = int.tryParse(totalOut?.trim() ?? '');

    int? available;
    if (vmOut != null) {
      final pageSize =
          int.tryParse(RegExp(r'page size of (\d+) bytes').firstMatch(vmOut)?.group(1) ?? '');
      int? pages(String key) => int.tryParse(
            RegExp('^$key:\\s+(\\d+)', multiLine: true).firstMatch(vmOut)?.group(1) ?? '',
          );
      final free = pages('Pages free');
      final inactive = pages('Pages inactive');
      final speculative = pages('Pages speculative') ?? 0;
      if (pageSize != null && free != null && inactive != null) {
        available = (free + inactive + speculative) * pageSize;
      }
    }

    double? cpu;
    if (topOut != null) {
      final matches =
          RegExp(r'CPU usage:[^\n]*?([\d.]+)% idle').allMatches(topOut).toList();
      if (matches.isNotEmpty) {
        final idle = double.tryParse(matches.last.group(1) ?? '');
        if (idle != null) cpu = (100 - idle).clamp(0.0, 100.0).toDouble();
      }
    }

    return PlatformStats(
      ramTotalBytes: total != null && total > 0 ? total : null,
      ramAvailableBytes: available,
      cpuPercent: cpu,
      storageTotalBytes: storage?.$1,
      storageAvailableBytes: storage?.$2,
    );
  }

  // ------------------------------------------------------- shared helpers

  /// Runs [exe] and returns stdout, or null on non-zero exit, error, or
  /// timeout. The process is killed on timeout so nothing is left running.
  static Future<String?> _run(
    String exe,
    List<String> args,
    Duration timeout,
  ) async {
    Process? process;
    try {
      process = await Process.start(exe, args);
      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.drain<void>();
      final code = await process.exitCode.timeout(timeout);
      final out = await stdoutFuture;
      await stderrFuture;
      return code == 0 ? out : null;
    } on TimeoutException {
      process?.kill();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Parses POSIX `df -k` output: returns (totalBytes, availableBytes).
  static Future<(int, int)?> _dfStorage(String exe, List<String> args) async {
    try {
      final out = await _run(exe, args, const Duration(seconds: 4));
      if (out == null) return null;
      final lines = out
          .trim()
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      if (lines.length < 2) return null;
      final cols = lines.last.trim().split(RegExp(r'\s+'));
      if (cols.length < 4) return null;
      final totalKb = int.tryParse(cols[1]);
      final availableKb = int.tryParse(cols[3]);
      if (totalKb == null || availableKb == null || totalKb <= 0) return null;
      return (totalKb * 1024, availableKb * 1024);
    } catch (_) {
      return null;
    }
  }

  static Future<(int, int)?> _procMemory() async {
    try {
      final text = await File('/proc/meminfo').readAsString();
      int? kbFor(String key) {
        final match = RegExp('^$key:\\s+(\\d+)\\s+kB', multiLine: true)
            .firstMatch(text);
        return match == null ? null : int.tryParse(match.group(1)!);
      }

      final totalKb = kbFor('MemTotal');
      final availableKb = kbFor('MemAvailable') ?? kbFor('MemFree');
      if (totalKb == null || availableKb == null || totalKb <= 0) return null;
      return (totalKb * 1024, availableKb * 1024);
    } catch (_) {
      return null;
    }
  }

  /// System-wide CPU % from two /proc/stat samples ~180 ms apart.
  static Future<double?> _procCpu() async {
    try {
      Future<({int total, int idle})> read() async {
        final firstLine = (await File('/proc/stat').readAsLines()).first;
        final parts = firstLine
            .trim()
            .split(RegExp(r'\s+'))
            .skip(1)
            .map(int.parse)
            .toList();
        // user nice system idle iowait irq softirq steal. Guest time is
        // already counted inside user/nice, so it is not added again.
        final total = parts.take(8).fold<int>(0, (sum, v) => sum + v);
        final idle = parts[3] + (parts.length > 4 ? parts[4] : 0);
        return (total: total, idle: idle);
      }

      final first = await read();
      await Future<void>.delayed(const Duration(milliseconds: 180));
      final second = await read();

      final totalDelta = second.total - first.total;
      final idleDelta = second.idle - first.idle;
      if (totalDelta <= 0) return null;

      return ((totalDelta - idleDelta) / totalDelta * 100)
          .clamp(0.0, 100.0)
          .toDouble();
    } catch (_) {
      return null;
    }
  }
}
