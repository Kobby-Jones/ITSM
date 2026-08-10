import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Generic offline cache for "last known good" API responses, so screens
/// have something to show immediately on cold start and while offline.
///
/// Stores raw JSON strings keyed by a simple string key (e.g. `tickets:all`,
/// `kb_articles:all`). Callers decode the JSON themselves — this class
/// doesn't know about domain models, keeping it reusable across services.
class LocalCacheService {
  LocalCacheService._();
  static final LocalCacheService instance = LocalCacheService._();

  static const _boxName = 'itsm_cache';
  Box? _box;

  /// Must be called once at app startup, before any other member is used.
  /// See `main.dart`.
  static Future<void> init() async {
    await Hive.initFlutter();
    instance._box = await Hive.openBox(_boxName);
  }

  Box get _requireBox {
    final box = _box;
    if (box == null) {
      throw StateError('LocalCacheService.init() must be awaited before use (see main.dart)');
    }
    return box;
  }

  Future<void> putJson(String key, Object value) => _requireBox.put(key, jsonEncode(value));

  /// Returns the decoded JSON for [key], or null if never cached / cleared.
  dynamic getJson(String key) {
    final raw = _requireBox.get(key) as String?;
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  DateTime? lastUpdated(String key) {
    final ts = _requireBox.get('$key::updatedAt') as String?;
    return ts != null ? DateTime.tryParse(ts) : null;
  }

  Future<void> putJsonWithTimestamp(String key, Object value) async {
    await putJson(key, value);
    await _requireBox.put('$key::updatedAt', DateTime.now().toIso8601String());
  }

  Future<void> remove(String key) => _requireBox.delete(key);

  Future<void> clearAll() => _requireBox.clear();
}
