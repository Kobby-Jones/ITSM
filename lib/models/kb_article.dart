import 'package:flutter/material.dart';

enum KbCategory {
  gettingStarted('Getting Started', Icons.rocket_launch_rounded),
  troubleshooting('Troubleshooting', Icons.build_rounded),
  network('Network', Icons.wifi_rounded),
  email('Email & Comms', Icons.mail_rounded),
  security('Security', Icons.shield_rounded),
  hardware('Hardware', Icons.computer_rounded),
  software('Software', Icons.apps_rounded),
  general('General', Icons.folder_rounded);

  final String label;
  final IconData icon;
  const KbCategory(this.label, this.icon);

  /// The backend stores `category` as free text (not a fixed enum), so this
  /// does a best-effort keyword match onto the UI's closed set of
  /// categories, falling back to [general] for anything unrecognized. The
  /// original raw string from the API is preserved separately on
  /// [KbArticle.rawCategory] for exact round-tripping (e.g. when editing).
  static KbCategory fromApi(String? value) {
    final v = (value ?? '').toLowerCase();
    if (v.contains('start') || v.contains('onboard')) return KbCategory.gettingStarted;
    if (v.contains('trouble') || v.contains('fix') || v.contains('error')) {
      return KbCategory.troubleshooting;
    }
    if (v.contains('network') || v.contains('wifi') || v.contains('vpn')) return KbCategory.network;
    if (v.contains('mail') || v.contains('comm')) return KbCategory.email;
    if (v.contains('secur') || v.contains('password') || v.contains('access')) {
      return KbCategory.security;
    }
    if (v.contains('hardware') || v.contains('device') || v.contains('printer')) {
      return KbCategory.hardware;
    }
    if (v.contains('software') || v.contains('app')) return KbCategory.software;
    return KbCategory.general;
  }
}

class KbArticle {
  final String id;
  final String title;
  final String summary;
  final String content;
  final KbCategory category;
  /// Exact category string as stored on the backend (free text) — use this
  /// when sending updates back, so we don't clobber it with the UI bucket.
  final String rawCategory;
  final List<String> tags;
  final String author;
  final DateTime updatedAt;
  final int views;
  final int helpfulVotes;
  final List<String> relatedArticles;
  final int readMinutes;

  const KbArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.category,
    this.rawCategory = '',
    required this.tags,
    required this.author,
    required this.updatedAt,
    required this.views,
    required this.helpfulVotes,
    required this.relatedArticles,
    required this.readMinutes,
  });

  factory KbArticle.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final content = json['content'] as String? ?? '';
    final wordCount = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final rawCategory = json['category'] as String? ?? '';
    return KbArticle(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      content: content,
      category: KbCategory.fromApi(rawCategory),
      rawCategory: rawCategory,
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      author: author != null ? '${author['firstName'] ?? ''} ${author['lastName'] ?? ''}'.trim() : '',
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
      views: json['viewCount'] as int? ?? 0,
      helpfulVotes: json['helpfulCount'] as int? ?? 0,
      relatedArticles: (json['relatedTickets'] as List?)
              ?.map((r) => r['ticketId'] as String? ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      readMinutes: (wordCount / 200).ceil().clamp(1, 60),
    );
  }
}
