import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/api_exception.dart';
import '../core/storage/local_cache_service.dart';
import '../core/storage/sync_queue_service.dart';
import '../models/ticket.dart';

/// Ticket API + durable offline-first cache/queue.
class TicketsService {
  TicketsService._();
  static final TicketsService instance = TicketsService._();

  final _dio = ApiClient.instance.dio;
  static const _cacheKey = 'tickets:all';

  Future<void> persistTickets(List<Ticket> tickets) =>
      LocalCacheService.instance.putJsonWithTimestamp(
        _cacheKey,
        tickets.map((t) => t.toCacheJson()).toList(),
      );

  List<Ticket>? _readCachedTickets() {
    final cached = LocalCacheService.instance.getJson(_cacheKey) as List?;
    if (cached == null) return null;

    final result = <Ticket>[];
    for (final raw in cached) {
      if (raw is! Map) continue;
      final json = Map<String, dynamic>.from(raw);
      try {
        // New normalized cache format.
        if (json['_cacheFormat'] == 1 || json.containsKey('code')) {
          result.add(Ticket.fromCacheJson(json));
        } else {
          // Backwards compatibility with earlier cache entries that stored
          // raw API JSON.
          result.add(Ticket.fromJson(json));
        }
      } catch (_) {
        // One malformed cached ticket must not make the entire offline list
        // unusable.
      }
    }
    return result;
  }


  /// While local writes are pending, prefer the locally-mutated ticket over
  /// the stale server copy. This prevents an online refresh racing with the
  /// sync worker from making offline comments/status changes disappear from
  /// the UI before they have been uploaded.
  List<Ticket> _mergePendingLocal(List<Ticket> serverTickets) {
    final queue = SyncQueueService.instance;
    if (queue.pendingCount == 0) return serverTickets;

    final cached = _readCachedTickets();
    if (cached == null || cached.isEmpty) return serverTickets;

    final merged = [...serverTickets];
    for (final local in cached.where((t) => t.syncState != SyncState.synced)) {
      final resolvedLocalId = queue.resolveTicketId(local.id);
      final index = merged.indexWhere(
        (server) => server.id == resolvedLocalId || server.id == local.id,
      );
      if (index >= 0) {
        merged[index] = local;
      } else {
        merged.insert(0, local);
      }
    }
    return merged;
  }

  Future<({List<Ticket> tickets, int total})> getTicketsPaginated({
    int page = 1,
    int limit = 50,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final res = await _dio.get(ApiEndpoints.tickets, queryParameters: {
        'page': page,
        'limit': limit,
        ...?filters,
      });
      final data = res.data['data'] as List;
      final total = res.data['total'] as int? ?? data.length;
      final serverTickets = data
          .map((t) => Ticket.fromJson(t as Map<String, dynamic>))
          .toList();
      final tickets = page == 1
          ? _mergePendingLocal(serverTickets)
          : serverTickets;
      if (page == 1) {
        await persistTickets(tickets);
      }
      return (tickets: tickets, total: total + (tickets.length - serverTickets.length));
    } catch (e) {
      final mapped = ApiClient.instance.mapError(e);

      // Cache is an availability fallback, not an authorization fallback.
      // Returning old cached tickets for a 401/403 masks real permission
      // problems and makes admin/technician lists look mysteriously empty.
      final canUseOfflineCache =
          mapped is NetworkException ||
          mapped is ServerException ||
          mapped is RateLimitException;

      if (page == 1 && canUseOfflineCache) {
        final cached = _readCachedTickets();
        if (cached != null) {
          return (tickets: cached, total: cached.length);
        }
      }
      throw mapped;
    }
  }

  Future<List<Ticket>> getTickets({Map<String, dynamic>? filters}) async {
    final result = await getTicketsPaginated(
      page: 1,
      limit: 100,
      filters: filters,
    );
    return result.tickets;
  }

  Future<Ticket> getTicketById(String id) async {
    try {
      final resolvedId = SyncQueueService.instance.resolveTicketId(id);
      final res = await _dio.get(ApiEndpoints.ticket(resolvedId));
      return Ticket.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      final cached = _readCachedTickets();
      if (cached != null) {
        for (final ticket in cached) {
          if (ticket.id == id || ticket.code == id) return ticket;
          final resolved = SyncQueueService.instance.resolveTicketId(ticket.id);
          if (resolved == id) return ticket;
        }
      }
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<Ticket> createTicket(
    Ticket draft, {
    required String offlineId,
    Map<String, dynamic>? telemetry,
    bool offline = false,
  }) async {
    final payload = draft.toCreatePayload(offlineId: offlineId);
    if (telemetry != null) payload['telemetry'] = telemetry;

    if (offline) {
      await SyncQueueService.instance.enqueue('create_ticket', payload);
      return draft.copyWith(syncState: SyncState.pending);
    }

    try {
      final res = await _dio.post(ApiEndpoints.tickets, data: payload);
      final created =
          Ticket.fromJson(res.data['data'] as Map<String, dynamic>);
      return created.copyWith(
        deviceId: telemetry?['deviceId']?.toString(),
        telemetrySnapshot: telemetry,
      );
    } catch (e) {
      final mapped = ApiClient.instance.mapError(e);
      if (mapped is NetworkException) {
        await SyncQueueService.instance.enqueue('create_ticket', payload);
        return draft.copyWith(syncState: SyncState.pending);
      }
      throw mapped;
    }
  }

  Future<void> queueStatus(String ticketId, TicketStatus status) async {
    await SyncQueueService.instance.enqueue('update_status', {
      'ticketId': ticketId,
      'status': status.apiValue,
    });
  }

  Future<Ticket> updateStatus(String ticketId, TicketStatus status) async {
    final resolvedId = SyncQueueService.instance.resolveTicketId(ticketId);
    try {
      final res = await _dio.patch(ApiEndpoints.ticketStatus(resolvedId), data: {
        'status': status.apiValue,
      });
      return Ticket.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      final mapped = ApiClient.instance.mapError(e);
      if (mapped is NetworkException) {
        await queueStatus(ticketId, status);
      }
      throw mapped;
    }
  }

  Future<void> queueAssignment(String ticketId, String assigneeId) async {
    await SyncQueueService.instance.enqueue('assign_ticket', {
      'ticketId': ticketId,
      'assigneeId': assigneeId,
    });
  }

  Future<Ticket> assign(String ticketId, String assigneeId) async {
    final resolvedId = SyncQueueService.instance.resolveTicketId(ticketId);
    try {
      final res = await _dio.patch(ApiEndpoints.ticketAssign(resolvedId), data: {
        'assigneeId': assigneeId,
      });
      return Ticket.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      final mapped = ApiClient.instance.mapError(e);
      if (mapped is NetworkException) {
        await queueAssignment(ticketId, assigneeId);
      }
      throw mapped;
    }
  }

  Future<void> queueComment(
    String ticketId,
    String content, {
    bool isInternal = false,
  }) async {
    await SyncQueueService.instance.enqueue('add_comment', {
      'ticketId': ticketId,
      'content': content,
      'isInternal': isInternal,
    });
  }

  Future<Comment> addComment(
    String ticketId,
    String content, {
    bool isInternal = false,
  }) async {
    final resolvedId = SyncQueueService.instance.resolveTicketId(ticketId);
    final payload = {'content': content, 'isInternal': isInternal};
    try {
      final res = await _dio.post(
        ApiEndpoints.ticketComments(resolvedId),
        data: payload,
      );
      return Comment.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      final mapped = ApiClient.instance.mapError(e);
      if (mapped is NetworkException) {
        await queueComment(ticketId, content, isInternal: isInternal);
      }
      throw mapped;
    }
  }
}
