// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../theme/app_colors.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final reports = [
      _Report('Monthly service desk summary', 'PDF', 'Auto • 1st of every month',
          now.subtract(const Duration(days: 8)), AppColors.primary),
      _Report('Weekly SLA compliance', 'XLSX', 'Auto • Every Monday',
          now.subtract(const Duration(days: 2)), AppColors.success),
      _Report('Technician performance — Q4', 'PDF', 'Manual',
          now.subtract(const Duration(days: 14)), AppColors.info),
      _Report('Asset utilization — Tarkwa', 'XLSX', 'Manual',
          now.subtract(const Duration(days: 24)), AppColors.warning),
      _Report('Top recurring incidents', 'PDF', 'Auto • Quarterly',
          now.subtract(const Duration(days: 36)), AppColors.statusInProgress),
    ];

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Reports',
                subtitle: 'Generated and scheduled service desk reports.',
                trailing: FilledButton.icon(
                  onPressed: () => context.showSnack('Report builder coming soon.'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New report'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              for (final r in reports)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReportRow(report: r),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Report {
  final String title;
  final String format;
  final String schedule;
  final DateTime lastRun;
  final Color color;
  const _Report(this.title, this.format, this.schedule, this.lastRun, this.color);
}

class _ReportRow extends StatelessWidget {
  final _Report report;
  const _ReportRow({required this.report});

  IconData get _icon {
    switch (report.format) {
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'XLSX':
        return Icons.table_chart_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: report.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: report.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(report.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '${report.format} • ${report.schedule} • Last run ${Formatters.relativeTime(report.lastRun)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, size: 18),
            tooltip: 'Download',
            onPressed: () => context.showSnack('Downloading ${report.title}…'),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, size: 18),
            tooltip: 'More',
            onPressed: () => context.showSnack('Report options coming soon.'),
          ),
        ],
      ),
    );
  }
}
