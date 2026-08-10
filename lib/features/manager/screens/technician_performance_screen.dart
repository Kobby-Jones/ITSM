// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/technician.dart';
import '../../../providers/technicians_provider.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';

class TechnicianPerformanceScreen extends ConsumerWidget {
  const TechnicianPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final technicians = ref.watch(techniciansProvider);
    final isDesktop = Responsive.isDesktop(context);

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Technician performance',
                subtitle: 'Per-technician resolution, workload, and customer satisfaction.',
              ),
              const SizedBox(height: 24),
              _SummaryRow(technicians: technicians),
              const SizedBox(height: 20),
              if (isDesktop)
                _DesktopTable(technicians: technicians)
              else
                Column(
                  children: [
                    for (final t in technicians)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MobileCard(tech: t),
                      ),
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

class _SummaryRow extends StatelessWidget {
  final List<Technician> technicians;
  const _SummaryRow({required this.technicians});

  @override
  Widget build(BuildContext context) {
    final online = technicians.where((t) => t.online).length;
    final totalActive = technicians.fold<int>(0, (s, t) => s + t.activeTickets);
    final totalResolved = technicians.fold<int>(0, (s, t) => s + t.resolvedThisWeek);
    final avgSla =
        technicians.fold<double>(0, (s, t) => s + t.slaComplianceRate) / technicians.length;
    final avgCsat =
        technicians.fold<double>(0, (s, t) => s + t.customerSatisfaction) / technicians.length;

    return Row(
      children: [
        Expanded(child: _summaryTile(context, 'Online', '$online of ${technicians.length}', Icons.circle_rounded, AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: _summaryTile(context, 'Active tickets', '$totalActive', Icons.assignment_ind_rounded, AppColors.statusInProgress)),
        const SizedBox(width: 12),
        Expanded(child: _summaryTile(context, 'Resolved (week)', '$totalResolved', Icons.check_circle_rounded, AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _summaryTile(context, 'Avg SLA', '${(avgSla * 100).toStringAsFixed(0)}%', Icons.verified_rounded, AppColors.info)),
        const SizedBox(width: 12),
        Expanded(child: _summaryTile(context, 'Avg CSAT', avgCsat.toStringAsFixed(1), Icons.sentiment_satisfied_rounded, AppColors.warning)),
      ],
    );
  }

  Widget _summaryTile(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
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
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: context.colors.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopTable extends StatelessWidget {
  final List<Technician> technicians;
  const _DesktopTable({required this.technicians});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        children: [
          _Header(),
          for (var i = 0; i < technicians.length; i++)
            _Row(tech: technicians[i], isLast: i == technicians.length - 1)
                .animate(delay: (i * 30).ms)
                .fadeIn(duration: 200.ms),
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 44),
          Expanded(flex: 4, child: Text('TECHNICIAN', style: s)),
          Expanded(flex: 3, child: Text('SPECIALTY', style: s)),
          Expanded(flex: 2, child: Text('ACTIVE', style: s, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('RESOLVED (WK)', style: s, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('AVG TIME', style: s, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('SLA', style: s, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('CSAT', style: s, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final Technician tech;
  final bool isLast;
  const _Row({required this.tech, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final slaColor = tech.slaComplianceRate >= 0.95
        ? AppColors.success
        : tech.slaComplianceRate >= 0.9
            ? AppColors.warning
            : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: isLast ? Colors.transparent : context.colors.outline),
        ),
      ),
      child: Row(
        children: [
          UserAvatar(
            initials: tech.avatarInitials,
            size: 36,
            showStatus: true,
            online: tech.online,
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tech.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(tech.online ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        color: tech.online
                            ? AppColors.success
                            : context.colors.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(tech.specialty,
                style: const TextStyle(fontSize: 12.5),
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${tech.activeTickets}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                SizedBox(
                  width: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: tech.workloadPercent,
                      minHeight: 4,
                      backgroundColor: context.colors.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        tech.workloadPercent > 0.8
                            ? AppColors.danger
                            : tech.workloadPercent > 0.6
                                ? AppColors.warning
                                : AppColors.success,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('${tech.resolvedThisWeek}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: Text('${tech.avgResolutionHours.toStringAsFixed(1)}h',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${(tech.slaComplianceRate * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: slaColor),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                const SizedBox(width: 3),
                Text(tech.customerSatisfaction.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileCard extends StatelessWidget {
  final Technician tech;
  const _MobileCard({required this.tech});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                initials: tech.avatarInitials,
                size: 36,
                showStatus: true,
                online: tech.online,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tech.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(tech.specialty,
                        style: TextStyle(
                            fontSize: 11.5,
                            color: context.colors.onSurface.withOpacity(0.6))),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                  const SizedBox(width: 3),
                  Text(tech.customerSatisfaction.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat(context, 'Active', '${tech.activeTickets}'),
              _stat(context, 'Resolved', '${tech.resolvedThisWeek}'),
              _stat(context, 'Avg', '${tech.avgResolutionHours.toStringAsFixed(1)}h'),
              _stat(context, 'SLA', '${(tech.slaComplianceRate * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: context.colors.onSurface.withOpacity(0.55))),
        ],
      ),
    );
  }
}
