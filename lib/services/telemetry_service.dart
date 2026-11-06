import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/storage/local_cache_service.dart';
import '../core/storage/sync_queue_service.dart';
import '../models/telemetry.dart';

/// Reads ticket-linked telemetry from the backend with an offline cache.
class TelemetryService {
  TelemetryService._();
  static final TelemetryService instance = TelemetryService._();

  final _dio = ApiClient.instance.dio;

  String _cacheKey(String ticketId) => 'telemetry:ticket:$ticketId';

  /// A ticket created offline is addressed by a local UUID until it syncs.
  /// Every other ticket call maps that to the server id; telemetry must too.
  String _resolve(String ticketId) {
    try {
      return SyncQueueService.instance.resolveTicketId(ticketId);
    } catch (_) {
      return ticketId;
    }
  }

  /// Keep the snapshot captured on this device under every id the ticket may
  /// be known by (local UUID and server id), so the creator can always view it
  /// even if the server read fails.
  Future<void> rememberLocal(
    Iterable<String> ticketIds,
    Map<String, dynamic>? snapshot,
  ) async {
    if (snapshot == null) return;
    for (final id in ticketIds.toSet()) {
      if (id.isEmpty) continue;
      try {
        await LocalCacheService.instance
            .putJsonWithTimestamp(_cacheKey(id), snapshot);
      } catch (_) {}
    }
  }

  /// Accepts the shapes a backend commonly returns: `{data: {...}}`,
  /// `{data: [...]}` (newest wins), or `{data: {telemetry: {...}}}`.
  Map<String, dynamic>? _extract(dynamic body) {
    dynamic data = body is Map && body.containsKey('data') ? body['data'] : body;

    if (data is List) {
      Map? best;
      for (final item in data) {
        if (item is! Map) continue;
        if (best == null ||
            (item['recordedAt']?.toString() ?? '')
                    .compareTo(best['recordedAt']?.toString() ?? '') >
                0) {
          best = item;
        }
      }
      data = best;
    }
    if (data is Map && data['telemetry'] is Map) data = data['telemetry'];
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  Future<DeviceTelemetry?> getForTicket(
    String ticketId, {
    Map<String, dynamic>? localSnapshot,
  }) async {
    final resolvedId = _resolve(ticketId);

    try {
      final response =
          await _dio.get(ApiEndpoints.telemetryForTicket(resolvedId));
      final json = _extract(response.data);
      if (json != null) {
        await LocalCacheService.instance.putJsonWithTimestamp(
          _cacheKey(resolvedId),
          json,
        );
        return DeviceTelemetry.fromJson(json);
      }
      if (kDebugMode) {
        final body = response.data.toString();
        debugPrint(
          '[TELEMETRY] fetch for $resolvedId: ${response.statusCode} but no '
          'telemetry object. Body: ${body.length > 300 ? body.substring(0, 300) : body}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        if (e is DioException) {
          final body = e.response?.data?.toString() ?? '';
          debugPrint(
            '[TELEMETRY] fetch for $resolvedId failed: '
            '${e.response?.statusCode} ${e.requestOptions.uri} '
            '${body.length > 300 ? body.substring(0, 300) : body}',
          );
        } else {
          debugPrint('[TELEMETRY] fetch for $resolvedId failed: $e');
        }
      }
    }

    // Server had nothing usable: use what this device captured.
    for (final id in {resolvedId, ticketId}) {
      final cached = LocalCacheService.instance.getJson(_cacheKey(id));
      if (cached is Map) {
        return DeviceTelemetry.fromJson(Map<String, dynamic>.from(cached));
      }
    }
    if (localSnapshot != null) {
      return DeviceTelemetry.fromJson(localSnapshot);
    }
    return null;
  }
}
