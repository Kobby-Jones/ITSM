// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../models/ticket.dart';

class PriorityBadge extends StatelessWidget {
  final TicketPriority priority;
  final bool dense;
  final bool showLabel;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.dense = false,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: priority.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: priority.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priority.icon, size: dense ? 11 : 12, color: priority.color),
          const SizedBox(width: 4),
          Text(
            showLabel ? '${priority.code} ${priority.label}' : priority.code,
            style: TextStyle(
              fontSize: dense ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              color: priority.color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
