/// Result of a platform-level hardware read.
///
/// Any field that could not be read is `null` (never zero), so callers can tell
/// "not available" apart from a real reading. [unavailable] may carry a short
/// human-readable reason keyed by metric (`cpu`, `memory`, `storage`).
class PlatformStats {
  final int? ramTotalBytes;
  final int? ramAvailableBytes;

  /// System-wide CPU utilisation, 0..100.
  final double? cpuPercent;
  final int? storageTotalBytes;
  final int? storageAvailableBytes;
  final Map<String, String> unavailable;

  const PlatformStats({
    this.ramTotalBytes,
    this.ramAvailableBytes,
    this.cpuPercent,
    this.storageTotalBytes,
    this.storageAvailableBytes,
    this.unavailable = const {},
  });
}
