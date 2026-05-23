import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum TicketPriority {
  p1('P1', 'Critical', AppColors.p1Critical, Icons.error_rounded, 4),
  p2('P2', 'High', AppColors.p2High, Icons.warning_rounded, 8),
  p3('P3', 'Medium', AppColors.p3Medium, Icons.flag_rounded, 24),
  p4('P4', 'Low', AppColors.p4Low, Icons.low_priority_rounded, 72);

  final String code;
  final String label;
  final Color color;
  final IconData icon;
  final int slaHours;
  const TicketPriority(this.code, this.label, this.color, this.icon, this.slaHours);
}

enum TicketStatus {
  open('Open', AppColors.statusOpen, Icons.fiber_new_rounded),
  inProgress('In Progress', AppColors.statusInProgress, Icons.sync_rounded),
  onHold('On Hold', AppColors.statusOnHold, Icons.pause_circle_rounded),
  resolved('Resolved', AppColors.statusResolved, Icons.check_circle_rounded),
  closed('Closed', AppColors.statusClosed, Icons.lock_rounded);

  final String label;
  final Color color;
  final IconData icon;
  const TicketStatus(this.label, this.color, this.icon);
}

enum TicketCategory {
  network('Network & Connectivity', Icons.wifi_rounded),
  hardware('Hardware Issues', Icons.computer_rounded),
  software('Software / Application', Icons.apps_rounded),
  account('Account Access & Identity', Icons.lock_person_rounded),
  printing('Printing Problems', Icons.print_rounded),
  production('Production Systems', Icons.factory_rounded);

  final String label;
  final IconData icon;
  const TicketCategory(this.label, this.icon);
}

enum TicketImpact {
  individual('Individual', 'Affects one user'),
  team('Team', 'Affects a small group'),
  department('Department', 'Affects a department'),
  organization('Organization', 'Affects entire organization');

  final String label;
  final String description;
  const TicketImpact(this.label, this.description);
}

class Comment {
  final String id;
  final String authorName;
  final String authorRole;
  final String content;
  final DateTime createdAt;
  final bool isInternal;

  const Comment({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.content,
    required this.createdAt,
    this.isInternal = false,
  });
}

class TicketEvent {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
  final String? actor;

  const TicketEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
    required this.color,
    this.actor,
  });
}

class Attachment {
  final String name;
  final String size;
  final IconData icon;

  const Attachment({required this.name, required this.size, required this.icon});
}

enum SyncState { synced, pending, syncing, failed }

class Ticket {
  final String id;
  final String code;
  final String title;
  final String description;
  final TicketPriority priority;
  final TicketStatus status;
  final TicketCategory category;
  final TicketImpact impact;
  final String reporterId;
  final String reporterName;
  final String reporterDepartment;
  final String? assigneeId;
  final String? assigneeName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime slaDueAt;
  final List<Comment> comments;
  final List<TicketEvent> events;
  final List<Attachment> attachments;
  final String? deviceId;
  final SyncState syncState;
  final String location;

  const Ticket({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.category,
    required this.impact,
    required this.reporterId,
    required this.reporterName,
    required this.reporterDepartment,
    this.assigneeId,
    this.assigneeName,
    required this.createdAt,
    required this.updatedAt,
    required this.slaDueAt,
    this.comments = const [],
    this.events = const [],
    this.attachments = const [],
    this.deviceId,
    this.syncState = SyncState.synced,
    required this.location,
  });

  Duration get slaRemaining => slaDueAt.difference(DateTime.now());
  bool get slaBreached =>
      slaRemaining.isNegative &&
      status != TicketStatus.resolved &&
      status != TicketStatus.closed;
  double get slaProgress {
    final total = slaDueAt.difference(createdAt).inSeconds;
    final elapsed = DateTime.now().difference(createdAt).inSeconds;
    if (total <= 0) return 1.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Ticket copyWith({
    TicketStatus? status,
    String? assigneeId,
    String? assigneeName,
    DateTime? updatedAt,
    List<Comment>? comments,
    List<TicketEvent>? events,
    SyncState? syncState,
  }) {
    return Ticket(
      id: id,
      code: code,
      title: title,
      description: description,
      priority: priority,
      status: status ?? this.status,
      category: category,
      impact: impact,
      reporterId: reporterId,
      reporterName: reporterName,
      reporterDepartment: reporterDepartment,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      slaDueAt: slaDueAt,
      comments: comments ?? this.comments,
      events: events ?? this.events,
      attachments: attachments,
      deviceId: deviceId,
      syncState: syncState ?? this.syncState,
      location: location,
    );
  }
}
