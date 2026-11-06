import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// A pending write that couldn't reach the backend and must be replayed later.
class QueuedOperation {
  final String id;
  final String kind;
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

  QueuedOperation copyWith({
    Map<String, dynamic>? payload,
    int? attempts,
    String? lastError,
  }) =>
      QueuedOperation(
        id: id,
        kind: kind,
        payload: payload ?? this.payload,
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

/// Durable local queue for offline writes.
///
/// A second Hive box stores local-ticket-id -> server-ticket-id mappings.
/// This matters when a ticket is created offline and the user comments,
/// assigns, or changes its status before the CREATE operation has synced.
class SyncQueueService {
  SyncQueueService._();
  static final SyncQueueService instance = SyncQueueService._();

  static const _boxName = 'itsm_sync_queue';
  static const _idMapBoxName = 'itsm_sync_id_map';
  Box? _box;
  Box? _idMapBox;
  String? _userId;
  static const _uuid = Uuid();

  static Future<void> init() async {
    instance._box = await Hive.openBox(_boxName);
    instance._idMapBox = await Hive.openBox(_idMapBoxName);
  }


  void setCurrentUser(String userId) {
    _userId = userId;
    unawaited(_migrateLegacyEntries(userId));
  }

  Future<void> _migrateLegacyEntries(String userId) async {
    // Older builds stored queue entries without a user prefix. Migrate those
    // once to the first authenticated user after upgrade so already-pending
    // offline work is not stranded by the user-partitioning improvement.
    final legacyQueueKeys = _requireBox.keys
        .where((k) => k is String && !k.contains(':'))
        .cast<String>()
        .toList();
    for (final key in legacyQueueKeys) {
      final value = _requireBox.get(key);
      await _requireBox.put('$userId:$key', value);
      await _requireBox.delete(key);
    }

    final legacyMapKeys = _requireIdMapBox.keys
        .where((k) => k is String && !k.contains(':'))
        .cast<String>()
        .toList();
    for (final key in legacyMapKeys) {
      final value = _requireIdMapBox.get(key);
      await _requireIdMapBox.put('$userId:$key', value);
      await _requireIdMapBox.delete(key);
    }
  }

  void clearCurrentUser() {
    _userId = null;
  }

  String get _userPrefix {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      throw StateError('SyncQueueService requires an authenticated user');
    }
    return '$userId:';
  }

  String _scopedKey(String id) => '$_userPrefix$id';

  Box get _requireBox {
    final box = _box;
    if (box == null) {
      throw StateError('SyncQueueService.init() must be awaited before use (see main.dart)');
    }
    return box;
  }

  Box get _requireIdMapBox {
    final box = _idMapBox;
    if (box == null) {
      throw StateError('SyncQueueService.init() must be awaited before use (see main.dart)');
    }
    return box;
  }

  Future<String> enqueue(String kind, Map<String, dynamic> payload) async {
    final id = _uuid.v4();
    final op = QueuedOperation(
      id: id,
      kind: kind,
      payload: Map<String, dynamic>.from(payload),
      queuedAt: DateTime.now(),
    );
    await _requireBox.put(_scopedKey(id), jsonEncode(op.toJson()));
    return id;
  }

  List<QueuedOperation> all() {
    final prefix = _userPrefix;
    final result = <QueuedOperation>[];
    for (final key in _requireBox.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;
      final raw = _requireBox.get(key);
      if (raw is! String) continue;
      try {
        result.add(QueuedOperation.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        ));
      } catch (_) {
        // Keep corrupt/legacy entries from crashing the whole queue screen.
      }
    }
    result.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
    return result;
  }

  Future<void> remove(String id) => _requireBox.delete(_scopedKey(id));

  Future<void> markFailed(String id, String error) async {
    final raw = _requireBox.get(_scopedKey(id)) as String?;
    if (raw == null) return;
    final op = QueuedOperation.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
    final updated = op.copyWith(
      attempts: op.attempts + 1,
      lastError: error,
    );
    await _requireBox.put(_scopedKey(id), jsonEncode(updated.toJson()));
  }

  /// Remember the real backend id assigned to a locally-created ticket.
  Future<void> saveTicketIdMapping({
    required String localId,
    required String serverId,
  }) async {
    if (localId.isEmpty || serverId.isEmpty) return;
    await _requireIdMapBox.put(_scopedKey(localId), serverId);
  }

  /// Resolve a local offline ticket UUID to the backend id if it has synced.
  String resolveTicketId(String ticketId) {
    final mapped = _requireIdMapBox.get(_scopedKey(ticketId));
    return mapped is String && mapped.isNotEmpty ? mapped : ticketId;
  }

  bool hasPendingForTicket(String ticketId) {
    final resolved = resolveTicketId(ticketId);
    return all().any((op) {
      final id = op.payload['ticketId']?.toString();
      final offlineId = op.payload['offlineId']?.toString();
      if (id != null && (id == ticketId || resolveTicketId(id) == resolved)) {
        return true;
      }
      return offlineId == ticketId;
    });
  }

  int get pendingCount {
    final prefix = _userPrefix;
    return _requireBox.keys.where((k) => k is String && k.startsWith(prefix)).length;
  }

  /// Emergency wipe for every user's queued work on this device.
  Future<void> clearAll() async {
    await _requireBox.clear();
    await _requireIdMapBox.clear();
    _userId = null;
  }
}
