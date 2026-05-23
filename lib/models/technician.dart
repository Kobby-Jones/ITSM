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
}
