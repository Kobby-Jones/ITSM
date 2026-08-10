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
