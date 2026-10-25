/// What the journal says about one exercise over time: how many days it was
/// done, a few weeks of "how often" and, for lifts, how much was lifted in total.
/// Like the personal bests it is only for looking back on. It is worked out from
/// the journal each time, stores nothing, never changes a reward, and never sets
/// a target or compares the player with anyone else. A week with nothing in it is
/// shown as a rest, not a gap (docs/CONTENT_GUIDELINES.md).
library;

import 'records.dart';
import 'workout.dart';

/// One Monday-to-Sunday week of one exercise.
class ExerciseWeek {
  const ExerciseWeek({required this.start, required this.days, required this.liftedKg});

  /// The Monday this week starts on.
  final DateTime start;

  /// On how many different days of the week the exercise was done.
  final int days;

  /// Weight × reps × sets, added up, in kilograms. Zero when no load was logged.
  final double liftedKg;

  bool get rest => days == 0;
}

/// A line in the Journal's list of exercises.
class ExerciseSummary {
  const ExerciseSummary({required this.activityId, required this.days, required this.last});

  final String activityId;
  final int days;
  final DateTime last;
}

class ExerciseHistory {
  const ExerciseHistory({
    required this.activityId,
    required this.days,
    required this.entryCount,
    required this.first,
    required this.last,
    required this.weeks,
    required this.bests,
    required this.recent,
  });

  /// How many weeks "how often" looks back over.
  static const weeksShown = 8;

  /// How many of the latest entries are listed.
  static const recentShown = 5;

  final String activityId;

  /// On how many different days it was logged.
  final int days;
  final int entryCount;
  final DateTime? first;
  final DateTime? last;

  /// The latest [weeksShown] weeks, oldest first, ending with the current one.
  final List<ExerciseWeek> weeks;

  /// One mark per kind, in the order heaviest, most in a set, longest, farthest.
  final List<PersonalBest> bests;

  /// The latest entries, newest first.
  final List<WorkoutEntry> recent;

  bool get hasHistory => entryCount > 0;

  /// Some weight was logged for it, so a total lifted makes sense.
  bool get hasLoad => weeks.any((w) => w.liftedKg > 0);

  int get activeWeeks => weeks.where((w) => !w.rest).length;

  /// Kilograms lifted over the weeks shown.
  double get liftedKg => weeks.fold(0.0, (a, w) => a + w.liftedKg);

  static ExerciseHistory of(Iterable<WorkoutEntry> entries, String activityId, {required DateTime now}) {
    final mine = [
      for (final e in entries)
        if (e.activityId == activityId && e.hasMeasurement) e,
    ]..sort((a, b) => a.performedAt.compareTo(b.performedAt));

    final thisMonday = mondayOf(now);
    final starts = [
      for (var i = weeksShown - 1; i >= 0; i--) DateTime(thisMonday.year, thisMonday.month, thisMonday.day - 7 * i),
    ];
    final weeks = <ExerciseWeek>[];
    for (final start in starts) {
      final end = DateTime(start.year, start.month, start.day + 7);
      final inWeek = mine.where((e) {
        final d = startOfDay(e.performedAt);
        return !d.isBefore(start) && d.isBefore(end);
      }).toList();
      weeks.add(ExerciseWeek(
        start: start,
        days: {for (final e in inWeek) dayKey(e.performedAt)}.length,
        liftedKg: inWeek.fold(0.0, (a, e) => a + liftedBy(e)),
      ));
    }

    final marks = PersonalBests.of(mine)..sort((a, b) => a.kind.index.compareTo(b.kind.index));
    return ExerciseHistory(
      activityId: activityId,
      days: {for (final e in mine) dayKey(e.performedAt)}.length,
      entryCount: mine.length,
      first: mine.isEmpty ? null : mine.first.performedAt,
      last: mine.isEmpty ? null : mine.last.performedAt,
      weeks: weeks,
      bests: marks,
      recent: mine.reversed.take(recentShown).toList(),
    );
  }

  /// Every exercise in the journal, most recently done first, for the list that
  /// leads to each exercise's page.
  static List<ExerciseSummary> summaries(Iterable<WorkoutEntry> entries) {
    final days = <String, Set<String>>{};
    final last = <String, DateTime>{};
    for (final e in entries) {
      if (e.activity == null || !e.hasMeasurement) continue;
      days.putIfAbsent(e.activityId, () => {}).add(dayKey(e.performedAt));
      final held = last[e.activityId];
      if (held == null || e.performedAt.isAfter(held)) last[e.activityId] = e.performedAt;
    }
    return [
      for (final id in days.keys) ExerciseSummary(activityId: id, days: days[id]!.length, last: last[id]!),
    ]..sort((a, b) => b.last.compareTo(a.last));
  }

  /// Kilograms moved by one entry: load × reps × sets. Zero without a load or reps.
  static double liftedBy(WorkoutEntry e) {
    final load = e.loadKg ?? 0, reps = e.reps ?? 0;
    if (load <= 0 || reps <= 0) return 0;
    return load * reps * (e.sets ?? 1).clamp(1, 1000);
  }

  /// The Monday on or before [t], built from the date so a clock change cannot shift it.
  static DateTime mondayOf(DateTime t) {
    final d = startOfDay(t);
    return DateTime(d.year, d.month, d.day - (d.weekday - 1));
  }

  /// "1,250 kg" or "2,756 lb".
  static String describeLifted(double kg, {bool metric = true}) {
    final v = metric ? kg : kg * 2.2046226;
    final s = v.round().toString();
    final grouped = s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return '$grouped ${metric ? 'kg' : 'lb'}';
  }
}
