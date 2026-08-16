import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Generic offline cache for "last known good" API responses, so screens
/// have something to show immediately on cold start and while offline.
///
/// **User-partitioned**: every key is scoped to the signed-in user so
/// one person's cached data is never returned to another person on the
/// same device.  Call [setCurrentUser] at login and [clearCurrentUser]
/// (which also wipes cached data) at logout.
class LocalCacheService {
  LocalCacheService._();
  static final LocalCacheService instance = LocalCacheService._();

  static const _boxName = 'itsm_cache';
  Box? _box;

  /// The id of the currently authenticated user, set at login.
  String? _userId;

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

  /// Call after a successful login so cache keys are scoped.
  void setCurrentUser(String userId) {
    _userId = userId;
  }

  /// Build the actual Hive key by prefixing the logical key with the
  /// current user id.  If no user has been set (e.g. pre-login) the raw
  /// key is used — but writes in that state should be avoided.
  String _scopedKey(String key) {
    if (_userId != null) return '$_userId:$key';
    return key;
  }

  Future<void> putJson(String key, Object value) =>
      _requireBox.put(_scopedKey(key), jsonEncode(value));

  /// Returns the decoded JSON for [key], or null if never cached / cleared.
  dynamic getJson(String key) {
    final raw = _requireBox.get(_scopedKey(key)) as String?;
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  DateTime? lastUpdated(String key) {
    final ts = _requireBox.get('${_scopedKey(key)}::updatedAt') as String?;
    return ts != null ? DateTime.tryParse(ts) : null;
  }

  Future<void> putJsonWithTimestamp(String key, Object value) async {
    await putJson(key, value);
    await _requireBox.put(
        '${_scopedKey(key)}::updatedAt', DateTime.now().toIso8601String());
  }

  Future<void> remove(String key) => _requireBox.delete(_scopedKey(key));

  /// Wipe every cache entry that belongs to the current user and then
  /// forget the current user id.  Call this at logout.
  Future<void> clearCurrentUser() async {
    if (_userId != null) {
      final prefix = '$_userId:';
      final keysToRemove = _requireBox.keys
          .where((k) => k is String && k.startsWith(prefix))
          .toList();
      for (final key in keysToRemove) {
        await _requireBox.delete(key);
      }
    }
    _userId = null;
  }

  /// Emergency full wipe — removes every key regardless of user scope.
  Future<void> clearAll() => _requireBox.clear();
}
