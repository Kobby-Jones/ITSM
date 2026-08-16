import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/storage/local_cache_service.dart';
import '../models/kb_article.dart';

class KbService {
  KbService._();
  static final KbService instance = KbService._();

  final _dio = ApiClient.instance.dio;
  static const _cacheKey = 'kb_articles:all';

  Future<List<KbArticle>> getArticles({String? search, String? category}) async {
    try {
      final res = await _dio.get(ApiEndpoints.kbArticles, queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
        'limit': 200,
      });
      final data = res.data['data'] as List;
      if (search == null && category == null) {
        await LocalCacheService.instance.putJsonWithTimestamp(_cacheKey, data);
      }
      return data.map((a) => KbArticle.fromJson(a as Map<String, dynamic>)).toList();
    } catch (e) {
      final cached = LocalCacheService.instance.getJson(_cacheKey) as List?;
      if (cached != null) {
        return cached.map((a) => KbArticle.fromJson(a as Map<String, dynamic>)).toList();
      }
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<KbArticle> getArticleById(String id) async {
    try {
      final res = await _dio.get(ApiEndpoints.kbArticle(id));
      return KbArticle.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  /// Backend expects `{ rating: 1-5, feedback? }`, not a boolean — map the
  /// simple "was this helpful" UI action onto a 5 (helpful) or 1 (not).
  Future<void> rate(String id, {required bool helpful, String? feedback}) async {
    try {
      await _dio.post(ApiEndpoints.kbRate(id), data: {
        'rating': helpful ? 5 : 1,
        if (feedback != null && feedback.isNotEmpty) 'feedback': feedback,
      });
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<KbArticle> createArticle({
    required String title,
    required String content,
    required String category,
    String? summary,
    List<String> tags = const [],
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.kbArticles, data: {
        'title': title,
        'content': content,
        'category': category,
        'summary': ?summary,
        if (tags.isNotEmpty) 'tags': tags,
      });
      return KbArticle.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> updateArticle(String id, Map<String, dynamic> data) async {
    try {
      await _dio.patch(ApiEndpoints.kbArticle(id), data: data);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> deleteArticle(String id) async {
    try {
      await _dio.delete(ApiEndpoints.kbArticle(id));
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
