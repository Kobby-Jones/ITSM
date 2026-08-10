import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/notification_model.dart';
import '../services/notifications_service.dart';

class NotificationsController extends StateNotifier<List<AppNotification>> {
  NotificationsController() : super(const []) {
    load();
  }

  Future<void> load() async {
    try {
      state = await NotificationsService.instance.getNotifications();
    } catch (_) {
      // Keep last-known state (possibly empty) rather than throwing in the
      // UI tree; the bell icon just won't update until the next load().
    }
  }

  Future<void> refresh() => load();

  /// Optimistic local update + fire-and-forget API call, same pattern as
  /// `TicketsController` — the UI reflects the tap instantly.
  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(read: true) else n,
    ];
    NotificationsService.instance.markRead(id).catchError((_) {});
  }

  void markAllRead() {
    state = [for (final n in state) n.copyWith(read: true)];
    NotificationsService.instance.markAllRead().catchError((_) {});
  }

  int get unreadCount => state.where((n) => !n.read).length;
}

final notificationsProvider =
    StateNotifierProvider<NotificationsController, List<AppNotification>>(
        (ref) => NotificationsController());

/// Reactive unread count — recomputes whenever the notifications list
/// changes (unlike reading `.notifier.unreadCount` once, which wouldn't
/// trigger a rebuild on its own).
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((n) => !n.read).length;
});
