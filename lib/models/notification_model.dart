import 'package:flutter/material.dart';

enum NotificationType {
  ticketCreated('TICKET_CREATED', 'Ticket Created', Icons.fiber_new_rounded, Color(0xFF3B82F6)),
  ticketAssigned('TICKET_ASSIGNED', 'Ticket Assigned', Icons.assignment_ind_rounded, Color(0xFF3B82F6)),
  slaBreach('SLA_BREACH', 'SLA Breach', Icons.warning_amber_rounded, Color(0xFFEF4444)),
  slaWarning('SLA_WARNING', 'SLA Warning', Icons.timer_rounded, Color(0xFFF59E0B)),
  ticketUpdated('TICKET_UPDATED', 'Ticket Updated', Icons.update_rounded, Color(0xFF8B5CF6)),
  ticketResolved('TICKET_RESOLVED', 'Ticket Resolved', Icons.check_circle_rounded, Color(0xFF10B981)),
  newComment('COMMENT_ADDED', 'New Comment', Icons.comment_rounded, Color(0xFF06B6D4)),
  escalation('TICKET_ESCALATED', 'Escalation', Icons.arrow_upward_rounded, Color(0xFFDC2626)),
  assetAssigned('ASSET_ASSIGNED', 'Asset Assigned', Icons.devices_rounded, Color(0xFF0EA5E9)),
  system('SYSTEM_ALERT', 'System', Icons.settings_rounded, Color(0xFF6B7280));

  final String apiValue;
  final String label;
  final IconData icon;
  final Color color;
  const NotificationType(this.apiValue, this.label, this.icon, this.color);

  static NotificationType fromApi(String? value) => NotificationType.values.firstWhere(
        (t) => t.apiValue == value,
        orElse: () => NotificationType.system,
      );
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

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.fromApi(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['message'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      read: json['isRead'] as bool? ?? false,
      ticketId: json['ticketId'] as String?,
      ticketCode: data?['ticketNumber'] as String?,
    );
  }
}
