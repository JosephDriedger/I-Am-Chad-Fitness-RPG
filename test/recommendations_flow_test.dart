import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/quests.dart';
import 'package:i_am_chad/domain/recommendations.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

final _now = DateTime(2026, 10, 22, 10);
const _preferred = {ActivityCategory.resistance};

Future<(AppDatabase, GameRepository)> _boot(WidgetTester tester, {List<WorkoutEntry> before = const [], bool usePhoneSurface = true}) async {
  if (usePhoneSurface) usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = GameRepository(db);
  await tester.runAsync(() async {
    await repo.createHero(const HeroProfile(
      name: 'Ada',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.returning,
      preferredCategories: _preferred,
      hasDumbbells: true,
    ));
    for (final e in before) {
      await repo.addWorkout(e);
    }
  });
  await bootApp(tester, db, now: _now);
  return (db, repo);
}

/// What the screen should be showing, worked out the same way the screen does.
List<Recommendation> _expected(List<WorkoutEntry> history) => Recommendations.forDay(
      level: ExperienceLevel.returning,
      day: _now,
      preferred: _preferred,
      hasDumbbells: true,
      quests: QuestBoard.dailySuggestions(level: ExperienceLevel.returning, day: _now, preferred: _preferred, hasDumbbells: true, count: 4),
      history: history,
    );

WorkoutEntry _entry(String id, DateTime at, {double? kg}) =>
    WorkoutEntry(activityId: id, performedAt: at, sets: 2, reps: 8, durationSeconds: 600, loadKg: kg);

Future<void> _openQuests(WidgetTester tester) async {
  await tester.tap(find.text('Quests'));
  await settle(tester, frames: 30);
}

Future<void> _reveal(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).last);
  await tester.ensureVisible(f);
  await settle(tester, frames: 3);
}

void main() {
  testWidgets('the quest board is followed by ideas for today, each optional and with an easy start', (tester) async {
    final (db, _) = await _boot(tester);
    await _openQuests(tester);
    final recs = _expected(const []);
    await _reveal(tester, find.text('Try Something Today'));

    expect(find.text('Try Something Today'), findsOneWidget);
    expect(find.textContaining('Pick one, none, or something else entirely'), findsOneWidget);
    for (final r in recs) {
      await _reveal(tester, find.byKey(Key('rec_${r.activity.id}')));
      expect(find.byKey(Key('rec_${r.activity.id}')), findsOneWidget, reason: r.activity.name);
      expect(find.text(r.reason), findsWidgets, reason: r.reason);
      expect(find.text('Start with ${r.plan.description}'), findsWidgets);
    }
    expect(recs.first.kind, RecommendationKind.pairsWith);
    expect(find.textContaining('Goes well with'), findsOneWidget);
    expect(find.text('Something new to try'), findsWidgets);
    // A new player has no marks to show yet.
    expect(find.byKey(const Key('past_last')), findsNothing);
    await shutDown(tester, db);
  });

  testWidgets('Try It opens the log screen for that exercise, with a gentle amount filled in', (tester) async {
    final (db, _) = await _boot(tester);
    await _openQuests(tester);
    final recs = _expected(const []);
    final r = recs.firstWhere((x) => x.plan.sets != null && x.plan.reps != null, orElse: () => recs.first);
    await _reveal(tester, find.byKey(Key('rec_try_${r.activity.id}')));
    await tester.tap(find.byKey(Key('rec_try_${r.activity.id}')));
    await settle(tester, frames: 30);

    expect(find.text(r.activity.name), findsWidgets);
    if (r.plan.sets != null && r.plan.reps != null) {
      expect(tester.widget<TextField>(find.widgetWithText(TextField, 'Sets')).controller!.text, '${r.plan.sets}');
      expect(tester.widget<TextField>(find.widgetWithText(TextField, 'Reps per Set')).controller!.text, '${r.plan.reps}');
    }
    await shutDown(tester, db);
  });

  testWidgets('one done today shows as done, the list does not change, and it can be done again', (tester) async {
    final r = _expected(const [])[1];
    final today = [_entry(r.activity.id, _now.add(const Duration(minutes: 1)))];
    final (db, _) = await _boot(tester, before: today);
    await _openQuests(tester);
    await _reveal(tester, find.byKey(Key('rec_${r.activity.id}')));

    final ids = [for (final x in _expected(today)) x.activity.id];
    expect(ids, [for (final x in _expected(const [])) x.activity.id], reason: 'the same ideas all day');
    expect(find.text('Done Today'), findsOneWidget);
    expect(find.text('Do It Again'), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('an exercise done before shows its last time and marks beside the idea', (tester) async {
    // Everything has been done a month ago, so the ideas are a pairing and old favourites.
    final old = [for (final a in ActivityCatalog.all) _entry(a.id, DateTime(2026, 9, 20, 9), kg: a.metrics.contains(Metric.load) ? 20 : null)];
    final (db, _) = await _boot(tester, before: old);
    await _openQuests(tester);
    final recs = _expected(old);
    expect(recs.any((r) => r.kind == RecommendationKind.anotherGo), isTrue);
    final favourite = recs.firstWhere((r) => r.kind == RecommendationKind.anotherGo);
    await _reveal(tester, find.byKey(Key('rec_${favourite.activity.id}')));
    expect(find.text('An old favourite, if you fancy it'), findsWidgets);

    expect(find.byKey(const Key('past_last')), findsWidgets);
    expect(find.textContaining('Last time:'), findsWidgets);
    expect(find.textContaining('Sep 20'), findsWidgets);
    expect(find.text('Something new to try'), findsNothing, reason: 'nothing is new to this player');
    await shutDown(tester, db);
  });

  testWidgets('the log screen shows last time and personal marks for an exercise done before, and each opens its progress', (tester) async {
    final (db, _) = await _boot(tester, before: [
      WorkoutEntry(activityId: 'dumbbell_press', performedAt: DateTime(2026, 10, 12, 9), sets: 3, reps: 8, loadKg: 12.5),
      WorkoutEntry(activityId: 'dumbbell_press', performedAt: DateTime(2026, 10, 19, 9), sets: 3, reps: 8, loadKg: 15),
      WorkoutEntry(activityId: 'dumbbell_press', performedAt: DateTime(2026, 10, 21, 9), sets: 3, reps: 10, loadKg: 14),
    ]);
    await tester.tap(find.text('Train'));
    await settle(tester, frames: 30);
    await openExercise(tester, 'Dumbbell Shoulder Press');

    expect(find.text('Your Marks'), findsOneWidget);
    expect(find.text('Last time: 3 × 10 · 14 kg, Oct 21'), findsOneWidget);
    expect(find.text('Done on 3 days.'), findsOneWidget);
    expect(find.text('Heaviest: 15 kg × 8'), findsOneWidget);
    expect(find.text('Most in a Set: 10 reps'), findsOneWidget);
    expect(find.textContaining('never change what you earn'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('past_heaviest')));
    await tester.tap(find.byKey(const Key('past_heaviest')));
    await settle(tester, frames: 20);
    expect(find.text('Your Progress'), findsOneWidget);
    expect(find.byKey(const Key('progress_chart')), findsOneWidget);
    await tester.tap(find.byKey(const Key('progress_close')));
    await settle(tester, frames: 20);
    await shutDown(tester, db);
  });

  testWidgets('an exercise they have never done shows no marks', (tester) async {
    final (db, _) = await _boot(tester, before: [_entry('walking', DateTime(2026, 10, 20, 9))]);
    await tester.tap(find.text('Train'));
    await settle(tester, frames: 30);
    await openExercise(tester, 'Dumbbell Shoulder Press');
    expect(find.text('Your Marks'), findsNothing);
    expect(find.byKey(const Key('past_last')), findsNothing);
    await shutDown(tester, db);
  });

  testWidgets('editing an entry does not compare it with itself', (tester) async {
    final (db, repo) = await _boot(tester, before: [
      WorkoutEntry(activityId: 'dumbbell_press', performedAt: DateTime(2026, 10, 21, 9), sets: 3, reps: 8, loadKg: 14),
    ]);
    final saved = (await tester.runAsync(() => repo.watchWorkouts().first))!.single;
    await tester.tap(find.text('Journal'));
    await settle(tester, frames: 30);
    await tester.scrollUntilVisible(find.byType(ListTile), 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.byType(ListTile));
    await settle(tester, frames: 2);
    await tester.tap(find.byType(ListTile));
    await settle(tester, frames: 30);
    expect(saved.id, isNotNull);
    expect(find.text('Your Marks'), findsNothing, reason: 'this is the only time, and it is the one being edited');
    await shutDown(tester, db);
  });

  testWidgets('the ideas and the marks fit a small phone at large text', (tester) async {
    final old = [for (final a in ActivityCatalog.all.take(30)) _entry(a.id, DateTime(2026, 9, 20, 9))];
    final (db, _) = await _boot(tester, before: old, usePhoneSurface: false);
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await settle(tester, frames: 10);
    await _openQuests(tester);
    await _reveal(tester, find.text('Try Something Today'));
    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -240));
      await settle(tester, frames: 3);
    }
    expect(tester.takeException(), isNull);
    await shutDown(tester, db);
  });

  group('repeating a session', () {
    String text(WidgetTester tester, String label) => tester.widget<TextField>(find.widgetWithText(TextField, label)).controller!.text;

    Future<void> openLog(WidgetTester tester, String name) async {
      await tester.tap(find.text('Train'));
      await settle(tester, frames: 30);
      await openExercise(tester, name);
    }

    testWidgets('one tap fills in last time\'s numbers, and the entry saves as they were', (tester) async {
      final (db, repo) = await _boot(tester, before: [
        WorkoutEntry(activityId: 'dumbbell_press', performedAt: DateTime(2026, 10, 19, 9), sets: 3, reps: 8, loadKg: 15),
        WorkoutEntry(activityId: 'dumbbell_press', performedAt: DateTime(2026, 10, 21, 9), sets: 4, reps: 10, loadKg: 14, notes: 'felt great', perceivedEffort: 2),
      ]);
      await openLog(tester, 'Dumbbell Shoulder Press');
      await tester.ensureVisible(find.byKey(const Key('past_use_last')));
      await settle(tester, frames: 2);
      expect(text(tester, 'Sets'), isEmpty, reason: 'nothing is filled until they ask');
      await tester.tap(find.byKey(const Key('past_use_last')));
      await settle(tester, frames: 5);

      expect(text(tester, 'Sets'), '4');
      expect(text(tester, 'Reps per Set'), '10');
      expect(text(tester, 'Weight (Optional)'), '14');
      expect(find.widgetWithText(TextField, 'Notes (Optional)').evaluate().isEmpty || text(tester, 'Notes (Optional)').isEmpty, isTrue,
          reason: 'notes belong to that day, so they are not copied');

      await tester.scrollUntilVisible(find.text('Save Workout'), 300, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.text('Save Workout'));
      await tester.pump();
      await tester.ensureVisible(find.text('Save Workout'));
      await tester.tap(find.text('Save Workout'));
      await settle(tester);
      final all = (await tester.runAsync(() => repo.watchWorkouts().first))!;
      final newest = all.firstWhere((e) => e.performedAt.isAfter(DateTime(2026, 10, 22)));
      expect([newest.sets, newest.reps, newest.loadKg], [4, 10, 14]);
      expect(newest.notes, anyOf(isNull, isEmpty));
      expect(newest.perceivedEffort, isNull);
      await shutDown(tester, db);
    });

    testWidgets('it fills time and distance too, and replaces what was typed', (tester) async {
      final (db, _) = await _boot(tester, before: [
        WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 21, 18), durationSeconds: 25 * 60 + 30, distanceMeters: 2100),
      ]);
      await openLog(tester, 'Walking');
      await tester.enterText(find.widgetWithText(TextField, 'Minutes'), '99');
      await tester.ensureVisible(find.byKey(const Key('past_use_last')));
      await settle(tester, frames: 2);
      await tester.tap(find.byKey(const Key('past_use_last')));
      await settle(tester, frames: 5);
      expect(text(tester, 'Minutes'), '25');
      expect(text(tester, 'Seconds'), '30');
      expect(text(tester, 'Distance (Optional)'), '2.10', reason: 'formatted the way editing formats it');
      await shutDown(tester, db);
    });

    testWidgets('there is no button for something never done, or while editing an entry', (tester) async {
      final (db, _) = await _boot(tester, before: [
        WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 20, 9), durationSeconds: 600),
        WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 21, 9), durationSeconds: 900),
      ]);
      await openLog(tester, 'Dumbbell Shoulder Press');
      expect(find.byKey(const Key('past_use_last')), findsNothing);
      await tester.pageBack();
      await settle(tester, frames: 20);
      await tester.pageBack();
      await settle(tester, frames: 20);

      // Editing the newest walk: it is compared with the earlier one, but its numbers are already filled in.
      await tester.tap(find.text('Journal'));
      await settle(tester, frames: 30);
      await tester.scrollUntilVisible(find.byType(ListTile).first, 300, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.byType(ListTile).first);
      await settle(tester, frames: 2);
      await tester.tap(find.byType(ListTile).first);
      await settle(tester, frames: 30);
      expect(find.byKey(const Key('past_use_last')), findsNothing);
      await shutDown(tester, db);
    });
  });
}
