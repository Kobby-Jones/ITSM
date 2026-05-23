// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/kb_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/section_header.dart';

class KbManagementScreen extends ConsumerWidget {
  const KbManagementScreen({super.key});

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
            subtitle: '${articles.length} articles published.',
            trailing: FilledButton.icon(
              onPressed: () => context.showSnack('Editor coming soon.'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New article'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
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
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            tooltip: 'Edit',
                            onPressed: () => context.showSnack('Editor coming soon.'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert_rounded, size: 16),
                            tooltip: 'More',
                            onPressed: () => context.showSnack('Article options coming soon.'),
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
