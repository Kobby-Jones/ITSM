// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/ticket.dart';
import '../../../theme/app_colors.dart';

class SyncStateChip extends StatelessWidget {
  final SyncState state;
  final bool dense;

  const SyncStateChip({super.key, required this.state, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (state) {
      SyncState.synced => ('Synced', Icons.cloud_done_rounded, AppColors.success),
      SyncState.pending => ('Pending sync', Icons.cloud_queue_rounded, AppColors.warning),
      SyncState.syncing => ('Syncing', Icons.cloud_sync_rounded, AppColors.info),
      SyncState.failed => ('Sync failed', Icons.cloud_off_rounded, AppColors.danger),
    };

    final iconWidget = state == SyncState.syncing
        ? Icon(icon, size: dense ? 11 : 12, color: color)
            .animate(onPlay: (c) => c.repeat())
            .rotate(duration: 1200.ms)
        : Icon(icon, size: dense ? 11 : 12, color: color);

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 7 : 9, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: dense ? 10.5 : 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
