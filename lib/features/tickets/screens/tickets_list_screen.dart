// ignore_for_file: deprecated_member_use, unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/user_role.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/tickets_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/ticket_card.dart';
import '../widgets/ticket_filter_sheet.dart';

class TicketsListScreen extends ConsumerStatefulWidget {
  const TicketsListScreen({super.key});

  @override
  ConsumerState<TicketsListScreen> createState() => _TicketsListScreenState();
}

class _TicketsListScreenState extends ConsumerState<TicketsListScreen> {
  final _searchCtrl = TextEditingController();
  bool _initialScopeApplied = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    if (!_initialScopeApplied) {
      _initialScopeApplied = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final defaultScope = ref.read(defaultScopeForRoleProvider);
        final filters = ref.read(ticketFiltersProvider);
        if (filters.scope == TicketScope.all) {
          ref.read(ticketFiltersProvider.notifier).state =
              filters.copyWith(scope: defaultScope);
        }
      });
    }

    final tickets = ref.watch(filteredTicketsProvider);
    final filters = ref.watch(ticketFiltersProvider);
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    return Padding(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(canCreate: user.role == UserRole.endUser || user.role == UserRole.admin),
          const SizedBox(height: 20),
          _ScopeBar(role: user.role),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    ref.read(ticketFiltersProvider.notifier).state =
                        ref.read(ticketFiltersProvider).copyWith(query: v);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by code, title, description, or reporter…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(ticketFiltersProvider.notifier).state =
                                  ref.read(ticketFiltersProvider).copyWith(query: '');
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _openFilters(context),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.tune_rounded, size: 18),
                    if (filters.activeCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                            shape: BoxShape.circle,
                          ),
                          constraints:
                              const BoxConstraints(minWidth: 14, minHeight: 14),
                          child: Text(
                            '${filters.activeCount}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
                label: const Text('Filters'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${tickets.length} ticket${tickets.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              if (filters.isActive) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Filtered',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ],
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: tickets.isEmpty
                ? EmptyState(
                    icon: Icons.inbox_rounded,
                    title: filters.isActive
                        ? 'No tickets match your filters'
                        : 'No tickets yet',
                    message: filters.isActive
                        ? 'Try adjusting or clearing the filters to see more results.'
                        : 'When tickets are submitted, they will show up here.',
                    actionLabel: filters.isActive ? 'Clear filters' : null,
                    onAction: filters.isActive
                        ? () => ref.read(ticketFiltersProvider.notifier).state =
                            const TicketFilters()
                        : null,
                  )
                : isDesktop
                    ? GridView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 460,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 280,
                        ),
                        itemCount: tickets.length,
                        itemBuilder: (_, i) => TicketCard(
                          ticket: tickets[i],
                          onTap: () =>
                              context.go(AppRoutes.ticketDetailFor(tickets[i].id)),
                        ).animate(delay: (i * 18).ms).fadeIn(duration: 200.ms).moveY(begin: 6, end: 0),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: tickets.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: isMobile ? 10 : 12),
                        itemBuilder: (_, i) => TicketCard(
                          ticket: tickets[i],
                          onTap: () =>
                              context.go(AppRoutes.ticketDetailFor(tickets[i].id)),
                          compact: isMobile,
                        ).animate(delay: (i * 14).ms).fadeIn(duration: 180.ms),
                      ),
          ),
        ],
      ),
    );
  }

  void _openFilters(BuildContext context) {
    if (Responsive.isMobile(context)) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const TicketFilterSheet(),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: const TicketFilterSheet(),
          ),
        ),
      );
    }
  }
}

class _Header extends StatelessWidget {
  final bool canCreate;
  const _Header({required this.canCreate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tickets',
                  style: context.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text(
                'Browse, filter, and dive into any incident.',
                style: context.textTheme.bodyMedium
                    ?.copyWith(color: context.colors.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
        ),
        if (canCreate)
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.submitTicket),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New ticket'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
      ],
    );
  }
}

class _ScopeBar extends ConsumerWidget {
  final UserRole role;
  const _ScopeBar({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(ticketFiltersProvider);
    final tabs = <(TicketScope, String, IconData)>[
      (TicketScope.all, 'All', Icons.list_rounded),
      (TicketScope.openOnly, 'Open', Icons.fiber_new_rounded),
      if (role == UserRole.endUser)
        (TicketScope.mine, 'Reported by me', Icons.person_rounded),
      if (role == UserRole.technician)
        (TicketScope.assignedToMe, 'Assigned to me', Icons.assignment_ind_rounded),
      if (role == UserRole.technician || role == UserRole.admin || role == UserRole.manager)
        (TicketScope.unassigned, 'Unassigned', Icons.person_off_rounded),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (scope, label, icon) = tabs[i];
          final selected = filters.scope == scope;
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => ref.read(ticketFiltersProvider.notifier).state =
                filters.copyWith(scope: scope),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? context.colors.primary : context.colors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? context.colors.primary : context.colors.outline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 14,
                      color: selected
                          ? Colors.white
                          : context.colors.onSurface.withOpacity(0.65)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : context.colors.onSurface.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
