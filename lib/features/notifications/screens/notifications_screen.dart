// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/notification_model.dart';
import '../../../providers/notifications_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(notificationsProvider);
    final unread = all.where((n) => !n.read).length;

    var filtered = all;
    if (_filter == 'Unread') filtered = filtered.where((n) => !n.read).toList();

    return Padding(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Notifications',
                subtitle: '$unread unread of ${all.length} total.',
                trailing: TextButton.icon(
                  onPressed: unread == 0
                      ? null
                      : () {
                          ref.read(notificationsProvider.notifier).markAllRead();
                          context.showSnack('All notifications marked as read.');
                        },
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('Mark all read'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final f in const ['All', 'Unread']) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _filter == f ? context.colors.primary : context.colors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _filter == f ? context.colors.primary : context.colors.outline,
                          ),
                        ),
                        child: Text(
                          f == 'Unread' ? 'Unread ($unread)' : f,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _filter == f
                                ? Colors.white
                                : context.colors.onSurface.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: 'You\'re all caught up',
                        message: 'No notifications to show right now.',
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.colors.outline),
                        ),
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _NotificationRow(
                            notification: filtered[i],
                            isLast: i == filtered.length - 1,
                          ).animate(delay: (i * 18).ms).fadeIn(duration: 200.ms),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  final AppNotification notification;
  final bool isLast;
  const _NotificationRow({required this.notification, required this.isLast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        if (!notification.read) {
          ref.read(notificationsProvider.notifier).markAsRead(notification.id);
        }
        if (notification.ticketId != null) {
          context.go(AppRoutes.ticketDetailFor(notification.ticketId!));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: notification.read ? null : notification.type.color.withOpacity(0.04),
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : context.colors.outline,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!notification.read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 8, right: 12),
                decoration: BoxDecoration(
                  color: notification.type.color,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(width: 20),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: notification.type.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(notification.type.icon,
                  color: notification.type.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: notification.read ? FontWeight.w600 : FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        Formatters.relativeTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.colors.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.colors.onSurface.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                  if (notification.ticketCode != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: context.colors.outline),
                      ),
                      child: Text(
                        notification.ticketCode!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          color: context.colors.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
