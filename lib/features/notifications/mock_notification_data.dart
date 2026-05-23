import '../../models/notification_model.dart';

class MockNotificationData {
  static List<AppNotification> generate() {
    final now = DateTime.now();
    DateTime ago(Duration d) => now.subtract(d);

    return [
      AppNotification(
        id: 'n-001',
        type: NotificationType.slaWarning,
        title: 'SLA approaching breach',
        body: 'INC-1031 — Zebra label printer has 1h 12m of SLA remaining.',
        createdAt: ago(const Duration(minutes: 8)),
        ticketId: 't-1031',
        ticketCode: 'INC-1031',
      ),
      AppNotification(
        id: 'n-002',
        type: NotificationType.ticketAssigned,
        title: 'New ticket assigned to you',
        body: 'INC-1042 — Plant SCADA terminal cannot connect to OPC server.',
        createdAt: ago(const Duration(minutes: 38)),
        ticketId: 't-1042',
        ticketCode: 'INC-1042',
      ),
      AppNotification(
        id: 'n-003',
        type: NotificationType.newComment,
        title: 'New comment on INC-1041',
        body: 'Yaa Mensah commented: "We have isolated the issue to the firewall…"',
        createdAt: ago(const Duration(hours: 2, minutes: 40)),
        ticketId: 't-1041',
        ticketCode: 'INC-1041',
      ),
      AppNotification(
        id: 'n-004',
        type: NotificationType.ticketResolved,
        title: 'Ticket resolved',
        body: 'INC-1037 — Laptop overheating and shutting down has been resolved.',
        createdAt: ago(const Duration(hours: 6)),
        read: true,
        ticketId: 't-1037',
        ticketCode: 'INC-1037',
      ),
      AppNotification(
        id: 'n-005',
        type: NotificationType.escalation,
        title: 'P1 escalation',
        body: 'INC-1042 has been escalated to senior IT — SCADA terminal critical.',
        createdAt: ago(const Duration(hours: 7)),
        ticketId: 't-1042',
        ticketCode: 'INC-1042',
      ),
      AppNotification(
        id: 'n-006',
        type: NotificationType.slaBreach,
        title: 'SLA breached',
        body: 'INC-1027 — Wi-Fi signal weak in Tarkwa canteen has breached SLA.',
        createdAt: ago(const Duration(hours: 9)),
        read: true,
        ticketId: 't-1027',
        ticketCode: 'INC-1027',
      ),
      AppNotification(
        id: 'n-007',
        type: NotificationType.system,
        title: 'Scheduled maintenance',
        body: 'VPN gateway maintenance window: Saturday 02:00-04:00. Brief disconnects expected.',
        createdAt: ago(const Duration(hours: 14)),
        read: true,
      ),
      AppNotification(
        id: 'n-008',
        type: NotificationType.ticketUpdated,
        title: 'Ticket status changed',
        body: 'INC-1039 was placed on hold pending hardware delivery.',
        createdAt: ago(const Duration(days: 1, hours: 4)),
        read: true,
        ticketId: 't-1039',
        ticketCode: 'INC-1039',
      ),
      AppNotification(
        id: 'n-009',
        type: NotificationType.system,
        title: 'New KB article published',
        body: 'KB-010 "Reporting a phishing email" was just published.',
        createdAt: ago(const Duration(days: 2, hours: 6)),
        read: true,
      ),
      AppNotification(
        id: 'n-010',
        type: NotificationType.ticketResolved,
        title: 'Ticket resolved',
        body: 'INC-1034 — Outlook keeps prompting for password.',
        createdAt: ago(const Duration(days: 2, hours: 8)),
        read: true,
        ticketId: 't-1034',
        ticketCode: 'INC-1034',
      ),
    ];
  }
}
