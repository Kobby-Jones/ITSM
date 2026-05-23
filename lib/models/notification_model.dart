import 'package:flutter/material.dart';

enum NotificationType {
  ticketAssigned('Ticket Assigned', Icons.assignment_ind_rounded, Color(0xFF3B82F6)),
  slaBreach('SLA Breach', Icons.warning_amber_rounded, Color(0xFFEF4444)),
  slaWarning('SLA Warning', Icons.timer_rounded, Color(0xFFF59E0B)),
  ticketUpdated('Ticket Updated', Icons.update_rounded, Color(0xFF8B5CF6)),
  ticketResolved('Ticket Resolved', Icons.check_circle_rounded, Color(0xFF10B981)),
  newComment('New Comment', Icons.comment_rounded, Color(0xFF06B6D4)),
  escalation('Escalation', Icons.arrow_upward_rounded, Color(0xFFDC2626)),
  system('System', Icons.settings_rounded, Color(0xFF6B7280));

  final String label;
  final IconData icon;
  final Color color;
  const NotificationType(this.label, this.icon, this.color);
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? ticketId;
  final String? ticketCode;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.ticketId,
    this.ticketCode,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        read: read ?? this.read,
        ticketId: ticketId,
        ticketCode: ticketCode,
      );
}
