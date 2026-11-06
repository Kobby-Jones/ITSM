import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../core/network/api_exception.dart';
import '../core/storage/sync_queue_service.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../services/tickets_service.dart';
import '../services/sync_service.dart';
import '../services/telemetry_service.dart';
import '../theme/app_colors.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';

/// Filters applied on top of the master ticket list.
class TicketFilters {
  final Set<TicketStatus> statuses;
  final Set<TicketPriority> priorities;
  final Set<TicketCategory> categories;
  final String query;
  final TicketScope scope;

  const TicketFilters({
    this.statuses = const {},
    this.priorities = const {},
    this.categories = const {},
    this.query = '',
    this.scope = TicketScope.all,
  });

  bool get isActive =>
      statuses.isNotEmpty ||
      priorities.isNotEmpty ||
      categories.isNotEmpty ||
      query.isNotEmpty ||
      scope != TicketScope.all;

  int get activeCount =>
      statuses.length +
      priorities.length +
      categories.length +
      (query.isEmpty ? 0 : 1) +
      (scope == TicketScope.all ? 0 : 1);

  TicketFilters copyWith({
    Set<TicketStatus>? statuses,
    Set<TicketPriority>? priorities,
    Set<TicketCategory>? categories,
    String? query,
    TicketScope? scope,
  }) {
    return TicketFilters(
      statuses: statuses ?? this.statuses,
      priorities: priorities ?? this.priorities,
      categories: categories ?? this.categories,
      query: query ?? this.query,
      scope: scope ?? this.scope,
    );
  }

  TicketFilters cleared() => const TicketFilters();
}

enum TicketScope { all, mine, assignedToMe, unassigned, openOnly }

enum TicketsLoadState { loading, loaded, error, offlineCached }

/// Backed by [TicketsService] (real `/tickets` API + offline cache/queue).
///
/// Writes are applied optimistically to local state immediately (so the UI
/// feels instant) and fired off to the backend in the background; if the
/// device is offline, [TicketsService] transparently queues the write via
/// [SyncQueueService] instead of throwing. This mirrors the previous
/// mock-data version's synchronous feel while actually talking to the API.
class TicketsController extends StateNotifier<List<Ticket>> {
  TicketsController(this._ref) : super(const []) {
    load();
  }

  final Ref _ref;
  final _uuid = const Uuid();

  TicketsLoadState loadState = TicketsLoadState.loading;
  String? loadError;
  int _currentPage = 1;
  int _totalServerCount = 0;
  bool get hasMore => state.length < _totalServerCount;

  Future<void> load() async {
    _currentPage = 1;
    loadState = TicketsLoadState.loading;
    try {
      final result = await TicketsService.instance.getTicketsPaginated(page: 1);
      state = result.tickets;
      _totalServerCount = result.total;
      loadState = _ref.read(connectivityProvider)
          ? TicketsLoadState.loaded
          : TicketsLoadState.offlineCached;
    } catch (e) {
      loadError = e.toString();
      loadState = TicketsLoadState.error;
    }
    // Trigger a rebuild of anything watching ticketsLoadStateProvider.
    _ref.invalidate(ticketsLoadStateProvider);
  }

  Future<void> loadMore() async {
    if (!hasMore) return;
    _currentPage++;
    try {
      final result = await TicketsService.instance.getTicketsPaginated(page: _currentPage);
      // Append, avoiding duplicates by id.
      final existingIds = state.map((t) => t.id).toSet();
      final newOnes = result.tickets.where((t) => !existingIds.contains(t.id));
      state = [...state, ...newOnes];
      _totalServerCount = result.total;
    } catch (_) {
      _currentPage--; // roll back so the next attempt retries this page
    }
  }

  Future<void> refresh() => load();

  Ticket? byId(String id) {
    for (final t in state) {
      if (t.id == id || t.code == id) return t;
    }
    return null;
  }

  /// Fetch a single ticket from the server by its id and merge it into
  /// the in-memory list. This gives the detail screen fresh comments,
  /// attachments, history and SLA data.
  Future<Ticket> fetchById(String id) async {
    if (!_ref.read(connectivityProvider)) {
      final local = byId(id);
      if (local != null) return local;
    }

    final ticket = await TicketsService.instance.getTicketById(id);
    // Replace the stale list version (if present) with the full detail.
    final exists = state.any((t) => t.id == id || t.code == id);
    if (exists) {
      _replace(id, (_) => ticket);
    } else {
      state = [ticket, ...state];
      _persistState();
    }
    return ticket;
  }

  void _replace(String id, Ticket Function(Ticket) update) {
    state = [
      for (final t in state)
        if (t.id == id || t.code == id) update(t) else t,
    ];
    unawaited(TicketsService.instance.persistTickets(state));
  }

  void _persistState() {
    unawaited(TicketsService.instance.persistTickets(state));
  }

  void updateStatus(String id, TicketStatus status, {String? actor}) {
    final now = DateTime.now();
    final online = _ref.read(connectivityProvider);
    _replace(
      id,
      (t) => t.copyWith(
        status: status,
        updatedAt: now,
        syncState: online ? t.syncState : SyncState.pending,
        events: [
          ...t.events,
          TicketEvent(
            id: 'evt-${_uuid.v4()}',
            title: 'Status → ${status.label}',
            description: 'Updated by ${actor ?? 'system'}',
            timestamp: now,
            icon: status.icon,
            color: status.color,
            actor: actor,
          ),
        ],
      ),
    );

    if (!online) {
      unawaited(TicketsService.instance.queueStatus(id, status));
      return;
    }

    unawaited(_sendStatus(id, status));
  }

  Future<void> _sendStatus(String id, TicketStatus status) async {
    try {
      await TicketsService.instance.updateStatus(id, status);
    } on NetworkException {
      _replace(id, (t) => t.copyWith(syncState: SyncState.pending));
    } catch (_) {
      // Keep the optimistic local view. Authorization/validation failures are
      // not queued by the service and can be reconciled on the next refresh.
    }
  }

  void assign(
    String id, {
    required String assigneeId,
    required String assigneeName,
    String? actor,
  }) {
    final now = DateTime.now();
    final online = _ref.read(connectivityProvider);
    _replace(
      id,
      (t) => t.copyWith(
        assigneeId: assigneeId,
        assigneeName: assigneeName,
        updatedAt: now,
        syncState: online ? t.syncState : SyncState.pending,
        events: [
          ...t.events,
          TicketEvent(
            id: 'evt-${_uuid.v4()}',
            title: 'Assigned to $assigneeName',
            description: 'Manual assignment by ${actor ?? 'system'}',
            timestamp: now,
            icon: Icons.assignment_ind_rounded,
            color: AppColors.statusInProgress,
            actor: actor,
          ),
        ],
      ),
    );

    if (!online) {
      unawaited(TicketsService.instance.queueAssignment(id, assigneeId));
      return;
    }

    unawaited(_sendAssignment(id, assigneeId));
  }

  Future<void> _sendAssignment(String id, String assigneeId) async {
    try {
      await TicketsService.instance.assign(id, assigneeId);
    } on NetworkException {
      _replace(id, (t) => t.copyWith(syncState: SyncState.pending));
    } catch (_) {}
  }

  void addComment(
    String id, {
    required AppUser author,
    required String content,
    bool internal = false,
  }) {
    final now = DateTime.now();
    final online = _ref.read(connectivityProvider);
    _replace(
      id,
      (t) => t.copyWith(
        comments: [
          ...t.comments,
          Comment(
            id: 'cmt-${_uuid.v4()}',
            authorName: author.name,
            authorRole: author.role.label,
            content: content,
            createdAt: now,
            isInternal: internal,
          ),
        ],
        updatedAt: now,
        syncState: online ? t.syncState : SyncState.pending,
        events: [
          ...t.events,
          TicketEvent(
            id: 'evt-${_uuid.v4()}',
            title: '${author.name} commented',
            description: internal
                ? 'Internal note added'
                : content.length > 60
                    ? '${content.substring(0, 60)}…'
                    : content,
            timestamp: now,
            icon: Icons.comment_rounded,
            color: AppColors.info,
            actor: author.name,
          ),
        ],
      ),
    );

    if (!online) {
      unawaited(
        TicketsService.instance.queueComment(
          id,
          content,
          isInternal: internal,
        ),
      );
      return;
    }

    unawaited(_sendComment(id, content, internal));
  }

  Future<void> _sendComment(String id, String content, bool internal) async {
    try {
      await TicketsService.instance.addComment(
        id,
        content,
        isInternal: internal,
      );
    } on NetworkException {
      _replace(id, (t) => t.copyWith(syncState: SyncState.pending));
    } catch (_) {}
  }

  /// Submits a new ticket. If offline, [TicketsService] queues it locally
  /// and returns a placeholder marked [SyncState.pending] instead of
  /// throwing — the caller (submit screen) doesn't need to branch on
  /// connectivity itself.
  Future<Ticket> submit({
    required AppUser reporter,
    required String title,
    required String description,
    required TicketPriority priority,
    required TicketCategory category,
    required TicketImpact impact,
    required bool isOnline,
    List<Attachment> attachments = const [],
    Map<String, dynamic>? telemetry,
  }) async {
    final now = DateTime.now();
    final offlineId = _uuid.v4();
    final draft = Ticket(
      id: offlineId,
      code: 'PENDING-${offlineId.substring(0, 6)}',
      title: title,
      description: description,
      priority: priority,
      status: TicketStatus.open,
      category: category,
      impact: impact,
      reporterId: reporter.id,
      reporterName: reporter.name,
      reporterDepartment: reporter.department,
      createdAt: now,
      updatedAt: now,
      slaDueAt: now.add(Duration(hours: priority.slaHours)),
      attachments: attachments,
      deviceId: telemetry?['deviceId']?.toString(),
      telemetrySnapshot: telemetry,
      location: reporter.location,
      syncState: isOnline ? SyncState.synced : SyncState.pending,
      events: [
        TicketEvent(
          id: 'evt-${_uuid.v4()}',
          title: 'Ticket created',
          description: 'Submitted by ${reporter.name}',
          timestamp: now,
          icon: Icons.add_circle_rounded,
          color: AppColors.primary,
          actor: reporter.name,
        ),
        if (!isOnline)
          TicketEvent(
            id: 'evt-${_uuid.v4()}',
            title: 'Queued for sync',
            description: 'Device offline — will sync when back online',
            timestamp: now,
            icon: Icons.cloud_off_rounded,
            color: AppColors.warning,
          ),
      ],
    );

    final result = await TicketsService.instance.createTicket(
      draft,
      offlineId: offlineId,
      telemetry: telemetry,
      offline: !isOnline,
    );
    state = [result, ...state];
    _persistState();
    // Remember what this device captured under both the local and server ids,
    // so the creator can always open it from the ticket.
    unawaited(TelemetryService.instance
        .rememberLocal([offlineId, result.id], telemetry));
    return result;
  }

  /// Manually retry syncing everything in the offline queue (not just one
  /// ticket — the backend dedupes by `offlineId` so replaying is safe).
  Future<void> retrySync(String id) async {
    _replace(id, (t) => t.copyWith(syncState: SyncState.syncing));
    await SyncService.instance.processQueue();
    await load();
  }
}

final ticketsProvider =
    StateNotifierProvider<TicketsController, List<Ticket>>((ref) => TicketsController(ref));

/// Non-breaking companion to [ticketsProvider] for screens that want to show
/// a loading/error state instead of just an empty list on first load.
final ticketsLoadStateProvider = Provider<TicketsLoadState>((ref) {
  ref.watch(ticketsProvider); // rebuild when the list changes
  return ref.read(ticketsProvider.notifier).loadState;
});

final ticketFiltersProvider = StateProvider<TicketFilters>((ref) => const TicketFilters());

/// Visible tickets after applying filters and the role-based scope.
final filteredTicketsProvider = Provider<List<Ticket>>((ref) {
  final all = ref.watch(ticketsProvider);
  final filters = ref.watch(ticketFiltersProvider);
  final user = ref.watch(authProvider).user;

  Iterable<Ticket> list = all;

  // Scope
  switch (filters.scope) {
    case TicketScope.mine:
      if (user != null) list = list.where((t) => t.reporterId == user.id);
      break;
    case TicketScope.assignedToMe:
      if (user != null) list = list.where((t) => t.assigneeId == user.id);
      break;
    case TicketScope.unassigned:
      list = list.where((t) => t.assigneeId == null);
      break;
    case TicketScope.openOnly:
      list = list.where((t) =>
          t.status != TicketStatus.resolved && t.status != TicketStatus.closed);
      break;
    case TicketScope.all:
      break;
  }

  // Status
  if (filters.statuses.isNotEmpty) {
    list = list.where((t) => filters.statuses.contains(t.status));
  }
  // Priority
  if (filters.priorities.isNotEmpty) {
    list = list.where((t) => filters.priorities.contains(t.priority));
  }
  // Category
  if (filters.categories.isNotEmpty) {
    list = list.where((t) => filters.categories.contains(t.category));
  }
  // Query
  if (filters.query.isNotEmpty) {
    final q = filters.query.toLowerCase();
    list = list.where((t) =>
        t.title.toLowerCase().contains(q) ||
        t.code.toLowerCase().contains(q) ||
        t.description.toLowerCase().contains(q) ||
        t.reporterName.toLowerCase().contains(q));
  }

  final result = list.toList();
  // Sort: priority, then most recent
  result.sort((a, b) {
    final p = a.priority.index.compareTo(b.priority.index);
    if (p != 0) return p;
    return b.updatedAt.compareTo(a.updatedAt);
  });
  return result;
});

/// Default scope based on the user's role — when they land on the tickets page.
final defaultScopeForRoleProvider = Provider<TicketScope>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return TicketScope.all;
  switch (user.role) {
    case UserRole.endUser:
      return TicketScope.mine;
    case UserRole.technician:
      // Technicians need visibility of newly submitted tickets even when the
      // routing engine assigns them to a different technician. "Assigned to
      // me" remains available as an explicit tab for focused work.
      return TicketScope.all;
    case UserRole.admin:
    case UserRole.manager:
      return TicketScope.all;
  }
});

/// Tickets in the sync queue (pending, syncing, failed).
final syncQueueTicketsProvider = Provider<List<Ticket>>((ref) {
  final all = ref.watch(ticketsProvider);
  return all.where((t) => t.syncState != SyncState.synced).toList()
    ..sort((a, b) => a.syncState.index.compareTo(b.syncState.index));
});

/// Automatically flushes the offline write queue when connectivity comes
/// back, then reloads tickets so synced items pick up their real server
/// state (ids, ticket numbers, etc). Watch this provider once near the root
/// of the authenticated shell (see `adaptive_shell.dart`) to activate it.
final autoSyncProvider = Provider<void>((ref) {
  var syncing = false;

  Future<void> syncIfNeeded(bool online) async {
    if (!online || syncing || SyncQueueService.instance.pendingCount == 0) {
      return;
    }

    syncing = true;
    try {
      final synced = await SyncService.instance.processQueue();
      if (synced > 0) {
        await ref.read(ticketsProvider.notifier).load();
      }
    } finally {
      syncing = false;
    }
  }

  // Flush work left from a previous app session when the authenticated shell
  // first mounts while already online.
  Future.microtask(() => syncIfNeeded(ref.read(connectivityProvider)));

  // React immediately to Android's connectivity transitions.
  ref.listen<bool>(connectivityProvider, (prev, next) {
    unawaited(syncIfNeeded(next));
  });

  // Connectivity APIs report link state, not guaranteed internet reachability.
  // If Wi-Fi remains connected while the WAN is down, there may be no later
  // offline->online event. Retry only while queued work exists so restoration
  // of real internet access still triggers eventual synchronization.
  final retryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    unawaited(syncIfNeeded(ref.read(connectivityProvider)));
  });
  ref.onDispose(retryTimer.cancel);
});
