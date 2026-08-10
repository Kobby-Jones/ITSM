// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/ticket.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/kb_provider.dart';
import '../../../providers/tickets_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../theme/app_colors.dart';
import '../../tickets/widgets/priority_badge.dart';

class TicketResolutionScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketResolutionScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketResolutionScreen> createState() => _TicketResolutionScreenState();
}

class _TicketResolutionScreenState extends ConsumerState<TicketResolutionScreen> {
  final _summaryCtrl = TextEditingController();
  final _rootCauseCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _resolutionType = 'Permanent fix';
  String? _linkedKbId;
  bool _notifyReporter = true;
  bool _submitting = false;

  static const _resolutionTypes = [
    'Permanent fix',
    'Workaround',
    'Configuration change',
    'User error',
    'Cannot reproduce',
    'Duplicate',
  ];

  @override
  void dispose() {
    _summaryCtrl.dispose();
    _rootCauseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(Ticket ticket) async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider).user!;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 600));

    ref.read(ticketsProvider.notifier).addComment(
          ticket.id,
          author: user,
          content:
              'Resolved: ${_summaryCtrl.text.trim()}\n\nRoot cause: ${_rootCauseCtrl.text.trim()}\n\nResolution type: $_resolutionType',
        );
    ref.read(ticketsProvider.notifier).updateStatus(
          ticket.id,
          TicketStatus.resolved,
          actor: user.name,
        );

    if (!mounted) return;
    setState(() => _submitting = false);
    context.showSnack('Ticket ${ticket.code} resolved.');
    context.go(AppRoutes.ticketDetailFor(ticket.id));
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(ticketsProvider);
    Ticket? ticket;
    for (final t in tickets) {
      if (t.id == widget.ticketId || t.code == widget.ticketId) {
        ticket = t;
        break;
      }
    }
    if (ticket == null) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Ticket not found',
        message: 'We couldn\'t find ticket "${widget.ticketId}".',
        actionLabel: 'Back to tickets',
        onAction: () => context.go(AppRoutes.tickets),
      );
    }
    final t = ticket;
    final kbArticles = ref.watch(kbArticlesProvider);

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.go(AppRoutes.ticketDetailFor(t.id)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      t.code,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: context.colors.onSurface.withOpacity(0.55),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 10),
                    PriorityBadge(priority: t.priority),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Resolving',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  t.title,
                  style: context.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
                ),
                const SizedBox(height: 24),
                CardSection(
                  title: 'Resolution',
                  titleIcon: Icons.check_circle_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Resolution type', subtitle: 'Categorize how this was solved.'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final type in _resolutionTypes)
                            ChoiceChip(
                              label: Text(type),
                              selected: _resolutionType == type,
                              onSelected: (_) => setState(() => _resolutionType = type),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _label('Resolution summary',
                          subtitle: 'What did you do to resolve this? Visible to the reporter.'),
                      TextFormField(
                        controller: _summaryCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Reset the OPC client subscription and restored connection.',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 15) ? 'At least 15 characters' : null,
                      ),
                      const SizedBox(height: 20),
                      _label('Root cause',
                          subtitle: 'Internal — not shown to the reporter.'),
                      TextFormField(
                        controller: _rootCauseCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'e.g. OPC server connection pool was exhausted after the recent patch.',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 15) ? 'At least 15 characters' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CardSection(
                  title: 'Link a KB article',
                  titleIcon: Icons.menu_book_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Help future incidents resolve faster by linking a relevant article.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.colors.onSurface.withOpacity(0.65),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        value: _linkedKbId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.article_outlined, size: 20),
                          hintText: 'No article linked',
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('No article linked')),
                          for (final a in kbArticles)
                            DropdownMenuItem(
                              value: a.id,
                              child: Text(a.title, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (v) => setState(() => _linkedKbId = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CardSection(
                  title: 'Notify reporter',
                  titleIcon: Icons.notifications_rounded,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _notifyReporter,
                    onChanged: (v) => setState(() => _notifyReporter = v),
                    title: Text('Email ${t.reporterName}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      'Send a copy of the resolution summary to the reporter.',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => context.go(AppRoutes.ticketDetailFor(t.id)),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        label: 'Resolve & close',
                        icon: Icons.check_circle_rounded,
                        loading: _submitting,
                        onPressed: () => _submit(t),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, {String? subtitle}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ],
        ),
      );
}
