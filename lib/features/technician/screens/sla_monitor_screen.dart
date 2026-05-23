// ignore_for_file: deprecated_member_use, avoid_function_literals_in_foreach_calls

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/ticket.dart';
import '../../../providers/tickets_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../theme/app_colors.dart';
import '../../tickets/widgets/priority_badge.dart';
import '../../tickets/widgets/ticket_status_chip.dart';

class SlaMonitorScreen extends ConsumerStatefulWidget {
  const SlaMonitorScreen({super.key});

  @override
  ConsumerState<SlaMonitorScreen> createState() => _SlaMonitorScreenState();
}

class _SlaMonitorScreenState extends ConsumerState<SlaMonitorScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(ticketsProvider);
    final live = tickets.where((t) =>
        t.status != TicketStatus.resolved && t.status != TicketStatus.closed).toList();

    final breached = live.where((t) => t.slaBreached).toList();
    final critical = live.where((t) => !t.slaBreached && t.slaProgress >= 0.85).toList();
    final warning = live.where((t) => !t.slaBreached && t.slaProgress >= 0.7 && t.slaProgress < 0.85).toList();
    final healthy = live.where((t) => t.slaProgress < 0.7).toList();

    [breached, critical, warning, healthy].forEach((g) =>
        g.sort((a, b) => a.slaRemaining.compareTo(b.slaRemaining)));

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'SLA monitor',
                subtitle: 'Live view — refreshes every 30 seconds.',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Live',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SummaryRow(
                breached: breached.length,
                critical: critical.length,
                warning: warning.length,
                healthy: healthy.length,
              ),
              const SizedBox(height: 24),
              if (breached.isEmpty && critical.isEmpty && warning.isEmpty)
                const EmptyState(
                  icon: Icons.shield_rounded,
                  title: 'All SLAs healthy',
                  message: 'No tickets are at risk right now. Great job.',
                ),
              if (breached.isNotEmpty)
                _Group(
                  title: 'Breached',
                  description: 'SLA window already exceeded — escalation needed.',
                  color: AppColors.danger,
                  icon: Icons.error_rounded,
                  tickets: breached,
                ),
              if (critical.isNotEmpty)
                _Group(
                  title: 'Critical',
                  description: '85%+ of SLA window used — act now.',
                  color: AppColors.danger,
                  icon: Icons.warning_rounded,
                  tickets: critical,
                ),
              if (warning.isNotEmpty)
                _Group(
                  title: 'Warning',
                  description: '70-85% of SLA window used.',
                  color: AppColors.warning,
                  icon: Icons.timer_rounded,
                  tickets: warning,
                ),
              if (healthy.isNotEmpty)
                _Group(
                  title: 'Healthy',
                  description: 'Plenty of time remaining.',
                  color: AppColors.success,
                  icon: Icons.check_circle_rounded,
                  tickets: healthy,
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int breached, critical, warning, healthy;
  const _SummaryRow({required this.breached, required this.critical, required this.warning, required this.healthy});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _tile(context, 'Breached', '$breached', AppColors.danger, Icons.error_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _tile(context, 'Critical', '$critical', AppColors.danger, Icons.warning_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _tile(context, 'Warning', '$warning', AppColors.warning, Icons.timer_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _tile(context, 'Healthy', '$healthy', AppColors.success, Icons.check_circle_rounded)),
      ],
    );
  }

  Widget _tile(BuildContext context, String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.5,
                    )),
                Text(label,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.colors.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title, description;
  final Color color;
  final IconData icon;
  final List<Ticket> tickets;
  const _Group({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.tickets,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${tickets.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description,
              style: TextStyle(
                fontSize: 12.5,
                color: context.colors.onSurface.withOpacity(0.6),
              )),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.outline),
            ),
            child: Column(
              children: [
                for (var i = 0; i < tickets.length; i++)
                  InkWell(
                    onTap: () => context.go(AppRoutes.ticketDetailFor(tickets[i].id)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: i == tickets.length - 1
                                ? Colors.transparent
                                : context.colors.outline,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          PriorityBadge(priority: tickets[i].priority, dense: true, showLabel: false),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: Text(
                              tickets[i].code,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: context.colors.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              tickets[i].title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tickets[i].assigneeName ?? 'Unassigned',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.colors.onSurface.withOpacity(0.65),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TicketStatusChip(status: tickets[i].status, dense: true),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 90,
                            child: Text(
                              tickets[i].slaBreached
                                  ? 'Breached'
                                  : Formatters.countdown(tickets[i].slaRemaining),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 12, color: context.colors.onSurface.withOpacity(0.4)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
