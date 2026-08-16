import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum TicketPriority {
  p1('P1_CRITICAL', 'P1', 'Critical', AppColors.p1Critical, Icons.error_rounded, 4),
  p2('P2_HIGH', 'P2', 'High', AppColors.p2High, Icons.warning_rounded, 8),
  p3('P3_MEDIUM', 'P3', 'Medium', AppColors.p3Medium, Icons.flag_rounded, 24),
  p4('P4_LOW', 'P4', 'Low', AppColors.p4Low, Icons.low_priority_rounded, 72);

  /// Exact enum value the backend (Prisma `TicketPriority`) sends/expects.
  final String apiValue;
  final String code;
  final String label;
  final Color color;
  final IconData icon;
  final int slaHours;
  const TicketPriority(this.apiValue, this.code, this.label, this.color, this.icon, this.slaHours);

  static TicketPriority fromApi(String? value) => TicketPriority.values.firstWhere(
        (p) => p.apiValue == value,
        orElse: () => TicketPriority.p3,
      );
}

enum TicketStatus {
  open('OPEN', 'Open', AppColors.statusOpen, Icons.fiber_new_rounded),
  assigned('ASSIGNED', 'Assigned', AppColors.statusAssigned, Icons.assignment_ind_rounded),
  inProgress('IN_PROGRESS', 'In Progress', AppColors.statusInProgress, Icons.sync_rounded),
  onHold('PENDING', 'On Hold', AppColors.statusOnHold, Icons.pause_circle_rounded),
  resolved('RESOLVED', 'Resolved', AppColors.statusResolved, Icons.check_circle_rounded),
  closed('CLOSED', 'Closed', AppColors.statusClosed, Icons.lock_rounded),
  escalated('ESCALATED', 'Escalated', AppColors.statusEscalated, Icons.arrow_upward_rounded);

  /// Exact enum value the backend (Prisma `TicketStatus`) sends/expects.
  final String apiValue;
  final String label;
  final Color color;
  final IconData icon;
  const TicketStatus(this.apiValue, this.label, this.color, this.icon);

  static TicketStatus fromApi(String? value) => TicketStatus.values.firstWhere(
        (s) => s.apiValue == value,
        orElse: () => TicketStatus.open,
      );
}

enum TicketCategory {
  network('NETWORK_CONNECTIVITY', 'Network & Connectivity', Icons.wifi_rounded),
  hardware('HARDWARE_ISSUES', 'Hardware Issues', Icons.computer_rounded),
  software('SOFTWARE_APPLICATION', 'Software / Application', Icons.apps_rounded),
  account('ACCOUNT_ACCESS_IDENTITY', 'Account Access & Identity', Icons.lock_person_rounded),
  printing('PRINTING_PROBLEMS', 'Printing Problems', Icons.print_rounded),
  production('PRODUCTION_SYSTEMS', 'Production Systems', Icons.factory_rounded);

  /// Exact enum value the backend (Prisma `TicketCategory`) sends/expects.
  final String apiValue;
  final String label;
  final IconData icon;
  const TicketCategory(this.apiValue, this.label, this.icon);

  static TicketCategory fromApi(String? value) => TicketCategory.values.firstWhere(
        (c) => c.apiValue == value,
        orElse: () => TicketCategory.software,
      );
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

  factory Comment.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final name = author == null
        ? 'Unknown'
        : '${author['firstName'] ?? ''} ${author['lastName'] ?? ''}'.trim();
    return Comment(
      id: json['id'] as String,
      authorName: name.isEmpty ? 'Unknown' : name,
      authorRole: author?['role'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      isInternal: json['isInternal'] as bool? ?? false,
    );
  }
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

  factory TicketEvent.fromJson(Map<String, dynamic> json) {
    final action = json['action'] as String? ?? 'UPDATED';
    final changedBy = json['changedBy'] as Map<String, dynamic>?;
    final actorName = changedBy == null
        ? null
        : '${changedBy['firstName'] ?? ''} ${changedBy['lastName'] ?? ''}'.trim();
    final field = json['field'] as String?;
    final oldValue = json['oldValue'] as String?;
    final newValue = json['newValue'] as String?;

    final (icon, color) = _iconAndColorFor(action);

    return TicketEvent(
      id: json['id'] as String,
      title: _titleFor(action),
      description: json['note'] as String? ??
          (field != null && newValue != null
              ? '$field changed${oldValue != null ? ' from $oldValue' : ''} to $newValue'
              : ''),
      timestamp: DateTime.parse(json['createdAt'] as String),
      icon: icon,
      color: color,
      actor: (actorName?.isEmpty ?? true) ? null : actorName,
    );
  }

  static String _titleFor(String action) => switch (action) {
        'CREATED' => 'Ticket created',
        'ASSIGNED' || 'ASSIGN' => 'Assigned',
        'RESOLVED' || 'RESOLVE' => 'Resolved',
        'CLOSED' || 'CLOSE' => 'Closed',
        'ESCALATED' || 'ESCALATE' => 'Escalated',
        'IN_PROGRESS' => 'In progress',
        'PENDING' => 'Pending',
        'OPEN' => 'Reopened',
        'UPDATED' => 'Updated',
        _ => 'Updated',
      };

  static (IconData, Color) _iconAndColorFor(String action) => switch (action) {
        'CREATED' => (Icons.fiber_new_rounded, AppColors.statusOpen),
        'ASSIGNED' || 'ASSIGN' => (Icons.assignment_ind_rounded, AppColors.statusAssigned),
        'RESOLVED' || 'RESOLVE' => (Icons.check_circle_rounded, AppColors.statusResolved),
        'CLOSED' || 'CLOSE' => (Icons.lock_rounded, AppColors.statusClosed),
        'ESCALATED' || 'ESCALATE' => (Icons.arrow_upward_rounded, AppColors.statusEscalated),
        'IN_PROGRESS' => (Icons.play_circle_rounded, AppColors.statusInProgress),
        'PENDING' => (Icons.pause_circle_rounded, AppColors.warning),
        'OPEN' => (Icons.refresh_rounded, AppColors.statusOpen),
        _ => (Icons.update_rounded, AppColors.statusInProgress),
      };
}

class Attachment {
  final String name;
  final String size;
  final IconData icon;
  final String? url;

  const Attachment({required this.name, required this.size, required this.icon, this.url});

  factory Attachment.fromJson(Map<String, dynamic> json) {
    final bytes = json['size'] as int? ?? 0;
    final mimetype = json['mimetype'] as String? ?? '';
    return Attachment(
      name: json['originalName'] as String? ?? json['filename'] as String? ?? 'file',
      size: _formatBytes(bytes),
      icon: _iconForMime(mimetype),
      url: json['url'] as String?,
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static IconData _iconForMime(String mimetype) {
    if (mimetype.startsWith('image/')) return Icons.image_rounded;
    if (mimetype == 'application/pdf') return Icons.picture_as_pdf_rounded;
    if (mimetype.contains('word')) return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }
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

  /// Builds a [Ticket] from the raw JSON returned by `GET /tickets` and
  /// `GET /tickets/:id`. Handles both the list shape (no `comments`/`history`)
  /// and the detail shape (includes them) — missing keys default to empty.
  factory Ticket.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String? s) => s != null ? DateTime.parse(s) : DateTime.now();

    final creator = json['creator'] as Map<String, dynamic>?;
    final assignee = json['assignee'] as Map<String, dynamic>?;
    final department = json['department'] as Map<String, dynamic>?;

    String fullName(Map<String, dynamic>? u) =>
        u == null ? '' : '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim();

    return Ticket(
      id: json['id'] as String,
      code: json['ticketNumber'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority: TicketPriority.fromApi(json['priority'] as String?),
      status: TicketStatus.fromApi(json['status'] as String?),
      category: TicketCategory.fromApi(json['category'] as String?),
      impact: _impactFromApi(json['impact'] as String?),
      reporterId: json['creatorId'] as String? ?? creator?['id'] as String? ?? '',
      reporterName: fullName(creator),
      reporterDepartment: department?['name'] as String? ?? '',
      assigneeId: json['assigneeId'] as String?,
      assigneeName: assignee != null ? fullName(assignee) : null,
      createdAt: parseDate(json['createdAt'] as String? ?? json['openedAt'] as String?),
      updatedAt: parseDate(json['updatedAt'] as String?),
      slaDueAt: json['slaResolutionDue'] != null
          ? DateTime.parse(json['slaResolutionDue'] as String)
          : parseDate(json['createdAt'] as String?)
              .add(Duration(hours: TicketPriority.fromApi(json['priority'] as String?).slaHours)),
      comments: (json['comments'] as List?)
              ?.map((c) => Comment.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      events: (json['history'] as List?)
              ?.map((h) => TicketEvent.fromJson(h as Map<String, dynamic>))
              .toList() ??
          const [],
      attachments: (json['attachments'] as List?)
              ?.map((a) => Attachment.fromJson(a as Map<String, dynamic>))
              .toList() ??
          const [],
      deviceId: json['deviceId'] as String?,
      syncState: SyncState.synced,
      location: department?['name'] as String? ?? '',
    );
  }

  static TicketImpact _impactFromApi(String? value) {
    switch (value) {
      case 'ORGANIZATION':
        return TicketImpact.organization;
      case 'DEPARTMENT':
        return TicketImpact.department;
      case 'TEAM':
        return TicketImpact.team;
      default:
        return TicketImpact.individual;
    }
  }

  /// Payload for `POST /tickets`. [offlineId] should be a locally-generated
  /// UUID so the backend can dedupe if the same create is retried after a
  /// dropped connection (see `SyncQueueService`).
  Map<String, dynamic> toCreatePayload({String? offlineId}) => {
        'title': title,
        'description': description,
        'category': category.apiValue,
        'priority': priority.apiValue,
        'tags': <String>[],
        // ignore: use_null_aware_elements
        if (offlineId != null) 'offlineId': offlineId,
      };

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
