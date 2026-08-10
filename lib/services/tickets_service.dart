import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/api_exception.dart';
import '../core/storage/local_cache_service.dart';
import '../core/storage/sync_queue_service.dart';
import '../models/ticket.dart';

/// Talks to `/tickets/*`.
///
/// Read paths cache their last successful response so the UI has something
/// to show offline (see [LocalCacheService]); write paths that fail with a
/// [NetworkException] fall back to [SyncQueueService] instead of throwing,
/// so "submit ticket while offline" still succeeds from the user's
/// perspective and gets replayed by `SyncProvider` once connectivity
/// returns.
class TicketsService {
  TicketsService._();
  static final TicketsService instance = TicketsService._();

  final _dio = ApiClient.instance.dio;
  static const _cacheKey = 'tickets:all';

  /// Fetches all tickets visible to the current user (own tickets for end
  /// users, all tickets for staff — enforced server-side by permission).
  /// Falls back to the last cached page if offline.
  Future<List<Ticket>> getTickets({Map<String, dynamic>? filters}) async {
    try {
      final res = await _dio.get(ApiEndpoints.tickets, queryParameters: {
        'limit': 100,
        ...?filters,
      });
      final data = res.data['data'] as List;
      await LocalCacheService.instance.putJsonWithTimestamp(_cacheKey, data);
      return data.map((t) => Ticket.fromJson(t as Map<String, dynamic>)).toList();
    } catch (e) {
      final cached = LocalCacheService.instance.getJson(_cacheKey) as List?;
      if (cached != null) {
        return cached.map((t) => Ticket.fromJson(t as Map<String, dynamic>)).toList();
      }
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<Ticket> getTicketById(String id) async {
    try {
      final res = await _dio.get(ApiEndpoints.ticket(id));
      return Ticket.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  /// Creates a ticket. If the device is offline, queues the write locally
  /// and returns a client-side placeholder [Ticket] marked
  /// [SyncState.pending] instead of throwing, so the submit flow always
  /// feels successful and the write survives an app restart.
  Future<Ticket> createTicket(Ticket draft, {required String offlineId}) async {
    final payload = draft.toCreatePayload(offlineId: offlineId);
    try {
      final res = await _dio.post(ApiEndpoints.tickets, data: payload);
      return Ticket.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      final mapped = ApiClient.instance.mapError(e);
      if (mapped is NetworkException) {
        await SyncQueueService.instance.enqueue('create_ticket', payload);
        return draft.copyWith(syncState: SyncState.pending);
      }
      throw mapped;
    }
  }

  Future<Ticket> updateStatus(String ticketId, TicketStatus status) async {
    try {
      final res = await _dio.patch(ApiEndpoints.ticketStatus(ticketId), data: {
        'status': status.apiValue,
      });
      return Ticket.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      final mapped = ApiClient.instance.mapError(e);
      if (mapped is NetworkException) {
        await SyncQueueService.instance.enqueue('update_status', {
          'ticketId': ticketId,
          'status': status.apiValue,
        });
      }
      rethrow;
    }
  }

  Future<Ticket> assign(String ticketId, String assigneeId) async {
    try {
      final res = await _dio.patch(ApiEndpoints.ticketAssign(ticketId), data: {
        'assigneeId': assigneeId,
      });
      return Ticket.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<Comment> addComment(String ticketId, String content, {bool isInternal = false}) async {
    final payload = {'content': content, 'isInternal': isInternal};
    try {
      final res = await _dio.post(ApiEndpoints.ticketComments(ticketId), data: payload);
      return Comment.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      final mapped = ApiClient.instance.mapError(e);
      if (mapped is NetworkException) {
        await SyncQueueService.instance.enqueue('add_comment', {'ticketId': ticketId, ...payload});
      }
      throw mapped;
    }
  }
}
