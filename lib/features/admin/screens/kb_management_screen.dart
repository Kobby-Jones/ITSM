// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/kb_article.dart';
import '../../../providers/kb_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/kb_service.dart';
import '../../../shared/widgets/section_header.dart';

class KbManagementScreen extends ConsumerWidget {
  const KbManagementScreen({super.key});

  Future<void> _deleteArticle(BuildContext context, WidgetRef ref, KbArticle article) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete article'),
        content: Text('Delete "${article.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await KbService.instance.deleteArticle(article.id);
      await ref.read(kbControllerProvider.notifier).refresh();
      if (context.mounted) context.showSnack('Article deleted.');
    } catch (e) {
      if (context.mounted) context.showSnack('Failed: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(kbArticlesProvider);
    final isDesktop = Responsive.isDesktop(context);

    return Padding(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Knowledge base management',
            subtitle: '${articles.length} articles.',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: articles.isEmpty
                ? const Center(child: Text('No articles yet.'))
                : Container(
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.outline),
                    ),
                    child: ListView.builder(
                      itemCount: articles.length,
                      itemBuilder: (_, i) {
                        final a = articles[i];
                        return InkWell(
                          onTap: () => context.go(AppRoutes.kbArticleFor(a.id)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: i == articles.length - 1
                                      ? Colors.transparent
                                      : context.colors.outline,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: context.colors.primary.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(a.category.icon,
                                      color: context.colors.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(a.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700, fontSize: 13.5)),
                                      Text(a.summary,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.colors.onSurface.withOpacity(0.6),
                                          )),
                                    ],
                                  ),
                                ),
                                if (isDesktop) ...[
                                  Expanded(
                                    flex: 2,
                                    child: Text(a.category.label,
                                        style: const TextStyle(
                                            fontSize: 12, fontWeight: FontWeight.w500)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Updated ${Formatters.relativeTime(a.updatedAt)}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: context.colors.onSurface.withOpacity(0.6)),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(Icons.visibility_rounded,
                                            size: 13,
                                            color: context.colors.onSurface.withOpacity(0.5)),
                                        const SizedBox(width: 4),
                                        Text('${a.views}',
                                            style: const TextStyle(
                                                fontSize: 12, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, size: 16),
                                  tooltip: 'Actions',
                                  onSelected: (v) {
                                    if (v == 'view') {
                                      context.go(AppRoutes.kbArticleFor(a.id));
                                    } else if (v == 'delete') {
                                      _deleteArticle(context, ref, a);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'view', child: Text('View')),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
