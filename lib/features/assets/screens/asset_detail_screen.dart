// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/asset.dart';
import '../../../providers/assets_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';

class AssetDetailScreen extends ConsumerStatefulWidget {
  final String assetId;
  const AssetDetailScreen({super.key, required this.assetId});

  @override
  ConsumerState<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends ConsumerState<AssetDetailScreen> {
  bool _loading = true;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    _fetchAsset();
  }

  Future<void> _fetchAsset() async {
    setState(() { _loading = true; _fetchError = null; });
    try {
      await ref.read(assetsControllerProvider.notifier).fetchById(widget.assetId);
    } catch (e) {
      _fetchError = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final all = ref.watch(assetsProvider);
    final asset = assetByIdFrom(all, widget.assetId);
    if (asset == null) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: _fetchError != null ? 'Failed to load asset' : 'Asset not found',
        message: _fetchError ?? 'We couldn\'t find asset "${widget.assetId}".',
        actionLabel: 'Back to assets',
        onAction: () => context.go(AppRoutes.assets),
      );
    }
    final isDesktop = Responsive.isDesktop(context);
    final warrantyExpired = asset.warrantyUntil.isBefore(DateTime.now());

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.go(AppRoutes.assets),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              asset.tag,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.colors.onSurface.withOpacity(0.55),
                                letterSpacing: 0.4,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: asset.status.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: asset.status.color.withOpacity(0.3)),
                              ),
                              child: Text(
                                asset.status.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: asset.status.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          asset.name,
                          style: context.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.showSnack('Edit asset coming soon.'),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _buildLeft(asset, warrantyExpired)),
                        const SizedBox(width: 16),
                        Expanded(flex: 4, child: _buildRight(asset)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildLeft(asset, warrantyExpired),
                        const SizedBox(height: 16),
                        _buildRight(asset),
                      ],
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeft(Asset asset, bool warrantyExpired) {
    return Column(
      children: [
        CardSection(
          title: 'Specifications',
          titleIcon: Icons.info_outline_rounded,
          child: Column(
            children: [
              _detail('Category', asset.category.label, asset.category.icon),
              _detail('Manufacturer', asset.manufacturer, Icons.factory_rounded),
              _detail('Model', asset.model, Icons.devices_other_rounded),
              _detail('Serial number', asset.serialNumber, Icons.qr_code_2_rounded),
              _detail('Cost', 'GHS ${asset.cost.toStringAsFixed(2)}', Icons.payments_rounded),
              _detail('Purchased', Formatters.date(asset.purchasedOn), Icons.event_rounded),
              _detail(
                'Warranty until',
                warrantyExpired ? 'Expired (${Formatters.date(asset.warrantyUntil)})' : Formatters.date(asset.warrantyUntil),
                Icons.shield_rounded,
                muted: warrantyExpired,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CardSection(
          title: 'Assignment history',
          titleIcon: Icons.history_rounded,
          child: asset.assignmentHistory.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No assignment history yet.',
                    style: TextStyle(fontSize: 13),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < asset.assignmentHistory.length; i++)
                      _AssignmentRow(
                        assignment: asset.assignmentHistory[i],
                        isLast: i == asset.assignmentHistory.length - 1,
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildRight(Asset asset) {
    return Column(
      children: [
        CardSection(
          title: 'Currently assigned',
          titleIcon: Icons.person_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detail('User', asset.currentUser, Icons.account_circle_rounded),
              _detail('Department', asset.department, Icons.apartment_rounded),
              _detail('Location', asset.location, Icons.place_rounded),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CardSection(
          title: 'Actions',
          titleIcon: Icons.bolt_rounded,
          child: Builder(
            builder: (ctx) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => ctx.showSnack('Reassign coming soon.'),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('Reassign'),
                ),
                OutlinedButton.icon(
                  onPressed: () => ctx.showSnack('Maintenance flag set.'),
                  icon: const Icon(Icons.build_rounded, size: 16),
                  label: const Text('Maintenance'),
                ),
                OutlinedButton.icon(
                  onPressed: () => ctx.showSnack('Asset retired.'),
                  icon: const Icon(Icons.archive_rounded, size: 16),
                  label: const Text('Retire'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _detail(String label, String value, IconData icon, {bool muted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Builder(
        builder: (context) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: context.colors.onSurface.withOpacity(0.5)),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface.withOpacity(0.55),
                  )),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: muted ? Theme.of(context).colorScheme.error : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  final AssetAssignment assignment;
  final bool isLast;
  const _AssignmentRow({required this.assignment, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final ongoing = assignment.returnedOn == null;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ongoing
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                  : context.colors.surfaceContainerHighest,
            ),
            child: Icon(
              ongoing ? Icons.person_pin_circle_rounded : Icons.history_rounded,
              size: 14,
              color: ongoing
                  ? Theme.of(context).colorScheme.primary
                  : context.colors.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(assignment.userName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(assignment.department,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurface.withOpacity(0.6),
                    )),
                const SizedBox(height: 2),
                Text(
                  ongoing
                      ? 'Since ${Formatters.date(assignment.assignedOn)}'
                      : '${Formatters.date(assignment.assignedOn)} → ${Formatters.date(assignment.returnedOn!)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.colors.onSurface.withOpacity(0.55),
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
