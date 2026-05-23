import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/extensions/context_extensions.dart';

/// A shimmer-animated placeholder block.
class SkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBlock({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final base = context.colors.surfaceContainerHighest;
    final highlight = context.colors.surface;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Stack of skeleton lines to mimic a list of loading rows.
class SkeletonList extends StatelessWidget {
  final int rows;
  final EdgeInsetsGeometry padding;
  const SkeletonList({super.key, this.rows = 5, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: rows,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.outline),
          ),
          child: const Row(
            children: [
              SkeletonBlock(width: 32, height: 32, radius: 8),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(width: 200, height: 14),
                    SizedBox(height: 6),
                    SkeletonBlock(width: 140, height: 11),
                  ],
                ),
              ),
              SizedBox(width: 12),
              SkeletonBlock(width: 70, height: 22, radius: 6),
            ],
          ),
        ),
      ),
    );
  }
}
