import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/ticket.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../providers/tickets_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../theme/app_colors.dart';
import '../../tickets/widgets/priority_badge.dart';

class SyncQueueScreen extends ConsumerWidget {
  const SyncQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(syncQueueTicketsProvider);
    final online = ref.watch(connectivityProvider);

    final pending = queue.where((t) => t.syncState == SyncState.pending).toList();
    final syncing = queue.where((t) => t.syncState == SyncState.syncing).toList();
    final failed = queue.where((t) => t.syncState == SyncState.failed).toList();

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Sync queue',
                subtitle: queue.isEmpty
                    ? 'Everything is synced.'
                    : '${queue.length} ticket${queue.length == 1 ? '' : 's'} waiting to sync.',
                trailing: queue.isEmpty
                    ? null
                    : FilledButton.icon(
                        onPressed: !online
                            ? null
                            : () async {
                                final ctrl = ref.read(ticketsProvider.notifier);
                                for (final t in queue) {
                                  ctrl.retrySync(t.id);
                                }
                                context.showSnack('Retrying ${queue.length} ticket${queue.length == 1 ? '' : 's'}…');
                              },
                        icon: const Icon(Icons.cloud_sync_rounded, size: 18),
                        label: Text(online ? 'Retry all' : 'Offline'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              _ConnectivityCard(online: online),
              const SizedBox(height: 16),
              _SummaryRow(
                pending: pending.length,
                syncing: syncing.length,
                failed: failed.length,
              ),
              const SizedBox(height: 20),
              if (queue.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: EmptyState(
                    icon: Icons.cloud_done_rounded,
                    title: 'All caught up',
                    message: 'No tickets are waiting to sync. Anything you create offline will appear here.',
                  ),
                ),
              if (failed.isNotEmpty)
                _Group(
                  title: 'Failed',
                  description: 'These tickets failed to sync. Check your connection and retry.',
                  color: AppColors.danger,
                  icon: Icons.error_rounded,
                  tickets: failed,
                  online: online,
                ),
              if (syncing.isNotEmpty)
                _Group(
                  title: 'Syncing',
                  description: 'Currently being uploaded.',
                  color: AppColors.info,
                  icon: Icons.cloud_upload_rounded,
                  tickets: syncing,
                  online: online,
                ),
              if (pending.isNotEmpty)
                _Group(
                  title: 'Pending',
                  description: online
                      ? 'Waiting in line — will sync automatically.'
                      : 'Will sync as soon as you are back online.',
                  color: AppColors.warning,
                  icon: Icons.schedule_rounded,
                  tickets: pending,
                  online: online,
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectivityCard extends StatelessWidget {
  final bool online;
  const _ConnectivityCard({required this.online});

  @override
  Widget build(BuildContext context) {
    final color = online ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  online ? 'You are online' : 'You are offline',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  online
                      ? 'Tickets will sync to the server in real time.'
                      : 'New tickets will be queued and uploaded when you reconnect.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.colors.onSurface.withOpacity(0.7),
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

class _SummaryRow extends StatelessWidget {
  final int pending, syncing, failed;
  const _SummaryRow({required this.pending, required this.syncing, required this.failed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _tile(context, 'Pending', '$pending', AppColors.warning, Icons.schedule_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _tile(context, 'Syncing', '$syncing', AppColors.info, Icons.cloud_upload_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _tile(context, 'Failed', '$failed', AppColors.danger, Icons.error_rounded)),
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
  final bool online;
  const _Group({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.tickets,
    required this.online,
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
                  _Row(
                    ticket: tickets[i],
                    isLast: i == tickets.length - 1,
                    online: online,
                  ).animate(delay: (i * 30).ms).fadeIn(duration: 200.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends ConsumerWidget {
  final Ticket ticket;
  final bool isLast;
  final bool online;
  const _Row({required this.ticket, required this.isLast, required this.online});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => context.go(AppRoutes.ticketDetailFor(ticket.id)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : context.colors.outline,
            ),
          ),
        ),
        child: Row(
          children: [
            PriorityBadge(priority: ticket.priority, dense: true, showLabel: false),
            const SizedBox(width: 10),
            SizedBox(
              width: 90,
              child: Text(
                ticket.code,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: context.colors.onSurface.withOpacity(0.65),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(ticket.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    'Created ${Formatters.relativeTime(ticket.createdAt)} · ${ticket.reporterName}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.colors.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (ticket.syncState == SyncState.syncing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (ticket.syncState == SyncState.failed)
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: AppColors.danger),
                tooltip: 'Retry',
                onPressed: !online
                    ? null
                    : () {
                        ref.read(ticketsProvider.notifier).retrySync(ticket.id);
                        context.showSnack('Retrying ${ticket.code}…');
                      },
              )
            else if (ticket.syncState == SyncState.pending && online)
              IconButton(
                icon: Icon(Icons.cloud_upload_rounded, color: AppColors.warning),
                tooltip: 'Sync now',
                onPressed: () {
                  ref.read(ticketsProvider.notifier).retrySync(ticket.id);
                  context.showSnack('Syncing ${ticket.code}…');
                },
              ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: context.colors.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}
