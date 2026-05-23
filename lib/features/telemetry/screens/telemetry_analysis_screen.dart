// ignore_for_file: deprecated_member_use, unnecessary_underscores

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/telemetry.dart';
import '../../../models/ticket.dart';
import '../../../providers/tickets_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../tickets/mock_ticket_data.dart';

class TelemetryAnalysisScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TelemetryAnalysisScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TelemetryAnalysisScreen> createState() => _TelemetryAnalysisScreenState();
}

class _TelemetryAnalysisScreenState extends ConsumerState<TelemetryAnalysisScreen> {
  String _logFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(ticketsProvider);
    Ticket? ticket;
    for (final t in tickets) {
      if (t.id == widget.ticketId || t.code == widget.ticketId) {
        ticket = t;
        break;
      }
    }
    final tel = MockTelemetryData.forTicket(widget.ticketId);
    final isDesktop = Responsive.isDesktop(context);

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(ticketCode: ticket?.code ?? widget.ticketId, ticketId: ticket?.id ?? widget.ticketId),
              const SizedBox(height: 20),
              _DeviceInfoCard(tel: tel),
              const SizedBox(height: 16),
              _MetricsGrid(tel: tel, isDesktop: isDesktop),
              const SizedBox(height: 16),
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _LogsCard(tel: tel, filter: _logFilter, onFilter: (v) => setState(() => _logFilter = v))),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: _ProcessesCard(tel: tel)),
                      ],
                    )
                  : Column(
                      children: [
                        _LogsCard(tel: tel, filter: _logFilter, onFilter: (v) => setState(() => _logFilter = v)),
                        const SizedBox(height: 16),
                        _ProcessesCard(tel: tel),
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

class _Header extends StatelessWidget {
  final String ticketCode;
  final String ticketId;
  const _Header({required this.ticketCode, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.ticketDetailFor(ticketId)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Telemetry — $ticketCode',
                style: context.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
              ),
              const SizedBox(height: 2),
              Text(
                'Full device snapshot at the time of the incident.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => context.showSnack('Refreshed telemetry.'),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Refresh'),
        ),
      ],
    );
  }
}

class _DeviceInfoCard extends StatelessWidget {
  final DeviceTelemetry tel;
  const _DeviceInfoCard({required this.tel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Wrap(
        spacing: 32,
        runSpacing: 16,
        children: [
          _info(context, 'Device', tel.deviceModel, Icons.laptop_mac_rounded),
          _info(context, 'Hostname', tel.hostname, Icons.dns_rounded),
          _info(context, 'OS', tel.osVersion, Icons.desktop_windows_rounded),
          _info(context, 'Asset tag', tel.deviceId, Icons.qr_code_2_rounded),
          _info(context, 'IP address', tel.publicIp, Icons.lan_rounded),
          _info(context, 'MAC', tel.macAddress, Icons.settings_ethernet_rounded),
          _info(context, 'Collected', Formatters.dateTime(tel.collectedAt), Icons.schedule_rounded),
        ],
      ),
    );
  }

  Widget _info(BuildContext context, String label, String value, IconData icon) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 13, color: context.colors.onSurface.withOpacity(0.5)),
              const SizedBox(width: 5),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final DeviceTelemetry tel;
  final bool isDesktop;
  const _MetricsGrid({required this.tel, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _GaugeCard(
        title: 'CPU',
        value: tel.cpuUsage,
        valueLabel: '${(tel.cpuUsage * 100).toStringAsFixed(0)}%',
        sublabel: 'Temp ${tel.cpuTemperature.toStringAsFixed(1)}°C',
        icon: Icons.memory_rounded,
      ),
      _GaugeCard(
        title: 'Memory',
        value: tel.ramUsage,
        valueLabel: '${(tel.ramUsedMb / 1024).toStringAsFixed(1)} GB',
        sublabel: 'of ${(tel.ramTotalMb / 1024).toStringAsFixed(0)} GB',
        icon: Icons.developer_board_rounded,
      ),
      _GaugeCard(
        title: 'Storage',
        value: tel.storageUsage,
        valueLabel: '${tel.storageUsedGb} GB',
        sublabel: 'of ${tel.storageTotalGb} GB',
        icon: Icons.storage_rounded,
      ),
      _NetworkCard(tel: tel),
      if (tel.batteryPercent != null) _BatteryCard(tel: tel),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 5 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isDesktop ? 1.0 : 1.1,
      children: [
        for (var i = 0; i < cards.length; i++)
          cards[i].animate(delay: (i * 80).ms).fadeIn(duration: 240.ms).moveY(begin: 6, end: 0),
      ],
    );
  }
}

class _GaugeCard extends StatelessWidget {
  final String title;
  final double value;
  final String valueLabel;
  final String sublabel;
  final IconData icon;

  const _GaugeCard({
    required this.title,
    required this.value,
    required this.valueLabel,
    required this.sublabel,
    required this.icon,
  });

  Color _color(double v) {
    if (v > 0.85) return AppColors.danger;
    if (v > 0.7) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(value);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => SizedBox(
                      width: 84,
                      height: 84,
                      child: CircularProgressIndicator(
                        value: v,
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        backgroundColor: context.colors.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  Text(
                    valueLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              sublabel,
              style: TextStyle(
                fontSize: 11.5,
                color: context.colors.onSurface.withOpacity(0.55),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkCard extends StatelessWidget {
  final DeviceTelemetry tel;
  const _NetworkCard({required this.tel});

  Color get _color {
    switch (tel.networkStatus) {
      case 'Online':
        return AppColors.success;
      case 'Limited':
        return AppColors.warning;
      default:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.network_check_rounded, size: 16, color: _color),
              const SizedBox(width: 6),
              const Text('Network',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            ],
          ),
          const Spacer(),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _color.withOpacity(0.10),
                border: Border.all(color: _color, width: 1.5),
              ),
              child: Icon(
                tel.networkType == 'Wi-Fi'
                    ? Icons.wifi_rounded
                    : tel.networkType == 'Ethernet'
                        ? Icons.lan_rounded
                        : Icons.signal_cellular_alt_rounded,
                color: _color,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Column(
              children: [
                Text(tel.networkStatus,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _color,
                    )),
                Text(tel.networkType,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.onSurface.withOpacity(0.55),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BatteryCard extends StatelessWidget {
  final DeviceTelemetry tel;
  const _BatteryCard({required this.tel});

  @override
  Widget build(BuildContext context) {
    final percent = tel.batteryPercent! / 100;
    final color = percent < 0.2
        ? AppColors.danger
        : percent < 0.4
            ? AppColors.warning
            : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                tel.charging ? Icons.battery_charging_full_rounded : Icons.battery_full_rounded,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              const Text('Battery',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            ],
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: percent),
                    duration: const Duration(milliseconds: 700),
                    builder: (_, v, __) => SizedBox(
                      width: 84,
                      height: 84,
                      child: CircularProgressIndicator(
                        value: v,
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        backgroundColor: context.colors.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  Text(
                    '${tel.batteryPercent}%',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14, color: color),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              tel.charging ? 'Charging' : 'On battery',
              style: TextStyle(
                fontSize: 11.5,
                color: context.colors.onSurface.withOpacity(0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogsCard extends StatelessWidget {
  final DeviceTelemetry tel;
  final String filter;
  final ValueChanged<String> onFilter;
  const _LogsCard({required this.tel, required this.filter, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    final logs = filter == 'ALL'
        ? tel.logs
        : tel.logs.where((l) => l.level == filter).toList();
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
              Icon(Icons.terminal_rounded,
                  size: 18, color: context.colors.onSurface.withOpacity(0.55)),
              const SizedBox(width: 8),
              const Text('System logs',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              const Spacer(),
              Wrap(
                spacing: 6,
                children: [
                  for (final f in const ['ALL', 'INFO', 'WARN', 'ERROR', 'CRASH'])
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => onFilter(f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: filter == f
                              ? context.colors.primary
                              : context.colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: filter == f
                                ? Colors.white
                                : context.colors.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B0D12),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final log in logs)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: SelectableText.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.5,
                          color: Color(0xFFE5E7EB),
                        ),
                        children: [
                          TextSpan(
                            text: '${_fmt(log.timestamp)} ',
                            style: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                          TextSpan(
                            text: '[${log.level}]'.padRight(8),
                            style: TextStyle(
                              color: log.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: ' ${log.tag}: ',
                            style: const TextStyle(color: Color(0xFF9CA3AF)),
                          ),
                          TextSpan(text: log.message),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }
}

class _ProcessesCard extends StatelessWidget {
  final DeviceTelemetry tel;
  const _ProcessesCard({required this.tel});

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
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 18, color: context.colors.onSurface.withOpacity(0.55)),
              const SizedBox(width: 8),
              const Text('Top processes (CPU)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 50,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 10,
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
                      reservedSize: 30,
                      interval: 10,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}%',
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
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= tel.topProcesses.length) {
                          return const SizedBox.shrink();
                        }
                        final name = tel.topProcesses[i].name;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            name.length > 8 ? '${name.substring(0, 8)}…' : name,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: context.colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < tel.topProcesses.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: tel.topProcesses[i].cpu,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColors.primary.withOpacity(0.6),
                              AppColors.primary,
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: context.colors.outline, height: 1),
          const SizedBox(height: 12),
          for (final p in tel.topProcesses)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(p.name,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${p.cpu.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${p.mem.toStringAsFixed(0)} MB',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: context.colors.onSurface.withOpacity(0.6)),
                      textAlign: TextAlign.right,
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
