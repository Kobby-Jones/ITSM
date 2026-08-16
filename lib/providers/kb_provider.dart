import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/kb_article.dart';
import '../services/kb_service.dart';

class KbController extends StateNotifier<List<KbArticle>> {
  KbController() : super(const []) {
    load();
  }

  Future<void> load() async {
    try {
      state = await KbService.instance.getArticles();
    } catch (_) {
      // Keep whatever was last loaded (possibly empty on first run offline).
    }
  }

  Future<void> refresh() => load();

  /// Fetch a single article from the server by its id and merge it into
  /// the in-memory list so the detail screen gets full content.
  Future<KbArticle> fetchById(String id) async {
    final article = await KbService.instance.getArticleById(id);
    final exists = state.any((a) => a.id == id);
    if (exists) {
      state = [
        for (final a in state) a.id == id ? article : a,
      ];
    } else {
      state = [article, ...state];
    }
    return article;
  }

  Future<void> rate(String articleId, {required bool helpful}) async {
    try {
      await KbService.instance.rate(articleId, helpful: helpful);
    } catch (_) {
      // Best-effort; article view already reflects the tap locally if the
      // screen updates its own local vote-count state.
    }
  }
}

final kbControllerProvider =
    StateNotifierProvider<KbController, List<KbArticle>>((ref) => KbController());

/// Kept for backwards compatibility with screens expecting a plain list.
final kbArticlesProvider = Provider<List<KbArticle>>((ref) => ref.watch(kbControllerProvider));

KbArticle? kbArticleByIdFrom(List<KbArticle> all, String id) {
  for (final a in all) {
    if (a.id == id) return a;
  }
  return null;
}
