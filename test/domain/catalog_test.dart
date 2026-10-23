import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/rewards.dart';
import 'package:i_am_chad/domain/workout.dart';

final _all = ActivityCatalog.all;
final _original = {
  'push_up', 'squat', 'sit_up', 'plank', 'walking', 'running', 'dumbbell_row', //
  'dumbbell_press', 'barbell_squat', 'stretching', 'light_mobility',
};

void main() {
  test('the catalog is large and every category is well stocked', () {
    expect(_all.length, greaterThanOrEqualTo(75));
    for (final c in ActivityCategory.values) {
      expect(ActivityCatalog.inCategory(c).length, greaterThanOrEqualTo(5), reason: c.label);
    }
  });

  test('ids are unique, stable-looking and findable', () {
    final ids = _all.map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'duplicate id');
    for (final a in _all) {
      expect(a.id, matches(RegExp(r'^[a-z][a-z0-9_]*$')), reason: a.id);
      expect(ActivityCatalog.byId(a.id), same(a));
    }
    // Ids already saved with players' workouts must still exist.
    for (final id in _original) {
      expect(ActivityCatalog.byId(id), isNotNull, reason: id);
    }
  });

  test('names are unique and in Title Case', () {
    final names = _all.map((a) => a.name.toLowerCase()).toList();
    expect(names.toSet().length, names.length, reason: 'duplicate name');
    for (final a in _all.where((a) => !_original.contains(a.id))) {
      for (final word in a.name.split(' ')) {
        final first = word[0];
        expect(first == first.toUpperCase(), isTrue, reason: '"${a.name}" should be Title Case');
      }
    }
  });

  test('every cue is a calm, complete sentence', () {
    for (final a in _all) {
      expect(a.formCue.trim(), isNotEmpty, reason: a.id);
      expect(a.formCue, endsWith('.'), reason: a.id);
      expect(a.formCue.length, lessThan(190), reason: '${a.id} cue is too long to read mid-workout');
      if (a.easierAlternative != null) expect(a.easierAlternative, endsWith('.'), reason: a.id);
    }
  });

  test('every exercise records something sensible', () {
    for (final a in _all) {
      expect(a.metrics, isNotEmpty, reason: a.id);
      final reps = a.metrics.contains(Metric.reps);
      final duration = a.metrics.contains(Metric.duration);
      final distance = a.metrics.contains(Metric.distance);
      expect(reps || duration || distance, isTrue, reason: '${a.id} has nothing to measure');
      if (reps) expect(a.metrics.contains(Metric.sets), isTrue, reason: '${a.id}: reps need sets');
      if (a.metrics.contains(Metric.load)) {
        expect(a.equipment, isNot(Equipment.none), reason: '${a.id} lifts a load but lists no equipment');
      }
    }
  });

  test('the honesty limits are filled in wherever they apply', () {
    for (final a in _all) {
      if (a.metrics.contains(Metric.reps)) {
        expect(a.plausibleRepsPerSet, isNotNull, reason: '${a.id} has reps but no plausible limit');
        expect(a.plausibleRepsPerSet, inInclusiveRange(20, 500), reason: a.id);
      }
      if (a.metrics.contains(Metric.distance)) {
        expect(a.plausibleKmh, isNotNull, reason: '${a.id} has distance but no plausible pace');
        expect(a.minutesPerKm, isNotNull, reason: '${a.id} needs a pace for distance-only entries');
        // The slowest pace the rewards assume must sit inside the plausible speed.
        final kmh = 60 / a.minutesPerKm!;
        expect(kmh, lessThan(a.plausibleKmh!), reason: a.id);
      }
    }
  });

  test('reward tuning is in a sensible range, so no exercise is a shortcut', () {
    const rules = RewardRules.v1;
    for (final a in _all) {
      expect(a.effortFactor, inInclusiveRange(0.5, 1.6), reason: a.id);
      expect(a.secondsPerRep, inInclusiveRange(1, 8), reason: a.id);

      final entries = <WorkoutEntry>[
        if (a.metrics.contains(Metric.reps))
          WorkoutEntry(activityId: a.id, performedAt: DateTime(2026, 1, 1), sets: 3, reps: 10),
        if (a.metrics.contains(Metric.duration))
          WorkoutEntry(activityId: a.id, performedAt: DateTime(2026, 1, 1), durationSeconds: 600),
      ];
      for (final e in entries) {
        final minutes = rules.effortMinutes(e);
        expect(minutes, greaterThanOrEqualTo(rules.minEffortPerEntry), reason: a.id);
        // A normal set of work or ten minutes is never worth more than 20 minutes.
        expect(minutes, lessThan(20), reason: '${a.id}: $minutes effort minutes is too generous');
      }
    }
  });

  test('harder cardio is worth more per minute than gentle movement, never wildly so', () {
    double perMinute(String id) {
      final a = ActivityCatalog.byId(id)!;
      return rules.effortMinutes(WorkoutEntry(activityId: a.id, performedAt: DateTime(2026, 1, 1), durationSeconds: 1200)) / 20;
    }

    expect(perMinute('jump_rope'), greaterThan(perMinute('walking')));
    expect(perMinute('walking'), greaterThan(perMinute('stretching')));
    expect(perMinute('jump_rope'), lessThan(perMinute('stretching') * 3));
  });

  test('equipment labels read well and at-home means no gear', () {
    for (final e in Equipment.values) {
      expect(e.label.trim(), isNotEmpty);
    }
    expect(Equipment.none.atHome, isTrue);
    expect(Equipment.chair.atHome, isTrue);
    expect(Equipment.barbell.atHome, isFalse);
    expect(_all.where((a) => a.equipment.atHome).length, greaterThan(30), reason: 'plenty to do at home');
  });

  test('categories keep their saved names, so old preferences still load', () {
    expect(ActivityCategory.values.map((c) => c.name), containsAll(['bodyweight', 'cardio', 'resistance', 'mobility']));
  });
}

const rules = RewardRules.v1;
