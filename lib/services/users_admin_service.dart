import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/user.dart';

class UsersAdminService {
  UsersAdminService._();
  static final UsersAdminService instance = UsersAdminService._();

  final _dio = ApiClient.instance.dio;

  /// Fetches users with optional search and role filter.
  Future<({List<AppUser> users, int total})> getUsers({
    int page = 1,
    int limit = 50,
    String? search,
    String? status,
  }) async {
    try {
      final res = await _dio.get(ApiEndpoints.users, queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        'status': ?status,
      });
      final data = res.data['data'] as List;
      final total = res.data['total'] as int? ?? data.length;
      return (
        users: data.map((u) => AppUser.fromJson(u as Map<String, dynamic>)).toList(),
        total: total,
      );
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  /// Update a user's role via PATCH /users/:id.
  Future<void> updateUserRole(String userId, String roleId) async {
    try {
      await _dio.patch(ApiEndpoints.user(userId), data: {'roleId': roleId});
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  /// Deactivate a user via PATCH /users/:id.
  Future<void> deactivateUser(String userId) async {
    try {
      await _dio.patch(ApiEndpoints.user(userId), data: {'status': 'INACTIVE'});
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  /// Reactivate a user via PATCH /users/:id.
  Future<void> activateUser(String userId) async {
    try {
      await _dio.patch(ApiEndpoints.user(userId), data: {'status': 'ACTIVE'});
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
