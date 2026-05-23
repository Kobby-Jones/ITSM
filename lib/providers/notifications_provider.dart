import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/notification_model.dart';
import '../features/notifications/mock_notification_data.dart';

class NotificationsController extends StateNotifier<List<AppNotification>> {
  NotificationsController() : super(MockNotificationData.generate());

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(read: true) else n,
    ];
  }

  void markAllRead() {
    state = [for (final n in state) n.copyWith(read: true)];
  }

  int get unreadCount => state.where((n) => !n.read).length;
}

final notificationsProvider =
    StateNotifierProvider<NotificationsController, List<AppNotification>>(
        (ref) => NotificationsController());

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.read).length;
});
