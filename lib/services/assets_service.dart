import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/storage/local_cache_service.dart';
import '../models/asset.dart';

class AssetsService {
  AssetsService._();
  static final AssetsService instance = AssetsService._();

  final _dio = ApiClient.instance.dio;
  static const _cacheKey = 'assets:all';

  Future<List<Asset>> getAssets() async {
    try {
      final res = await _dio.get(ApiEndpoints.assets, queryParameters: {'limit': 200});
      final data = res.data['data'] as List;
      await LocalCacheService.instance.putJsonWithTimestamp(_cacheKey, data);
      return data.map((a) => Asset.fromJson(a as Map<String, dynamic>)).toList();
    } catch (e) {
      final cached = LocalCacheService.instance.getJson(_cacheKey) as List?;
      if (cached != null) {
        return cached.map((a) => Asset.fromJson(a as Map<String, dynamic>)).toList();
      }
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<Asset> getAssetById(String id) async {
    try {
      final res = await _dio.get(ApiEndpoints.asset(id));
      return Asset.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
