import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/asset.dart';
import '../features/assets/mock_asset_data.dart';

final assetsProvider = Provider<List<Asset>>((ref) => MockAssetData.generate());

Asset? assetByIdFrom(List<Asset> all, String id) {
  for (final a in all) {
    if (a.id == id || a.tag == id) return a;
  }
  return null;
}
