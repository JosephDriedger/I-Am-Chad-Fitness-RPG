/// A gentle look back at last week for the quest board. It only ever describes
/// the player's own week against their own goal: no comparison with other
/// people, with an ideal, or with an earlier week, and a quiet week is simply a
/// rest week. See docs/CONTENT_GUIDELINES.md before changing the words.
library;

import 'activity.dart';
import 'quests.dart';
import 'rewards.dart';
import 'workout.dart';

class WeekRecap {
  const WeekRecap({
    required this.start,
    required this.activeDays,
    required this.weekdays,
    required this.goalDays,
    required this.effortMinutes,
    required this.mostLogged,
  });

  /// Midnight starting that Monday-to-Sunday week.
  final DateTime start;

  /// Days with any logged movement that counts for rewards, as for the weekly goal.
  final int activeDays;

  /// Which weekdays (1 = Monday ... 7 = Sunday) were active.
  final Set<int> weekdays;
  final int goalDays;

  /// Raw effort minutes (before the daily limit), as the Journal shows them.
  final double effortMinutes;

  /// The activity logged most often that week and how many times, or null for a quiet week.
  final (ActivityType, int)? mostLogged;

  bool get quiet => activeDays == 0;
  bool get metGoal => activeDays >= goalDays;
  bool get beyondGoal => activeDays > goalDays;
}

class WeeklyRecap {
  const WeeklyRecap._();

  /// The week before the one containing [now], or null when the player has
  /// nothing logged from before this week (a brand-new player has no "last
  /// week" to look back on).
  static WeekRecap? lastWeek({
    required DateTime now,
    required Iterable<WorkoutEntry> entries,
    required int goalDays,
    RewardRules rules = RewardRules.current,
  }) {
    final (thisMonday, _) = QuestBoard.weekBounds(now);
    if (!entries.any((e) => e.performedAt.isBefore(thisMonday))) return null;

    // Built from the calendar date, not by subtracting 24 hours a few times, so a
    // clock change inside the week cannot move the edges.
    final lastMonday = DateTime(thisMonday.year, thisMonday.month, thisMonday.day - 7);
    final counted = [
      for (final e in entries)
        if (e.countsForRewards && !e.performedAt.isBefore(lastMonday) && e.performedAt.isBefore(thisMonday)) e,
    ];

    final days = {for (final e in counted) dayKey(e.performedAt)};
    var minutes = 0.0;
    final byActivity = <String, int>{};
    for (final e in counted) {
      minutes += rules.effortMinutes(e);
      byActivity[e.activityId] = (byActivity[e.activityId] ?? 0) + 1;
    }

    (ActivityType, int)? top;
    for (final entry in byActivity.entries) {
      final a = ActivityCatalog.byId(entry.key);
      if (a == null) continue;
      // The most logged wins; a tie goes to the one that sorts first, so it is stable.
      if (top == null || entry.value > top.$2 || (entry.value == top.$2 && a.id.compareTo(top.$1.id) < 0)) {
        top = (a, entry.value);
      }
    }

    return WeekRecap(
      start: lastMonday,
      activeDays: days.length,
      weekdays: {for (final e in counted) e.performedAt.toLocal().weekday},
      goalDays: goalDays,
      effortMinutes: minutes,
      mostLogged: top,
    );
  }

  static const _title = 'Last Week';

  static String get title => _title;

  static const _metGoal = <String>[
    'You reached your goal last week, and it showed. Well done.',
    'Goal reached last week. The chronicle noted it in its best handwriting.',
  ];

  static const _beyondGoal = <String>[
    'You went past your goal last week. Lovely, and rest is allowed to follow.',
    'More than your goal last week! Remember that rest days are training too.',
  ];

  static const _some = <String>[
    'You moved on {n} last week, and every one of them counts.',
    'That is {n} of movement last week. Each one went in the chronicle.',
  ];

  static const _quiet = <String>[
    'Last week was a rest week, and rest is training. Your place in the chronicle is kept.',
    'A quiet week is a perfectly good week. The guild kept your chair warm.',
  ];

  /// Chad's line for the week, chosen by [seed] so it does not flicker.
  static String chadLine(WeekRecap r, {int seed = 0}) {
    final pool = r.quiet
        ? _quiet
        : r.beyondGoal
            ? _beyondGoal
            : r.metGoal
                ? _metGoal
                : _some;
    final line = pool[seed.abs() % pool.length];
    return line.replaceAll('{n}', r.activeDays == 1 ? '1 day' : '${r.activeDays} days');
  }

  /// "3 of 4 Days" style summary of the week.
  static String activeLabel(WeekRecap r) => '${r.activeDays} of ${r.goalDays} ${r.goalDays == 1 ? 'Day' : 'Days'}';

  /// Every line a player can read, for tests. [WeekRecap]s with every outcome.
  static List<String> get words => [
        _title,
        ..._metGoal,
        ..._beyondGoal,
        ..._some.map((s) => s.replaceAll('{n}', '2 days')),
        ..._quiet,
      ];
}
