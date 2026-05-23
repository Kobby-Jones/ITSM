// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import '../../models/telemetry.dart';
import '../../models/ticket.dart';
import '../../theme/app_colors.dart';

/// Builder helpers for realistic mock tickets.
class MockTicketData {
  static DateTime _ago(Duration d) => DateTime.now().subtract(d);
  static DateTime _ahead(Duration d) => DateTime.now().add(d);

  // Reporters across departments
  static const _reporters = [
    ('u-001', 'Akosua Mensah', 'Operations', 'Tarkwa Mine'),
    ('u-002', 'Kofi Asare', 'Plant Maintenance', 'Tarkwa Mine'),
    ('u-003', 'Ama Boateng', 'Finance', 'Accra HQ'),
    ('u-004', 'Yaw Darko', 'Geology', 'Damang Mine'),
    ('u-005', 'Adwoa Frimpong', 'Human Resources', 'Accra HQ'),
    ('u-006', 'Kwesi Antwi', 'Procurement', 'Accra HQ'),
    ('u-007', 'Esi Adjei', 'Health & Safety', 'Tarkwa Mine'),
    ('u-008', 'Nana Osei', 'Engineering', 'Damang Mine'),
    ('u-009', 'Akua Tetteh', 'Operations', 'Tarkwa Mine'),
    ('u-010', 'Kojo Sarpong', 'Finance', 'Accra HQ'),
  ];

  static const _technicians = [
    ('t-001', 'Kwame Boateng'),
    ('t-002', 'Yaa Mensah'),
    ('t-003', 'Kojo Owusu'),
    ('t-004', 'Abena Asante'),
  ];

  static List<Ticket> generate() {
    final tickets = <Ticket>[];

    tickets.add(_make(
      id: 't-1042',
      code: 'INC-1042',
      title: 'Plant SCADA terminal cannot connect to OPC server',
      description:
          'The SCADA terminal at the CIL plant control room (Tarkwa) is failing to connect to the OPC server. Operators cannot read live tank levels. Restarting the terminal did not resolve the issue. This is impacting production monitoring.',
      priority: TicketPriority.p1,
      status: TicketStatus.inProgress,
      category: TicketCategory.production,
      impact: TicketImpact.organization,
      reporter: _reporters[0],
      assignee: _technicians[0],
      createdAgo: const Duration(minutes: 38),
      attachments: const [
        Attachment(name: 'scada_error.png', size: '412 KB', icon: Icons.image_rounded),
        Attachment(name: 'opc_log.txt', size: '88 KB', icon: Icons.description_rounded),
      ],
      withTelemetry: true,
    ));

    tickets.add(_make(
      id: 't-1041',
      code: 'INC-1041',
      title: 'VPN repeatedly disconnects every 5 minutes',
      description:
          'My company VPN drops every few minutes. I have to re-authenticate constantly. This started this morning after the Windows update.',
      priority: TicketPriority.p2,
      status: TicketStatus.inProgress,
      category: TicketCategory.network,
      impact: TicketImpact.team,
      reporter: _reporters[2],
      assignee: _technicians[1],
      createdAgo: const Duration(hours: 1, minutes: 15),
      withTelemetry: true,
    ));

    tickets.add(_make(
      id: 't-1040',
      code: 'INC-1040',
      title: 'SAP login fails with "user locked out" error',
      description:
          'Cannot log into SAP since this morning. Error message: "User account is locked. Contact administrator." I have tried clearing cache without success.',
      priority: TicketPriority.p2,
      status: TicketStatus.open,
      category: TicketCategory.account,
      impact: TicketImpact.individual,
      reporter: _reporters[3],
      createdAgo: const Duration(hours: 2),
      syncState: SyncState.pending,
    ));

    tickets.add(_make(
      id: 't-1039',
      code: 'INC-1039',
      title: 'Microsoft Teams audio cuts out during calls',
      description:
          'Audio drops every 30-40 seconds during Teams calls. Other participants say I sound robotic. Headset is plugged in correctly. Reinstalled Teams already.',
      priority: TicketPriority.p3,
      status: TicketStatus.onHold,
      category: TicketCategory.software,
      impact: TicketImpact.individual,
      reporter: _reporters[4],
      assignee: _technicians[2],
      createdAgo: const Duration(hours: 4, minutes: 10),
    ));

    tickets.add(_make(
      id: 't-1038',
      code: 'INC-1038',
      title: 'Printer in 3rd floor finance dept showing offline',
      description:
          'HP LaserJet on 3rd floor finance is showing as offline for everyone in the department. We have payslips to print today.',
      priority: TicketPriority.p3,
      status: TicketStatus.inProgress,
      category: TicketCategory.printing,
      impact: TicketImpact.department,
      reporter: _reporters[2],
      assignee: _technicians[3],
      createdAgo: const Duration(hours: 5),
    ));

    tickets.add(_make(
      id: 't-1037',
      code: 'INC-1037',
      title: 'Laptop overheating and shutting down',
      description:
          'My Dell Latitude shuts down after about 30 minutes of use. Bottom of the laptop is very hot. Started this week.',
      priority: TicketPriority.p2,
      status: TicketStatus.resolved,
      category: TicketCategory.hardware,
      impact: TicketImpact.individual,
      reporter: _reporters[5],
      assignee: _technicians[0],
      createdAgo: const Duration(days: 1, hours: 3),
      resolvedAgo: const Duration(hours: 6),
    ));

    tickets.add(_make(
      id: 't-1036',
      code: 'INC-1036',
      title: 'Cannot access shared drive \\\\fileserver\\geology',
      description:
          'Geology shared drive is not accessible. Says "network path not found." Other shares work fine.',
      priority: TicketPriority.p2,
      status: TicketStatus.inProgress,
      category: TicketCategory.network,
      impact: TicketImpact.department,
      reporter: _reporters[3],
      assignee: _technicians[1],
      createdAgo: const Duration(days: 1, hours: 6),
    ));

    tickets.add(_make(
      id: 't-1035',
      code: 'INC-1035',
      title: 'New starter laptop request — Geology',
      description:
          'New geologist starting Monday. Need a Dell Latitude 7440 with standard image, ArcGIS, and the geology drive mapped.',
      priority: TicketPriority.p4,
      status: TicketStatus.open,
      category: TicketCategory.hardware,
      impact: TicketImpact.individual,
      reporter: _reporters[7],
      createdAgo: const Duration(days: 1, hours: 8),
    ));

    tickets.add(_make(
      id: 't-1034',
      code: 'INC-1034',
      title: 'Outlook keeps prompting for password',
      description:
          'Outlook is asking for my password every few minutes. I enter it correctly and it pops up again.',
      priority: TicketPriority.p3,
      status: TicketStatus.resolved,
      category: TicketCategory.software,
      impact: TicketImpact.individual,
      reporter: _reporters[4],
      assignee: _technicians[2],
      createdAgo: const Duration(days: 2),
      resolvedAgo: const Duration(days: 1, hours: 18),
    ));

    tickets.add(_make(
      id: 't-1033',
      code: 'INC-1033',
      title: 'Damang Mine fibre link degraded',
      description:
          'Network monitoring shows packet loss to Damang site over the last hour. Users are reporting slow performance.',
      priority: TicketPriority.p1,
      status: TicketStatus.resolved,
      category: TicketCategory.network,
      impact: TicketImpact.organization,
      reporter: _reporters[7],
      assignee: _technicians[0],
      createdAgo: const Duration(days: 2, hours: 4),
      resolvedAgo: const Duration(days: 2, hours: 1),
    ));

    tickets.add(_make(
      id: 't-1032',
      code: 'INC-1032',
      title: 'PowerBI report failing to refresh',
      description:
          'Daily Production Dashboard PowerBI report is failing to refresh. Error: "Data source credentials are missing."',
      priority: TicketPriority.p3,
      status: TicketStatus.inProgress,
      category: TicketCategory.software,
      impact: TicketImpact.team,
      reporter: _reporters[9],
      assignee: _technicians[3],
      createdAgo: const Duration(days: 2, hours: 7),
    ));

    tickets.add(_make(
      id: 't-1031',
      code: 'INC-1031',
      title: 'Zebra label printer not printing — Procurement',
      description:
          'Zebra GK420d in receiving bay is not responding. Light on, no print jobs going through.',
      priority: TicketPriority.p2,
      status: TicketStatus.inProgress,
      category: TicketCategory.printing,
      impact: TicketImpact.team,
      reporter: _reporters[5],
      assignee: _technicians[1],
      createdAgo: const Duration(days: 2, hours: 12),
    ));

    tickets.add(_make(
      id: 't-1030',
      code: 'INC-1030',
      title: 'Two-factor authentication code not arriving',
      description:
          'Not receiving SMS codes for 2FA. Have tried 5 times in the last hour.',
      priority: TicketPriority.p2,
      status: TicketStatus.resolved,
      category: TicketCategory.account,
      impact: TicketImpact.individual,
      reporter: _reporters[6],
      assignee: _technicians[2],
      createdAgo: const Duration(days: 3),
      resolvedAgo: const Duration(days: 2, hours: 22),
    ));

    tickets.add(_make(
      id: 't-1029',
      code: 'INC-1029',
      title: 'Conveyor belt monitoring system showing stale data',
      description:
          'Conveyor 3 monitoring shows "last update 45 mins ago" — should be every 30s. Sensor field check shows no fault.',
      priority: TicketPriority.p1,
      status: TicketStatus.resolved,
      category: TicketCategory.production,
      impact: TicketImpact.department,
      reporter: _reporters[1],
      assignee: _technicians[0],
      createdAgo: const Duration(days: 3, hours: 5),
      resolvedAgo: const Duration(days: 3, hours: 2),
    ));

    tickets.add(_make(
      id: 't-1028',
      code: 'INC-1028',
      title: 'Microsoft Excel hangs when opening large workbook',
      description:
          'Production tracking workbook (~120MB) takes 8 minutes to open and Excel becomes unresponsive.',
      priority: TicketPriority.p3,
      status: TicketStatus.closed,
      category: TicketCategory.software,
      impact: TicketImpact.individual,
      reporter: _reporters[2],
      assignee: _technicians[3],
      createdAgo: const Duration(days: 4),
      resolvedAgo: const Duration(days: 3, hours: 14),
    ));

    tickets.add(_make(
      id: 't-1027',
      code: 'INC-1027',
      title: 'Wi-Fi signal weak in Tarkwa canteen',
      description:
          'Wi-Fi unusable in canteen during lunch — 50+ people on phones. Disconnects constantly.',
      priority: TicketPriority.p4,
      status: TicketStatus.open,
      category: TicketCategory.network,
      impact: TicketImpact.team,
      reporter: _reporters[8],
      createdAgo: const Duration(days: 4, hours: 8),
      syncState: SyncState.failed,
    ));

    tickets.add(_make(
      id: 't-1026',
      code: 'INC-1026',
      title: 'Request: Install AutoCAD on workstation',
      description:
          'Need AutoCAD 2024 installed on my workstation for the new mine planning project.',
      priority: TicketPriority.p4,
      status: TicketStatus.resolved,
      category: TicketCategory.software,
      impact: TicketImpact.individual,
      reporter: _reporters[7],
      assignee: _technicians[1],
      createdAgo: const Duration(days: 5),
      resolvedAgo: const Duration(days: 4, hours: 4),
    ));

    tickets.add(_make(
      id: 't-1025',
      code: 'INC-1025',
      title: 'External monitor not detected after dock change',
      description:
          'Got a new docking station yesterday. Second monitor not detected anymore. First one works.',
      priority: TicketPriority.p3,
      status: TicketStatus.closed,
      category: TicketCategory.hardware,
      impact: TicketImpact.individual,
      reporter: _reporters[2],
      assignee: _technicians[2],
      createdAgo: const Duration(days: 5, hours: 6),
      resolvedAgo: const Duration(days: 5, hours: 2),
    ));

    tickets.add(_make(
      id: 't-1024',
      code: 'INC-1024',
      title: 'Mine dispatch system slow in mornings',
      description:
          'Dispatch system takes 30+ seconds to load each truck assignment between 6-8am. Faster after 9am.',
      priority: TicketPriority.p2,
      status: TicketStatus.resolved,
      category: TicketCategory.production,
      impact: TicketImpact.department,
      reporter: _reporters[1],
      assignee: _technicians[0],
      createdAgo: const Duration(days: 6),
      resolvedAgo: const Duration(days: 5, hours: 18),
    ));

    tickets.add(_make(
      id: 't-1023',
      code: 'INC-1023',
      title: 'Need access to Procurement SharePoint folder',
      description:
          'New role in procurement, need read/write access to the contracts SharePoint folder.',
      priority: TicketPriority.p4,
      status: TicketStatus.closed,
      category: TicketCategory.account,
      impact: TicketImpact.individual,
      reporter: _reporters[5],
      assignee: _technicians[3],
      createdAgo: const Duration(days: 7),
      resolvedAgo: const Duration(days: 6, hours: 20),
    ));

    tickets.add(_make(
      id: 't-1022',
      code: 'INC-1022',
      title: 'BSOD on warehouse scanning PC',
      description:
          'Warehouse scanning workstation crashed with blue screen — DRIVER_IRQL_NOT_LESS_OR_EQUAL. Restarted, but worried it will recur.',
      priority: TicketPriority.p2,
      status: TicketStatus.resolved,
      category: TicketCategory.hardware,
      impact: TicketImpact.team,
      reporter: _reporters[5],
      assignee: _technicians[2],
      createdAgo: const Duration(days: 8),
      resolvedAgo: const Duration(days: 7, hours: 14),
    ));

    tickets.add(_make(
      id: 't-1021',
      code: 'INC-1021',
      title: 'Antivirus blocking ERP report exports',
      description:
          'ERP financial report export to Excel is being blocked by antivirus. Says it\'s a "potentially unwanted program."',
      priority: TicketPriority.p3,
      status: TicketStatus.resolved,
      category: TicketCategory.software,
      impact: TicketImpact.team,
      reporter: _reporters[9],
      assignee: _technicians[1],
      createdAgo: const Duration(days: 9),
      resolvedAgo: const Duration(days: 8, hours: 16),
    ));

    tickets.add(_make(
      id: 't-1020',
      code: 'INC-1020',
      title: 'Email signature missing company disclaimer',
      description:
          'Updated email signature template did not apply to my Outlook. Missing the legal disclaimer.',
      priority: TicketPriority.p4,
      status: TicketStatus.closed,
      category: TicketCategory.software,
      impact: TicketImpact.individual,
      reporter: _reporters[4],
      assignee: _technicians[3],
      createdAgo: const Duration(days: 10),
      resolvedAgo: const Duration(days: 9, hours: 20),
    ));

    tickets.add(_make(
      id: 't-1019',
      code: 'INC-1019',
      title: 'Cannot log into mining ERP after password change',
      description:
          'Changed password yesterday as required. Now cannot log into mining ERP. Other systems work.',
      priority: TicketPriority.p2,
      status: TicketStatus.closed,
      category: TicketCategory.account,
      impact: TicketImpact.individual,
      reporter: _reporters[6],
      assignee: _technicians[0],
      createdAgo: const Duration(days: 11),
      resolvedAgo: const Duration(days: 10, hours: 18),
    ));

    tickets.add(_make(
      id: 't-1018',
      code: 'INC-1018',
      title: 'Vibration sensor on Mill #2 not reporting',
      description:
          'Vibration sensor on Mill #2 has stopped reporting to monitoring system. Mill running normally per visual inspection.',
      priority: TicketPriority.p1,
      status: TicketStatus.closed,
      category: TicketCategory.production,
      impact: TicketImpact.department,
      reporter: _reporters[1],
      assignee: _technicians[0],
      createdAgo: const Duration(days: 12),
      resolvedAgo: const Duration(days: 11, hours: 22),
    ));

    return tickets;
  }

  // ---------------------------------------------------------------------------
  static Ticket _make({
    required String id,
    required String code,
    required String title,
    required String description,
    required TicketPriority priority,
    required TicketStatus status,
    required TicketCategory category,
    required TicketImpact impact,
    required (String, String, String, String) reporter,
    (String, String)? assignee,
    required Duration createdAgo,
    Duration? resolvedAgo,
    List<Attachment> attachments = const [],
    SyncState syncState = SyncState.synced,
    bool withTelemetry = false,
  }) {
    final created = _ago(createdAgo);
    final slaDue = created.add(Duration(hours: priority.slaHours));
    final updated = resolvedAgo != null ? _ago(resolvedAgo) : created.add(const Duration(minutes: 15));

    final events = <TicketEvent>[
      TicketEvent(
        id: '$id-e1',
        title: 'Ticket created',
        description: 'Submitted by ${reporter.$2}',
        timestamp: created,
        icon: Icons.add_circle_rounded,
        color: AppColors.primary,
        actor: reporter.$2,
      ),
    ];

    if (assignee != null) {
      events.add(TicketEvent(
        id: '$id-e2',
        title: 'Auto-assigned to ${assignee.$2}',
        description: 'Routed via category + workload rule',
        timestamp: created.add(const Duration(minutes: 2)),
        icon: Icons.assignment_ind_rounded,
        color: AppColors.statusInProgress,
      ));
    }

    if (status == TicketStatus.inProgress || status == TicketStatus.onHold) {
      events.add(TicketEvent(
        id: '$id-e3',
        title: 'Status → In Progress',
        description: 'Investigation started',
        timestamp: created.add(const Duration(minutes: 8)),
        icon: Icons.sync_rounded,
        color: AppColors.statusInProgress,
        actor: assignee?.$2,
      ));
    }

    if (status == TicketStatus.onHold) {
      events.add(TicketEvent(
        id: '$id-e4',
        title: 'Status → On Hold',
        description: 'Waiting for hardware replacement to arrive',
        timestamp: created.add(const Duration(hours: 1)),
        icon: Icons.pause_circle_rounded,
        color: AppColors.statusOnHold,
        actor: assignee?.$2,
      ));
    }

    if (resolvedAgo != null) {
      events.add(TicketEvent(
        id: '$id-e5',
        title: 'Status → Resolved',
        description: 'Issue resolved and verified with user',
        timestamp: _ago(resolvedAgo),
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        actor: assignee?.$2,
      ));
    }

    if (status == TicketStatus.closed) {
      events.add(TicketEvent(
        id: '$id-e6',
        title: 'Ticket closed',
        description: 'Confirmed by reporter',
        timestamp: updated.add(const Duration(hours: 2)),
        icon: Icons.lock_rounded,
        color: AppColors.statusClosed,
      ));
    }

    final comments = <Comment>[];
    if (assignee != null) {
      comments.add(Comment(
        id: '$id-c1',
        authorName: assignee.$2,
        authorRole: 'IT Technician',
        content:
            'Looking into this now. I\'ll update you within the hour.',
        createdAt: created.add(const Duration(minutes: 12)),
      ));
    }
    if (status == TicketStatus.onHold || status == TicketStatus.resolved || status == TicketStatus.closed) {
      comments.add(Comment(
        id: '$id-c2',
        authorName: reporter.$2,
        authorRole: 'Reporter',
        content: 'Thanks — let me know if you need anything else from me.',
        createdAt: created.add(const Duration(minutes: 30)),
      ));
    }
    if (resolvedAgo != null) {
      comments.add(Comment(
        id: '$id-c3',
        authorName: assignee?.$2 ?? 'IT Team',
        authorRole: 'IT Technician',
        content:
            'Resolved. Root cause identified and remediated. Closing this out — please reopen if it recurs.',
        createdAt: _ago(resolvedAgo),
      ));
    }

    return Ticket(
      id: id,
      code: code,
      title: title,
      description: description,
      priority: priority,
      status: status,
      category: category,
      impact: impact,
      reporterId: reporter.$1,
      reporterName: reporter.$2,
      reporterDepartment: reporter.$3,
      assigneeId: assignee?.$1,
      assigneeName: assignee?.$2,
      createdAt: created,
      updatedAt: updated,
      slaDueAt: slaDue,
      comments: comments,
      events: events,
      attachments: attachments,
      deviceId: withTelemetry ? 'GHA-LT-${id.split('-').last}' : null,
      syncState: syncState,
      location: reporter.$4,
    );
  }
}

/// Mock device telemetry for tickets that have a device attached.
class MockTelemetryData {
  static DeviceTelemetry forTicket(String ticketId) {
    final base = DateTime.now();
    final logs = [
      TelemetryLog(timestamp: base.subtract(const Duration(seconds: 12)), level: 'ERROR', tag: 'OPC.Client', message: 'Connection refused: server unreachable at 10.42.18.5:4840'),
      TelemetryLog(timestamp: base.subtract(const Duration(seconds: 22)), level: 'WARN', tag: 'Network', message: 'Latency spike detected: 412ms to gateway'),
      TelemetryLog(timestamp: base.subtract(const Duration(minutes: 1)), level: 'ERROR', tag: 'OPC.Client', message: 'Subscription handshake timed out after 30s'),
      TelemetryLog(timestamp: base.subtract(const Duration(minutes: 2)), level: 'WARN', tag: 'CPU', message: 'CPU usage above 85% for 30s sustained'),
      TelemetryLog(timestamp: base.subtract(const Duration(minutes: 3)), level: 'INFO', tag: 'System', message: 'User akosua.mensah signed in'),
      TelemetryLog(timestamp: base.subtract(const Duration(minutes: 4)), level: 'CRASH', tag: 'scada.exe', message: 'Process exited unexpectedly with code 0xC0000005'),
      TelemetryLog(timestamp: base.subtract(const Duration(minutes: 8)), level: 'INFO', tag: 'System', message: 'Network adapter reset (DHCP renew)'),
      TelemetryLog(timestamp: base.subtract(const Duration(minutes: 12)), level: 'WARN', tag: 'Storage', message: 'Disk write latency: 240ms'),
    ];

    return DeviceTelemetry(
      deviceId: 'GHA-LT-${ticketId.split('-').last}',
      deviceModel: 'Dell Latitude 7440',
      osVersion: 'Windows 11 Pro 23H2 (Build 22631.3447)',
      hostname: 'TKW-SCADA-04',
      ramTotalMb: 16384,
      ramUsedMb: 12950,
      cpuUsage: 0.78,
      storageTotalGb: 512,
      storageUsedGb: 387,
      networkStatus: 'Limited',
      networkType: 'Ethernet',
      batteryPercent: 64,
      charging: true,
      cpuTemperature: 72.4,
      logs: logs,
      collectedAt: base,
      publicIp: '197.221.24.11',
      macAddress: 'AC:DE:48:00:11:22',
      topProcesses: const [
        (name: 'scada.exe', cpu: 38.2, mem: 1840.0),
        (name: 'chrome.exe', cpu: 14.6, mem: 2100.0),
        (name: 'OUTLOOK.EXE', cpu: 6.2, mem: 540.0),
        (name: 'Teams.exe', cpu: 5.1, mem: 720.0),
        (name: 'antivirus.exe', cpu: 4.4, mem: 380.0),
      ],
    );
  }
}
