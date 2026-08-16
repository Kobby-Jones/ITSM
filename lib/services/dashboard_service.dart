import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

/// Dashboard KPIs returned by `GET /analytics/dashboard`.
class DashboardKpis {
  final int totalTickets;
  final int openTickets;
  final int resolvedTickets;
  final int closedTickets;
  final int escalatedTickets;
  final int thisMonthTickets;
  final double? monthGrowth;
  final int criticalOpen;
  final int slaBreached;
  final double slaComplianceRate;
  final int? avgResolutionMinutes;
  final double? avgResolutionHours;
  final int? totalUsers;
  final int? activeAssets;
  final Map<String, int> byCategory;
  final Map<String, int> byStatus;

  const DashboardKpis({
    this.totalTickets = 0,
    this.openTickets = 0,
    this.resolvedTickets = 0,
    this.closedTickets = 0,
    this.escalatedTickets = 0,
    this.thisMonthTickets = 0,
    this.monthGrowth,
    this.criticalOpen = 0,
    this.slaBreached = 0,
    this.slaComplianceRate = 100,
    this.avgResolutionMinutes,
    this.avgResolutionHours,
    this.totalUsers,
    this.activeAssets,
    this.byCategory = const {},
    this.byStatus = const {},
  });

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    final tickets = json['tickets'] as Map<String, dynamic>? ?? {};
    final sla = json['sla'] as Map<String, dynamic>? ?? {};
    final perf = json['performance'] as Map<String, dynamic>? ?? {};

    return DashboardKpis(
      totalTickets: tickets['total'] as int? ?? 0,
      openTickets: tickets['open'] as int? ?? 0,
      resolvedTickets: tickets['resolved'] as int? ?? 0,
      closedTickets: tickets['closed'] as int? ?? 0,
      escalatedTickets: tickets['escalated'] as int? ?? 0,
      thisMonthTickets: tickets['thisMonth'] as int? ?? 0,
      monthGrowth: (tickets['monthGrowth'] as num?)?.toDouble(),
      criticalOpen: tickets['criticalOpen'] as int? ?? 0,
      slaBreached: sla['breached'] as int? ?? 0,
      slaComplianceRate: (sla['complianceRate'] as num?)?.toDouble() ?? 100,
      avgResolutionMinutes: perf['avgResolutionMinutes'] as int?,
      avgResolutionHours: (perf['avgResolutionHours'] as num?)?.toDouble(),
      totalUsers: json['totalUsers'] as int?,
      activeAssets: json['activeAssets'] as int?,
      byCategory: _toIntMap(json['byCategory']),
      byStatus: _toIntMap(json['byStatus']),
    );
  }

  static Map<String, int> _toIntMap(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
  }
}

class DashboardService {
  DashboardService._();
  static final DashboardService instance = DashboardService._();

  final _dio = ApiClient.instance.dio;

  Future<DashboardKpis> getKpis() async {
    try {
      final res = await _dio.get(ApiEndpoints.analyticsDashboard);
      return DashboardKpis.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
