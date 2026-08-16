import '../core/network/api_client.dart';

class RoutingRule {
  final String id;
  final String name;
  final String? description;
  final String ruleType;
  final int priority;
  final bool isActive;
  final Map<String, dynamic> conditions;
  final String? assignTo;
  final String? departmentId;

  const RoutingRule({
    required this.id,
    required this.name,
    this.description,
    required this.ruleType,
    required this.priority,
    required this.isActive,
    required this.conditions,
    this.assignTo,
    this.departmentId,
  });

  factory RoutingRule.fromJson(Map<String, dynamic> json) => RoutingRule(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        ruleType: json['ruleType'] as String,
        priority: json['priority'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        conditions: json['conditions'] as Map<String, dynamic>? ?? {},
        assignTo: json['assignTo'] as String?,
        departmentId: json['departmentId'] as String?,
      );
}

class RoutingAdminService {
  RoutingAdminService._();
  static final RoutingAdminService instance = RoutingAdminService._();

  final _dio = ApiClient.instance.dio;

  Future<List<RoutingRule>> getRules() async {
    try {
      final res = await _dio.get('/routing');
      final data = res.data['data'] as List;
      return data
          .map((r) => RoutingRule.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<RoutingRule> createRule(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/routing', data: body);
      return RoutingRule.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> updateRule(String id, Map<String, dynamic> body) async {
    try {
      await _dio.patch('/routing/$id', data: body);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> deleteRule(String id) async {
    try {
      await _dio.delete('/routing/$id');
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
