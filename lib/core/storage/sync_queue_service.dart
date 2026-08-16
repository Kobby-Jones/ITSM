import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// A pending write that couldn't reach the backend (device was offline, or
/// the request failed) and needs to be retried later.
class QueuedOperation {
  final String id;
  final String kind; // 'create_ticket' | 'add_comment' | 'update_status' | ...
  final Map<String, dynamic> payload;
  final DateTime queuedAt;
  final int attempts;
  final String? lastError;

  const QueuedOperation({
    required this.id,
    required this.kind,
    required this.payload,
    required this.queuedAt,
    this.attempts = 0,
    this.lastError,
  });

  QueuedOperation copyWith({int? attempts, String? lastError}) => QueuedOperation(
        id: id,
        kind: kind,
        payload: payload,
        queuedAt: queuedAt,
        attempts: attempts ?? this.attempts,
        lastError: lastError ?? this.lastError,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'payload': payload,
        'queuedAt': queuedAt.toIso8601String(),
        'attempts': attempts,
        'lastError': lastError,
      };

  factory QueuedOperation.fromJson(Map<String, dynamic> json) => QueuedOperation(
        id: json['id'] as String,
        kind: json['kind'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        queuedAt: DateTime.parse(json['queuedAt'] as String),
        attempts: json['attempts'] as int? ?? 0,
        lastError: json['lastError'] as String?,
      );
}

/// Persists writes that need to be replayed once connectivity returns.
///
/// This is what makes the app genuinely "offline-first" rather than just
/// offline-tolerant: creating a ticket with no signal still succeeds locally
/// and survives an app restart, then syncs automatically when
/// `ConnectivityController` reports back online (see `sync_provider` wiring
/// in `tickets_provider.dart`).
class SyncQueueService {
  SyncQueueService._();
  static final SyncQueueService instance = SyncQueueService._();

  static const _boxName = 'itsm_sync_queue';
  Box? _box;
  static const _uuid = Uuid();

  static Future<void> init() async {
    instance._box = await Hive.openBox(_boxName);
  }

  Box get _requireBox {
    final box = _box;
    if (box == null) {
      throw StateError('SyncQueueService.init() must be awaited before use (see main.dart)');
    }
    return box;
  }

  /// Adds an operation to the queue and returns the generated offline id
  /// (useful as the `offlineId` sent to the backend for dedup, e.g. ticket
  /// creation).
  Future<String> enqueue(String kind, Map<String, dynamic> payload) async {
    final id = _uuid.v4();
    final op = QueuedOperation(id: id, kind: kind, payload: payload, queuedAt: DateTime.now());
    await _requireBox.put(id, jsonEncode(op.toJson()));
    return id;
  }

  List<QueuedOperation> all() {
    return _requireBox.keys
        .map((k) => jsonDecode(_requireBox.get(k) as String) as Map<String, dynamic>)
        .map(QueuedOperation.fromJson)
        .toList()
      ..sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
  }

  Future<void> remove(String id) => _requireBox.delete(id);

  Future<void> markFailed(String id, String error) async {
    final raw = _requireBox.get(id) as String?;
    if (raw == null) return;
    final op = QueuedOperation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final updated = op.copyWith(attempts: op.attempts + 1, lastError: error);
    await _requireBox.put(id, jsonEncode(updated.toJson()));
  }

  int get pendingCount => _requireBox.keys.length;

  /// Wipe the entire queue — called at logout so the next user on a
  /// shared device does not inherit queued operations.
  Future<void> clearAll() => _requireBox.clear();
}
