import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/activity.dart';
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

  group('MarkHistory', () {
    MarkHistory press(List<WorkoutEntry> e, {RecordKind kind = RecordKind.heaviest}) =>
        MarkHistory.of(e, activityId: 'dumbbell_press', kind: kind);

    test('is one point per day, oldest first, whatever order the journal is in', () {
      final h = press([_lift(9, 15, 8), _lift(1, 10, 12), _lift(5, 12.5, 10)]);
      expect([for (final p in h.points) p.value], [10, 12.5, 15]);
      expect([for (final p in h.points) p.achievedAt.day], [1, 5, 9]);
      expect(h.hasLine, isTrue);
      expect(h.first!.value, 10);
      expect(h.latest!.value, 15);
      expect(h.best!.value, 15);
    });

    test('a day with several entries counts once, at its best', () {
      final h = press([_lift(3, 10, 8), _lift(3, 14, 6), _lift(3, 12, 8)]);
      expect(h.points.length, 1);
      expect(h.points.single.value, 14);
      expect(h.points.single.reps, 6, reason: 'the reps done at that weight');
      expect(h.hasLine, isFalse, reason: 'one day is not a line yet');
    });

    test('the line can go down: a lighter day is simply shown, and the best stays the best', () {
      final h = press([_lift(1, 20, 8), _lift(4, 15, 8), _lift(8, 17.5, 8)]);
      expect([for (final p in h.points) p.value], [20, 15, 17.5]);
      expect(h.best!.value, 20);
      expect(h.latest!.value, 17.5);
    });

    test('follows one exercise and one kind of mark only', () {
      final entries = [_lift(1, 10, 12), _lift(2, 12, 10), _walk(3, 30, 2.5), _walk(6, 40, 3.5)];
      expect(press(entries).points.length, 2);
      expect(press(entries, kind: RecordKind.mostReps).points.map((p) => p.value), [12, 10]);
      final walks = MarkHistory.of(entries, activityId: 'walking', kind: RecordKind.farthest);
      expect(walks.points.map((p) => p.value), [2500, 3500]);
      expect(press(entries, kind: RecordKind.longest).points, isEmpty, reason: 'no lift was timed');
    });

    test('keeps only the latest days, so the line stays readable', () {
      final h = press([for (var d = 1; d <= 28; d++) _lift(d, 10 + d.toDouble(), 8)]);
      expect(h.points.length, MarkHistory.maxPoints);
      expect(h.points.last.value, 38);
      expect(h.points.first.achievedAt.day, 28 - MarkHistory.maxPoints + 1);
    });

    test('is empty when there is nothing, and never needs a stored value', () {
      expect(press(const []).points, isEmpty);
      expect(press(const []).best, isNull);
      expect(press(const []).first, isNull);
      expect(press(const []).latest, isNull);
    });
  });

  group('RecentExercises', () {
    test('is the latest entry of each of the last few different exercises, newest first', () {
      final recent = RecentExercises.of([
        _walk(1, 20, 1.5),
        _lift(2, 10, 8),
        _walk(3, 30, 2.5),
        _lift(5, 12.5, 8),
        _lift(8, 15, 8),
      ]);
      expect([for (final e in recent) e.activityId], ['dumbbell_press', 'walking']);
      expect(recent.first.performedAt.day, 8, reason: 'the newest lift, which is the newest of all');
      expect(recent.last.performedAt.day, 3, reason: 'the newest walk');
    });

    test('shows at most the requested number, one entry per exercise', () {
      final entries = [
        for (var i = 0; i < 8; i++) WorkoutEntry(activityId: ActivityCatalog.all[i].id, performedAt: DateTime(2026, 10, 1 + i, 9), durationSeconds: 600),
        _walk(20, 10, 1),
      ];
      final recent = RecentExercises.of(entries);
      expect(recent.length, RecentExercises.defaultCount);
      expect({for (final e in recent) e.activityId}.length, recent.length);
      expect(RecentExercises.of(entries, count: 2).length, 2);
      expect(RecentExercises.of(entries, count: 20).length, {for (final e in entries) e.activityId}.length);
    });

    test('ignores entries with nothing measured, and is empty with no history', () {
      expect(RecentExercises.of(const []), isEmpty);
      expect(
        RecentExercises.of([WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 3, 9))]),
        isEmpty,
      );
    });
  });
}
