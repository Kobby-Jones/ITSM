import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/asset.dart';
import '../../../models/kb_article.dart';
import '../../../models/ticket.dart';
import '../../../providers/assets_provider.dart';
import '../../../providers/kb_provider.dart';
import '../../../providers/tickets_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../theme/app_colors.dart';
import '../../tickets/widgets/priority_badge.dart';
import '../../tickets/widgets/ticket_status_chip.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final _focus = FocusNode();
  String _query = '';
  String _scope = 'All';

  static const _scopes = ['All', 'Tickets', 'Articles', 'Assets'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool _shouldInclude(String section) =>
      _scope == 'All' || _scope == section;

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(ticketsProvider);
    final articles = ref.watch(kbArticlesProvider);
    final assets = ref.watch(assetsProvider);

    final q = _query.trim().toLowerCase();
    final hasQuery = q.isNotEmpty;

    final ticketHits = !hasQuery || !_shouldInclude('Tickets')
        ? <Ticket>[]
        : tickets.where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.code.toLowerCase().contains(q) ||
            t.reporterName.toLowerCase().contains(q)).take(10).toList();

    final articleHits = !hasQuery || !_shouldInclude('Articles')
        ? <KbArticle>[]
        : articles.where((a) =>
            a.title.toLowerCase().contains(q) ||
            a.summary.toLowerCase().contains(q) ||
            a.tags.any((t) => t.toLowerCase().contains(q))).take(10).toList();

    final assetHits = !hasQuery || !_shouldInclude('Assets')
        ? <Asset>[]
        : assets.where((a) =>
            a.name.toLowerCase().contains(q) ||
            a.tag.toLowerCase().contains(q) ||
            a.serialNumber.toLowerCase().contains(q) ||
            a.currentUser.toLowerCase().contains(q)).take(10).toList();

    final totalHits = ticketHits.length + articleHits.length + assetHits.length;

    return Padding(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Search',
                subtitle: 'Find anything across tickets, knowledge base, and assets.',
              ),
              const SizedBox(height: 20),
              CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape): () {
                    if (_query.isEmpty) {
                      context.go(AppRoutes.home);
                    } else {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    }
                  },
                },
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _focus,
                  onChanged: (v) => setState(() => _query = v),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search tickets, articles, assets…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 22),
                    suffixIcon: _query.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: context.colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: context.colors.outline),
                              ),
                              child: Text(
                                'esc to clear',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: context.colors.onSurface.withOpacity(0.55),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final s in _scopes) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => setState(() => _scope = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _scope == s ? AppColors.primary : context.colors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _scope == s ? AppColors.primary : context.colors.outline,
                          ),
                        ),
                        child: Text(s,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _scope == s
                                  ? Colors.white
                                  : context.colors.onSurface.withOpacity(0.85),
                            )),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              if (hasQuery)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '$totalHits result${totalHits == 1 ? '' : 's'} for "$_query"',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface.withOpacity(0.65),
                    ),
                  ),
                ),
              Expanded(
                child: !hasQuery
                    ? _SuggestionsPane(
                        recentTickets: tickets.take(4).toList(),
                        recentArticles: articles.take(4).toList(),
                      )
                    : (totalHits == 0
                        ? const EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No results found',
                            message: 'Try different keywords or change the scope.',
                          )
                        : ListView(
                            padding: const EdgeInsets.only(bottom: 24),
                            children: [
                              if (ticketHits.isNotEmpty)
                                _ResultsGroup(
                                  title: 'Tickets',
                                  count: ticketHits.length,
                                  icon: Icons.confirmation_number_rounded,
                                  color: AppColors.primary,
                                  children: [
                                    for (var i = 0; i < ticketHits.length; i++)
                                      _TicketHit(ticket: ticketHits[i], query: q)
                                          .animate(delay: (i * 18).ms)
                                          .fadeIn(duration: 180.ms),
                                  ],
                                ),
                              if (articleHits.isNotEmpty)
                                _ResultsGroup(
                                  title: 'Knowledge base',
                                  count: articleHits.length,
                                  icon: Icons.menu_book_rounded,
                                  color: AppColors.info,
                                  children: [
                                    for (var i = 0; i < articleHits.length; i++)
                                      _ArticleHit(article: articleHits[i], query: q)
                                          .animate(delay: (i * 18).ms)
                                          .fadeIn(duration: 180.ms),
                                  ],
                                ),
                              if (assetHits.isNotEmpty)
                                _ResultsGroup(
                                  title: 'Assets',
                                  count: assetHits.length,
                                  icon: Icons.inventory_2_rounded,
                                  color: AppColors.warning,
                                  children: [
                                    for (var i = 0; i < assetHits.length; i++)
                                      _AssetHit(asset: assetHits[i], query: q)
                                          .animate(delay: (i * 18).ms)
                                          .fadeIn(duration: 180.ms),
                                  ],
                                ),
                            ],
                          )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultsGroup extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final List<Widget> children;
  const _ResultsGroup({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.outline),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _TicketHit extends StatelessWidget {
  final Ticket ticket;
  final String query;
  const _TicketHit({required this.ticket, required this.query});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.ticketDetailFor(ticket.id)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.colors.outline.withOpacity(0.5))),
        ),
        child: Row(
          children: [
            PriorityBadge(priority: ticket.priority, dense: true, showLabel: false),
            const SizedBox(width: 10),
            SizedBox(
              width: 80,
              child: Text(
                ticket.code,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: context.colors.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  HighlightedText(text: ticket.title, query: query, bold: true),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.person_rounded, size: 12, color: context.colors.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(ticket.reporterName,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: context.colors.onSurface.withOpacity(0.55),
                          )),
                      const SizedBox(width: 10),
                      Icon(Icons.schedule_rounded, size: 12, color: context.colors.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(Formatters.relativeTime(ticket.createdAt),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: context.colors.onSurface.withOpacity(0.55),
                          )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TicketStatusChip(status: ticket.status, dense: true),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 11, color: context.colors.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

class _ArticleHit extends StatelessWidget {
  final KbArticle article;
  final String query;
  const _ArticleHit({required this.article, required this.query});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.kbArticleFor(article.id)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.colors.outline.withOpacity(0.5))),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(article.category.icon, size: 16, color: AppColors.info),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  HighlightedText(text: article.title, query: query, bold: true),
                  const SizedBox(height: 2),
                  Text(
                    article.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('${article.readMinutes} min',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface.withOpacity(0.55),
                )),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 11, color: context.colors.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

class _AssetHit extends StatelessWidget {
  final Asset asset;
  final String query;
  const _AssetHit({required this.asset, required this.query});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.assetDetailFor(asset.id)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.colors.outline.withOpacity(0.5))),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(asset.category.icon, size: 16, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  HighlightedText(text: asset.name, query: query, bold: true),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(asset.tag,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            color: context.colors.onSurface.withOpacity(0.6),
                          )),
                      const SizedBox(width: 10),
                      Icon(Icons.person_rounded, size: 12,
                          color: context.colors.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(asset.currentUser,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.colors.onSurface.withOpacity(0.6),
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: asset.status.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                asset.status.label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: asset.status.color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 11, color: context.colors.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsPane extends StatelessWidget {
  final List<Ticket> recentTickets;
  final List<KbArticle> recentArticles;
  const _SuggestionsPane({
    required this.recentTickets,
    required this.recentArticles,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: context.colors.onSurface.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text('Try searching: "VPN", "scada", "P1 critical", "GHA-LT"',
                  style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurface.withOpacity(0.55))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (recentTickets.isNotEmpty) ...[
          Text('Recent tickets',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface.withOpacity(0.55),
              )),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.outline),
            ),
            child: Column(
              children: [
                for (var i = 0; i < recentTickets.length; i++)
                  InkWell(
                    onTap: () => context.go(AppRoutes.ticketDetailFor(recentTickets[i].id)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: i == recentTickets.length - 1
                            ? null
                            : Border(bottom: BorderSide(color: context.colors.outline.withOpacity(0.5))),
                      ),
                      child: Row(
                        children: [
                          PriorityBadge(priority: recentTickets[i].priority, dense: true, showLabel: false),
                          const SizedBox(width: 10),
                          Text(recentTickets[i].code,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                color: context.colors.onSurface.withOpacity(0.6),
                              )),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(recentTickets[i].title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
          const SizedBox(height: 16),
        ],
        if (recentArticles.isNotEmpty) ...[
          Text('Popular articles',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface.withOpacity(0.55),
              )),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.outline),
            ),
            child: Column(
              children: [
                for (var i = 0; i < recentArticles.length; i++)
                  InkWell(
                    onTap: () => context.go(AppRoutes.kbArticleFor(recentArticles[i].id)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: i == recentArticles.length - 1
                            ? null
                            : Border(bottom: BorderSide(color: context.colors.outline.withOpacity(0.5))),
                      ),
                      child: Row(
                        children: [
                          Icon(recentArticles[i].category.icon, size: 14, color: AppColors.info),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(recentArticles[i].title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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

/// Highlights matching characters within text using a yellow-ish accent.
class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final bool bold;
  const HighlightedText({super.key, required this.text, required this.query, this.bold = false});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ));
    }

    final lower = text.toLowerCase();
    final idx = lower.indexOf(query);
    if (idx < 0) {
      return Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ));
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: context.colors.onSurface,
        ),
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: TextStyle(
              backgroundColor: AppColors.warning.withOpacity(0.30),
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }
}
