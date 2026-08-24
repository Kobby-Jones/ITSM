import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/ticket.dart';
import '../models/kb_article.dart';
import '../models/asset.dart';

class SearchResults {
  final List<Ticket> tickets;
  final List<KbArticle> articles;
  final List<Asset> assets;

  const SearchResults({
    this.tickets = const [],
    this.articles = const [],
    this.assets = const [],
  });

  int get total => tickets.length + articles.length + assets.length;
}

class SearchService {
  SearchService._();
  static final SearchService instance = SearchService._();

  final _dio = ApiClient.instance.dio;

  /// Calls `GET /search?q=...&scope=...` on the backend, which searches
  /// across tickets, KB articles, and assets simultaneously.
  Future<SearchResults> search(String query, {String scope = 'all'}) async {
    if (query.trim().isEmpty) return const SearchResults();

    try {
      final res = await _dio.get(ApiEndpoints.search, queryParameters: {
        'q': query.trim(),
        'scope': scope.toLowerCase(),
        'limit': 20,
      });

      final data = res.data['data'] as Map<String, dynamic>? ?? {};

      final ticketList = data['tickets'] as List? ?? [];
      final articleList = data['articles'] as List? ?? [];
      final assetList = data['assets'] as List? ?? [];

      return SearchResults(
        tickets: ticketList
            .map((t) => Ticket.fromJson(t as Map<String, dynamic>))
            .toList(),
        articles: articleList
            .map((a) => KbArticle.fromJson(a as Map<String, dynamic>))
            .toList(),
        assets: assetList
            .map((a) => Asset.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
