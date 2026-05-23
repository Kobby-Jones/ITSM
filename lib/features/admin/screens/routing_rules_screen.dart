// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../theme/app_colors.dart';

class RoutingRulesScreen extends ConsumerStatefulWidget {
  const RoutingRulesScreen({super.key});

  @override
  ConsumerState<RoutingRulesScreen> createState() => _RoutingRulesScreenState();
}

class _RoutingRulesScreenState extends ConsumerState<RoutingRulesScreen> {
  final _rules = <_Rule>[
    _Rule('Network → Network specialists',
        'Category = Network → Assign to Kwame Boateng or Yaa Mensah (least workload)',
        true, 0),
    _Rule('Production → Production specialists',
        'Category = Production OR location = Tarkwa Mine → Assign to Kwame Boateng',
        true, 1),
    _Rule('P1 escalation',
        'Priority = P1 AND unassigned for > 5m → Notify on-call manager',
        true, 2),
    _Rule('Account access → Admin team',
        'Category = Account Access & Identity → Assign to Abena Asante',
        true, 3),
    _Rule('Hardware → Field tech by location',
        'Category = Hardware → Assign to nearest field tech (Tarkwa: Nana Adjei, Damang: Akua Pokuaa)',
        true, 4),
    _Rule('Printer issues → Office tech',
        'Category = Printing → Assign to Yaa Mensah',
        false, 5),
    _Rule('After-hours fallback',
        'Time outside 06:00-22:00 → Route to on-call duty technician',
        true, 6),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Routing rules',
                subtitle: 'Auto-assignment rules — evaluated top to bottom.',
                trailing: FilledButton.icon(
                  onPressed: () => context.showSnack('Rule builder coming soon.'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New rule'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              for (var i = 0; i < _rules.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RuleCard(
                    rule: _rules[i],
                    onToggle: (v) => setState(() => _rules[i] = _rules[i].copyWith(enabled: v)),
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

class _Rule {
  final String name;
  final String description;
  final bool enabled;
  final int order;
  const _Rule(this.name, this.description, this.enabled, this.order);
  _Rule copyWith({bool? enabled}) => _Rule(name, description, enabled ?? this.enabled, order);
}

class _RuleCard extends StatelessWidget {
  final _Rule rule;
  final ValueChanged<bool> onToggle;
  const _RuleCard({required this.rule, required this.onToggle});

  @override
  Widget build(BuildContext context) {
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
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rule.enabled
                  ? AppColors.primary.withOpacity(0.10)
                  : context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${rule.order + 1}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: rule.enabled
                    ? AppColors.primary
                    : context.colors.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(rule.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (rule.enabled ? AppColors.success : Colors.grey)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rule.enabled ? 'Enabled' : 'Disabled',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: rule.enabled ? AppColors.success : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(rule.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.colors.onSurface.withOpacity(0.65),
                      height: 1.4,
                    )),
              ],
            ),
          ),
          Switch(
            value: rule.enabled,
            onChanged: onToggle,
          ),
          IconButton(
            icon: const Icon(Icons.drag_indicator_rounded),
            tooltip: 'Reorder',
            onPressed: () => context.showSnack('Reorder coming soon.'),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 18),
            tooltip: 'Edit',
            onPressed: () => context.showSnack('Rule editor coming soon.'),
          ),
        ],
      ),
    );
  }
}
