import '../core/network/api_client.dart';

class SlaConfig {
  final String priority;
  final int responseTimeMinutes;
  final int resolutionTimeMinutes;

  const SlaConfig({
    required this.priority,
    required this.responseTimeMinutes,
    required this.resolutionTimeMinutes,
  });

  factory SlaConfig.fromJson(Map<String, dynamic> json) => SlaConfig(
        priority: json['priority'] as String,
        responseTimeMinutes: json['responseTimeMinutes'] as int,
        resolutionTimeMinutes: json['resolutionTimeMinutes'] as int,
      );
}

class SlaAdminService {
  SlaAdminService._();
  static final SlaAdminService instance = SlaAdminService._();

  final _dio = ApiClient.instance.dio;

  /// GET /sla/configurations
  Future<List<SlaConfig>> getConfigurations() async {
    try {
      final res = await _dio.get('/sla/configurations');
      final data = res.data['data'] as List;
      return data
          .map((c) => SlaConfig.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  /// PUT /sla/configurations/:priority
  Future<void> updateConfiguration({
    required String priority,
    required int responseTimeMinutes,
    required int resolutionTimeMinutes,
  }) async {
    try {
      await _dio.put('/sla/configurations/$priority', data: {
        'responseTimeMinutes': responseTimeMinutes,
        'resolutionTimeMinutes': resolutionTimeMinutes,
      });
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
