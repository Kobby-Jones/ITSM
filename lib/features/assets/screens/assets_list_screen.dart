// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

class AssetsListScreen extends ConsumerStatefulWidget {
  const AssetsListScreen({super.key});

  @override
  ConsumerState<AssetsListScreen> createState() => _AssetsListScreenState();
}

class _AssetsListScreenState extends ConsumerState<AssetsListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  AssetCategory? _category;
  AssetStatus? _status;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(assetsProvider);
    var assets = all;
    if (_category != null) assets = assets.where((a) => a.category == _category).toList();
    if (_status != null) assets = assets.where((a) => a.status == _status).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      assets = assets.where((a) =>
          a.name.toLowerCase().contains(q) ||
          a.tag.toLowerCase().contains(q) ||
          a.serialNumber.toLowerCase().contains(q) ||
          a.currentUser.toLowerCase().contains(q)).toList();
    }

    final isDesktop = Responsive.isDesktop(context);

    return Padding(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Asset management',
            subtitle: 'Hardware and software registry — ${all.length} assets.',
            trailing: FilledButton.icon(
              onPressed: () => context.showSnack('Asset registration coming soon.'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Register asset'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search by name, tag, serial, or user…',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.colors.outline),
                  ),
                  child: DropdownButton<AssetCategory?>(
                    value: _category,
                    hint: const Text('All categories', style: TextStyle(fontSize: 13)),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                    isDense: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All categories')),
                      for (final c in AssetCategory.values)
                        DropdownMenuItem(value: c, child: Text(c.label)),
                    ],
                    onChanged: (v) => setState(() => _category = v),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.colors.outline),
                  ),
                  child: DropdownButton<AssetStatus?>(
                    value: _status,
                    hint: const Text('All statuses', style: TextStyle(fontSize: 13)),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                    isDense: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All statuses')),
                      for (final s in AssetStatus.values)
                        DropdownMenuItem(value: s, child: Text(s.label)),
                    ],
                    onChanged: (v) => setState(() => _status = v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${assets.length} of ${all.length} assets',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: assets.isEmpty
                ? const EmptyState(
                    icon: Icons.inventory_2_rounded,
                    title: 'No assets match',
                    message: 'Try clearing some filters.',
                  )
                : isDesktop
                    ? _DesktopTable(assets: assets)
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: assets.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _AssetRow(asset: assets[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _DesktopTable extends StatelessWidget {
  final List<Asset> assets;
  const _DesktopTable({required this.assets});

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
          Expanded(
            child: ListView.builder(
              itemCount: assets.length,
              itemBuilder: (_, i) => _AssetRow(asset: assets[i], desktop: true)
                  .animate(delay: (i * 18).ms)
                  .fadeIn(duration: 180.ms),
            ),
          ),
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
          const SizedBox(width: 40),
          Expanded(flex: 4, child: Text('ASSET', style: s)),
          Expanded(flex: 2, child: Text('TAG', style: s)),
          Expanded(flex: 3, child: Text('ASSIGNED TO', style: s)),
          Expanded(flex: 2, child: Text('LOCATION', style: s)),
          Expanded(flex: 2, child: Text('STATUS', style: s)),
          Expanded(flex: 2, child: Text('WARRANTY', style: s)),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _AssetRow extends StatelessWidget {
  final Asset asset;
  final bool desktop;
  const _AssetRow({required this.asset, this.desktop = false});

  @override
  Widget build(BuildContext context) {
    final warrantyExpired = asset.warrantyUntil.isBefore(DateTime.now());

    if (!desktop) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(AppRoutes.assetDetailFor(asset.id)),
        child: Container(
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.colors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(asset.category.icon, color: context.colors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(asset.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(asset.tag,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.colors.onSurface.withOpacity(0.6),
                            )),
                      ],
                    ),
                  ),
                  _StatusChip(status: asset.status),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                children: [
                  _meta(context, Icons.person_rounded, asset.currentUser),
                  _meta(context, Icons.place_rounded, asset.location),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => context.go(AppRoutes.assetDetailFor(asset.id)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.colors.outline)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(asset.category.icon, color: context.colors.primary, size: 16),
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
                    Text(asset.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(asset.model,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.colors.onSurface.withOpacity(0.55),
                        )),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(asset.tag,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
            ),
            Expanded(
              flex: 3,
              child: Text(asset.currentUser,
                  style: const TextStyle(fontSize: 12.5),
                  overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: Text(asset.location,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.colors.onSurface.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis),
            ),
            Expanded(flex: 2, child: _StatusChip(status: asset.status)),
            Expanded(
              flex: 2,
              child: Text(
                warrantyExpired ? 'Expired' : Formatters.shortDate(asset.warrantyUntil),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: warrantyExpired
                      ? Theme.of(context).colorScheme.error
                      : context.colors.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: context.colors.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  Widget _meta(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: context.colors.onSurface.withOpacity(0.55)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
              fontSize: 12,
              color: context.colors.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AssetStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: status.color.withOpacity(0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: status.color,
        ),
      ),
    );
  }
}
