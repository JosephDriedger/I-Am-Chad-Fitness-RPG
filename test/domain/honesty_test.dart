import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/honesty.dart';
import 'package:i_am_chad/domain/rewards.dart';
import 'package:i_am_chad/domain/workout.dart';

final _now = DateTime(2026, 10, 22, 10);
const _check = HonestyCheck();

WorkoutEntry _e(
  String id, {
  int? sets,
  int? reps,
  int? seconds,
  double? metres,
}) =>
    WorkoutEntry(
      activityId: id,
      performedAt: _now,
      sets: sets,
      reps: reps,
      durationSeconds: seconds,
      distanceMeters: metres,
    );

Set<HonestyConcern> _concerns(WorkoutEntry e, {List<WorkoutEntry> sameDay = const [], bool metric = true}) =>
    _check.review(e, sameDay: sameDay, metric: metric).map((n) => n.concern).toSet();

void main() {
  test('ordinary workouts raise nothing', () {
    expect(_concerns(_e('walking', seconds: 1800, metres: 3000)), isEmpty);
    expect(_concerns(_e('running', seconds: 1500, metres: 4000)), isEmpty);
    expect(_concerns(_e('push_up', sets: 3, reps: 10)), isEmpty);
    expect(_concerns(_e('push_up', sets: 2, reps: 8)), isEmpty);
    expect(_concerns(_e('plank', sets: 2, seconds: 30)), isEmpty);
    expect(_concerns(_e('stretching', seconds: 300)), isEmpty);
    expect(_concerns(_e('walking', metres: 2000)), isEmpty, reason: 'distance alone has no pace');
  });

  test('a pace nobody can hold is flagged, in the player\'s units', () {
    // 10 km in 20 minutes of walking is 30 km/h.
    final e = _e('walking', seconds: 1200, metres: 10000);
    expect(_concerns(e), {HonestyConcern.impossiblePace});
    expect(_check.review(e).single.text, contains('30 km/h'));
    expect(_check.review(e, metric: false).single.text, contains('19 mph'));
    // Elite-level but possible running is left alone; 40 km/h is not.
    expect(_concerns(_e('running', seconds: 1200, metres: 7000)), isEmpty);
    expect(_concerns(_e('running', seconds: 900, metres: 10000)), {HonestyConcern.impossiblePace});
  });

  test('very short timed entries do not get a pace verdict', () {
    // 100 m in 10 s is 36 km/h, but that says little over so short a time.
    expect(_concerns(_e('running', seconds: 10, metres: 100)), {HonestyConcern.veryQuick});
  });

  test('absurd rep counts are flagged', () {
    expect(_concerns(_e('push_up', sets: 1, reps: 200)), {HonestyConcern.tooManyReps});
    expect(_concerns(_e('push_up', sets: 1, reps: 40)), isEmpty);
    expect(_concerns(_e('dumbbell_row', sets: 1, reps: 60)), {HonestyConcern.tooManyReps});
  });

  test('entries far shorter than the paid minimum are flagged', () {
    expect(_concerns(_e('push_up', sets: 1, reps: 2)), {HonestyConcern.veryQuick});
    expect(_concerns(_e('plank', sets: 1, seconds: 5)), {HonestyConcern.veryQuick});
    // A short but real set is fine.
    expect(_concerns(_e('push_up', sets: 1, reps: 5)), isEmpty);
    final note = _check.review(_e('plank', sets: 1, seconds: 5)).single.text;
    expect(note, contains('at least ${RewardRules.v1.minEffortPerEntry.toInt()} minutes'));
  });

  test('piling up tiny entries in one day is flagged, but one set per entry is not', () {
    final tiny = _e('push_up', sets: 1, reps: 8); // about 48 seconds
    expect(_concerns(tiny, sameDay: [tiny, tiny]), isEmpty);
    expect(_concerns(tiny, sameDay: [tiny, tiny, tiny]), {HonestyConcern.manyTinyEntries});
    // A real workout is never called tiny, however many small ones came before.
    final real = _e('walking', seconds: 1200, metres: 1500);
    expect(_concerns(real, sameDay: [tiny, tiny, tiny, tiny]), isEmpty);
  });

  test('editing an entry does not count it against itself', () {
    final saved = WorkoutEntry(
      id: 7,
      activityId: 'push_up',
      performedAt: _now,
      sets: 1,
      reps: 8,
    );
    final tiny = _e('push_up', sets: 1, reps: 8);
    expect(_concerns(saved, sameDay: [saved, tiny, tiny]), isEmpty);
  });

  test('unknown activities and empty entries are ignored', () {
    expect(_concerns(_e('from_a_newer_app', reps: 500)), isEmpty);
    expect(_concerns(_e('push_up')), isEmpty);
  });
}
