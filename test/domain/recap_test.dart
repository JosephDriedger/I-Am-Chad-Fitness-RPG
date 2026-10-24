import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/recap.dart';
import 'package:i_am_chad/domain/rewards.dart';
import 'package:i_am_chad/domain/workout.dart';

// Wednesday 21 Oct 2026. Its week is Mon 19 to Sun 25; last week was Mon 12 to Sun 18.
final _now = DateTime(2026, 10, 21, 10);

WorkoutEntry _walk(DateTime when, {int seconds = 600, DateTime? loggedAt, String id = 'walking'}) =>
    WorkoutEntry(activityId: id, performedAt: when, durationSeconds: seconds, loggedAt: loggedAt);

WeekRecap? _recap(List<WorkoutEntry> entries, {int goal = 3, DateTime? now}) =>
    WeeklyRecap.lastWeek(now: now ?? _now, entries: entries, goalDays: goal);

void main() {
  test('a brand-new player has no last week to look back on', () {
    expect(_recap([]), isNull);
    // Everything logged is from this week: still nothing to look back on.
    expect(_recap([_walk(DateTime(2026, 10, 19, 8)), _walk(DateTime(2026, 10, 20, 8))]), isNull);
  });

  test('last week is the Monday to Sunday before this one, and nothing else leaks in', () {
    final r = _recap([
      _walk(DateTime(2026, 10, 11, 23, 59)), // the Sunday before: not last week
      _walk(DateTime(2026, 10, 12, 0, 0)), // Monday 12th, first minute: last week
      _walk(DateTime(2026, 10, 18, 23, 59)), // Sunday 18th, last minute: last week
      _walk(DateTime(2026, 10, 19, 0, 0)), // this week: not last week
    ])!;
    expect(r.start, DateTime(2026, 10, 12));
    expect(r.activeDays, 2);
    expect(r.weekdays, {1, 7});
  });

  test('several workouts in one day are one active day', () {
    final r = _recap([
      _walk(DateTime(2026, 10, 13, 8)),
      _walk(DateTime(2026, 10, 13, 18)),
      _walk(DateTime(2026, 10, 15, 8)),
    ])!;
    expect(r.activeDays, 2);
    expect(r.weekdays, {2, 4});
  });

  test('effort minutes add up the entries, as the journal shows them', () {
    final entries = [
      _walk(DateTime(2026, 10, 13, 8)), // 10 minutes of walking
      _walk(DateTime(2026, 10, 14, 8), seconds: 1200), // 20 minutes
    ];
    final r = _recap(entries)!;
    expect(r.effortMinutes, closeTo(RewardRules.v1.effortMinutes(entries[0]) + RewardRules.v1.effortMinutes(entries[1]), 1e-9));
    expect(r.effortMinutes, closeTo(30, 0.01));
  });

  test('a workout added afterwards for an earlier day is journal-only and does not count', () {
    final r = _recap([
      _walk(DateTime(2026, 10, 12, 8)),
      _walk(DateTime(2026, 10, 14, 8), loggedAt: DateTime(2026, 10, 20, 9)), // back-dated
    ])!;
    expect(r.activeDays, 1);
  });

  test('the most-logged activity is named, and a tie is settled the same way every time', () {
    final r = _recap([
      _walk(DateTime(2026, 10, 12, 8)),
      _walk(DateTime(2026, 10, 13, 8)),
      _walk(DateTime(2026, 10, 14, 8), id: 'stretching'),
    ])!;
    expect(r.mostLogged!.$1.id, 'walking');
    expect(r.mostLogged!.$2, 2);

    final tie = _recap([
      _walk(DateTime(2026, 10, 12, 8), id: 'walking'),
      _walk(DateTime(2026, 10, 13, 8), id: 'stretching'),
    ])!;
    final again = _recap([
      _walk(DateTime(2026, 10, 13, 8), id: 'stretching'),
      _walk(DateTime(2026, 10, 12, 8), id: 'walking'),
    ])!;
    expect(tie.mostLogged!.$1.id, again.mostLogged!.$1.id, reason: 'order of entries must not matter');
  });

  test('a quiet last week, after earlier history, is a rest week with no numbers to worry about', () {
    final r = _recap([_walk(DateTime(2026, 10, 5, 8))])!; // two weeks ago only
    expect(r.quiet, isTrue);
    expect(r.activeDays, 0);
    expect(r.effortMinutes, 0);
    expect(r.mostLogged, isNull);
    final line = WeeklyRecap.chadLine(r).toLowerCase();
    expect(line, anyOf(contains('rest'), contains('quiet')));
  });

  test('goal reached, passed, or partly met each get their own words', () {
    WeekRecap week(int days) => _recap([
          for (var d = 0; d < days; d++) _walk(DateTime(2026, 10, 12 + d, 8)),
        ], goal: 3)!;
    expect(week(2).metGoal, isFalse);
    expect(week(3).metGoal, isTrue);
    expect(week(3).beyondGoal, isFalse);
    expect(week(4).beyondGoal, isTrue);
    expect(WeeklyRecap.chadLine(week(2)), contains('2 days'));
    expect(WeeklyRecap.chadLine(week(1)), contains('1 day'));
    expect(WeeklyRecap.chadLine(week(1)), isNot(contains('1 days')));
    expect(WeeklyRecap.chadLine(week(3)).toLowerCase(), contains('goal'));
    expect(WeeklyRecap.chadLine(week(4)).toLowerCase(), contains('goal'));
    expect(WeeklyRecap.activeLabel(week(2)), '2 of 3 Days');
    expect(_recap([_walk(DateTime(2026, 10, 12, 8))], goal: 1)!.metGoal, isTrue);
    expect(WeeklyRecap.activeLabel(_recap([_walk(DateTime(2026, 10, 12, 8))], goal: 1)!), '1 of 1 Day');
  });

  test('the wording is stable for a given seed, and varies across weeks', () {
    final r = _recap([_walk(DateTime(2026, 10, 12, 8))])!;
    expect(WeeklyRecap.chadLine(r, seed: 5), WeeklyRecap.chadLine(r, seed: 5));
    expect({for (var s = 0; s < 6; s++) WeeklyRecap.chadLine(r, seed: s)}.length, greaterThan(1));
    expect(WeeklyRecap.chadLine(r, seed: -3), isNotEmpty);
  });

  test('a clock change inside the week cannot move its edges', () {
    // In many places the clocks change in late October or March; build the same recap from days either side.
    final r = _recap([_walk(DateTime(2026, 10, 12, 0, 30)), _walk(DateTime(2026, 10, 18, 23, 30))], now: DateTime(2026, 10, 19, 0, 5))!;
    expect(r.start, DateTime(2026, 10, 12));
    expect(r.activeDays, 2);
  });

  test('the words are kind: no comparison, no pressure, nothing about bodies', () {
    const banned = [
      'lazy', 'weak', 'failure', 'failed', 'excuse', 'weight', 'in shape', 'burn off', 'hurry', 'must ',
      'only ', 'just ', 'less than', 'behind', 'catch up', 'should', 'streak', 'missed', 'lost',
    ];
    for (final w in WeeklyRecap.words) {
      final lower = w.toLowerCase();
      for (final b in banned) {
        expect(lower.contains(b), isFalse, reason: '"$b" in: $w');
      }
      expect(w.length, lessThan(110), reason: w);
    }
    for (final w in WeeklyRecap.words.skip(1)) {
      expect(RegExp(r'[.!?]$').hasMatch(w), isTrue, reason: w);
    }
  });
}
