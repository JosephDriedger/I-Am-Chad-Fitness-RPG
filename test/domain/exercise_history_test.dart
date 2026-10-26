import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/exercise_history.dart';
import 'package:i_am_chad/domain/workout.dart';

// Thursday 22 October 2026. Its Monday is the 19th.
final _now = DateTime(2026, 10, 22, 10);

WorkoutEntry _squat(DateTime at, {double? kg, int sets = 3, int reps = 8}) =>
    WorkoutEntry(activityId: 'squat', performedAt: at, sets: sets, reps: reps, loadKg: kg);

void main() {
  test('weeks run Monday to Sunday and end with the current week', () {
    final h = ExerciseHistory.of([_squat(DateTime(2026, 10, 19, 8)), _squat(DateTime(2026, 10, 18, 8))], 'squat', now: _now);
    expect(h.weeks, hasLength(ExerciseHistory.weeksShown));
    expect(h.weeks.last.start, DateTime(2026, 10, 19));
    expect(h.weeks.last.days, 1);
    // Sunday the 18th belongs to the week before.
    expect(h.weeks[h.weeks.length - 2].start, DateTime(2026, 10, 12));
    expect(h.weeks[h.weeks.length - 2].days, 1);
    expect(h.weeks.first.start, DateTime(2026, 8, 31));
  });

  test('several entries on one day count as one day', () {
    final h = ExerciseHistory.of([
      _squat(DateTime(2026, 10, 20, 8)),
      _squat(DateTime(2026, 10, 20, 18)),
      _squat(DateTime(2026, 10, 21, 8)),
    ], 'squat', now: _now);
    expect(h.weeks.last.days, 2);
    expect(h.days, 2);
    expect(h.entryCount, 3);
  });

  test('a quiet week is a rest, not a gap', () {
    final h = ExerciseHistory.of([_squat(DateTime(2026, 9, 1, 8)), _squat(DateTime(2026, 10, 20, 8))], 'squat', now: _now);
    expect(h.weeks.where((w) => w.rest).length, ExerciseHistory.weeksShown - 2);
    expect(h.activeWeeks, 2);
  });

  test('older entries still count in the totals but not in the weeks', () {
    final h = ExerciseHistory.of([_squat(DateTime(2026, 1, 5, 8)), _squat(DateTime(2026, 10, 20, 8))], 'squat', now: _now);
    expect(h.days, 2);
    expect(h.first, DateTime(2026, 1, 5, 8));
    expect(h.last, DateTime(2026, 10, 20, 8));
    expect(h.activeWeeks, 1);
  });

  test('total lifted is weight times reps times sets, and only when a weight was logged', () {
    final h = ExerciseHistory.of([
      _squat(DateTime(2026, 10, 20, 8), kg: 40),
      _squat(DateTime(2026, 10, 21, 8), kg: 50, sets: 2, reps: 5),
    ], 'squat', now: _now);
    expect(h.hasLoad, isTrue);
    expect(h.weeks.last.liftedKg, 40 * 8 * 3 + 50 * 5 * 2);
    final none = ExerciseHistory.of([_squat(DateTime(2026, 10, 20, 8))], 'squat', now: _now);
    expect(none.hasLoad, isFalse);
    expect(none.liftedKg, 0);
  });

  test('only this exercise is counted, and nothing logged is an empty history', () {
    final other = WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 20, 8), durationSeconds: 600);
    final h = ExerciseHistory.of([other], 'squat', now: _now);
    expect(h.hasHistory, isFalse);
    expect(h.first, isNull);
    expect(h.bests, isEmpty);
    expect(h.recent, isEmpty);
  });

  test('the latest entries come newest first and are capped', () {
    final entries = [for (var d = 1; d <= 9; d++) _squat(DateTime(2026, 10, d, 8))];
    final h = ExerciseHistory.of(entries, 'squat', now: _now);
    expect(h.recent, hasLength(ExerciseHistory.recentShown));
    expect(h.recent.first.performedAt, DateTime(2026, 10, 9, 8));
  });

  test('the list of exercises is most recent first', () {
    final walk = WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 21, 8), durationSeconds: 600);
    final list = ExerciseHistory.summaries([_squat(DateTime(2026, 10, 20, 8)), _squat(DateTime(2026, 10, 10, 8)), walk]);
    expect([for (final s in list) s.activityId], ['walking', 'squat']);
    expect(list.last.days, 2);
  });

  test('a clock change cannot shift a week', () {
    // The end of daylight saving falls around here in many places.
    final h = ExerciseHistory.of([_squat(DateTime(2026, 11, 2, 8))], 'squat', now: DateTime(2026, 11, 3, 10));
    expect(h.weeks.last.start, DateTime(2026, 11, 2));
    expect(h.weeks.last.days, 1);
  });

  test('weights are shown in kilograms or pounds with separators', () {
    expect(ExerciseHistory.describeLifted(1250), '1,250 kg');
    expect(ExerciseHistory.describeLifted(1000, metric: false), '2,205 lb');
    expect(ExerciseHistory.describeLifted(90), '90 kg');
  });
}
