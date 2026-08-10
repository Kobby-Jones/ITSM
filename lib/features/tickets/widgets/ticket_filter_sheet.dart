// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../models/ticket.dart';
import '../../../providers/tickets_provider.dart';

class TicketFilterSheet extends ConsumerWidget {
  const TicketFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(ticketFiltersProvider);
    final ctrl = ref.read(ticketFiltersProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Filters',
                    style: context.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                if (filters.isActive)
                  TextButton.icon(
                    onPressed: () => ctrl.state = const TicketFilters(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Clear all'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const _SectionLabel('Scope'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _scopeChip(ref, filters, TicketScope.all, 'All tickets'),
                _scopeChip(ref, filters, TicketScope.openOnly, 'Open only'),
                _scopeChip(ref, filters, TicketScope.mine, 'Reported by me'),
                _scopeChip(ref, filters, TicketScope.assignedToMe, 'Assigned to me'),
                _scopeChip(ref, filters, TicketScope.unassigned, 'Unassigned'),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Status'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in TicketStatus.values)
                  FilterChip(
                    label: Text(s.label),
                    avatar: Icon(s.icon, size: 14, color: s.color),
                    selected: filters.statuses.contains(s),
                    onSelected: (sel) {
                      final set = Set<TicketStatus>.from(filters.statuses);
                      sel ? set.add(s) : set.remove(s);
                      ctrl.state = filters.copyWith(statuses: set);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Priority'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in TicketPriority.values)
                  FilterChip(
                    label: Text('${p.code} ${p.label}'),
                    avatar: Icon(p.icon, size: 14, color: p.color),
                    selected: filters.priorities.contains(p),
                    onSelected: (sel) {
                      final set = Set<TicketPriority>.from(filters.priorities);
                      sel ? set.add(p) : set.remove(p);
                      ctrl.state = filters.copyWith(priorities: set);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Category'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in TicketCategory.values)
                  FilterChip(
                    label: Text(c.label),
                    avatar: Icon(c.icon, size: 14),
                    selected: filters.categories.contains(c),
                    onSelected: (sel) {
                      final set = Set<TicketCategory>.from(filters.categories);
                      sel ? set.add(c) : set.remove(c);
                      ctrl.state = filters.copyWith(categories: set);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Apply filters'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _scopeChip(WidgetRef ref, TicketFilters filters, TicketScope scope, String label) {
    final selected = filters.scope == scope;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => ref.read(ticketFiltersProvider.notifier).state = filters.copyWith(scope: scope),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: context.colors.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}
