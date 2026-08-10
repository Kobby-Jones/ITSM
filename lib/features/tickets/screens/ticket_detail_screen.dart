// ignore_for_file: unused_element_parameter, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/ticket.dart';
import '../../../models/user.dart';
import '../../../models/user_role.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/tickets_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../mock_ticket_data.dart';
import '../widgets/priority_badge.dart';
import '../widgets/sla_countdown.dart';
import '../widgets/sync_state_chip.dart';
import '../widgets/ticket_status_chip.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _internalNote = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(ticketsProvider);
    final ticket = tickets.firstWhere(
      (t) => t.id == widget.ticketId || t.code == widget.ticketId,
      orElse: () => tickets.first,
    );
    final ticketExists = tickets.any(
        (t) => t.id == widget.ticketId || t.code == widget.ticketId);
    if (!ticketExists) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Ticket not found',
        message: 'We couldn\'t find ticket "${widget.ticketId}".',
        actionLabel: 'Back to tickets',
        onAction: () => context.go(AppRoutes.tickets),
      );
    }

    final user = ref.watch(authProvider).user!;
    final isDesktop = Responsive.isDesktop(context);

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(ticket: ticket),
              const SizedBox(height: 20),
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: _buildLeft(ticket, user)),
                        const SizedBox(width: 20),
                        Expanded(flex: 4, child: _buildRight(ticket, user)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildRight(ticket, user),
                        const SizedBox(height: 16),
                        _buildLeft(ticket, user),
                      ],
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeft(Ticket ticket, AppUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DescriptionCard(ticket: ticket),
        const SizedBox(height: 16),
        if (ticket.attachments.isNotEmpty) ...[
          _AttachmentsCard(ticket: ticket),
          const SizedBox(height: 16),
        ],
        _CommentsCard(
          ticket: ticket,
          ctrl: _commentCtrl,
          internal: _internalNote,
          onInternalToggle: (v) => setState(() => _internalNote = v),
          allowInternal: user.role != UserRole.endUser,
          onSubmit: () {
            final txt = _commentCtrl.text.trim();
            if (txt.isEmpty) return;
            ref.read(ticketsProvider.notifier).addComment(
                  ticket.id,
                  author: user,
                  content: txt,
                  internal: _internalNote,
                );
            _commentCtrl.clear();
            setState(() => _internalNote = false);
          },
        ),
        const SizedBox(height: 16),
        _TimelineCard(ticket: ticket),
      ],
    );
  }

  Widget _buildRight(Ticket ticket, AppUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlaCard(ticket: ticket),
        const SizedBox(height: 16),
        _DetailsCard(ticket: ticket),
        const SizedBox(height: 16),
        if (user.role != UserRole.endUser) ...[
          _ActionsCard(ticket: ticket, user: user),
          const SizedBox(height: 16),
        ],
        if (ticket.deviceId != null) _TelemetryPreviewCard(ticket: ticket),
      ],
    );
  }
}

// =============================================================================
// HEADER
// =============================================================================

class _Header extends StatelessWidget {
  final Ticket ticket;
  const _Header({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back',
              onPressed: () => context.go(AppRoutes.tickets),
            ),
            const SizedBox(width: 4),
            Text(
              ticket.code,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: context.colors.onSurface.withOpacity(0.55),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 10),
            PriorityBadge(priority: ticket.priority),
            const SizedBox(width: 8),
            TicketStatusChip(status: ticket.status),
            if (ticket.syncState != SyncState.synced) ...[
              const SizedBox(width: 8),
              SyncStateChip(state: ticket.syncState),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            ticket.title,
            style: context.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.3),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// LEFT: Description / Attachments / Comments / Timeline
// =============================================================================

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Card({required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  const _CardTitle({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.colors.onSurface.withOpacity(0.55)),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final Ticket ticket;
  const _DescriptionCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.description_rounded, title: 'Description'),
          const SizedBox(height: 12),
          Text(
            ticket.description,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _AttachmentsCard extends StatelessWidget {
  final Ticket ticket;
  const _AttachmentsCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.attach_file_rounded,
            title: 'Attachments',
            trailing: Text(
              '${ticket.attachments.length}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface.withOpacity(0.55),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final a in ticket.attachments)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.colors.outline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(a.icon, size: 18, color: context.colors.primary),
                      const SizedBox(width: 8),
                      Text(a.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text(a.size,
                          style: TextStyle(
                              fontSize: 12,
                              color: context.colors.onSurface.withOpacity(0.55))),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.download_rounded, size: 16),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: () =>
                            context.showSnack('Download started: ${a.name}'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentsCard extends StatelessWidget {
  final Ticket ticket;
  final TextEditingController ctrl;
  final bool internal;
  final ValueChanged<bool> onInternalToggle;
  final bool allowInternal;
  final VoidCallback onSubmit;

  const _CommentsCard({
    required this.ticket,
    required this.ctrl,
    required this.internal,
    required this.onInternalToggle,
    required this.allowInternal,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.forum_rounded,
            title: 'Comments',
            trailing: Text(
              '${ticket.comments.length}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface.withOpacity(0.55),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (ticket.comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No comments yet. Be the first to add one.',
                style: TextStyle(
                  fontSize: 13,
                  color: context.colors.onSurface.withOpacity(0.55),
                ),
              ),
            )
          else
            for (final c in ticket.comments) _CommentRow(comment: c),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: internal
                    ? AppColors.warning.withOpacity(0.5)
                    : context.colors.outline,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: TextField(
                    controller: ctrl,
                    maxLines: 3,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: internal
                          ? 'Internal note (visible to IT only)…'
                          : 'Write a comment…',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: Row(
                    children: [
                      if (allowInternal)
                        Row(
                          children: [
                            Switch(
                                value: internal,
                                onChanged: onInternalToggle,
                                activeColor: AppColors.warning),
                            const SizedBox(width: 6),
                            Text(
                              'Internal note',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: internal
                                    ? AppColors.warning
                                    : context.colors.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: onSubmit,
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Send'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
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

class _CommentRow extends StatelessWidget {
  final Comment comment;
  const _CommentRow({required this.comment});

  String _initials(String name) {
    final p = name.split(' ');
    if (p.length >= 2) return '${p.first[0]}${p[1][0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(initials: _initials(comment.authorName), size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: comment.isInternal
                    ? AppColors.warning.withOpacity(0.08)
                    : context.colors.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: comment.isInternal
                      ? AppColors.warning.withOpacity(0.3)
                      : context.colors.outline,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(comment.authorName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: context.colors.onSurface.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          comment.authorRole,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: context.colors.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                      if (comment.isInternal) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded,
                                  size: 10, color: AppColors.warning),
                              SizedBox(width: 3),
                              Text(
                                'Internal',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        Formatters.relativeTime(comment.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(comment.content, style: const TextStyle(fontSize: 13.5, height: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final Ticket ticket;
  const _TimelineCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final events = ticket.events;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.timeline_rounded, title: 'Activity timeline'),
          const SizedBox(height: 18),
          for (var i = 0; i < events.length; i++)
            _TimelineRow(
              event: events[i],
              isFirst: i == 0,
              isLast: i == events.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TicketEvent event;
  final bool isFirst;
  final bool isLast;
  const _TimelineRow({required this.event, required this.isFirst, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: event.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: event.color, width: 1.5),
                  ),
                  child: Icon(event.icon, size: 13, color: event.color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: context.colors.outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                      ),
                      Text(
                        Formatters.relativeTime(event.timestamp),
                        style: TextStyle(
                            fontSize: 11.5,
                            color: context.colors.onSurface.withOpacity(0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.colors.onSurface.withOpacity(0.65),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// RIGHT: SLA / Details / Actions / Telemetry
// =============================================================================

class _SlaCard extends StatelessWidget {
  final Ticket ticket;
  const _SlaCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              const _CardTitle(icon: Icons.timer_rounded, title: 'SLA'),
              const Spacer(),
              Text(
                'Due ${Formatters.dateTime(ticket.slaDueAt)}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: context.colors.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SlaRing(ticket: ticket, size: 140).animate().fadeIn(duration: 300.ms),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final Ticket ticket;
  const _DetailsCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.info_outline_rounded, title: 'Details'),
          const SizedBox(height: 12),
          _detailRow(context, 'Category', ticket.category.label, icon: ticket.category.icon),
          _detailRow(context, 'Impact', ticket.impact.label, icon: Icons.public_rounded),
          _detailRow(context, 'Reporter', ticket.reporterName,
              subtitle: ticket.reporterDepartment, icon: Icons.person_rounded),
          if (ticket.assigneeName != null)
            _detailRow(context, 'Assigned to', ticket.assigneeName!,
                icon: Icons.assignment_ind_rounded)
          else
            _detailRow(context, 'Assigned to', 'Unassigned',
                icon: Icons.person_off_rounded, muted: true),
          _detailRow(context, 'Location', ticket.location, icon: Icons.place_rounded),
          _detailRow(context, 'Created', Formatters.dateTime(ticket.createdAt),
              icon: Icons.event_rounded),
          _detailRow(context, 'Updated', Formatters.relativeTime(ticket.updatedAt),
              icon: Icons.update_rounded),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value,
      {IconData? icon, String? subtitle, bool muted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: context.colors.onSurface.withOpacity(0.5)),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface.withOpacity(0.55),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontStyle: muted ? FontStyle.italic : FontStyle.normal,
                    color: muted
                        ? context.colors.onSurface.withOpacity(0.5)
                        : context.colors.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.colors.onSurface.withOpacity(0.55),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsCard extends ConsumerWidget {
  final Ticket ticket;
  final AppUser user;
  const _ActionsCard({required this.ticket, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClosed = ticket.status == TicketStatus.closed;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.bolt_rounded, title: 'Actions'),
          const SizedBox(height: 12),
          if (!isClosed) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (ticket.status != TicketStatus.inProgress)
                  _actionBtn(context, ref, 'Start work', Icons.play_arrow_rounded,
                      AppColors.statusInProgress, TicketStatus.inProgress),
                if (ticket.status != TicketStatus.onHold)
                  _actionBtn(context, ref, 'Put on hold', Icons.pause_rounded,
                      AppColors.statusOnHold, TicketStatus.onHold),
                if (ticket.status != TicketStatus.resolved)
                  _actionBtn(context, ref, 'Resolve', Icons.check_circle_rounded,
                      AppColors.success, TicketStatus.resolved),
                _actionBtn(context, ref, 'Close', Icons.lock_rounded,
                    AppColors.statusClosed, TicketStatus.closed),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (ticket.deviceId != null)
            OutlinedButton.icon(
              onPressed: () =>
                  context.go(AppRoutes.telemetryFor(ticket.id)),
              icon: const Icon(Icons.monitor_heart_rounded, size: 16),
              label: const Text('View full telemetry'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionBtn(BuildContext context, WidgetRef ref, String label, IconData icon,
      Color color, TicketStatus newStatus) {
    return OutlinedButton.icon(
      onPressed: () {
        ref.read(ticketsProvider.notifier).updateStatus(
              ticket.id,
              newStatus,
              actor: user.name,
            );
        context.showSnack('Ticket marked ${newStatus.label}.');
      },
      icon: Icon(icon, size: 14, color: color),
      label: Text(label,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: color.withOpacity(0.4)),
        backgroundColor: color.withOpacity(0.08),
      ),
    );
  }
}

class _TelemetryPreviewCard extends StatelessWidget {
  final Ticket ticket;
  const _TelemetryPreviewCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    // NOTE: still mock data — see telemetry_analysis_screen.dart for why
    // (backend telemetry is per-device, not per-ticket).
    final tel = MockTelemetryData.forTicket(ticket.id);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.memory_rounded,
            title: 'Device telemetry',
            trailing: TextButton.icon(
              onPressed: () => context.go(AppRoutes.telemetryFor(ticket.id)),
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: const Text('Full view'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 28),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tel.deviceModel,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          Text(
            tel.hostname,
            style: TextStyle(
                fontSize: 11.5, color: context.colors.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 12),
          _MetricBar(label: 'CPU', value: tel.cpuUsage, valueLabel: '${(tel.cpuUsage * 100).toStringAsFixed(0)}%'),
          const SizedBox(height: 8),
          _MetricBar(
            label: 'RAM',
            value: tel.ramUsage,
            valueLabel:
                '${(tel.ramUsedMb / 1024).toStringAsFixed(1)} / ${(tel.ramTotalMb / 1024).toStringAsFixed(0)} GB',
          ),
          const SizedBox(height: 8),
          _MetricBar(
            label: 'Disk',
            value: tel.storageUsage,
            valueLabel: '${tel.storageUsedGb} / ${tel.storageTotalGb} GB',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.network_check_rounded,
                  size: 14, color: context.colors.onSurface.withOpacity(0.55)),
              const SizedBox(width: 6),
              Text(
                '${tel.networkType} · ${tel.networkStatus}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  final String label;
  final double value;
  final String valueLabel;
  const _MetricBar({required this.label, required this.value, required this.valueLabel});

  Color _color(double v) {
    if (v > 0.85) return AppColors.danger;
    if (v > 0.7) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface.withOpacity(0.65),
                )),
            const Spacer(),
            Text(valueLabel,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: context.colors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
