import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/chad.dart';
import 'package:i_am_chad/domain/difficulty.dart';
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

  group('quest pools', () {
    final every = [
      for (final l in ExperienceLevel.values) ...QuestBoard.poolFor(l),
    ];

    test('each level has plenty to rotate through, with or without dumbbells', () {
      for (final l in ExperienceLevel.values) {
        expect(QuestBoard.poolFor(l).length, greaterThanOrEqualTo(15), reason: '$l');
        expect(QuestBoard.poolFor(l, hasDumbbells: false).length, greaterThanOrEqualTo(14), reason: '$l without dumbbells');
      }
    });

    test('ids are unique across every pool, and titles within a pool', () {
      expect({for (final q in every) q.id}.length, every.length);
      for (final l in ExperienceLevel.values) {
        final titles = [for (final q in QuestBoard.poolFor(l)) q.title];
        expect(titles.toSet().length, titles.length, reason: '$l');
      }
    });

    test('every quest asks only for what its activity measures, with a real variant', () {
      for (final q in every) {
        final a = q.activity;
        if (q.sets != null) expect(a.metrics, contains(Metric.sets), reason: q.id);
        if (q.reps != null) expect(a.metrics, contains(Metric.reps), reason: q.id);
        if (q.durationSeconds != null) expect(a.metrics, contains(Metric.duration), reason: q.id);
        expect(q.reps != null || q.durationSeconds != null, isTrue, reason: '${q.id} has something to do');
        if (q.variant != null) expect(a.variants, contains(q.variant), reason: q.id);
      }
    });

    test('equipment is honest: dumbbell quests are flagged, and nothing needs gym kit', () {
      for (final q in every) {
        expect(q.needsDumbbells, q.activity.equipment == Equipment.dumbbells, reason: q.id);
        expect(q.activity.equipment.atHome || q.activity.equipment == Equipment.dumbbells, isTrue, reason: q.id);
      }
    });

    test('any three neighbours on a rotation mix categories, so no day is all one thing', () {
      for (final l in ExperienceLevel.values) {
        for (final dumbbells in [true, false]) {
          final pool = QuestBoard.poolFor(l, hasDumbbells: dumbbells);
          for (var i = 0; i < pool.length; i++) {
            final three = {for (var j = 0; j < 3; j++) pool[(i + j) % pool.length].activity.category};
            expect(three.length, greaterThanOrEqualTo(2), reason: '$l from ${pool[i].id}, dumbbells: $dumbbells');
          }
        }
      }
    });

    test('over a fortnight a beginner sees most of their pool, not the same few', () {
      final seen = <String>{};
      for (var d = 0; d < 14; d++) {
        for (final q in QuestBoard.dailySuggestions(
          level: ExperienceLevel.starting,
          day: DateTime(2026, 10, 1).add(Duration(days: d)),
          preferred: const {},
          hasDumbbells: false,
        )) {
          seen.add(q.id);
        }
      }
      expect(seen.length, greaterThanOrEqualTo(12));
    });

    test('the words are kind and every description is a finished sentence', () {
      const banned = ['lazy', 'weak', 'failure', 'failed', 'excuse', 'burn off', 'in shape', 'hurry', 'must ', 'no pain', 'deadline'];
      for (final q in every) {
        final t = '${q.title} ${q.description}'.toLowerCase();
        for (final b in banned) {
          expect(t.contains(b), isFalse, reason: '"$b" in ${q.id}');
        }
        expect(RegExp(r'[.!?]$').hasMatch(q.description), isTrue, reason: q.id);
        expect(q.description.length, lessThan(110), reason: q.id);
      }
    });

    test('beginner quests stay gentle, and the harder levels are not silly', () {
      for (final q in QuestBoard.poolFor(ExperienceLevel.starting)) {
        expect(q.durationSeconds ?? 0, lessThanOrEqualTo(600), reason: q.id);
        expect(q.sets ?? 0, lessThanOrEqualTo(2), reason: q.id);
        expect(q.reps ?? 0, lessThanOrEqualTo(10), reason: q.id);
      }
      for (final q in every) {
        // Never more than the daily full-value range, so no quest asks for more than is rewarded.
        expect(q.durationSeconds ?? 0, lessThanOrEqualTo(2400), reason: q.id);
        expect(q.sets ?? 0, lessThanOrEqualTo(5), reason: q.id);
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

    test('every line there is follows the content guidelines', () {
      // Whole words and phrases from docs/CONTENT_GUIDELINES.md. "fat" is matched as
      // a word so it does not trip on "fatal" or "Fatima".
      const phrases = [
        'lazy', 'ugly', 'pathetic', 'weak', 'failure', 'failed', 'excuse', 'no pain',
        'don\'t break', 'you missed', 'overdue', 'weight', 'in shape', 'burn off', 'hurry up',
        'you must', 'you have to', 'keep up', 'falling behind',
      ];
      final fat = RegExp(r'\bfat\b');
      for (final line in ChadDialogue.every) {
        final lower = line.toLowerCase();
        for (final p in phrases) {
          expect(lower.contains(p), isFalse, reason: '"$p" in: $line');
        }
        expect(fat.hasMatch(lower), isFalse, reason: line);
      }
    });

    test('lines are short, finished sentences, and none is repeated', () {
      final all = ChadDialogue.every;
      expect(all.toSet().length, all.length, reason: 'a line appears twice');
      for (final line in all) {
        expect(line.trim(), line);
        expect(line.length, inInclusiveRange(20, 190), reason: line);
        expect(RegExp(r'[.!?"]$').hasMatch(line), isTrue, reason: 'does not end like a sentence: $line');
      }
    });

    test('every region has tips for setting out, so a new region cannot ship without one', () {
      expect(ChadDialogue.tipRegions.toSet(), {for (var t = 1; t <= Difficulty.maxTier; t++) t});
      for (var tier = 1; tier <= Difficulty.maxTier; tier++) {
        // Across a spread of seeds, the tips for that region come up.
        final seen = {for (var s = 0; s < 40; s++) ChadDialogue.adventureLine(tier, seed: s)};
        expect(seen.length, greaterThan(5), reason: 'region $tier');
        expect(ChadDialogue.adventureLine(tier, seed: 7), ChadDialogue.adventureLine(tier, seed: 7));
        expect(ChadDialogue.adventureLine(tier, seed: -3), isNotEmpty);
      }
    });

    test('a region\'s tips are about the enemies met there', () {
      String tips(int tier) => [
            for (var s = 0; s < 40; s++) ChadDialogue.adventureLine(tier, seed: s),
          ].join(' ').toLowerCase();
      expect(tips(2), allOf(contains('crab'), contains('jell'), contains('gull')));
      expect(tips(4), allOf(contains('yeti'), contains('golem')));
      expect(tips(6), allOf(contains('scarab'), contains('sphinx')));
      // Nobody is told about an enemy that lives in a region they have not reached.
      expect(tips(1), isNot(contains('crab')));
    });
  });
}
