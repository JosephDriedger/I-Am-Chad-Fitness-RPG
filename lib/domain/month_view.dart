/// A month at a glance: which days someone moved. Only ever a look back. A day
/// without movement is simply blank, never marked, counted or called missed, so
/// a quiet stretch reads as rest rather than as a gap to feel bad about
/// (docs/CONTENT_GUIDELINES.md). It never changes a reward and stores nothing.
library;

import 'workout.dart';

class MonthDay {
  const MonthDay({required this.date, required this.inMonth, required this.entries});

  final DateTime date;

  /// False for the few days of the neighbouring months that fill out the first and last weeks.
  final bool inMonth;

  /// What was logged that day, oldest first.
  final List<WorkoutEntry> entries;

  bool get active => entries.isNotEmpty;
}

class MonthView {
  const MonthView({required this.year, required this.month, required this.weeks});

  final int year;
  final int month;

  /// Weeks from Monday to Sunday, to match the weekly goal.
  final List<List<MonthDay>> weeks;

  Iterable<MonthDay> get days => weeks.expand((w) => w).where((d) => d.inMonth);

  /// Days of this month with anything logged.
  int get activeDays => days.where((d) => d.active).length;

  static MonthView of(Iterable<WorkoutEntry> entries, {required int year, required int month}) {
    final byDay = <String, List<WorkoutEntry>>{};
    for (final e in entries) {
      byDay.putIfAbsent(dayKey(e.performedAt), () => []).add(e);
    }
    for (final list in byDay.values) {
      list.sort((a, b) => a.performedAt.compareTo(b.performedAt));
    }
    final first = DateTime(year, month, 1);
    // Back to the Monday on or before the 1st. Built from the date, so a clock change cannot shift it.
    final start = DateTime(year, month, 1 - (first.weekday - 1));
    final lastDay = DateTime(year, month + 1, 0);
    final weeks = <List<MonthDay>>[];
    for (var w = 0;; w++) {
      final week = <MonthDay>[
        for (var d = 0; d < 7; d++)
          () {
            final date = DateTime(start.year, start.month, start.day + w * 7 + d);
            return MonthDay(date: date, inMonth: date.month == month && date.year == year, entries: byDay[dayKey(date)] ?? const []);
          }(),
      ];
      weeks.add(week);
      if (!week.last.date.isBefore(lastDay)) break;
    }
    return MonthView(year: year, month: month, weeks: weeks);
  }

  /// The earliest month with anything logged, for stopping the back arrow.
  static (int, int)? firstMonth(Iterable<WorkoutEntry> entries) {
    DateTime? first;
    for (final e in entries) {
      final t = e.performedAt.toLocal();
      if (first == null || t.isBefore(first)) first = t;
    }
    return first == null ? null : (first.year, first.month);
  }
}
