import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../models/ticket.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../features/tickets/mock_ticket_data.dart';
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

class TicketsController extends StateNotifier<List<Ticket>> {
  TicketsController() : super(MockTicketData.generate());

  final _uuid = const Uuid();

  Ticket? byId(String id) {
    for (final t in state) {
      if (t.id == id || t.code == id) return t;
    }
    return null;
  }

  void updateStatus(String id, TicketStatus status, {String? actor}) {
    final now = DateTime.now();
    state = [
      for (final t in state)
        if (t.id == id || t.code == id)
          t.copyWith(
            status: status,
            updatedAt: now,
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
          )
        else
          t,
    ];
  }

  void assign(String id, {required String assigneeId, required String assigneeName, String? actor}) {
    final now = DateTime.now();
    state = [
      for (final t in state)
        if (t.id == id || t.code == id)
          t.copyWith(
            assigneeId: assigneeId,
            assigneeName: assigneeName,
            updatedAt: now,
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
          )
        else
          t,
    ];
  }

  void addComment(String id, {required AppUser author, required String content, bool internal = false}) {
    final now = DateTime.now();
    state = [
      for (final t in state)
        if (t.id == id || t.code == id)
          t.copyWith(
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
            events: [
              ...t.events,
              TicketEvent(
                id: 'evt-${_uuid.v4()}',
                title: '${author.name} commented',
                description: internal ? 'Internal note added' : content.length > 60 ? '${content.substring(0, 60)}…' : content,
                timestamp: now,
                icon: Icons.comment_rounded,
                color: AppColors.info,
                actor: author.name,
              ),
            ],
          )
        else
          t,
    ];
  }

  /// Submit a new ticket. If offline, marks as pending sync.
  Ticket submit({
    required AppUser reporter,
    required String title,
    required String description,
    required TicketPriority priority,
    required TicketCategory category,
    required TicketImpact impact,
    required bool isOnline,
    List<Attachment> attachments = const [],
  }) {
    final now = DateTime.now();
    final code = 'INC-${1043 + state.length}';
    final ticket = Ticket(
      id: 't-${1043 + state.length}',
      code: code,
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
    state = [ticket, ...state];
    return ticket;
  }

  /// Manually retry sync of a pending/failed ticket.
  Future<void> retrySync(String id) async {
    state = [
      for (final t in state)
        if (t.id == id || t.code == id) t.copyWith(syncState: SyncState.syncing) else t,
    ];
    await Future.delayed(const Duration(seconds: 1));
    state = [
      for (final t in state)
        if (t.id == id || t.code == id) t.copyWith(syncState: SyncState.synced) else t,
    ];
  }
}

final ticketsProvider =
    StateNotifierProvider<TicketsController, List<Ticket>>((ref) => TicketsController());

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
      return TicketScope.assignedToMe;
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

/// Used by some screens to mass-toggle sync after reconnection.
final autoSyncProvider = Provider<void>((ref) {
  // When connectivity comes back online, transition pending -> syncing -> synced.
  ref.listen<bool>(connectivityProvider, (prev, next) async {
    if (prev == false && next == true) {
      final ctrl = ref.read(ticketsProvider.notifier);
      final pending = ref.read(ticketsProvider).where((t) => t.syncState == SyncState.pending);
      for (final t in pending) {
        await ctrl.retrySync(t.id);
      }
    }
  });
});
