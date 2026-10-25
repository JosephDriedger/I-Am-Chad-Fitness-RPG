/// Personal bests: the player's own best marks, worked out from the journal.
///
/// Bests are only ever a thing to look back on. They never change a reward, so
/// nobody is nudged to lift heavier or push further than is right for them
/// (see docs/REWARD_RULES.md, "Things that deliberately do not change rewards").
library;

import 'workout.dart';

enum RecordKind {
  heaviest('Heaviest'),
  mostReps('Most in a Set'),
  longest('Longest'),
  farthest('Farthest');

  const RecordKind(this.label);
  final String label;
}

class PersonalBest {
  const PersonalBest({
    required this.activityId,
    required this.kind,
    required this.value,
    required this.achievedAt,
    this.reps,
  });

  final String activityId;
  final RecordKind kind;

  /// Kilograms, reps, seconds or metres, depending on [kind].
  final double value;
  final DateTime achievedAt;

  /// For a heaviest lift: the reps done at that weight, if they were logged.
  final int? reps;

  /// The mark in words, e.g. "40 kg × 8", "25 reps", "12 min 30 s", "5.20 km".
  String describe({bool metric = true}) => switch (kind) {
        RecordKind.heaviest => () {
            final w = metric ? '${_trim(value)} kg' : '${_trim(value * 2.2046226)} lb';
            return (reps ?? 0) > 0 ? '$w × $reps' : w;
          }(),
        RecordKind.mostReps => '${value.round()} reps',
        RecordKind.longest => _duration(value.round()),
        RecordKind.farthest => metric
            ? '${(value / 1000).toStringAsFixed(2)} km'
            : '${(value / 1609.344).toStringAsFixed(2)} mi',
      };

  static String _trim(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  static String _duration(int secs) {
    final m = secs ~/ 60, s = secs % 60;
    if (m == 0) return '$s s';
    return s == 0 ? '$m min' : '$m min $s s';
  }
}

class PersonalBests {
  const PersonalBests._();

  /// One mark per exercise and kind, newest first. A mark is only beaten by
  /// something strictly better, so a tie keeps the earlier one.
  static List<PersonalBest> of(Iterable<WorkoutEntry> entries) {
    final sorted = entries.where(_usable).toList()
      ..sort((a, b) => a.performedAt.compareTo(b.performedAt));
    final best = <String, PersonalBest>{};
    for (final e in sorted) {
      for (final candidate in _marksOf(e)) {
        final key = '${candidate.activityId}/${candidate.kind.name}';
        final held = best[key];
        if (held == null || candidate.value > held.value) best[key] = candidate;
      }
    }
    return best.values.toList()..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
  }

  /// The marks [entry] beats, for a "new personal best" note when it is saved.
  /// Only marks that already had a holder count, so the first time someone logs
  /// an exercise is not announced as a record. [before] is everything else in
  /// the journal; the entry itself is ignored if it is in there.
  static List<PersonalBest> brokenBy(WorkoutEntry entry, Iterable<WorkoutEntry> before) {
    if (!_usable(entry)) return const [];
    final others = before.where((o) => entry.id == null || o.id != entry.id);
    final held = {
      for (final b in of(others.where((o) => o.activityId == entry.activityId)))
        b.kind: b.value,
    };
    return [
      for (final m in _marksOf(entry))
        if (held[m.kind] != null && m.value > held[m.kind]!) m,
    ];
  }

  static bool _usable(WorkoutEntry e) => e.activity != null && e.hasMeasurement;

  static Iterable<PersonalBest> _marksOf(WorkoutEntry e) sync* {
    PersonalBest mark(RecordKind kind, double value, {int? reps}) => PersonalBest(
          activityId: e.activityId,
          kind: kind,
          value: value,
          achievedAt: e.performedAt,
          reps: reps,
        );
    if ((e.loadKg ?? 0) > 0) yield mark(RecordKind.heaviest, e.loadKg!, reps: e.reps);
    if ((e.reps ?? 0) > 0) yield mark(RecordKind.mostReps, e.reps!.toDouble());
    if ((e.durationSeconds ?? 0) > 0) yield mark(RecordKind.longest, e.durationSeconds!.toDouble());
    if ((e.distanceMeters ?? 0) > 0) yield mark(RecordKind.farthest, e.distanceMeters!);
  }
}

/// How one mark has moved over the days it was done, for a small "progress"
/// chart. One point per day (that day's best), oldest first, and only the latest
/// [maxPoints] so the line stays readable. Like the bests, it is derived from the
/// journal each time and never changes a reward. A line goes down as well as up,
/// because lighter days and rest weeks are part of getting stronger, so nothing
/// here compares the player with a target or with anyone else.
class MarkHistory {
  const MarkHistory(this.points);

  /// One point per day, oldest first.
  final List<PersonalBest> points;

  static const maxPoints = 24;

  static MarkHistory of(Iterable<WorkoutEntry> entries, {required String activityId, required RecordKind kind}) {
    final byDay = <String, PersonalBest>{};
    for (final e in entries) {
      if (e.activityId != activityId || !PersonalBests._usable(e)) continue;
      for (final m in PersonalBests._marksOf(e)) {
        if (m.kind != kind) continue;
        final key = dayKey(e.performedAt);
        final held = byDay[key];
        if (held == null || m.value > held.value) byDay[key] = m;
      }
    }
    final all = byDay.values.toList()..sort((a, b) => a.achievedAt.compareTo(b.achievedAt));
    return MarkHistory(all.length > maxPoints ? all.sublist(all.length - maxPoints) : all);
  }

  /// A line needs at least two days to be a line.
  bool get hasLine => points.length >= 2;

  PersonalBest? get first => points.isEmpty ? null : points.first;
  PersonalBest? get latest => points.isEmpty ? null : points.last;

  PersonalBest? get best {
    PersonalBest? top;
    for (final p in points) {
      if (top == null || p.value > top.value) top = p;
    }
    return top;
  }
}
