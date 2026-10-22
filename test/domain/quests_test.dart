import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/chad.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/quests.dart';
import 'package:i_am_chad/domain/workout.dart';

WorkoutEntry _on(DateTime d) => WorkoutEntry(
      activityId: 'walking',
      performedAt: d,
      durationSeconds: 600,
    );

void main() {
  final wed = DateTime(2026, 10, 21, 12); // a Wednesday

  group('dailySuggestions', () {
    test('every quest references a real activity', () {
      for (final level in ExperienceLevel.values) {
        for (var d = 0; d < 14; d++) {
          for (final q in QuestBoard.dailySuggestions(
            level: level,
            day: wed.add(Duration(days: d)),
            preferred: const {},
            hasDumbbells: true,
            count: 99,
          )) {
            expect(ActivityCatalog.byId(q.activityId), isNotNull, reason: q.id);
          }
        }
      }
    });

    test('are stable within a day and rotate across days', () {
      List<String> ids(DateTime d) => [
            for (final q in QuestBoard.dailySuggestions(
              level: ExperienceLevel.returning,
              day: d,
              preferred: const {},
              hasDumbbells: true,
            ))
              q.id
          ];
      expect(ids(wed), ids(wed.add(const Duration(hours: 5))));
      expect(ids(wed), isNot(ids(wed.add(const Duration(days: 1)))));
    });

    test('no dumbbells means no dumbbell quests', () {
      for (var d = 0; d < 10; d++) {
        final qs = QuestBoard.dailySuggestions(
          level: ExperienceLevel.regular,
          day: wed.add(Duration(days: d)),
          preferred: const {},
          hasDumbbells: false,
          count: 99,
        );
        expect(qs.any((q) => q.needsDumbbells), isFalse);
      }
    });

    test('preferred categories come first', () {
      final qs = QuestBoard.dailySuggestions(
        level: ExperienceLevel.starting,
        day: wed,
        preferred: {ActivityCategory.mobility},
        hasDumbbells: false,
      );
      expect(qs.first.activity.category, ActivityCategory.mobility);
    });

    test('beginner suggestions are gentle', () {
      for (final q in QuestBoard.dailySuggestions(
        level: ExperienceLevel.starting,
        day: wed,
        preferred: const {},
        hasDumbbells: false,
        count: 99,
      )) {
        expect(q.durationSeconds ?? 0, lessThanOrEqualTo(600));
        expect(q.sets ?? 0, lessThanOrEqualTo(2));
      }
    });
  });

  group('weeklyGoal', () {
    test('counts distinct active days Monday to Sunday, not entries', () {
      final goal = QuestBoard.weeklyGoal(
        level: ExperienceLevel.returning,
        now: wed,
        entries: [
          _on(DateTime(2026, 10, 19, 8)), // Mon
          _on(DateTime(2026, 10, 19, 18)), // Mon again
          _on(DateTime(2026, 10, 21, 7)), // Wed
          _on(DateTime(2026, 10, 18, 7)), // previous Sunday: excluded
        ],
      );
      expect(goal.daysActive, 2);
      expect(goal.target, 3);
      expect(goal.met, isFalse);
    });

    test('a quiet week is just zero, with no penalty state', () {
      final goal = QuestBoard.weeklyGoal(
        level: ExperienceLevel.regular,
        now: wed,
        entries: const [],
      );
      expect(goal.daysActive, 0);
      expect(goal.progress, 0);
    });
  });

  group('Chad', () {
    test('has lines for every context and never repeats on a stable seed', () {
      for (final c in ChadContext.values) {
        expect(ChadDialogue.line(c), isNotEmpty);
        expect(ChadDialogue.line(c, seed: 3), ChadDialogue.line(c, seed: 3));
        expect(ChadDialogue.line(c, seed: -7), isNotEmpty);
      }
    });

    test('dialogue avoids shaming vocabulary', () {
      const banned = ['lazy', 'fat', 'ugly', 'pathetic', 'weak', 'failure'];
      for (final c in ChadContext.values) {
        for (var s = 0; s < 6; s++) {
          final line = ChadDialogue.line(c, seed: s).toLowerCase();
          for (final w in banned) {
            expect(line.contains(w), isFalse, reason: '"$w" in: $line');
          }
        }
      }
    });
  });
}
