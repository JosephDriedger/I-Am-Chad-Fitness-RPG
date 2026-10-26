/// A single logged workout. This is the source of truth; game rewards are
/// derived from it and never write back to it.
library;

import 'activity.dart';

class WorkoutEntry {
  const WorkoutEntry({
    this.id,
    required this.activityId,
    required this.performedAt,
    this.variant,
    this.sets,
    this.reps,
    this.durationSeconds,
    this.distanceMeters,
    this.loadKg,
    this.perceivedEffort,
    this.notes,
    this.cameraCounted = false,
    this.loggedAt,
  });

  final int? id;
  final String activityId;
  final DateTime performedAt;
  final String? variant;
  final int? sets;

  /// Reps per set.
  final int? reps;
  final int? durationSeconds;
  final double? distanceMeters;
  final double? loadKg;

  /// Optional 1-5 rating. Recorded for the player's own insight; it never
  /// changes rewards (see docs/REWARD_RULES.md).
  final int? perceivedEffort;
  final String? notes;

  /// The reps were counted by the phone camera (see rep_counter.dart). Rewards
  /// are the same either way; this only marks the entry in the journal.
  final bool cameraCounted;

  /// When the workout was entered into the game. Null for entries from before
  /// this was recorded, which count as logged when they were performed.
  final DateTime? loggedAt;

  /// A workout can be logged late for the journal, but only earns rewards
  /// (XP, energy, streaks, quests, the weekly goal) if it was logged on the day
  /// it happened, or within [rewardGrace] after it, so a late-night session
  /// logged just after midnight still counts. See docs/REWARD_RULES.md.
  static const rewardGrace = Duration(hours: 6);

  bool get countsForRewards {
    final logged = loggedAt;
    if (logged == null) return true;
    // Dated in the future is never a real workout.
    if (performedAt.isAfter(logged.add(const Duration(minutes: 10)))) return false;
    if (dayKey(performedAt) == dayKey(logged)) return true;
    return logged.difference(performedAt) <= rewardGrace;
  }

  ActivityType? get activity => ActivityCatalog.byId(activityId);

  /// The words for the optional 1-5 "How did it feel?" rating, easiest first.
  static const feelLabels = ['Very Easy', 'Easy', 'Okay', 'Hard', 'Very Hard'];

  /// How the player said it felt, or null if they did not say.
  String? get feel {
    final p = perceivedEffort;
    return p == null || p < 1 || p > feelLabels.length ? null : feelLabels[p - 1];
  }

  /// Whether the query appears in the exercise's name, its variant or the note,
  /// ignoring case. An empty query matches everything. Only for finding things in
  /// the journal.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [activity?.name, variant, notes].any((t) => t != null && t.toLowerCase().contains(q));
  }

  /// True when the entry holds enough data to be worth saving.
  bool get hasMeasurement =>
      (durationSeconds ?? 0) > 0 ||
      (reps ?? 0) > 0 ||
      (distanceMeters ?? 0) > 0;

  WorkoutEntry copyWith({
    int? id,
    String? activityId,
    DateTime? performedAt,
    String? variant,
    int? sets,
    int? reps,
    int? durationSeconds,
    double? distanceMeters,
    double? loadKg,
    int? perceivedEffort,
    String? notes,
    bool? cameraCounted,
    DateTime? loggedAt,
  }) =>
      WorkoutEntry(
        id: id ?? this.id,
        activityId: activityId ?? this.activityId,
        performedAt: performedAt ?? this.performedAt,
        variant: variant ?? this.variant,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        loadKg: loadKg ?? this.loadKg,
        perceivedEffort: perceivedEffort ?? this.perceivedEffort,
        notes: notes ?? this.notes,
        cameraCounted: cameraCounted ?? this.cameraCounted,
        loggedAt: loggedAt ?? this.loggedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'activity': activityId,
        'performedAt': performedAt.toIso8601String(),
        'variant': variant,
        'sets': sets,
        'reps': reps,
        'durationSeconds': durationSeconds,
        'distanceMeters': distanceMeters,
        'loadKg': loadKg,
        'perceivedEffort': perceivedEffort,
        'notes': notes,
        'cameraCounted': cameraCounted,
        'loggedAt': loggedAt?.toIso8601String(),
        'countsForRewards': countsForRewards,
      };

  /// Short human summary, e.g. "2 × 8 · Wall" or "10 min · 1.2 km".
  String summary({bool metric = true}) {
    final parts = <String>[];
    if ((reps ?? 0) > 0) {
      parts.add('${sets ?? 1} × $reps');
    } else if ((sets ?? 0) > 0 && (durationSeconds ?? 0) > 0) {
      parts.add('${sets!} sets');
    }
    if ((durationSeconds ?? 0) > 0) {
      final m = durationSeconds! ~/ 60;
      final s = durationSeconds! % 60;
      parts.add(m > 0 ? (s > 0 ? '$m min $s s' : '$m min') : '$s s');
    }
    if ((distanceMeters ?? 0) > 0) {
      parts.add(metric
          ? '${(distanceMeters! / 1000).toStringAsFixed(2)} km'
          : '${(distanceMeters! / 1609.344).toStringAsFixed(2)} mi');
    }
    if ((loadKg ?? 0) > 0) {
      parts.add(metric
          ? '${_trim(loadKg!)} kg'
          : '${_trim(loadKg! * 2.2046226)} lb');
    }
    if (variant != null && variant!.isNotEmpty) parts.add(variant!);
    return parts.join(' · ');
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

/// Local calendar-day key (yyyy-MM-dd) used to group workouts and rewards.
String dayKey(DateTime t) {
  final l = t.toLocal();
  final m = l.month.toString().padLeft(2, '0');
  final d = l.day.toString().padLeft(2, '0');
  return '${l.year}-$m-$d';
}

DateTime startOfDay(DateTime t) {
  final l = t.toLocal();
  return DateTime(l.year, l.month, l.day);
}
