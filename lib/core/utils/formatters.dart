import 'package:intl/intl.dart';

class Formatters {
  static String date(DateTime d) => DateFormat('MMM d, yyyy').format(d);
  static String time(DateTime d) => DateFormat('h:mm a').format(d);
  static String dateTime(DateTime d) =>
      DateFormat('MMM d, yyyy • h:mm a').format(d);
  static String shortDate(DateTime d) => DateFormat('MMM d').format(d);

  static String relativeTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  static String countdown(Duration d) {
    if (d.isNegative) return 'Breached';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h >= 24) return '${(h / 24).floor()}d ${h % 24}h';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  static String percent(double v) => '${v.toStringAsFixed(0)}%';
  static String number(num n) => NumberFormat.decimalPattern().format(n);
  static String compact(num n) => NumberFormat.compact().format(n);
}
