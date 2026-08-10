// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/ticket.dart';
import '../../../theme/app_colors.dart';

class SlaCountdown extends StatefulWidget {
  final Ticket ticket;
  final bool dense;

  const SlaCountdown({super.key, required this.ticket, this.dense = false});

  @override
  State<SlaCountdown> createState() => _SlaCountdownState();
}

class _SlaCountdownState extends State<SlaCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _color(double progress, bool breached) {
    if (breached) return AppColors.danger;
    if (progress > 0.85) return AppColors.danger;
    if (progress > 0.6) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    final isClosed = t.status == TicketStatus.resolved || t.status == TicketStatus.closed;
    final progress = t.slaProgress;
    final breached = t.slaBreached;
    final color = isClosed ? AppColors.statusClosed : _color(progress, breached);
    final label = isClosed
        ? 'Met'
        : breached
            ? 'Breached'
            : Formatters.countdown(t.slaRemaining);

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: widget.dense ? 7 : 9, vertical: widget.dense ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isClosed
                ? Icons.check_circle_rounded
                : (breached ? Icons.warning_rounded : Icons.timer_rounded),
            size: widget.dense ? 11 : 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: widget.dense ? 10.5 : 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class SlaRing extends StatefulWidget {
  final Ticket ticket;
  final double size;

  const SlaRing({super.key, required this.ticket, this.size = 120});

  @override
  State<SlaRing> createState() => _SlaRingState();
}

class _SlaRingState extends State<SlaRing> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _color(double progress, bool breached, bool closed) {
    if (closed) return AppColors.success;
    if (breached) return AppColors.danger;
    if (progress > 0.85) return AppColors.danger;
    if (progress > 0.6) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    final isClosed = t.status == TicketStatus.resolved || t.status == TicketStatus.closed;
    final progress = t.slaProgress;
    final breached = t.slaBreached;
    final color = _color(progress, breached, isClosed);
    final label = isClosed
        ? 'Met'
        : breached
            ? 'Breached'
            : Formatters.countdown(t.slaRemaining);
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: isClosed ? 1.0 : progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SLA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withOpacity(0.5),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: widget.size * 0.16,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.3,
                ),
              ),
              if (!isClosed)
                Text(
                  '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}% used',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: scheme.onSurface.withOpacity(0.5),
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
