import 'package:flutter/material.dart';
import '../../../models/ticket.dart';
import '../../../shared/widgets/status_pill.dart';

class TicketStatusChip extends StatelessWidget {
  final TicketStatus status;
  final bool dense;
  final bool filled;

  const TicketStatusChip({
    super.key,
    required this.status,
    this.dense = false,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: status.label,
      color: status.color,
      icon: status.icon,
      dense: dense,
      filled: filled,
    );
  }
}
