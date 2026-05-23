import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/kb_article.dart';
import '../../../providers/kb_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../theme/app_colors.dart';

class KbBrowseScreen extends ConsumerStatefulWidget {
  const KbBrowseScreen({super.key});

  @override
  ConsumerState<KbBrowseScreen> createState() => _KbBrowseScreenState();
}

class _KbBrowseScreenState extends ConsumerState<KbBrowseScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  KbCategory? _category;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(kbArticlesProvider);
    var articles = all;
    if (_category != null) articles = articles.where((a) => a.category == _category).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      articles = articles.where((a) =>
          a.title.toLowerCase().contains(q) ||
          a.summary.toLowerCase().contains(q) ||
          a.tags.any((t) => t.toLowerCase().contains(q))).toList();
    }
    final isDesktop = Responsive.isDesktop(context);

    return Padding(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Knowledge base',
            subtitle: 'Search articles, troubleshooting guides, and how-tos.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search articles…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: 'All',
                  icon: Icons.list_rounded,
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final c in KbCategory.values) ...[
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: c.label,
                    icon: c.icon,
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${articles.length} of ${all.length} articles',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: articles.isEmpty
                ? const EmptyState(
                    icon: Icons.menu_book_rounded,
                    title: 'No articles match',
                    message: 'Try clearing the filters or searching for something different.',
                  )
                : isDesktop
                    ? GridView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 460,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 200,
                        ),
                        itemCount: articles.length,
                        itemBuilder: (_, i) => _ArticleCard(article: articles[i])
                            .animate(delay: (i * 18).ms)
                            .fadeIn(duration: 200.ms),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: articles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ArticleCard(article: articles[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : context.colors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : context.colors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected
                    ? Colors.white
                    : context.colors.onSurface.withOpacity(0.65)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : context.colors.onSurface.withOpacity(0.85),
                )),
          ],
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final KbArticle article;
  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go(AppRoutes.kbArticleFor(article.id)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(article.category.icon,
                        color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    article.category.label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.schedule_rounded,
                      size: 12, color: context.colors.onSurface.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  Text(
                    '${article.readMinutes} min read',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14.5, height: 1.3),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  article.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.colors.onSurface.withOpacity(0.65),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.visibility_rounded,
                      size: 13, color: context.colors.onSurface.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  Text('${article.views}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurface.withOpacity(0.6),
                      )),
                  const SizedBox(width: 14),
                  Icon(Icons.thumb_up_rounded, size: 13, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text('${article.helpfulVotes}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurface.withOpacity(0.6),
                      )),
                  const Spacer(),
                  Text(
                    Formatters.relativeTime(article.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
