import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/user_role.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    final isMobile = Responsive.isMobile(context);

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Greeting(name: user.name, role: user.role),
            const SizedBox(height: 24),
            _KpiGrid(role: user.role).animate().fadeIn(duration: 300.ms).moveY(begin: 8, end: 0),
            const SizedBox(height: 24),
            if (!isMobile)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _ActivityFeed(role: user.role)),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _QuickActions(role: user.role)),
                ],
              )
            else ...[
              _QuickActions(role: user.role),
              const SizedBox(height: 16),
              _ActivityFeed(role: user.role),
            ],
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String name;
  final UserRole role;

  const _Greeting({required this.name, required this.role});

  String get _timeOfDayGreeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(' ').first;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_timeOfDayGreeting, $firstName',
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _subtitleFor(role),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
        if (Responsive.isDesktop(context))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 16, color: context.colors.onSurface.withOpacity(0.6)),
                const SizedBox(width: 8),
                Text(
                  Formatters.date(DateTime.now()),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _subtitleFor(UserRole role) {
    switch (role) {
      case UserRole.endUser:
        return "Here's what's happening with your support requests today.";
      case UserRole.technician:
        return "Here's your queue, your SLAs, and what's hot right now.";
      case UserRole.admin:
        return "Manage users, assets, and routing rules across the organization.";
      case UserRole.manager:
        return "Service desk performance at a glance.";
    }
  }
}

class _KpiGrid extends StatelessWidget {
  final UserRole role;
  const _KpiGrid({required this.role});

  @override
  Widget build(BuildContext context) {
    final kpis = _kpisFor(role);
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final cross = isDesktop ? 4 : (isTablet ? 2 : 2);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: cross,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isDesktop ? 1.3 : (isTablet ? 1.1 : 1.0),
      children: [
        for (final k in kpis) _KpiCard(data: k),
      ],
    );
  }

  List<_KpiData> _kpisFor(UserRole role) {
    switch (role) {
      case UserRole.endUser:
        return const [
          _KpiData('Open tickets', '3', Icons.confirmation_number_rounded,
              AppColors.statusOpen, '+1 today'),
          _KpiData('Awaiting response', '1', Icons.hourglass_top_rounded,
              AppColors.warning, 'Updated 2h ago'),
          _KpiData('Resolved this month', '14', Icons.check_circle_rounded,
              AppColors.success, '+3 vs last'),
          _KpiData('KB articles read', '27', Icons.menu_book_rounded,
              AppColors.info, '+5 this week'),
        ];
      case UserRole.technician:
        return const [
          _KpiData('Assigned to me', '12', Icons.assignment_ind_rounded,
              AppColors.statusInProgress, '4 due today'),
          _KpiData('SLA at risk', '3', Icons.timer_rounded, AppColors.warning,
              'Within 1h'),
          _KpiData('Resolved today', '7', Icons.check_circle_rounded,
              AppColors.success, '+2 vs yesterday'),
          _KpiData('Avg. resolution', '4.2h', Icons.speed_rounded,
              AppColors.primary, '-0.5h vs last'),
        ];
      case UserRole.admin:
        return const [
          _KpiData('Total assets', '1,284', Icons.inventory_2_rounded,
              AppColors.primary, '+18 this month'),
          _KpiData('Active users', '342', Icons.group_rounded, AppColors.info,
              '12 new'),
          _KpiData('KB articles', '128', Icons.menu_book_rounded,
              AppColors.success, '+6 this week'),
          _KpiData('Routing rules', '24', Icons.route_rounded,
              AppColors.statusInProgress, '2 disabled'),
        ];
      case UserRole.manager:
        return const [
          _KpiData('Tickets this week', '247', Icons.confirmation_number_rounded,
              AppColors.primary, '+12% WoW'),
          _KpiData('SLA compliance', '94%', Icons.verified_rounded,
              AppColors.success, '+2.4 pts'),
          _KpiData('Avg. resolution', '3.8h', Icons.speed_rounded, AppColors.info,
              '-0.6h MoM'),
          _KpiData('CSAT', '4.6 / 5', Icons.sentiment_satisfied_rounded,
              AppColors.warning, '+0.1'),
        ];
    }
  }
}

class _KpiData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  const _KpiData(this.title, this.value, this.icon, this.color, this.trend);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.more_horiz_rounded,
                  size: 18, color: context.colors.onSurface.withOpacity(0.4)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.value,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.title,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.65),
                  fontSize: 12.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                data.trend,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: data.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final UserRole role;
  const _QuickActions({required this.role});

  @override
  Widget build(BuildContext context) {
    final actions = _actionsFor(role);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick actions',
            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < actions.length; i++) ...[
            _QuickActionTile(action: actions[i]),
            if (i < actions.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  List<_ActionData> _actionsFor(UserRole role) {
    switch (role) {
      case UserRole.endUser:
        return const [
          _ActionData('Submit a ticket', 'Report a new issue',
              Icons.add_circle_outline_rounded, AppColors.primary, AppRoutes.submitTicket),
          _ActionData('Browse Knowledge Base', 'Find answers fast',
              Icons.menu_book_rounded, AppColors.info, AppRoutes.knowledgeBase),
          _ActionData('Sync queue', 'View pending offline tickets',
              Icons.cloud_sync_rounded, AppColors.warning, AppRoutes.syncQueue),
        ];
      case UserRole.technician:
        return const [
          _ActionData('Open queue', 'Pick up the next ticket',
              Icons.list_alt_rounded, AppColors.primary, AppRoutes.ticketQueue),
          _ActionData('SLA monitor', 'See what\'s at risk',
              Icons.timer_rounded, AppColors.warning, AppRoutes.slaMonitor),
          _ActionData('Knowledge Base', 'Search for solutions',
              Icons.menu_book_rounded, AppColors.info, AppRoutes.knowledgeBase),
        ];
      case UserRole.admin:
        return const [
          _ActionData('Manage assets', 'View and assign devices',
              Icons.inventory_2_rounded, AppColors.primary, AppRoutes.assets),
          _ActionData('Manage users', 'Add or update accounts',
              Icons.group_rounded, AppColors.info, AppRoutes.userManagement),
          _ActionData('Routing rules', 'Configure auto-assignment',
              Icons.route_rounded, AppColors.statusInProgress, AppRoutes.routingRules),
        ];
      case UserRole.manager:
        return const [
          _ActionData('Analytics', 'See the full picture',
              Icons.analytics_rounded, AppColors.primary, AppRoutes.analytics),
          _ActionData('Technician performance', 'Per-tech metrics',
              Icons.engineering_rounded, AppColors.info, AppRoutes.technicianPerformance),
          _ActionData('SLA compliance', 'Compliance trends',
              Icons.verified_rounded, AppColors.success, AppRoutes.slaCompliance),
        ];
    }
  }
}

class _ActionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  const _ActionData(this.title, this.subtitle, this.icon, this.color, this.route);
}

class _QuickActionTile extends StatelessWidget {
  final _ActionData action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.go(action.route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(action.icon, color: action.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(action.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13.5)),
                  Text(action.subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurface.withOpacity(0.6))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: context.colors.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

class _ActivityFeed extends StatelessWidget {
  final UserRole role;
  const _ActivityFeed({required this.role});

  @override
  Widget build(BuildContext context) {
    final items = _itemsFor(role);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent activity',
                style: context.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(AppRoutes.tickets),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final item in items) _ActivityRow(item: item),
        ],
      ),
    );
  }

  List<_ActivityItem> _itemsFor(UserRole role) {
    final now = DateTime.now();
    return [
      _ActivityItem(
        icon: Icons.confirmation_number_rounded,
        color: AppColors.primary,
        title: 'INC-1042 — Plant SCADA terminal cannot connect',
        subtitle: role == UserRole.endUser
            ? 'You submitted a P1 ticket'
            : 'Assigned to Kwame Boateng',
        time: now.subtract(const Duration(minutes: 12)),
        priority: 'P1',
        priorityColor: AppColors.p1Critical,
      ),
      _ActivityItem(
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        title: 'INC-1037 — VPN keeps disconnecting',
        subtitle: 'Resolved by Esi Owusu',
        time: now.subtract(const Duration(hours: 1, minutes: 5)),
        priority: 'P3',
        priorityColor: AppColors.p3Medium,
      ),
      _ActivityItem(
        icon: Icons.comment_rounded,
        color: AppColors.info,
        title: 'INC-1039 — New comment on your ticket',
        subtitle: '"We\'ve isolated the issue to the firewall…"',
        time: now.subtract(const Duration(hours: 2, minutes: 40)),
        priority: 'P2',
        priorityColor: AppColors.p2High,
      ),
      _ActivityItem(
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        title: 'INC-1031 — SLA at 80% elapsed',
        subtitle: 'Action required within 2h',
        time: now.subtract(const Duration(hours: 4)),
        priority: 'P2',
        priorityColor: AppColors.p2High,
      ),
      _ActivityItem(
        icon: Icons.cloud_done_rounded,
        color: AppColors.statusInProgress,
        title: 'Sync complete',
        subtitle: '3 offline tickets synchronized',
        time: now.subtract(const Duration(hours: 6)),
        priority: '',
        priorityColor: AppColors.statusInProgress,
      ),
    ];
  }
}

class _ActivityItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final DateTime time;
  final String priority;
  final Color priorityColor;
  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.priority,
    required this.priorityColor,
  });
}

class _ActivityRow extends StatelessWidget {
  final _ActivityItem item;
  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.priority.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.priorityColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.priority,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: item.priorityColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.relativeTime(item.time),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.colors.onSurface.withOpacity(0.45),
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
