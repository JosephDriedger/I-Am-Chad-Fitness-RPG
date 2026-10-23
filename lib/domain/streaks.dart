/// Streaks, built to fit the game's other promises: rest is part of training,
/// nothing is ever taken away, and rewards pay for consistency, not volume.
/// See docs/REWARD_RULES.md ("Streaks").
///
/// A streak counts the days you were active (any logged movement) in a row,
/// where "in a row" allows quiet days in between: up to [allowedRestDays] of
/// them. Miss more than that and the next active day starts a fresh run. The
/// best run is remembered, and rewards already claimed are never taken back.
library;

import 'hero.dart';
import 'workout.dart';

/// A one-time reward for reaching [days] active days in a row.
class StreakMilestone {
  const StreakMilestone(this.days, this.title, this.coins, this.xp);

  final int days;
  final String title;
  final int coins;
  final int xp;
}

/// Where a player stands.
class StreakStatus {
  const StreakStatus({
    required this.current,
    required this.best,
    required this.allowedRestDays,
    required this.next,
    required this.lapsed,
  });

  /// Active days in the current run. Zero when there is no run to speak of.
  final int current;

  /// The longest run ever.
  final int best;

  /// Quiet days in a row the streak can take without ending.
  final int allowedRestDays;

  /// The next reward to reach, or null if there is none left (there always is
  /// one: after a year the rewards simply repeat every 100 days).
  final StreakMilestone? next;

  /// True when the last run ended and a new one has not started yet, with a
  /// run worth remembering behind it. Used for a kind "fresh start" message.
  final bool lapsed;

  bool get hasStreak => current > 0;

  /// The first day of a new run, after a longer one ended. A good moment for
  /// a warm "fresh start" rather than anything about what was lost.
  bool get startedFresh => current == 1 && best > 1;

  /// Days left to the next reward.
  int get daysToNext => next == null ? 0 : next!.days - current;

  /// Progress from the previous milestone toward the next, 0 to 1.
  double get progressToNext {
    final n = next;
    if (n == null) return 1;
    final previous = StreakRules.milestoneBefore(n.days)?.days ?? 0;
    final span = n.days - previous;
    return span <= 0 ? 1 : ((current - previous) / span).clamp(0.0, 1.0);
  }
}

class StreakRules {
  const StreakRules._();

  /// How many quiet days in a row a streak survives, by experience. Matches the
  /// rhythm of each level's weekly goal, and always covers a weekend off.
  static int allowedRestDays(ExperienceLevel level) => switch (level) {
        ExperienceLevel.starting => 3,
        ExperienceLevel.returning => 2,
        ExperienceLevel.regular => 2,
      };

  /// Rewards for the first year. After that, a smaller repeating reward.
  static const milestones = <StreakMilestone>[
    StreakMilestone(3, 'Getting Started', 15, 20),
    StreakMilestone(5, 'On a Roll', 25, 30),
    StreakMilestone(7, 'A Heroic Week', 40, 50),
    StreakMilestone(10, 'Ten Strong', 50, 60),
    StreakMilestone(14, 'Fortnight of Might', 80, 100),
    StreakMilestone(21, 'Three Weeks Strong', 100, 120),
    StreakMilestone(30, 'Month of Might', 150, 200),
    StreakMilestone(45, 'Steady as Stone', 180, 240),
    StreakMilestone(60, 'Two Months Strong', 220, 300),
    StreakMilestone(90, 'Season of Strength', 300, 400),
    StreakMilestone(120, 'Four Months Strong', 350, 450),
    StreakMilestone(180, 'Half-Year Hero', 450, 600),
    StreakMilestone(270, 'Nine Months Strong', 600, 800),
    StreakMilestone(365, 'Year of the Hero', 800, 1000),
  ];

  static const _repeatEvery = 100;
  static const _repeating = StreakMilestone(0, 'Legendary Run', 500, 600);

  /// The reward for exactly [days], or null if that is not a milestone.
  static StreakMilestone? milestoneAt(int days) {
    for (final m in milestones) {
      if (m.days == days) return m;
    }
    final last = milestones.last.days;
    if (days > last && (days - last) % _repeatEvery == 0) {
      return StreakMilestone(days, _repeating.title, _repeating.coins, _repeating.xp);
    }
    return null;
  }

  /// The first milestone strictly after [days].
  static StreakMilestone nextAfter(int days) {
    for (final m in milestones) {
      if (m.days > days) return m;
    }
    final last = milestones.last.days;
    final steps = (days - last) ~/ _repeatEvery + 1;
    return milestoneAt(last + steps * _repeatEvery)!;
  }

  /// The last milestone strictly before [days], or null.
  static StreakMilestone? milestoneBefore(int days) {
    StreakMilestone? found;
    for (final m in milestones) {
      if (m.days < days) found = m;
    }
    final last = milestones.last.days;
    final repeats = days > last ? (days - last - 1) ~/ _repeatEvery : 0;
    return repeats > 0 ? milestoneAt(last + repeats * _repeatEvery) : found;
  }

  /// Milestones reached by a run of [current] days that are not in [claimed].
  /// Several can be due at once, for example after back-dating a workout.
  static List<StreakMilestone> due({required int current, required Set<int> claimed}) {
    final out = <StreakMilestone>[];
    for (final m in milestones) {
      if (m.days <= current && !claimed.contains(m.days)) out.add(m);
    }
    final last = milestones.last.days;
    for (var d = last + _repeatEvery; d <= current; d += _repeatEvery) {
      if (!claimed.contains(d)) out.add(milestoneAt(d)!);
    }
    return out;
  }

  static int _dayNumber(DateTime t) {
    final l = t.toLocal();
    return DateTime.utc(l.year, l.month, l.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }

  /// Works out the streak from every entry ever logged.
  static StreakStatus evaluate({
    required Iterable<WorkoutEntry> workouts,
    required DateTime today,
    required ExperienceLevel experience,
  }) {
    final rest = allowedRestDays(experience);
    final now = _dayNumber(today);
    final days = <int>{
      for (final w in workouts)
        if (w.hasMeasurement && w.countsForRewards && _dayNumber(w.performedAt) <= now) _dayNumber(w.performedAt),
    }.toList()
      ..sort();

    // Split into runs wherever the quiet stretch is longer than allowed.
    final runs = <int>[];
    var run = 0;
    int? previous;
    for (final d in days) {
      if (previous != null && d - previous > rest + 1) {
        runs.add(run);
        run = 0;
      }
      run++;
      previous = d;
    }
    if (run > 0) runs.add(run);

    final best = runs.fold(0, (a, b) => a > b ? a : b);
    final alive = previous != null && now - previous <= rest + 1;
    final current = alive ? runs.last : 0;
    return StreakStatus(
      current: current,
      best: best,
      allowedRestDays: rest,
      next: nextAfter(current),
      lapsed: !alive && best > 0,
    );
  }
}
