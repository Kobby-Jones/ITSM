import 'package:flutter/material.dart';
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

class KbArticleScreen extends ConsumerStatefulWidget {
  final String articleId;
  const KbArticleScreen({super.key, required this.articleId});

  @override
  ConsumerState<KbArticleScreen> createState() => _KbArticleScreenState();
}

class _KbArticleScreenState extends ConsumerState<KbArticleScreen> {
  bool? _voted; // null = not voted, true = helpful, false = not helpful

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(kbArticlesProvider);
    final article = kbArticleByIdFrom(all, widget.articleId);
    if (article == null) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Article not found',
        message: 'We couldn\'t find article "${widget.articleId}".',
        actionLabel: 'Back to KB',
        onAction: () => context.go(AppRoutes.knowledgeBase),
      );
    }
    final isDesktop = Responsive.isDesktop(context);

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.go(AppRoutes.knowledgeBase),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(article.category.icon, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          article.category.label,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                article.title,
                style: context.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Text(
                article.summary,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _meta(context, Icons.person_rounded, article.author),
                  const SizedBox(width: 16),
                  _meta(context, Icons.schedule_rounded, '${article.readMinutes} min read'),
                  const SizedBox(width: 16),
                  _meta(context, Icons.update_rounded,
                      'Updated ${Formatters.relativeTime(article.updatedAt)}'),
                  const SizedBox(width: 16),
                  _meta(context, Icons.visibility_rounded, '${article.views} views'),
                ],
              ),
              const SizedBox(height: 24),
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _Body(content: article.content)),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: _Sidebar(article: article, all: all)),
                      ],
                    )
                  : Column(
                      children: [
                        _Body(content: article.content),
                        const SizedBox(height: 16),
                        _Sidebar(article: article, all: all),
                      ],
                    ),
              const SizedBox(height: 16),
              _Helpful(
                article: article,
                voted: _voted,
                onVote: (v) {
                  setState(() => _voted = v);
                  context.showSnack(v ? 'Marked helpful — thanks!' : 'Thanks for the feedback.');
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.colors.onSurface.withOpacity(0.55)),
        const SizedBox(width: 5),
        Text(text,
            style: TextStyle(
              fontSize: 12.5,
              color: context.colors.onSurface.withOpacity(0.65),
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  final String content;
  const _Body({required this.content});

  @override
  Widget build(BuildContext context) {
    final paras = content.split('\n');
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in paras) _renderLine(context, p),
        ],
      ),
    );
  }

  Widget _renderLine(BuildContext context, String line) {
    if (line.trim().isEmpty) return const SizedBox(height: 8);

    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          line.substring(3),
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2),
        ),
      );
    }

    if (line.startsWith('- ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: context.colors.onSurface.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _styled(line.substring(2))),
          ],
        ),
      );
    }

    final m = RegExp(r'^(\d+)\. (.*)$').firstMatch(line);
    if (m != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '${m.group(1)}.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.colors.primary,
                ),
              ),
            ),
            Expanded(child: _styled(m.group(2)!)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _styled(line),
    );
  }

  Widget _styled(String text) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'`([^`]+)`');
    int last = 0;
    for (final m in regex.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(WidgetSpan(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFF111827).withOpacity(0.08),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            m.group(1)!,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(
      TextSpan(children: spans),
      style: const TextStyle(fontSize: 14, height: 1.7),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final KbArticle article;
  final List<KbArticle> all;
  const _Sidebar({required this.article, required this.all});

  @override
  Widget build(BuildContext context) {
    final related = <KbArticle>[];
    for (final id in article.relatedArticles) {
      for (final a in all) {
        if (a.id == id) {
          related.add(a);
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (article.tags.isNotEmpty)
          CardSection(
            title: 'Tags',
            titleIcon: Icons.label_rounded,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in article.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: context.colors.outline),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: context.colors.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (related.isNotEmpty) ...[
          const SizedBox(height: 16),
          CardSection(
            title: 'Related articles',
            titleIcon: Icons.article_outlined,
            child: Column(
              children: [
                for (final r in related)
                  InkWell(
                    onTap: () => context.go(AppRoutes.kbArticleFor(r.id)),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(r.category.icon, size: 14, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 11, color: context.colors.onSurface.withOpacity(0.4)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Helpful extends StatelessWidget {
  final KbArticle article;
  final bool? voted;
  final ValueChanged<bool> onVote;
  const _Helpful({required this.article, required this.voted, required this.onVote});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Was this article helpful?',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '${article.helpfulVotes} of ${article.views} found this helpful.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.colors.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: voted == null ? () => onVote(true) : null,
            icon: Icon(Icons.thumb_up_rounded,
                size: 16, color: voted == true ? AppColors.success : null),
            label: Text(voted == true ? 'Marked helpful' : 'Yes, helpful'),
            style: OutlinedButton.styleFrom(
              backgroundColor: voted == true ? AppColors.success.withOpacity(0.10) : null,
              side: BorderSide(
                color: voted == true ? AppColors.success : context.colors.outline,
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: voted == null ? () => onVote(false) : null,
            icon: Icon(Icons.thumb_down_rounded,
                size: 16, color: voted == false ? AppColors.danger : null),
            label: const Text('Not really'),
            style: OutlinedButton.styleFrom(
              backgroundColor: voted == false ? AppColors.danger.withOpacity(0.10) : null,
            ),
          ),
        ],
      ),
    );
  }
}
