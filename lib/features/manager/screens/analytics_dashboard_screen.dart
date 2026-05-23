// ignore_for_file: deprecated_member_use

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/ticket.dart';
import '../../../providers/technicians_provider.dart';
import '../../../providers/tickets_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_tile.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(ticketsProvider);
    final technicians = ref.watch(techniciansProvider);
    final isDesktop = Responsive.isDesktop(context);

    final total = tickets.length;
    final open = tickets.where((t) => t.status != TicketStatus.resolved && t.status != TicketStatus.closed).length;
    final resolved = tickets.where((t) => t.status == TicketStatus.resolved || t.status == TicketStatus.closed).length;
    final breached = tickets.where((t) => t.slaBreached).length;
    final compliance = total == 0 ? 1.0 : (total - breached) / total;

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Analytics',
                subtitle: 'Service desk performance, trends, and breakdown.',
                trailing: _RangeSelector(),
              ),
              const SizedBox(height: 24),
              _KpiRow(
                total: total,
                open: open,
                resolved: resolved,
                breached: breached,
                compliance: compliance,
              ),
              const SizedBox(height: 20),
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _TicketsTrendCard()),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: _CategoryBreakdownCard(tickets: tickets)),
                      ],
                    )
                  : Column(
                      children: [
                        _TicketsTrendCard(),
                        const SizedBox(height: 16),
                        _CategoryBreakdownCard(tickets: tickets),
                      ],
                    ),
              const SizedBox(height: 16),
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _PriorityVolumeCard(tickets: tickets)),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: _TechnicianLeaderboardCard(technicians: technicians)),
                      ],
                    )
                  : Column(
                      children: [
                        _PriorityVolumeCard(tickets: tickets),
                        const SizedBox(height: 16),
                        _TechnicianLeaderboardCard(technicians: technicians),
                      ],
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeSelector extends StatefulWidget {
  @override
  State<_RangeSelector> createState() => _RangeSelectorState();
}

class _RangeSelectorState extends State<_RangeSelector> {
  String _value = 'Last 30 days';
  static const _opts = ['Today', 'Last 7 days', 'Last 30 days', 'This quarter'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colors.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
          items: [
            for (final o in _opts)
              DropdownMenuItem(
                value: o,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 13, color: context.colors.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 8),
                    Text(o,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface,
                        )),
                  ],
                ),
              ),
          ],
          onChanged: (v) => setState(() => _value = v ?? _value),
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final int total;
  final int open;
  final int resolved;
  final int breached;
  final double compliance;

  const _KpiRow({
    required this.total,
    required this.open,
    required this.resolved,
    required this.breached,
    required this.compliance,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 5 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isDesktop ? 1.5 : 1.4,
      children: [
        StatTile(
          label: 'Total tickets',
          value: '$total',
          icon: Icons.confirmation_number_rounded,
          color: AppColors.primary,
          trend: '+12% vs last month',
        ),
        StatTile(
          label: 'Open',
          value: '$open',
          icon: Icons.fiber_new_rounded,
          color: AppColors.statusOpen,
          trend: 'Active workload',
        ),
        StatTile(
          label: 'Resolved',
          value: '$resolved',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          trend: 'Cleared from queue',
        ),
        StatTile(
          label: 'SLA breached',
          value: '$breached',
          icon: Icons.warning_rounded,
          color: breached == 0 ? AppColors.success : AppColors.danger,
          trend: breached == 0 ? 'No breaches' : 'Needs attention',
        ),
        StatTile(
          label: 'SLA compliance',
          value: '${(compliance * 100).toStringAsFixed(0)}%',
          icon: Icons.verified_rounded,
          color: AppColors.info,
          progress: compliance,
        ),
      ],
    );
  }
}

class _TicketsTrendCard extends StatelessWidget {
  // Synthetic 14-day series — created tickets vs resolved tickets
  static const List<double> _created = [12, 14, 9, 18, 22, 16, 11, 14, 19, 24, 17, 13, 15, 20];
  static const List<double> _resolved = [10, 11, 12, 14, 17, 19, 12, 13, 15, 18, 21, 14, 13, 18];

  @override
  Widget build(BuildContext context) {
    return CardSection(
      title: 'Tickets over time',
      titleIcon: Icons.show_chart_rounded,
      titleTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendDot(AppColors.primary, 'Created'),
          const SizedBox(width: 14),
          _legendDot(AppColors.success, 'Resolved'),
        ],
      ),
      child: SizedBox(
        height: 240,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 28,
            gridData: FlGridData(
              show: true,
              horizontalInterval: 7,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: context.colors.outline,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 7,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}',
                      style: TextStyle(
                          fontSize: 10,
                          color: context.colors.onSurface.withOpacity(0.5))),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 2,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= _created.length || i % 2 != 0) {
                      return const SizedBox.shrink();
                    }
                    final daysAgo = _created.length - 1 - i;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        daysAgo == 0 ? 'today' : '-${daysAgo}d',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.colors.onSurface.withOpacity(0.55),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < _created.length; i++) FlSpot(i.toDouble(), _created[i]),
                ],
                isCurved: true,
                curveSmoothness: 0.3,
                barWidth: 3,
                color: AppColors.primary,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.20),
                      AppColors.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
              LineChartBarData(
                spots: [
                  for (var i = 0; i < _resolved.length; i++) FlSpot(i.toDouble(), _resolved[i]),
                ],
                isCurved: true,
                curveSmoothness: 0.3,
                barWidth: 3,
                color: AppColors.success,
                dotData: const FlDotData(show: false),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => context.colors.inverseSurface,
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                getTooltipItems: (spots) => spots.map((s) {
                  final label = s.barIndex == 0 ? 'Created' : 'Resolved';
                  return LineTooltipItem(
                    '$label: ${s.y.toInt()}',
                    TextStyle(
                      color: context.colors.onInverseSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  final List<Ticket> tickets;
  const _CategoryBreakdownCard({required this.tickets});

  @override
  Widget build(BuildContext context) {
    final byCategory = <TicketCategory, int>{};
    for (final t in tickets) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + 1;
    }
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = tickets.length;

    const palette = [
      AppColors.chart1,
      AppColors.chart2,
      AppColors.chart3,
      AppColors.chart4,
      AppColors.chart5,
      AppColors.chart6,
    ];

    return CardSection(
      title: 'Category breakdown',
      titleIcon: Icons.donut_large_rounded,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                startDegreeOffset: -90,
                sections: [
                  for (var i = 0; i < entries.length; i++)
                    PieChartSectionData(
                      value: entries[i].value.toDouble(),
                      color: palette[i % palette.length],
                      radius: 36,
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < entries.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: palette[i % palette.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entries[i].key.label,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${entries[i].value}',
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${((entries[i].value / total) * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.colors.onSurface.withOpacity(0.55),
                      fontWeight: FontWeight.w600,
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

class _PriorityVolumeCard extends StatelessWidget {
  final List<Ticket> tickets;
  const _PriorityVolumeCard({required this.tickets});

  @override
  Widget build(BuildContext context) {
    final byPriority = <TicketPriority, int>{};
    for (final t in tickets) {
      byPriority[t.priority] = (byPriority[t.priority] ?? 0) + 1;
    }
    final entries = TicketPriority.values
        .map((p) => MapEntry(p, byPriority[p] ?? 0))
        .toList();
    final maxValue = entries.fold<int>(0, (m, e) => e.value > m ? e.value : m).toDouble();

    return CardSection(
      title: 'Volume by priority',
      titleIcon: Icons.bar_chart_rounded,
      child: SizedBox(
        height: 240,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue == 0 ? 10 : maxValue * 1.2,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxValue == 0 ? 1.0 : maxValue / 4,
              getDrawingHorizontalLine: (_) => FlLine(
                color: context.colors.outline,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: maxValue == 0 ? 1.0 : maxValue / 4,
                  getTitlesWidget: (v, _) => Text(
                    '${v.toInt()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.colors.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                    final p = entries[i].key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          Text(p.code,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: p.color,
                              )),
                          Text(p.label,
                              style: TextStyle(
                                fontSize: 10,
                                color: context.colors.onSurface.withOpacity(0.55),
                              )),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < entries.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: entries[i].value.toDouble(),
                      width: 32,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          entries[i].key.color.withOpacity(0.5),
                          entries[i].key.color,
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechnicianLeaderboardCard extends StatelessWidget {
  final List technicians;
  const _TechnicianLeaderboardCard({required this.technicians});

  @override
  Widget build(BuildContext context) {
    final sorted = [...technicians]
      ..sort((a, b) => b.resolvedThisWeek.compareTo(a.resolvedThisWeek));
    final top = sorted.take(5).toList();

    return CardSection(
      title: 'Top technicians (this week)',
      titleIcon: Icons.emoji_events_rounded,
      titleTrailing: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(0, 28),
        ),
        onPressed: () => context.go(AppRoutes.technicianPerformance),
        child: const Text('View all'),
      ),
      child: Column(
        children: [
          for (var i = 0; i < top.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: i == 0
                            ? AppColors.warning
                            : context.colors.onSurface.withOpacity(0.45),
                      ),
                    ),
                  ),
                  UserAvatar(
                    initials: top[i].avatarInitials,
                    size: 32,
                    showStatus: true,
                    online: top[i].online,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          top[i].name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          top[i].specialty,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.onSurface.withOpacity(0.55),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${top[i].resolvedThisWeek}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'resolved',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: context.colors.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (i < top.length - 1) Divider(height: 1, color: context.colors.outline),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 220.ms);
  }
}
