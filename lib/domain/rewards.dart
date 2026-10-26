/// Transparent, bounded reward rules. See docs/REWARD_RULES.md.
///
/// Workouts are converted to "effort minutes", the day's effort is passed
/// through a diminishing-returns curve, and XP / adventure energy are derived
/// from the credited minutes. Everything here is pure and deterministic.
library;

import 'activity.dart';
import 'workout.dart';

class RewardRules {
  const RewardRules({
    this.version = 1,
    this.minEffortPerEntry = 3,
    this.fullValueMinutes = 20,
    this.halfValueMinutes = 20,
    this.xpPerCreditedMinute = 4,
    this.minutesPerEnergy = 5,
    this.restAllowancePerExtraSetSeconds = 45,
    this.maxFlooredEntriesPerDay,
  });

  static const v1 = RewardRules();

  /// Version 2 keeps "showing up counts" for the first few short entries of a day,
  /// then counts further short ones at their real length, so a pile of tiny entries
  /// cannot fill the daily limit. Nothing else changed.
  static const v2 = RewardRules(version: 2, maxFlooredEntriesPerDay: 3);

  /// The rules new days are granted under.
  static const current = v2;

  /// Persisted with each day's grant so rebalancing never rewrites history.
  final int version;

  /// Showing up counts: any valid entry is worth at least this many minutes.
  final double minEffortPerEntry;

  /// The first [fullValueMinutes] of a day's effort are credited at 100%.
  final double fullValueMinutes;

  /// The next [halfValueMinutes] are credited at 50%. Beyond that, 0%.
  final double halfValueMinutes;

  final int xpPerCreditedMinute;
  final int minutesPerEnergy;
  final int restAllowancePerExtraSetSeconds;

  /// How many entries in one day the [minEffortPerEntry] minimum lifts, oldest
  /// first. Later short entries count for what they really were. Null means every
  /// entry is lifted (version 1).
  final int? maxFlooredEntriesPerDay;

  double get maxCreditedMinutes => fullValueMinutes + halfValueMinutes * 0.5;
  int get maxDailyXp => (maxCreditedMinutes * xpPerCreditedMinute).round();
  int get maxDailyEnergy => (maxCreditedMinutes / minutesPerEnergy).ceil();

  /// Effort minutes represented by one entry (before the daily curve).
  /// Variants, load and perceived effort deliberately do not matter: an easier
  /// version of an exercise earns exactly the same as a harder one.
  double effortMinutes(WorkoutEntry e) {
    final minutes = unflooredEffortMinutes(e);
    if (minutes <= 0) return 0;
    return minutes < minEffortPerEntry ? minEffortPerEntry : minutes;
  }

  /// What the entry is worth before the "showing up counts" minimum applies.
  /// The honesty check uses this to spot entries that are implausibly short.
  double unflooredEffortMinutes(WorkoutEntry e) {
    final a = e.activity;
    if (a == null || !e.hasMeasurement) return 0;

    if ((e.durationSeconds ?? 0) > 0) {
      var minutes = e.durationSeconds! / 60 * a.effortFactor;
      if (a.metrics.contains(Metric.sets) && (e.sets ?? 1) > 1) {
        // Timed holds (e.g. plank) record the total hold per set.
        minutes = minutes * (e.sets ?? 1);
      }
      return minutes;
    }
    if ((e.reps ?? 0) > 0) {
      final sets = (e.sets ?? 1).clamp(1, 20);
      final seconds = sets * e.reps! * a.secondsPerRep +
          (sets - 1) * restAllowancePerExtraSetSeconds;
      return seconds / 60 * a.effortFactor;
    }
    if ((e.distanceMeters ?? 0) > 0 && a.minutesPerKm != null) {
      return e.distanceMeters! / 1000 * a.minutesPerKm! * a.effortFactor;
    }
    return 0;
  }

  /// Total credited minutes for a day's raw effort, with diminishing returns.
  double creditedMinutes(double rawEffort) {
    if (rawEffort <= 0) return 0;
    final full = rawEffort < fullValueMinutes ? rawEffort : fullValueMinutes;
    final overFull = rawEffort - fullValueMinutes;
    final half = overFull <= 0
        ? 0.0
        : (overFull < halfValueMinutes ? overFull : halfValueMinutes);
    return full + half * 0.5;
  }

  /// Reward for one local day, given every entry logged that day.
  DayReward rewardForDay(Iterable<WorkoutEntry> entries) {
    var raw = 0.0;
    var lifted = 0;
    var unlifted = 0;
    // Oldest first, so the minimum goes to the entries done first.
    final counted = [
      for (final e in entries)
        // Back-dated workouts are for the journal only.
        if (e.countsForRewards) e,
    ]..sort((a, b) {
        final byTime = a.performedAt.compareTo(b.performedAt);
        return byTime != 0 ? byTime : (a.id ?? 0).compareTo(b.id ?? 0);
      });
    for (final e in counted) {
      final real = unflooredEffortMinutes(e);
      if (real <= 0) continue;
      if (real >= minEffortPerEntry) {
        raw += real;
      } else if (maxFlooredEntriesPerDay == null || lifted < maxFlooredEntriesPerDay!) {
        lifted++;
        raw += minEffortPerEntry;
      } else {
        unlifted++;
        raw += real;
      }
    }
    final credited = creditedMinutes(raw);
    final xp = (credited * xpPerCreditedMinute).round();
    final energy = credited <= 0 ? 0 : (credited / minutesPerEnergy).ceil();
    return DayReward(
      rawEffortMinutes: raw,
      creditedMinutes: credited,
      xp: xp,
      energy: energy,
      rulesVersion: version,
      capReached: raw >= fullValueMinutes + halfValueMinutes,
      shortEntriesAtRealLength: unlifted,
    );
  }

  /// Plain-language explanation shown after logging, so the player can see
  /// exactly why a workout earned what it did.
  String explain(DayReward r) {
    if (r.xp == 0) return 'Nothing to count yet.';
    final b = StringBuffer(
      'Today\'s activity counts as ${_fmt(r.rawEffortMinutes)} effort minutes. '
      '${_fmt(r.creditedMinutes)} of them are credited '
      '(${_fmt(r.rawEffortMinutes)} is ',
    );
    if (r.rawEffortMinutes <= fullValueMinutes) {
      b.write('within the full-value range).');
    } else if (!r.capReached) {
      b.write('past ${_fmt(fullValueMinutes)}, so the extra counts half).');
    } else {
      b.write('past today\'s limit, so the extra does not add rewards).');
    }
    if (r.capReached) {
      b.write(' You\'ve hit today\'s reward limit. Resting is part of training!');
    }
    if (r.shortEntriesAtRealLength > 0 && maxFlooredEntriesPerDay != null) {
      b.write(
        ' The first $maxFlooredEntriesPerDay short entries of a day count as ${_fmt(minEffortPerEntry)} minutes each; '
        'shorter ones after that count for their real length.',
      );
    }
    return b.toString();
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class DayReward {
  const DayReward({
    required this.rawEffortMinutes,
    required this.creditedMinutes,
    required this.xp,
    required this.energy,
    required this.rulesVersion,
    required this.capReached,
    this.shortEntriesAtRealLength = 0,
  });

  static const none = DayReward(
    rawEffortMinutes: 0,
    creditedMinutes: 0,
    xp: 0,
    energy: 0,
    rulesVersion: 0,
    capReached: false,
  );

  /// Short entries that were past the day's allowance for the minimum and so
  /// counted for what they really were.
  final int shortEntriesAtRealLength;

  final double rawEffortMinutes;
  final double creditedMinutes;
  final int xp;
  final int energy;
  final int rulesVersion;
  final bool capReached;
}
