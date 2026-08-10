// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/ticket.dart';
import '../../../providers/technicians_provider.dart';
import '../../../providers/tickets_provider.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../theme/app_colors.dart';

class KpiDashboardScreen extends ConsumerWidget {
  const KpiDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(ticketsProvider);
    final techs = ref.watch(techniciansProvider);
    final isDesktop = Responsive.isDesktop(context);

    final total = tickets.length;
    final resolved = tickets.where((t) =>
        t.status == TicketStatus.resolved || t.status == TicketStatus.closed).length;
    final breached = tickets.where((t) => t.slaBreached).length;
    final compliance = total == 0 ? 1.0 : (total - breached) / total;
    final avgRes = techs.isEmpty
        ? 0.0
        : techs.fold<double>(0, (s, t) => s + t.avgResolutionHours) / techs.length;
    final avgCsat = techs.isEmpty
        ? 0.0
        : techs.fold<double>(0, (s, t) => s + t.customerSatisfaction) / techs.length;
    final firstResp = '12m';
    final reopens = tickets.where((t) => t.status == TicketStatus.open && t.events.length > 3).length;

    final kpis = [
      _Kpi('SLA compliance', '${(compliance * 100).toStringAsFixed(1)}%',
          'Target: 95%', compliance >= 0.95 ? AppColors.success : AppColors.warning, Icons.verified_rounded),
      _Kpi('First response', firstResp, 'Target: 15m', AppColors.success, Icons.timer_rounded),
      _Kpi('Avg resolution', '${avgRes.toStringAsFixed(1)}h', 'Across all tickets',
          AppColors.info, Icons.speed_rounded),
      _Kpi('Customer satisfaction', avgCsat.toStringAsFixed(2),
          'Out of 5.00', AppColors.warning, Icons.sentiment_satisfied_rounded),
      _Kpi('Resolved', '$resolved', 'This period',
          AppColors.success, Icons.check_circle_rounded),
      _Kpi('Reopened', '$reopens', 'Quality signal',
          reopens == 0 ? AppColors.success : AppColors.warning,
          Icons.replay_rounded),
    ];

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'KPI dashboard',
                subtitle: 'Headline metrics across the service desk.',
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isDesktop ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isDesktop ? 1.8 : 1.4,
                children: [for (final k in kpis) _KpiCard(kpi: k)],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Kpi {
  final String label;
  final String value;
  final String hint;
  final Color color;
  final IconData icon;
  const _Kpi(this.label, this.value, this.hint, this.color, this.icon);
}

class _KpiCard extends StatelessWidget {
  final _Kpi kpi;
  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kpi.color.withOpacity(0.04),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kpi.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(kpi.icon, color: kpi.color, size: 22),
              ),
              const Spacer(),
              Text(
                kpi.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: context.colors.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                kpi.value,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: kpi.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                kpi.hint,
                style: TextStyle(
                  fontSize: 12.5,
                  color: context.colors.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
