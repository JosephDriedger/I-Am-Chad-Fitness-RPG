import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/quests.dart';
import 'package:i_am_chad/domain/rewards.dart';
import 'package:i_am_chad/domain/workout.dart';

// Thursday 22 October 2026. This week began on Monday the 19th.
final _now = DateTime(2026, 10, 22, 10);

WorkoutEntry _on(DateTime d) => WorkoutEntry(activityId: 'walking', performedAt: DateTime(d.year, d.month, d.day, 9), durationSeconds: 600);

/// One walk on each of the first [days] days of the week starting on [monday].
List<WorkoutEntry> _week(DateTime monday, int days) => [
      for (var i = 0; i < days; i++) _on(DateTime(monday.year, monday.month, monday.day + i)),
    ];

DateTime _monday(int weeksAgo) => DateTime(2026, 10, 19 - 7 * weeksAgo);

const _hero = HeroProfile(
  name: 'Ada',
  appearanceStyle: 0,
  appearanceColor: 0,
  experience: ExperienceLevel.returning,
  preferredCategories: {},
  hasDumbbells: false,
);

void main() {
  group('usualDays', () {
    test('is the middle of the last complete weeks', () {
      final entries = [..._week(_monday(1), 4), ..._week(_monday(2), 3), ..._week(_monday(3), 3), ..._week(_monday(4), 5)];
      expect(PersonalBaseline.usualDays(now: _now, entries: entries), 4, reason: 'the middle of 3, 3, 4, 5 is 3.5, which rounds up');
    });

    test('one unusual week does not move it', () {
      final entries = [..._week(_monday(1), 2), ..._week(_monday(2), 7), ..._week(_monday(3), 2), ..._week(_monday(4), 2)];
      expect(PersonalBaseline.usualDays(now: _now, entries: entries), 2);
    });

    test('this week is not counted, so a week in progress cannot lower it', () {
      final entries = [..._week(_monday(1), 3), ..._week(_monday(2), 3), ..._week(_monday(3), 3), ..._week(_monday(0), 1)];
      expect(PersonalBaseline.usualDays(now: _now, entries: entries), 3);
    });

    test('a quiet week counts as zero, which is a rest and not a mark against anyone', () {
      final entries = [..._week(_monday(1), 0), ..._week(_monday(2), 0), ..._week(_monday(3), 3), ..._week(_monday(4), 3)];
      expect(PersonalBaseline.usualDays(now: _now, entries: entries), 2);
    });

    test('needs three complete weeks since the first workout, and says nothing before that', () {
      expect(PersonalBaseline.usualDays(now: _now, entries: const []), isNull);
      expect(PersonalBaseline.usualDays(now: _now, entries: [..._week(_monday(1), 3), ..._week(_monday(2), 3)]), isNull);
      expect(PersonalBaseline.usualDays(now: _now, entries: [..._week(_monday(1), 3), ..._week(_monday(2), 3), ..._week(_monday(3), 3)]), 3);
    });

    test('weeks before the first workout are not counted as quiet ones', () {
      // Three weeks of history, all of them busy: the weeks before the player began are not zeros.
      final entries = [..._week(_monday(1), 4), ..._week(_monday(2), 4), ..._week(_monday(3), 4)];
      expect(PersonalBaseline.usualDays(now: _now, entries: entries), 4);
    });

    test('back-dated entries are not part of a usual week, as for every other reward', () {
      final late = [
        for (var w = 1; w <= 4; w++)
          for (var i = 0; i < 5; i++)
            WorkoutEntry(
              activityId: 'walking',
              performedAt: DateTime(2026, 10, 19 - 7 * w + i, 9),
              loggedAt: DateTime(2026, 10, 22),
              durationSeconds: 600,
            ),
      ];
      expect(PersonalBaseline.usualDays(now: _now, entries: late), isNull);
    });
  });

  group('the suggestion', () {
    test('uses the experience level until there is history', () {
      final s = PersonalBaseline.suggest(level: ExperienceLevel.regular, now: _now, entries: const []);
      expect(s.days, ExperienceLevel.regular.weeklyDaysGoal);
      expect(s.fromHistory, isFalse);
    });

    test('follows what the player actually does, down as well as up, within reason', () {
      List<WorkoutEntry> weeks(int d) => [for (var w = 1; w <= 4; w++) ..._week(_monday(w), d)];
      final s = PersonalBaseline.suggest(level: ExperienceLevel.regular, now: _now, entries: weeks(2));
      expect(s.days, 2, reason: 'a regular who has been doing two days is not told four');
      expect(s.fromHistory, isTrue);
      expect(PersonalBaseline.suggest(level: ExperienceLevel.starting, now: _now, entries: weeks(4)).days, 4);
    });

    test('never asks for more than five days, because rest days are part of the plan', () {
      List<WorkoutEntry> weeks(int d) => [for (var w = 1; w <= 4; w++) ..._week(_monday(w), d)];
      expect(PersonalBaseline.suggest(level: ExperienceLevel.regular, now: _now, entries: weeks(7)).days, PersonalBaseline.maxSuggested);
    });

    test('never suggests zero, even after a long quiet spell', () {
      final entries = [..._week(_monday(4), 3), ..._week(_monday(5), 3)];
      // Weeks 1 to 3 ago are quiet, and the first workout was five weeks ago.
      final s = PersonalBaseline.suggest(level: ExperienceLevel.returning, now: _now, entries: entries);
      expect(s.days, greaterThanOrEqualTo(HeroProfile.minWeeklyGoal));
      expect(s.fromHistory, isTrue);
    });
  });

  group('the goal that is used', () {
    List<WorkoutEntry> steady(int d) => [for (var w = 1; w <= 4; w++) ..._week(_monday(w), d)];

    test('the player\'s own choice always wins', () {
      expect(QuestBoard.goalTarget(hero: _hero.copyWith(weeklyGoalDays: 6), now: _now, entries: steady(2)), 6);
    });

    test('otherwise it is their usual week, and with no history the experience level', () {
      expect(QuestBoard.goalTarget(hero: _hero, now: _now, entries: steady(2)), 2);
      expect(QuestBoard.goalTarget(hero: _hero, now: _now, entries: const []), ExperienceLevel.returning.weeklyDaysGoal);
    });
  });

  test('rewards are not touched: the same workouts earn the same with or without a history', () {
    const rules = RewardRules.current;
    final today = [_on(_now)];
    final before = rules.rewardForDay(today);
    // The baseline only ever reads the journal; it has no way into the reward rules.
    PersonalBaseline.suggest(level: ExperienceLevel.regular, now: _now, entries: [for (var w = 1; w <= 4; w++) ..._week(_monday(w), 5)]);
    expect(rules.rewardForDay(today).xp, before.xp);
    expect(rules.rewardForDay(today).energy, before.energy);
  });
}
