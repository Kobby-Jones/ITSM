import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/asset.dart';
import '../services/assets_service.dart';

enum LoadState { loading, loaded, error }

class AssetsController extends StateNotifier<List<Asset>> {
  AssetsController() : super(const []) {
    load();
  }

  LoadState loadState = LoadState.loading;

  Future<void> load() async {
    loadState = LoadState.loading;
    try {
      state = await AssetsService.instance.getAssets();
      loadState = LoadState.loaded;
    } catch (_) {
      loadState = LoadState.error;
    }
  }

  Future<void> refresh() => load();
}

final assetsControllerProvider =
    StateNotifierProvider<AssetsController, List<Asset>>((ref) => AssetsController());

/// Kept for backwards compatibility with screens that just want the list
/// (mirrors the old `Provider<List<Asset>>` shape).
final assetsProvider = Provider<List<Asset>>((ref) => ref.watch(assetsControllerProvider));

Asset? assetByIdFrom(List<Asset> all, String id) {
  for (final a in all) {
    if (a.id == id || a.tag == id) return a;
  }
  return null;
}
