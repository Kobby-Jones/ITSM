import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kb_article.dart';
import '../features/knowledge_base/mock_kb_data.dart';

final kbArticlesProvider = Provider<List<KbArticle>>((ref) => MockKbData.generate());

KbArticle? kbArticleByIdFrom(List<KbArticle> all, String id) {
  for (final a in all) {
    if (a.id == id) return a;
  }
  return null;
}
