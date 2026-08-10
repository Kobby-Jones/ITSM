// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/ticket.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../providers/tickets_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../theme/app_colors.dart';

class SubmitTicketScreen extends ConsumerStatefulWidget {
  const SubmitTicketScreen({super.key});

  @override
  ConsumerState<SubmitTicketScreen> createState() => _SubmitTicketScreenState();
}

class _SubmitTicketScreenState extends ConsumerState<SubmitTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();

  TicketCategory? _category;
  TicketPriority _priority = TicketPriority.p3;
  TicketImpact _impact = TicketImpact.individual;
  bool _includeTelemetry = true;
  bool _submitting = false;

  final _attachments = <Attachment>[];

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      context.showSnack('Please choose a category.', error: true);
      return;
    }
    final user = ref.read(authProvider).user!;
    final isOnline = ref.read(connectivityProvider);

    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final ticket = await ref.read(ticketsProvider.notifier).submit(
          reporter: user,
          title: _title.text.trim(),
          description: _desc.text.trim(),
          priority: _priority,
          category: _category!,
          impact: _impact,
          isOnline: isOnline,
          attachments: List.of(_attachments),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    context.showSnack(
      isOnline
          ? 'Ticket ${ticket.code} submitted.'
          : 'Ticket ${ticket.code} queued for sync.',
    );
    context.go(AppRoutes.ticketDetailFor(ticket.id));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isOnline = ref.watch(connectivityProvider);

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(),
                const SizedBox(height: 24),
                if (!isOnline) _OfflineNotice(),
                if (!isOnline) const SizedBox(height: 16),
                isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _formCard()),
                          const SizedBox(width: 20),
                          Expanded(flex: 2, child: _sidePanel()),
                        ],
                      )
                    : Column(
                        children: [_formCard(), const SizedBox(height: 16), _sidePanel()],
                      ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => context.go(AppRoutes.tickets),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        label: isOnline ? 'Submit ticket' : 'Queue ticket for sync',
                        icon: isOnline ? Icons.send_rounded : Icons.cloud_upload_rounded,
                        loading: _submitting,
                        onPressed: _submit,
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

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Title', subtitle: 'A short, descriptive summary'),
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(
              hintText: 'e.g. SCADA terminal cannot connect to OPC server',
            ),
            maxLength: 100,
            validator: (v) => (v == null || v.trim().length < 10)
                ? 'At least 10 characters'
                : null,
          ),
          const SizedBox(height: 20),
          _label('Category', subtitle: 'What kind of issue is this?'),
          _CategoryGrid(
            value: _category,
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 20),
          _label('Description', subtitle: 'Steps you tried, error messages, anything that helps'),
          TextFormField(
            controller: _desc,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Describe what happened, what you expected, and what you tried…',
              alignLabelWithHint: true,
            ),
            validator: (v) => (v == null || v.trim().length < 20)
                ? 'At least 20 characters'
                : null,
          ),
          const SizedBox(height: 20),
          _label('Attachments'),
          _AttachmentsRow(
            attachments: _attachments,
            onAdd: () {
              setState(() {
                _attachments.add(Attachment(
                  name: 'screenshot_${_attachments.length + 1}.png',
                  size: '${300 + _attachments.length * 60} KB',
                  icon: Icons.image_rounded,
                ));
              });
            },
            onRemove: (i) => setState(() => _attachments.removeAt(i)),
          ),
        ],
      ),
    );
  }

  Widget _sidePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Priority'),
              ...TicketPriority.values.map((p) => _PriorityRow(
                    priority: p,
                    selected: _priority == p,
                    onTap: () => setState(() => _priority = p),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Impact'),
              ...TicketImpact.values.map((imp) => _ImpactRow(
                    impact: imp,
                    selected: _impact == imp,
                    onTap: () => setState(() => _impact = imp),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withOpacity(0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.monitor_heart_rounded,
                  color: AppColors.info, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Include device telemetry',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      'Helps technicians diagnose hardware and network issues faster.',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.onSurface.withOpacity(0.65),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _includeTelemetry,
                onChanged: (v) => setState(() => _includeTelemetry = v),
              ),
            ],
          ),
        ),
      ],
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

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Submit a ticket',
          style: context.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Tell us what\'s happening — IT will pick this up automatically.',
          style: context.textTheme.bodyMedium
              ?.copyWith(color: context.colors.onSurface.withOpacity(0.6)),
        ),
      ],
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'You\'re currently offline. This ticket will be queued and synced automatically when you reconnect.',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final TicketCategory? value;
  final ValueChanged<TicketCategory> onChanged;
  const _CategoryGrid({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 3 : 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: isDesktop ? 3.4 : 2.8,
      children: [
        for (final c in TicketCategory.values)
          _CategoryTile(
            category: c,
            selected: value == c,
            onTap: () => onChanged(c),
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final TicketCategory category;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryTile({required this.category, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? context.colors.primary.withOpacity(0.10)
          : context.colors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? context.colors.primary : context.colors.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (selected
                          ? context.colors.primary
                          : context.colors.onSurface.withOpacity(0.6))
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  category.icon,
                  size: 16,
                  color: selected
                      ? context.colors.primary
                      : context.colors.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? context.colors.primary
                        : context.colors.onSurface,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  final TicketPriority priority;
  final bool selected;
  final VoidCallback onTap;
  const _PriorityRow({required this.priority, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: priority.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(priority.icon, size: 14, color: priority.color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${priority.code} · ${priority.label}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                  Text(
                    'SLA: ${priority.slaHours}h',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (_) => onTap(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  final TicketImpact impact;
  final bool selected;
  final VoidCallback onTap;
  const _ImpactRow({required this.impact, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    impact.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                  Text(
                    impact.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (_) => onTap(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentsRow extends StatelessWidget {
  final List<Attachment> attachments;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  const _AttachmentsRow({required this.attachments, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < attachments.length; i++)
          _AttachmentChip(
            attachment: attachments[i],
            onRemove: () => onRemove(i),
          ),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: context.colors.outline,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.attach_file_rounded,
                    size: 16, color: context.colors.primary),
                const SizedBox(width: 6),
                const Text(
                  'Add attachment',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback onRemove;
  const _AttachmentChip({required this.attachment, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(attachment.icon, size: 16, color: context.colors.primary),
          const SizedBox(width: 6),
          Text(attachment.name,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text(
            '· ${attachment.size}',
            style: TextStyle(
                fontSize: 11.5, color: context.colors.onSurface.withOpacity(0.55)),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 14),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}
