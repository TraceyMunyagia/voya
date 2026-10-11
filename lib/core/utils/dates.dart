import 'package:intl/intl.dart';

class Dates {
  /// `2026-12-01`: the format Postgres `date` columns expect.
  static String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Days from start to end counting both ends (same day = 1).
  static int dayCount(DateTime start, DateTime end) {
    final s = DateTime.utc(start.year, start.month, start.day);
    final e = DateTime.utc(end.year, end.month, end.day);
    return e.difference(s).inDays + 1;
  }

  /// `1–4 Dec 2026`, `28 Nov – 2 Dec 2026`, `30 Dec 2026 – 2 Jan 2027`, `1 Dec 2026`.
  static String range(DateTime start, DateTime end) {
    final day = DateFormat('d');
    final dayMonth = DateFormat('d MMM');
    final full = DateFormat('d MMM yyyy');

    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return full.format(start);
    }
    if (start.year == end.year && start.month == end.month) {
      return '${day.format(start)}–${full.format(end)}';
    }
    if (start.year == end.year) {
      return '${dayMonth.format(start)} – ${full.format(end)}';
    }
    return '${full.format(start)} – ${full.format(end)}';
  }
}
