class Technician {
  final String id;
  final String name;
  final String specialty;
  final int activeTickets;
  final int resolvedToday;
  final int resolvedThisWeek;
  final double avgResolutionHours;
  final double slaComplianceRate;
  final double customerSatisfaction;
  final bool online;
  final String avatarInitials;

  const Technician({
    required this.id,
    required this.name,
    required this.specialty,
    required this.activeTickets,
    required this.resolvedToday,
    required this.resolvedThisWeek,
    required this.avgResolutionHours,
    required this.slaComplianceRate,
    required this.customerSatisfaction,
    required this.online,
    required this.avatarInitials,
  });

  double get workloadPercent {
    const cap = 12.0;
    return (activeTickets / cap).clamp(0.0, 1.0);
  }

  /// Builds a [Technician] from `GET /users/technicians`.
  ///
  /// IMPORTANT: that endpoint currently only returns
  /// `{ id, firstName, lastName, email, activeTicketCount }` — it doesn't
  /// expose resolvedToday/resolvedThisWeek/avgResolutionHours/
  /// slaComplianceRate/customerSatisfaction/online yet. Those fields default
  /// to 0/false below. To show real performance data here, add an
  /// aggregation endpoint on the backend (e.g. extend `getTechnicians()` in
  /// `users.service.js` with the same per-technician SLA/CSAT rollups the
  /// analytics module already computes fleet-wide).
  factory Technician.fromJson(Map<String, dynamic> json) {
    final first = json['firstName'] as String? ?? '';
    final last = json['lastName'] as String? ?? '';
    final name = '$first $last'.trim();
    final initials = (first.isNotEmpty ? first[0] : '') + (last.isNotEmpty ? last[0] : '');
    return Technician(
      id: json['id'] as String,
      name: name.isEmpty ? json['email'] as String? ?? 'Technician' : name,
      specialty: json['specialty'] as String? ?? '',
      activeTickets: json['activeTicketCount'] as int? ?? 0,
      resolvedToday: json['resolvedToday'] as int? ?? 0,
      resolvedThisWeek: json['resolvedThisWeek'] as int? ?? 0,
      avgResolutionHours: (json['avgResolutionHours'] as num?)?.toDouble() ?? 0,
      slaComplianceRate: (json['slaComplianceRate'] as num?)?.toDouble() ?? 0,
      customerSatisfaction: (json['customerSatisfaction'] as num?)?.toDouble() ?? 0,
      online: json['online'] as bool? ?? false,
      avatarInitials: initials.toUpperCase(),
    );
  }
}
