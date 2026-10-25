import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/rewards.dart';
import 'package:i_am_chad/domain/workout.dart';

/// A short entry: two wall push-ups, about 12 seconds of real effort.
WorkoutEntry _tiny(int minute, {int? id}) => WorkoutEntry(
      id: id,
      activityId: 'push_up',
      performedAt: DateTime(2026, 10, 22, 9, minute),
      sets: 1,
      reps: 2,
    );

WorkoutEntry _walk(int minute, {int secs = 600}) => WorkoutEntry(
      activityId: 'walking',
      performedAt: DateTime(2026, 10, 22, 9, minute),
      durationSeconds: secs,
    );

void main() {
  const v1 = RewardRules.v1;
  const v2 = RewardRules.v2;

  test('new days use version 2, and version 1 is still there for old days', () {
    expect(RewardRules.current.version, 2);
    expect(v1.version, 1);
    expect(v1.maxFlooredEntriesPerDay, isNull);
  });

  test('the first three short entries of a day each count as the minimum', () {
    for (var n = 1; n <= 3; n++) {
      final r = v2.rewardForDay([for (var i = 0; i < n; i++) _tiny(i)]);
      expect(r.rawEffortMinutes, n * v2.minEffortPerEntry);
      expect(r.shortEntriesAtRealLength, 0);
    }
  });

  test('a fourth and later short entry counts for its real length', () {
    final entries = [for (var i = 0; i < 14; i++) _tiny(i)];
    final r = v2.rewardForDay(entries);
    final real = v2.unflooredEffortMinutes(entries.first);
    expect(r.rawEffortMinutes, closeTo(3 * v2.minEffortPerEntry + 11 * real, 1e-9));
    expect(r.shortEntriesAtRealLength, 11);
    // Version 1 let the same pile reach 42 minutes, past the day's limit.
    expect(v1.rewardForDay(entries).capReached, isTrue);
    expect(r.capReached, isFalse);
    expect(r.xp, lessThan(v1.rewardForDay(entries).xp));
  });

  test('honest small days lose nothing: three short moves and a walk', () {
    final entries = [_tiny(0), _tiny(5), _tiny(10), _walk(20)];
    expect(v2.rewardForDay(entries).xp, v1.rewardForDay(entries).xp);
  });

  test('entries at or above the minimum are never touched', () {
    final entries = [for (var i = 0; i < 8; i++) _walk(i * 10, secs: 240)];
    expect(v2.rewardForDay(entries).rawEffortMinutes, v1.rewardForDay(entries).rawEffortMinutes);
  });

  test('the minimum goes to the earliest entries, whatever order they arrive in', () {
    final entries = [for (var i = 0; i < 5; i++) _tiny(i)];
    final a = v2.rewardForDay(entries);
    final b = v2.rewardForDay(entries.reversed);
    expect(a.rawEffortMinutes, b.rawEffortMinutes);
  });

  test('back-dated entries use none of the allowance', () {
    final late = WorkoutEntry(
      activityId: 'push_up',
      performedAt: DateTime(2026, 10, 22, 8),
      loggedAt: DateTime(2026, 10, 25, 8),
      sets: 1,
      reps: 2,
    );
    final r = v2.rewardForDay([late, late, late, late, _tiny(30), _tiny(31), _tiny(32)]);
    expect(r.rawEffortMinutes, 3 * v2.minEffortPerEntry);
    expect(r.shortEntriesAtRealLength, 0);
  });

  test('the explanation says so, kindly, only when it applied', () {
    final many = v2.rewardForDay([for (var i = 0; i < 6; i++) _tiny(i)]);
    expect(v2.explain(many), contains('first 3 short entries'));
    final few = v2.rewardForDay([_tiny(0), _tiny(1)]);
    expect(v2.explain(few), isNot(contains('short entries')));
    for (final w in ['lazy', 'cheat', 'abuse', 'penalt', 'punish']) {
      expect(v2.explain(many).toLowerCase(), isNot(contains(w)));
    }
  });

  test('the daily limits are unchanged', () {
    expect(v2.maxDailyXp, v1.maxDailyXp);
    expect(v2.maxDailyEnergy, v1.maxDailyEnergy);
  });
}
