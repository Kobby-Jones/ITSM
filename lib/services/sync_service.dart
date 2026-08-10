import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/api_exception.dart';
import '../core/storage/sync_queue_service.dart';

/// Replays everything in [SyncQueueService] against the backend. Called by
/// `SyncProvider` whenever `connectivityProvider` flips from offline to
/// online, and can also be triggered manually from the Sync Queue screen.
///
/// A queued operation is removed once it succeeds; on failure it's left in
/// the queue with an incremented attempt count and last error recorded, so
/// it's retried on the next sync pass rather than lost.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _dio = ApiClient.instance.dio;

  /// Returns the number of operations that synced successfully.
  Future<int> processQueue() async {
    final ops = SyncQueueService.instance.all();
    var succeeded = 0;

    for (final op in ops) {
      try {
        switch (op.kind) {
          case 'create_ticket':
            await _dio.post(ApiEndpoints.tickets, data: op.payload);
            break;
          case 'update_status':
            await _dio.patch(
              ApiEndpoints.ticketStatus(op.payload['ticketId'] as String),
              data: {'status': op.payload['status']},
            );
            break;
          case 'add_comment':
            await _dio.post(
              ApiEndpoints.ticketComments(op.payload['ticketId'] as String),
              data: {'content': op.payload['content'], 'isInternal': op.payload['isInternal']},
            );
            break;
          default:
            // Unknown op kind (e.g. added by a future version) — leave it
            // queued rather than silently dropping it.
            continue;
        }
        await SyncQueueService.instance.remove(op.id);
        succeeded++;
      } catch (e) {
        final mapped = ApiClient.instance.mapError(e);
        if (mapped is NetworkException) {
          // Still offline — stop this pass entirely rather than burning
          // through the rest of the queue with the same failure.
          break;
        }
        await SyncQueueService.instance.markFailed(op.id, mapped.message);
      }
    }

    return succeeded;
  }
}
