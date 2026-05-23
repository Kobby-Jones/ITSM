import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/ticket.dart';
import '../../../shared/widgets/user_avatar.dart';
import 'priority_badge.dart';
import 'sla_countdown.dart';
import 'sync_state_chip.dart';
import 'ticket_status_chip.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;
  final bool compact;

  const TicketCard({super.key, required this.ticket, this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PriorityBadge(priority: ticket.priority, dense: true, showLabel: false),
                  const SizedBox(width: 8),
                  Text(
                    ticket.code,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: context.colors.onSurface.withOpacity(0.55),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  if (ticket.syncState != SyncState.synced) ...[
                    SyncStateChip(state: ticket.syncState, dense: true),
                    const SizedBox(width: 6),
                  ],
                  TicketStatusChip(status: ticket.status, dense: true),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ticket.title,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 6),
                Text(
                  ticket.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.colors.onSurface.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MetaChip(icon: ticket.category.icon, label: ticket.category.label),
                  _MetaChip(icon: Icons.location_on_outlined, label: ticket.location),
                  _MetaChip(
                    icon: Icons.schedule_rounded,
                    label: Formatters.relativeTime(ticket.createdAt),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(color: context.colors.outline, height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  UserAvatar(
                    initials: _initials(ticket.reporterName),
                    size: 26,
                    gradient: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      ticket.reporterName,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (ticket.assigneeName != null) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded,
                        size: 12, color: context.colors.onSurface.withOpacity(0.4)),
                    const SizedBox(width: 6),
                    UserAvatar(initials: _initials(ticket.assigneeName!), size: 22),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        ticket.assigneeName!,
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const Spacer(),
                  SlaCountdown(ticket: ticket, dense: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final p = name.split(' ');
    if (p.length >= 2) return '${p.first[0]}${p[1][0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.colors.onSurface.withOpacity(0.6)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: context.colors.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
