import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/notification_model.dart';

class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  final _dio = ApiClient.instance.dio;

  Future<List<AppNotification>> getNotifications() async {
    try {
      final res = await _dio.get(ApiEndpoints.notifications, queryParameters: {'limit': 100});
      final data = res.data['data'] as List;
      return data.map((n) => AppNotification.fromJson(n as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.patch(ApiEndpoints.notificationRead(id));
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.patch(ApiEndpoints.notificationsMarkAllRead);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final res = await _dio.get(ApiEndpoints.notificationsUnreadCount);
      return res.data['data']['count'] as int? ?? 0;
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _dio.delete(ApiEndpoints.notification(id));
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
