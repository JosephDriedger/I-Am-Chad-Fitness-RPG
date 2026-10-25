/// A friendly plausibility check on what the player logs. See
/// docs/REWARD_RULES.md ("Honest play").
///
/// The game cannot verify a workout, so this never blocks, never changes a
/// reward and never accuses: it only notices numbers that are unlikely to be
/// real (a pace nobody can hold, a rep count nobody can do, an entry far
/// shorter than the minimum it is paid as) and asks the player to check them.
library;

import 'rewards.dart';
import 'workout.dart';

enum HonestyConcern { impossiblePace, tooManyReps, veryQuick, manyTinyEntries }

class HonestyNote {
  const HonestyNote(this.concern, this.text);

  final HonestyConcern concern;
  final String text;
}

class HonestyCheck {
  const HonestyCheck({
    this.rules = RewardRules.current,
    this.quickSeconds = 20,
    this.tinySeconds = 60,
    this.tinyEntriesPerDay = 4,
    this.minPaceSeconds = 30,
  });

  final RewardRules rules;

  /// Under this much real effort an entry is "very quick".
  final int quickSeconds;

  /// Under this much real effort an entry counts as "tiny" for the day tally.
  final int tinySeconds;

  /// This many tiny entries in one day suggests the minimum is being farmed.
  final int tinyEntriesPerDay;

  /// Pace is only judged on entries at least this long.
  final int minPaceSeconds;

  /// Notes about [entry]; empty when nothing looks off. [sameDay] holds the
  /// other entries logged on the entry's day.
  List<HonestyNote> review(
    WorkoutEntry entry, {
    Iterable<WorkoutEntry> sameDay = const [],
    bool metric = true,
  }) {
    final a = entry.activity;
    if (a == null || !entry.hasMeasurement) return const [];
    final notes = <HonestyNote>[];

    final kmh = _speedKmh(entry);
    final fastest = a.plausibleKmh;
    if (kmh != null && fastest != null && kmh > fastest) {
      final shown = metric ? '${kmh.round()} km/h' : '${(kmh / 1.609344).round()} mph';
      notes.add(HonestyNote(
        HonestyConcern.impossiblePace,
        'That works out to $shown, which is quicker than almost anyone can '
        'keep up for ${a.name.toLowerCase()}. If the time or distance is a '
        'typo, fix it now.',
      ));
    }

    final perSet = a.plausibleRepsPerSet;
    if (perSet != null && (entry.reps ?? 0) > perSet) {
      notes.add(HonestyNote(
        HonestyConcern.tooManyReps,
        '${entry.reps} ${a.name.toLowerCase()} in one set is more than almost '
        'anyone can do. Did you mean to split them into several sets?',
      ));
    }

    final seconds = rules.unflooredEffortMinutes(entry) * 60;
    final tiny = seconds < tinySeconds;
    if (seconds > 0 && seconds < quickSeconds) {
      notes.add(HonestyNote(
        HonestyConcern.veryQuick,
        'That is under $quickSeconds seconds of effort. Every entry is paid as '
        'at least ${_fmt(rules.minEffortPerEntry)} minutes, so please only log '
        'what you really did.',
      ));
    }

    if (tiny) {
      final others = sameDay.where((o) =>
          (entry.id == null || o.id != entry.id) &&
          o.hasMeasurement &&
          rules.unflooredEffortMinutes(o) * 60 < tinySeconds);
      final count = others.length + 1;
      if (count >= tinyEntriesPerDay) {
        notes.add(HonestyNote(
          HonestyConcern.manyTinyEntries,
          'That is tiny entry number $count today. Log a whole workout as one '
          'entry (use sets) instead of lots of small ones.',
        ));
      }
    }
    return notes;
  }

  double? _speedKmh(WorkoutEntry e) {
    final secs = e.durationSeconds ?? 0;
    final metres = e.distanceMeters ?? 0;
    if (secs < minPaceSeconds || metres <= 0) return null;
    return metres / 1000 / (secs / 3600);
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}
