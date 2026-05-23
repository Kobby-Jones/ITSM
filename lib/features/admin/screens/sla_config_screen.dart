// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/ticket.dart';
import '../../../shared/widgets/section_header.dart';

class SlaConfigScreen extends ConsumerStatefulWidget {
  const SlaConfigScreen({super.key});

  @override
  ConsumerState<SlaConfigScreen> createState() => _SlaConfigScreenState();
}

class _SlaConfigScreenState extends ConsumerState<SlaConfigScreen> {
  final _firstResponse = <TicketPriority, int>{
    TicketPriority.p1: 15, // minutes
    TicketPriority.p2: 60,
    TicketPriority.p3: 240,
    TicketPriority.p4: 480,
  };

  final _resolution = <TicketPriority, int>{
    TicketPriority.p1: 4, // hours
    TicketPriority.p2: 8,
    TicketPriority.p3: 24,
    TicketPriority.p4: 72,
  };

  bool _businessHoursOnly = false;
  bool _autoEscalate = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'SLA configuration',
                subtitle: 'Set first-response and resolution targets per priority.',
                trailing: FilledButton.icon(
                  onPressed: () => context.showSnack('SLA targets saved.'),
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save changes'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CardSection(
                title: 'Targets',
                titleIcon: Icons.tune_rounded,
                child: Column(
                  children: [
                    _Header(),
                    for (final p in TicketPriority.values)
                      _PriorityRow(
                        priority: p,
                        firstResponse: _firstResponse[p]!,
                        resolution: _resolution[p]!,
                        onFirstChange: (v) => setState(() => _firstResponse[p] = v),
                        onResChange: (v) => setState(() => _resolution[p] = v),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CardSection(
                title: 'Behaviour',
                titleIcon: Icons.settings_rounded,
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _businessHoursOnly,
                      onChanged: (v) => setState(() => _businessHoursOnly = v),
                      title: const Text('Count business hours only',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                        'Pause SLA timers outside Mon–Fri 06:00–18:00.',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _autoEscalate,
                      onChanged: (v) => setState(() => _autoEscalate = v),
                      title: const Text('Auto-escalate at 80%',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                        'Notify the manager when 80% of the SLA window has elapsed.',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = TextStyle(
        fontSize: 11,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w700,
        color: context.colors.onSurface.withOpacity(0.55));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text('PRIORITY', style: s)),
          Expanded(child: Text('FIRST RESPONSE (MIN)', style: s, textAlign: TextAlign.center)),
          const SizedBox(width: 12),
          Expanded(child: Text('RESOLUTION (HRS)', style: s, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  final TicketPriority priority;
  final int firstResponse;
  final int resolution;
  final ValueChanged<int> onFirstChange;
  final ValueChanged<int> onResChange;

  const _PriorityRow({
    required this.priority,
    required this.firstResponse,
    required this.resolution,
    required this.onFirstChange,
    required this.onResChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: priority.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: priority.color.withOpacity(0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                '${priority.code} ${priority.label}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: priority.color,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: firstResponse.toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (v) => onFirstChange(int.tryParse(v) ?? firstResponse),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              initialValue: resolution.toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (v) => onResChange(int.tryParse(v) ?? resolution),
            ),
          ),
        ],
      ),
    );
  }
}
