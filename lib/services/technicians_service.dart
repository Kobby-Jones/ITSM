import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/technician.dart';

/// Talks to `/users/technicians` (roster: id/name/activeTicketCount) and
/// `/analytics/technician-performance` (resolution stats over a date range),
/// merging both into a single [Technician] per person since neither
/// endpoint alone has everything the manager dashboard wants to show.
///
/// Still missing from the backend entirely: resolvedToday, resolvedThisWeek,
/// customerSatisfaction, and online/presence status. Those default to 0 /
/// false — see the note on [Technician.fromJson] for what a backend
/// extension would need to add.
class TechniciansService {
  TechniciansService._();
  static final TechniciansService instance = TechniciansService._();

  final _dio = ApiClient.instance.dio;

  Future<List<Technician>> getTechnicians() async {
    try {
      final results = await Future.wait([
        _dio.get(ApiEndpoints.technicians),
        _dio.get(ApiEndpoints.analyticsTechnicianPerformance),
      ]);

      final roster = (results[0].data['data'] as List).cast<Map<String, dynamic>>();
      final performance = (results[1].data['data'] as List).cast<Map<String, dynamic>>();
      final performanceById = {for (final p in performance) p['id'] as String: p};

      return roster.map((r) {
        final perf = performanceById[r['id']];
        final merged = {
          ...r,
          if (perf != null) ...{
            'resolvedThisWeek': perf['resolved'],
            'avgResolutionHours': perf['avgResolutionMinutes'] != null
                ? (perf['avgResolutionMinutes'] as num) / 60
                : null,
            'slaComplianceRate': perf['totalAssigned'] != null && (perf['totalAssigned'] as int) > 0
                ? 100 -
                    (((perf['slaBreached'] as int) / (perf['totalAssigned'] as int)) * 100)
                : null,
          },
        };
        return Technician.fromJson(merged);
      }).toList();
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
