import 'package:flutter/material.dart';

enum KbCategory {
  gettingStarted('Getting Started', Icons.rocket_launch_rounded),
  troubleshooting('Troubleshooting', Icons.build_rounded),
  network('Network', Icons.wifi_rounded),
  email('Email & Comms', Icons.mail_rounded),
  security('Security', Icons.shield_rounded),
  hardware('Hardware', Icons.computer_rounded),
  software('Software', Icons.apps_rounded);

  final String label;
  final IconData icon;
  const KbCategory(this.label, this.icon);
}

class KbArticle {
  final String id;
  final String title;
  final String summary;
  final String content;
  final KbCategory category;
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
    required this.tags,
    required this.author,
    required this.updatedAt,
    required this.views,
    required this.helpfulVotes,
    required this.relatedArticles,
    required this.readMinutes,
  });
}
