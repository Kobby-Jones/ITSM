import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  final double size;
  final bool showLabel;
  final Color? labelColor;

  const BrandMark({super.key, this.size = 40, this.showLabel = true, this.labelColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Icon(Icons.support_agent_rounded, color: Colors.white, size: size * 0.55),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ITSM Framework',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.42,
                  letterSpacing: -0.3,
                  color: labelColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'Service Desk',
                style: TextStyle(
                  fontSize: size * 0.30,
                  color: (labelColor ?? Theme.of(context).colorScheme.onSurface).withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
