import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/api_exception.dart';
import '../core/storage/sync_queue_service.dart';

/// Replays durable offline operations against the backend.
///
/// Operations are processed in creation order. A locally-created ticket may
/// receive comments/status/assignment changes before it has a server id; once
/// CREATE succeeds, the local id is mapped to the real backend id and every
/// later operation resolves through that mapping.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _dio = ApiClient.instance.dio;

  Future<int> processQueue() async {
    final queue = SyncQueueService.instance;
    final ops = queue.all();
    var succeeded = 0;

    for (final op in ops) {
      if (op.attempts >= 3) continue;
      try {
        switch (op.kind) {
          case 'create_ticket':
            final response = await _dio.post(
              ApiEndpoints.tickets,
              data: op.payload,
            );
            final data = response.data is Map
                ? (response.data['data'] as Map?)
                : null;
            final serverId = data?['id']?.toString();
            final localId = op.payload['offlineId']?.toString();
            if (serverId != null &&
                serverId.isNotEmpty &&
                localId != null &&
                localId.isNotEmpty) {
              await queue.saveTicketIdMapping(
                localId: localId,
                serverId: serverId,
              );
            }
            break;

          case 'update_status':
            final ticketId = queue.resolveTicketId(
              op.payload['ticketId'] as String,
            );
            await _dio.patch(
              ApiEndpoints.ticketStatus(ticketId),
              data: {'status': op.payload['status']},
            );
            break;

          case 'assign_ticket':
            final ticketId = queue.resolveTicketId(
              op.payload['ticketId'] as String,
            );
            await _dio.patch(
              ApiEndpoints.ticketAssign(ticketId),
              data: {'assigneeId': op.payload['assigneeId']},
            );
            break;

          case 'add_comment':
            final ticketId = queue.resolveTicketId(
              op.payload['ticketId'] as String,
            );
            await _dio.post(
              ApiEndpoints.ticketComments(ticketId),
              data: {
                'content': op.payload['content'],
                'isInternal': op.payload['isInternal'],
              },
            );
            break;

          default:
            // Leave unknown future operation types in the queue rather than
            // silently deleting user work.
            continue;
        }

        await queue.remove(op.id);
        succeeded++;
      } catch (e) {
        final mapped = ApiClient.instance.mapError(e);
        if (mapped is NetworkException) {
          // Connectivity is still unavailable. Stop this pass and preserve
          // this operation plus everything after it in FIFO order.
          break;
        }
        await queue.markFailed(op.id, mapped.message);
      }
    }

    return succeeded;
  }
}
