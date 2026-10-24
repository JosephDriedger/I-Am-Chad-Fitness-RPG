import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/records.dart';
import 'package:i_am_chad/domain/workout.dart';

WorkoutEntry _lift(int day, double kg, int reps, {int? id}) => WorkoutEntry(
      id: id,
      activityId: 'dumbbell_press',
      performedAt: DateTime(2026, 10, day, 9),
      sets: 3,
      reps: reps,
      loadKg: kg,
    );

WorkoutEntry _walk(int day, int minutes, double km) => WorkoutEntry(
      activityId: 'walking',
      performedAt: DateTime(2026, 10, day, 18),
      durationSeconds: minutes * 60,
      distanceMeters: km * 1000,
    );

PersonalBest? _find(List<PersonalBest> all, String activity, RecordKind kind) {
  for (final b in all) {
    if (b.activityId == activity && b.kind == kind) return b;
  }
  return null;
}

void main() {
  group('PersonalBests.of', () {
    test('holds the best of each mark for each exercise', () {
      final all = PersonalBests.of([_lift(1, 10, 12), _lift(5, 15, 8), _lift(9, 12.5, 15)]);
      expect(_find(all, 'dumbbell_press', RecordKind.heaviest)!.value, 15);
      expect(_find(all, 'dumbbell_press', RecordKind.heaviest)!.reps, 8);
      expect(_find(all, 'dumbbell_press', RecordKind.mostReps)!.value, 15);
    });

    test('a tie keeps the earlier mark', () {
      final all = PersonalBests.of([_lift(9, 15, 8), _lift(2, 15, 8)]);
      expect(_find(all, 'dumbbell_press', RecordKind.heaviest)!.achievedAt, DateTime(2026, 10, 2, 9));
    });

    test('walks give a longest and a farthest, and no lift marks', () {
      final all = PersonalBests.of([_walk(1, 20, 1.5), _walk(3, 45, 3.2), _walk(6, 30, 2.4)]);
      expect(_find(all, 'walking', RecordKind.longest)!.value, 45 * 60);
      expect(_find(all, 'walking', RecordKind.farthest)!.value, 3200);
      expect(_find(all, 'walking', RecordKind.heaviest), isNull);
      expect(_find(all, 'walking', RecordKind.mostReps), isNull);
    });

    test('entries with nothing measured, or an unknown exercise, are ignored', () {
      final all = PersonalBests.of([
        WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 1)),
        WorkoutEntry(activityId: 'no_such_thing', performedAt: DateTime(2026, 10, 1), reps: 50),
      ]);
      expect(all, isEmpty);
    });

    test('newest marks come first', () {
      final all = PersonalBests.of([_lift(1, 10, 12), _walk(7, 30, 2)]);
      expect(all.first.activityId, 'walking');
    });
  });

  group('PersonalBests.brokenBy', () {
    test('the first time an exercise is logged is not a record', () {
      expect(PersonalBests.brokenBy(_lift(5, 20, 10), const []), isEmpty);
    });

    test('beating an earlier mark is announced, matching or missing it is not', () {
      final earlier = [_lift(1, 15, 8)];
      final broken = PersonalBests.brokenBy(_lift(5, 17.5, 8), earlier);
      expect(broken.map((b) => b.kind), [RecordKind.heaviest]);
      expect(PersonalBests.brokenBy(_lift(5, 15, 8), earlier), isEmpty);
      expect(PersonalBests.brokenBy(_lift(5, 10, 8), earlier), isEmpty);
    });

    test('several marks can fall at once', () {
      final broken = PersonalBests.brokenBy(_walk(9, 50, 4), [_walk(1, 20, 1.5)]);
      expect(broken.map((b) => b.kind).toSet(), {RecordKind.longest, RecordKind.farthest});
    });

    test('another exercise\'s marks are not compared', () {
      expect(PersonalBests.brokenBy(_walk(9, 50, 4), [_lift(1, 15, 8)]), isEmpty);
    });

    test('an entry being edited is not measured against its old self', () {
      final saved = _lift(1, 15, 8, id: 7);
      final edited = _lift(1, 16, 8, id: 7);
      expect(PersonalBests.brokenBy(edited, [saved]), isEmpty);
    });
  });

  group('describe', () {
    test('lifts read in the player\'s units', () {
      final b = PersonalBest(
        activityId: 'dumbbell_press',
        kind: RecordKind.heaviest,
        value: 20,
        achievedAt: DateTime(2026, 10, 1),
        reps: 8,
      );
      expect(b.describe(), '20 kg × 8');
      expect(b.describe(metric: false), '44.1 lb × 8');
    });

    test('time and distance read plainly', () {
      PersonalBest of(RecordKind k, double v) =>
          PersonalBest(activityId: 'walking', kind: k, value: v, achievedAt: DateTime(2026, 10, 1));
      expect(of(RecordKind.longest, 750).describe(), '12 min 30 s');
      expect(of(RecordKind.longest, 600).describe(), '10 min');
      expect(of(RecordKind.longest, 45).describe(), '45 s');
      expect(of(RecordKind.farthest, 5200).describe(), '5.20 km');
      expect(of(RecordKind.farthest, 1609.344).describe(metric: false), '1.00 mi');
      expect(of(RecordKind.mostReps, 25).describe(), '25 reps');
    });
  });
}
