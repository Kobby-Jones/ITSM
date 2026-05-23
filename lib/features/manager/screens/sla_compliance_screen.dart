import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/ticket.dart';
import '../../../providers/tickets_provider.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_tile.dart';
import '../../../theme/app_colors.dart';

class SlaComplianceScreen extends ConsumerWidget {
  const SlaComplianceScreen({super.key});

  // 12-week synthetic compliance series
  static const _series = [
    0.91, 0.93, 0.89, 0.94, 0.92, 0.95, 0.93, 0.96, 0.94, 0.95, 0.92, 0.94,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(ticketsProvider);
    final isDesktop = Responsive.isDesktop(context);

    final byPriority = <TicketPriority, ({int total, int breached})>{};
    for (final t in tickets) {
      final cur = byPriority[t.priority] ?? (total: 0, breached: 0);
      byPriority[t.priority] = (
        total: cur.total + 1,
        breached: cur.breached + (t.slaBreached ? 1 : 0),
      );
    }

    final total = tickets.length;
    final breached = tickets.where((t) => t.slaBreached).length;
    final compliance = total == 0 ? 1.0 : (total - breached) / total;
    final atRisk = tickets
        .where((t) =>
            !t.slaBreached &&
            t.slaProgress > 0.7 &&
            t.status != TicketStatus.resolved &&
            t.status != TicketStatus.closed)
        .length;

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'SLA compliance',
                subtitle: 'How we are tracking against our service-level agreements.',
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isDesktop ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isDesktop ? 1.5 : 1.4,
                children: [
                  StatTile(
                    label: 'Overall compliance',
                    value: '${(compliance * 100).toStringAsFixed(1)}%',
                    icon: Icons.verified_rounded,
                    color: compliance >= 0.95 ? AppColors.success : AppColors.warning,
                    progress: compliance,
                  ),
                  StatTile(
                    label: 'Breached',
                    value: '$breached',
                    icon: Icons.warning_rounded,
                    color: breached == 0 ? AppColors.success : AppColors.danger,
                    trend: breached == 0 ? 'Clean' : 'Action required',
                  ),
                  StatTile(
                    label: 'At risk',
                    value: '$atRisk',
                    icon: Icons.timer_rounded,
                    color: AppColors.warning,
                    trend: '> 70% SLA used',
                  ),
                  StatTile(
                    label: 'Tickets in window',
                    value: '$total',
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CardSection(
                title: 'Compliance trend (12 weeks)',
                titleIcon: Icons.timeline_rounded,
                child: SizedBox(
                  height: 240,
                  child: LineChart(
                    LineChartData(
                      minY: 0.80,
                      maxY: 1.0,
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 0.05,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: v == 0.95
                              ? AppColors.success.withOpacity(0.5)
                              : context.colors.outline,
                          strokeWidth: v == 0.95 ? 1.5 : 1,
                          dashArray: v == 0.95 ? [4, 4] : null,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: 0.05,
                            getTitlesWidget: (v, _) => Text(
                              '${(v * 100).toInt()}%',
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
                            reservedSize: 22,
                            interval: 2,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= _series.length || i % 2 != 0) {
                                return const SizedBox.shrink();
                              }
                              final weeksAgo = _series.length - 1 - i;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  weeksAgo == 0 ? 'now' : '-${weeksAgo}w',
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
                            for (var i = 0; i < _series.length; i++)
                              FlSpot(i.toDouble(), _series[i]),
                          ],
                          isCurved: true,
                          curveSmoothness: 0.3,
                          barWidth: 3,
                          color: AppColors.info,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                              radius: 4,
                              color: spot.y >= 0.95 ? AppColors.success : AppColors.warning,
                              strokeWidth: 2,
                              strokeColor: context.colors.surface,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.info.withOpacity(0.18),
                                AppColors.info.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => context.colors.inverseSurface,
                          getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                                '${(s.y * 100).toStringAsFixed(1)}%',
                                TextStyle(
                                  color: context.colors.onInverseSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              )).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CardSection(
                title: 'Compliance by priority',
                titleIcon: Icons.flag_rounded,
                child: Column(
                  children: [
                    for (final p in TicketPriority.values)
                      _PriorityRow(priority: p, data: byPriority[p] ?? (total: 0, breached: 0)),
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

class _PriorityRow extends StatelessWidget {
  final TicketPriority priority;
  final ({int total, int breached}) data;
  const _PriorityRow({required this.priority, required this.data});

  @override
  Widget build(BuildContext context) {
    final compliance = data.total == 0 ? 1.0 : (data.total - data.breached) / data.total;
    final color = compliance >= 0.95
        ? AppColors.success
        : compliance >= 0.9
            ? AppColors.warning
            : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: priority.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              priority.code,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: priority.color),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(priority.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: compliance,
                minHeight: 8,
                backgroundColor: context.colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 70,
            child: Text(
              '${(compliance * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              '${data.total - data.breached}/${data.total}',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 12, color: context.colors.onSurface.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }
}
