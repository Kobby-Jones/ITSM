// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../services/routing_admin_service.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../theme/app_colors.dart';

class RoutingRulesScreen extends ConsumerStatefulWidget {
  const RoutingRulesScreen({super.key});

  @override
  ConsumerState<RoutingRulesScreen> createState() => _RoutingRulesScreenState();
}

class _RoutingRulesScreenState extends ConsumerState<RoutingRulesScreen> {
  List<RoutingRule> _rules = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRules();
  }

  Future<void> _fetchRules() async {
    setState(() { _loading = true; _error = null; });
    try {
      _rules = await RoutingAdminService.instance.getRules();
      _rules.sort((a, b) => a.priority.compareTo(b.priority));
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleRule(RoutingRule rule) async {
    try {
      await RoutingAdminService.instance.updateRule(rule.id, {
        'isActive': !rule.isActive,
      });
      await _fetchRules();
    } catch (e) {
      if (mounted) context.showSnack('Failed: $e', error: true);
    }
  }

  Future<void> _deleteRule(RoutingRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete rule'),
        content: Text('Delete "${rule.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await RoutingAdminService.instance.deleteRule(rule.id);
      await _fetchRules();
      if (mounted) context.showSnack('Rule deleted.');
    } catch (e) {
      if (mounted) context.showSnack('Failed: $e', error: true);
    }
  }

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
                subtitle: '${_rules.length} rules — evaluated top to bottom.',
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ))
              else if (_error != null)
                Center(child: Column(
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _fetchRules, child: const Text('Retry')),
                  ],
                ))
              else ...[
                for (var i = 0; i < _rules.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RuleCard(
                      rule: _rules[i],
                      index: i,
                      onToggle: (_) => _toggleRule(_rules[i]),
                      onDelete: () => _deleteRule(_rules[i]),
                    ),
                  ),
                if (_rules.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No routing rules configured.')),
                  ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final RoutingRule rule;
  final int index;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  const _RuleCard({required this.rule, required this.index, required this.onToggle, required this.onDelete});

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
              color: rule.isActive
                  ? AppColors.primary.withOpacity(0.10)
                  : context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: rule.isActive
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
                    Flexible(
                      child: Text(rule.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (rule.isActive ? AppColors.success : Colors.grey).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rule.isActive ? 'Enabled' : 'Disabled',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: rule.isActive ? AppColors.success : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rule.ruleType.replaceAll('_', ' '),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.info),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(rule.description ?? '',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.colors.onSurface.withOpacity(0.65),
                      height: 1.4,
                    )),
              ],
            ),
          ),
          Switch(value: rule.isActive, onChanged: onToggle),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            tooltip: 'Delete',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
