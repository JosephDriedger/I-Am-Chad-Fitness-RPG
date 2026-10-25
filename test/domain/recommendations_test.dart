import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/quests.dart';
import 'package:i_am_chad/domain/recommendations.dart';
import 'package:i_am_chad/domain/workout.dart';

final _day = DateTime(2026, 10, 22, 10);

List<QuestSuggestion> _quests(ExperienceLevel level, DateTime day, {bool dumbbells = true}) =>
    QuestBoard.dailySuggestions(level: level, day: day, preferred: const {}, hasDumbbells: dumbbells, count: 4);

List<Recommendation> _recs({
  ExperienceLevel level = ExperienceLevel.returning,
  DateTime? day,
  Set<ActivityCategory> preferred = const {},
  bool dumbbells = true,
  List<WorkoutEntry> history = const [],
  int count = Recommendations.defaultCount,
  List<QuestSuggestion>? quests,
}) {
  final d = day ?? _day;
  return Recommendations.forDay(
    level: level,
    day: d,
    preferred: preferred,
    hasDumbbells: dumbbells,
    quests: quests ?? _quests(level, d, dumbbells: dumbbells),
    history: history,
    count: count,
  );
}

WorkoutEntry _did(String id, DateTime at) => WorkoutEntry(
      activityId: id,
      performedAt: at,
      durationSeconds: 600,
      sets: 2,
      reps: 8,
    );

/// Every exercise that could be offered to this player, as the rules see it.
List<ActivityType> _eligible(ExperienceLevel level, bool dumbbells) =>
    [for (final a in ActivityCatalog.all) if (Recommendations.fits(a, level: level, hasDumbbells: dumbbells)) a];

void main() {
  group('what is offered', () {
    test('three by default, on any day, for anyone', () {
      for (final level in ExperienceLevel.values) {
        for (var i = 0; i < 40; i++) {
          final day = _day.add(Duration(days: i));
          expect(_recs(level: level, day: day).length, Recommendations.defaultCount, reason: '$level $day');
        }
      }
    });

    test('the same day always gives the same list, and other days give other lists', () {
      List<String> ids(DateTime d) => [for (final r in _recs(day: d)) r.activity.id];
      expect(ids(_day), ids(_day.add(const Duration(hours: 5))), reason: 'stable through the day');
      final lists = {for (var i = 0; i < 14; i++) ids(_day.add(Duration(days: i))).join(',')};
      expect(lists.length, greaterThan(9), reason: 'a fortnight of mostly different lists');
      final everything = {for (var i = 0; i < 60; i++) ...ids(_day.add(Duration(days: i)))};
      expect(everything.length, greaterThan(25), reason: 'it draws on much of the catalog over time');
    });

    test('never repeats an exercise within a list, and never offers one that is already a quest today', () {
      for (final level in ExperienceLevel.values) {
        for (var i = 0; i < 60; i++) {
          final day = _day.add(Duration(days: i));
          final quests = _quests(level, day);
          final recs = _recs(level: level, day: day, quests: quests);
          final ids = [for (final r in recs) r.activity.id];
          expect(ids.toSet().length, ids.length, reason: '$level day $i');
          expect(ids.toSet().intersection({for (final q in quests) q.activityId}), isEmpty, reason: '$level day $i');
        }
      }
    });

    test('only what fits: no equipment someone may not have, no gym machines, nothing too hard for a beginner', () {
      for (final dumbbells in [true, false]) {
        for (final level in ExperienceLevel.values) {
          for (var i = 0; i < 60; i++) {
            for (final r in _recs(level: level, day: _day.add(Duration(days: i)), dumbbells: dumbbells)) {
              final a = r.activity;
              expect(a.equipment.atHome || (a.equipment == Equipment.dumbbells && dumbbells), isTrue, reason: '${a.id} ($dumbbells)');
              if (level == ExperienceLevel.starting) expect(Recommendations.demandingForBeginners, isNot(contains(a.id)));
              if (level != ExperienceLevel.regular) expect(Recommendations.demandingForReturning, isNot(contains(a.id)));
            }
          }
        }
      }
    });

    test('the held-back lists only name real exercises', () {
      final ids = {for (final a in ActivityCatalog.all) a.id};
      expect(ids, containsAll(Recommendations.demandingForBeginners));
      expect(ids, containsAll(Recommendations.demandingForReturning));
    });

    test('with no quests there is nothing to pair with, and the list is still full', () {
      final recs = _recs(quests: const []);
      expect(recs.length, 3);
      expect(recs.map((r) => r.kind), everyElement(isNot(RecommendationKind.pairsWith)));
    });

    test('count can be changed', () {
      expect(_recs(count: 1).length, 1);
      expect(_recs(count: 5).length, 5);
      expect(_recs(count: 0), isEmpty);
    });
  });

  group('going with the quests', () {
    test('the first suggestion goes with one of the day\'s quests, from a different part of fitness', () {
      for (final level in ExperienceLevel.values) {
        for (var i = 0; i < 40; i++) {
          final day = _day.add(Duration(days: i));
          final quests = _quests(level, day);
          final first = _recs(level: level, day: day, quests: quests).first;
          expect(first.kind, RecommendationKind.pairsWith, reason: '$level day $i');
          expect(quests.map((q) => q.id), contains(first.partner!.id));
          expect(Recommendations.pairs[first.partner!.activity.category], contains(first.activity.category));
          expect(first.activity.id, isNot(first.partner!.activityId));
          expect(first.reason, 'Goes well with ${first.partner!.title}');
        }
      }
    });

    test('over a fortnight it goes with different quests, not the same one every day', () {
      final partners = {
        for (var i = 0; i < 14; i++) _recs(day: _day.add(Duration(days: i))).first.partner!.id,
      };
      expect(partners.length, greaterThan(3));
    });

    test('a new exercise is the preferred partner when there is one', () {
      final day = _day;
      final quests = _quests(ExperienceLevel.returning, day);
      final first = _recs(day: day, quests: quests).first;
      // Everything of the partner kinds has been done except what was chosen.
      final categories = Recommendations.pairs[first.partner!.activity.category]!;
      final others = [
        for (final a in _eligible(ExperienceLevel.returning, true))
          if (categories.contains(a.category) && a.id != first.activity.id) a,
      ];
      final history = [for (final a in others) _did(a.id, day.subtract(const Duration(days: 3)))];
      final again = _recs(day: day, quests: quests, history: history).first;
      expect(again.activity.id, first.activity.id, reason: 'the one they have not done');
    });
  });

  group('exercises they have not logged before', () {
    test('what has been logged is not called new', () {
      final done = [
        for (final a in _eligible(ExperienceLevel.returning, true).take(40)) _did(a.id, _day.subtract(const Duration(days: 2))),
      ];
      final doneIds = {for (final e in done) e.activityId};
      for (var i = 0; i < 20; i++) {
        for (final r in _recs(day: _day.add(Duration(days: i)), history: done)) {
          if (r.kind == RecommendationKind.newToYou) expect(doneIds, isNot(contains(r.activity.id)));
        }
      }
    });

    test('the kinds they like come first', () {
      final recs = _recs(preferred: const {ActivityCategory.mobility}, quests: const []);
      expect(recs.first.activity.category, ActivityCategory.mobility);
    });

    test('they are spread across kinds when possible', () {
      for (var i = 0; i < 30; i++) {
        final recs = _recs(day: _day.add(Duration(days: i)));
        final cats = [for (final r in recs) r.activity.category];
        expect(cats.toSet().length, greaterThanOrEqualTo(2), reason: 'day $i: $cats');
      }
    });

    test('logging one today does not shuffle the list, and it shows as done', () {
      final before = _recs();
      final tryIt = before[1];
      final entry = _did(tryIt.activity.id, _day.add(const Duration(hours: 2)));
      final after = _recs(history: [entry]);
      expect([for (final r in after) r.activity.id], [for (final r in before) r.activity.id]);
      expect(after[1].isDoneBy([entry]), isTrue);
      expect(after[0].isDoneBy([entry]), isFalse);
      expect(after[1].isDoneBy(const []), isFalse);
      expect(after[1].isDoneBy([entry.copyWithJournalOnly()]), isFalse, reason: 'a journal-only entry earns nothing, so it is not "done"');
    });

    test('tomorrow, what they tried today is no longer new', () {
      final before = _recs();
      final tried = before.firstWhere((r) => r.kind == RecommendationKind.newToYou);
      final entry = _did(tried.activity.id, _day);
      for (var i = 1; i < 30; i++) {
        final next = _recs(day: _day.add(Duration(days: i)), history: [entry]);
        expect(next.where((r) => r.kind == RecommendationKind.newToYou).map((r) => r.activity.id), isNot(contains(tried.activity.id)));
      }
    });
  });

  group('old favourites', () {
    test('when everything has been done lately, only a pairing is left, and no "new" is invented', () {
      final recent = [for (final a in ActivityCatalog.all) _did(a.id, _day.subtract(const Duration(days: 3)))];
      final recs = _recs(history: recent);
      expect(recs.map((r) => r.kind), isNot(contains(RecommendationKind.newToYou)));
      expect(recs.map((r) => r.kind), isNot(contains(RecommendationKind.anotherGo)), reason: 'too soon to call it an old favourite');
      expect(recs.length, 1);
      expect(recs.single.kind, RecommendationKind.pairsWith);
    });

    test('when everything was done a while ago, the list fills with old favourites, longest rested first', () {
      final old = [
        for (final (i, a) in ActivityCatalog.all.indexed) _did(a.id, _day.subtract(Duration(days: 30 + (i % 20)))),
      ];
      final recs = _recs(history: old);
      expect(recs.length, 3);
      final favourites = recs.where((r) => r.kind == RecommendationKind.anotherGo).toList();
      expect(favourites, isNotEmpty);
      expect(favourites.first.reason, 'An old favourite, if you fancy it');
      final ages = [
        for (final r in favourites) old.firstWhere((e) => e.activityId == r.activity.id).performedAt,
      ];
      for (var i = 1; i < ages.length; i++) {
        expect(!ages[i].isBefore(ages[i - 1]), isTrue, reason: 'oldest first');
      }
    });
  });

  group('the amount suggested', () {
    test('is gentle, and fits what the exercise records', () {
      for (final level in ExperienceLevel.values) {
        for (final a in _eligible(level, true)) {
          final p = Recommendations.planFor(a, level);
          expect(p.id, 'rec_${a.id}');
          expect(p.activityId, a.id);
          expect(p.title, a.name);
          expect(p.description, isNotEmpty);
          if (p.sets != null) expect(a.metrics, contains(Metric.sets), reason: a.id);
          if (p.reps != null) expect(a.metrics, contains(Metric.reps), reason: a.id);
          if (p.durationSeconds != null) expect(a.usesDuration, isTrue, reason: a.id);
          if (a.metrics.contains(Metric.sets) && a.metrics.contains(Metric.reps)) {
            expect(p.sets, 2);
            expect(p.reps, inInclusiveRange(8, 10));
          }
          if (a.metrics.contains(Metric.sets) && a.metrics.contains(Metric.duration)) {
            expect(p.durationSeconds, 20);
          }
          if (a.usesDuration && !a.metrics.contains(Metric.sets)) {
            expect(p.durationSeconds, inInclusiveRange(180, 600), reason: a.id);
          }
          if (p.variant != null) expect(a.variants, contains(p.variant), reason: a.id);
          expect(p.needsDumbbells, isFalse);
        }
      }
    });

    test('the easiest version is suggested to anyone not already active', () {
      final pushUp = ActivityCatalog.byId('push_up')!;
      expect(Recommendations.planFor(pushUp, ExperienceLevel.starting).variant, 'Wall');
      expect(Recommendations.planFor(pushUp, ExperienceLevel.returning).variant, 'Wall');
      expect(Recommendations.planFor(pushUp, ExperienceLevel.regular).variant, isNull);
      expect(Recommendations.planFor(pushUp, ExperienceLevel.starting).description, '2 sets of 8 (Wall)');
    });
  });

  group('the words', () {
    test('are kind: ideas, never tasks, and never about what has not been done', () {
      const banned = [
        'should', 'must', 'need to', 'have to', "haven't", 'have not', 'missed', 'miss out', 'lazy', 'weak', 'failure',
        'excuse', 'weight', 'in shape', 'burn', 'hurry', 'behind', 'goal', 'streak', 'yet', 'only ', 'last chance',
      ];
      final seen = <String>{};
      for (final level in ExperienceLevel.values) {
        for (var i = 0; i < 60; i++) {
          for (final r in _recs(level: level, day: _day.add(Duration(days: i)))) {
            seen..add(r.reason)..add(r.plan.description);
          }
        }
      }
      for (final text in seen) {
        final lower = text.toLowerCase();
        for (final b in banned) {
          // Whole words, so "Bodyweight Squats" is not mistaken for talk about weight.
          expect(RegExp(r'\b' + RegExp.escape(b.trim()) + r'\b').hasMatch(lower), isFalse, reason: '"$b" in "$text"');
        }
        expect(text.length, lessThan(60), reason: text);
      }
    });
  });
}

extension on WorkoutEntry {
  /// The same entry, logged in the journal only (back-dated, so it earns nothing).
  WorkoutEntry copyWithJournalOnly() => WorkoutEntry(
        activityId: activityId,
        performedAt: performedAt,
        loggedAt: performedAt.add(const Duration(days: 10)),
        durationSeconds: durationSeconds,
        sets: sets,
        reps: reps,
      );
}
