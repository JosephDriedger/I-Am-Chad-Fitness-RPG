import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/streaks.dart';
import 'package:i_am_chad/domain/workout.dart';

final _today = DateTime(2026, 10, 22, 10);

/// A workout [daysAgo] days before [_today].
WorkoutEntry _on(int daysAgo, {int seconds = 600}) => WorkoutEntry(
      activityId: 'walking',
      performedAt: DateTime(2026, 10, 22 - daysAgo, 18),
      durationSeconds: seconds,
    );

StreakStatus _eval(List<int> daysAgo, {ExperienceLevel level = ExperienceLevel.returning}) =>
    StreakRules.evaluate(
      workouts: [for (final d in daysAgo) _on(d)],
      today: _today,
      experience: level,
    );

void main() {
  test('with no workouts there is no streak and nothing to lose', () {
    final s = _eval([]);
    expect(s.current, 0);
    expect(s.best, 0);
    expect(s.hasStreak, isFalse);
    expect(s.lapsed, isFalse);
    expect(s.next!.days, 3);
  });

  test('consecutive days build a streak, and several workouts in a day count once', () {
    final s = StreakRules.evaluate(
      workouts: [_on(0), _on(0, seconds: 300), _on(1), _on(2)],
      today: _today,
      experience: ExperienceLevel.returning,
    );
    expect(s.current, 3);
    expect(s.best, 3);
  });

  test('rest days are built in: quiet days in between do not break it', () {
    // Returning allows 2 quiet days in a row (a weekend off).
    expect(_eval([0, 3, 6]).current, 3, reason: 'two quiet days between each');
    // Three quiet days breaks it for them...
    expect(_eval([0, 4]).current, 1);
    // ...but beginners get one more.
    expect(_eval([0, 4], level: ExperienceLevel.starting).current, 2);
    expect(_eval([0, 5], level: ExperienceLevel.starting).current, 1);
  });

  test('a weekend off never breaks a streak, at any level', () {
    // Friday active, Saturday and Sunday quiet, Monday active.
    for (final level in ExperienceLevel.values) {
      expect(_eval([0, 3], level: level).current, 2, reason: '$level');
    }
  });

  test('the streak is still alive today if you have not moved yet', () {
    expect(_eval([1, 2, 3]).current, 3);
    expect(_eval([2, 3, 4]).current, 3);
    expect(_eval([3, 4, 5]).current, 3, reason: 'two quiet days is still fine');
  });

  test('once the allowed rest is used up the run ends, kindly: best is remembered', () {
    final s = _eval([4, 5, 6, 7, 8]); // 5 active days, then 3 quiet days
    expect(s.current, 0);
    expect(s.best, 5);
    expect(s.lapsed, isTrue);
    expect(s.hasStreak, isFalse);
  });

  test('starting again after a lapse begins a fresh run without erasing the best', () {
    final s = _eval([0, 5, 6, 7, 8, 9]);
    expect(s.current, 1);
    expect(s.best, 5);
    expect(s.startedFresh, isTrue);
    expect(s.lapsed, isFalse);
  });

  test('the best run is the longest one anywhere in history', () {
    final s = _eval([0, 1, 20, 21, 22, 23, 24, 25, 40]);
    expect(s.current, 2);
    expect(s.best, 6);
  });

  test('entries without a measurement, or in the future, do not count', () {
    final s = StreakRules.evaluate(
      workouts: [
        _on(0),
        WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 22, 9)),
        WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 25), durationSeconds: 600),
      ],
      today: _today,
      experience: ExperienceLevel.returning,
    );
    expect(s.current, 1);
  });

  test('deleting a workout can shorten the streak, never below what is still true', () {
    expect(_eval([0, 1, 2]).current, 3);
    expect(_eval([0, 2]).current, 2);
  });

  test('daylight saving changes do not shift days', () {
    // Across a spring-forward weekend in the northern hemisphere.
    final s = StreakRules.evaluate(
      workouts: [
        for (final d in [8, 9, 10, 11]) WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 3, d, 23, 30), durationSeconds: 600),
      ],
      today: DateTime(2026, 3, 11, 12),
      experience: ExperienceLevel.regular,
    );
    expect(s.current, 4);
  });

  group('milestones', () {
    test('they climb steadily and the rewards grow with them', () {
      final all = StreakRules.milestones;
      for (var i = 1; i < all.length; i++) {
        expect(all[i].days, greaterThan(all[i - 1].days));
        expect(all[i].coins, greaterThanOrEqualTo(all[i - 1].coins));
        expect(all[i].xp, greaterThanOrEqualTo(all[i - 1].xp));
      }
      expect(all.first.days, 3);
      expect(all.last.days, 365);
    });

    test('the first rewards are small next to a day of real exercise', () {
      // A full day is worth 120 XP at most; early streak rewards stay well under that.
      for (final m in StreakRules.milestones.where((m) => m.days <= 14)) {
        expect(m.xp, lessThanOrEqualTo(100));
      }
    });

    test('milestones repeat every 100 days after a year', () {
      expect(StreakRules.milestoneAt(365)!.title, 'Year of the Hero');
      expect(StreakRules.milestoneAt(465)!.coins, 500);
      expect(StreakRules.milestoneAt(466), isNull);
      expect(StreakRules.milestoneAt(4), isNull);
      expect(StreakRules.nextAfter(365).days, 465);
      expect(StreakRules.nextAfter(465).days, 565);
      expect(StreakRules.nextAfter(0).days, 3);
      expect(StreakRules.nextAfter(7).days, 10);
    });

    test('what is due is everything reached and not yet claimed', () {
      expect(StreakRules.due(current: 2, claimed: {}), isEmpty);
      expect(StreakRules.due(current: 3, claimed: {}).map((m) => m.days), [3]);
      expect(StreakRules.due(current: 7, claimed: {3}).map((m) => m.days), [5, 7]);
      expect(StreakRules.due(current: 7, claimed: {3, 5, 7}), isEmpty);
      expect(StreakRules.due(current: 470, claimed: {for (final m in StreakRules.milestones) m.days}).map((m) => m.days), [465]);
    });

    test('progress runs from the last milestone to the next', () {
      expect(_eval([0]).progressToNext, closeTo(1 / 3, 1e-9));
      final seven = _eval([0, 1, 2, 3, 4, 5, 6]);
      expect(seven.current, 7);
      expect(seven.next!.days, 10);
      expect(seven.daysToNext, 3);
      expect(seven.progressToNext, 0.0);
      expect(StreakRules.milestoneBefore(10)!.days, 7);
      expect(StreakRules.milestoneBefore(3), isNull);
      expect(StreakRules.milestoneBefore(465)!.days, 365);
      expect(StreakRules.milestoneBefore(566)!.days, 565);
    });

    test('rest allowance matches the experience levels', () {
      expect(StreakRules.allowedRestDays(ExperienceLevel.starting), 3);
      expect(StreakRules.allowedRestDays(ExperienceLevel.returning), 2);
      expect(StreakRules.allowedRestDays(ExperienceLevel.regular), 2);
    });
  });
}
