import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

final _now = DateTime(2026, 10, 22, 10);

Future<(AppDatabase, GameRepository)> _boot(WidgetTester tester, {List<WorkoutEntry> before = const [], bool phoneSurface = true}) async {
  if (phoneSurface) usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = GameRepository(db);
  await tester.runAsync(() async {
    await repo.createHero(const HeroProfile(
      name: 'Ada',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.returning,
      preferredCategories: {ActivityCategory.resistance},
      hasDumbbells: true,
    ));
    for (final e in before) {
      await repo.addWorkout(e);
    }
  });
  await bootApp(tester, db, now: _now);
  await tester.tap(find.text('Train'));
  await settle(tester, frames: 30);
  return (db, repo);
}

WorkoutEntry _e(String id, int daysAgo, {int? sets, int? reps, int? secs, double? kg, double? meters, String? notes, String? variant}) => WorkoutEntry(
      activityId: id,
      performedAt: DateTime(2026, 10, 22 - daysAgo, 9),
      sets: sets,
      reps: reps,
      durationSeconds: secs,
      loadKg: kg,
      distanceMeters: meters,
      notes: notes,
      variant: variant,
    );

String _text(WidgetTester tester, String label) => tester.widget<TextField>(find.widgetWithText(TextField, label)).controller!.text;

void main() {
  testWidgets('there is nothing to do again until something has been done', (tester) async {
    final (db, _) = await _boot(tester);
    expect(find.text('Do It Again'), findsNothing);
    await shutDown(tester, db);
  });

  testWidgets('the last few different exercises are listed, newest first, with their numbers', (tester) async {
    final (db, _) = await _boot(tester, before: [
      _e('dumbbell_press', 9, sets: 3, reps: 8, kg: 12.5),
      _e('squat', 7, sets: 2, reps: 10),
      _e('walking', 5, secs: 1500, meters: 2100),
      _e('dumbbell_press', 3, sets: 3, reps: 8, kg: 15),
      _e('stretching', 2, secs: 420),
      _e('plank', 1, sets: 2, secs: 30),
    ]);
    expect(find.text('Do It Again'), findsOneWidget);
    expect(find.byKey(const Key('again_plank')), findsOneWidget);
    expect(find.byKey(const Key('again_stretching')), findsOneWidget);
    expect(find.byKey(const Key('again_dumbbell_press')), findsOneWidget);
    expect(find.byKey(const Key('again_walking')), findsOneWidget);
    expect(find.byKey(const Key('again_squat')), findsNothing, reason: 'only the last four different exercises');
    expect(find.textContaining('3 × 8 · 15 kg'), findsOneWidget, reason: 'the newest lift, not the older one');
    expect(find.textContaining('Oct 19'), findsOneWidget);
    // Nothing that nags or counts.
    for (final w in ['should', 'missed', 'streak', 'goal', 'behind']) {
      expect(find.textContaining(w), findsNothing, reason: w);
    }
    await shutDown(tester, db);
  });

  testWidgets('tapping one opens the log screen with the same numbers filled in, and no notes carried over', (tester) async {
    final (db, repo) = await _boot(tester, before: [
      _e('dumbbell_press', 3, sets: 4, reps: 10, kg: 14, notes: 'felt great today', variant: null),
    ]);
    await tester.tap(find.byKey(const Key('again_dumbbell_press')));
    await settle(tester, frames: 30);

    expect(find.text('Dumbbell Shoulder Press'), findsWidgets);
    await tester.scrollUntilVisible(find.widgetWithText(TextField, 'Sets'), 300, scrollable: find.byType(Scrollable).first);
    expect(_text(tester, 'Sets'), '4');
    expect(_text(tester, 'Reps per Set'), '10');
    expect(_text(tester, 'Weight (Optional)'), '14');
    await tester.scrollUntilVisible(find.widgetWithText(TextField, 'Notes (Optional)'), 300, scrollable: find.byType(Scrollable).first);
    expect(_text(tester, 'Notes (Optional)'), isEmpty);

    // Saving it as it is logs a new entry today with those numbers.
    await tester.scrollUntilVisible(find.text('Save Workout'), 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Save Workout'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save Workout'));
    await tester.tap(find.text('Save Workout'));
    await settle(tester);
    final all = (await tester.runAsync(() => repo.watchWorkouts().first))!;
    final today = all.firstWhere((w) => w.performedAt.day == 22);
    expect([today.sets, today.reps, today.loadKg], [4, 10, 14]);
    expect(today.notes, anyOf(isNull, isEmpty));
    await shutDown(tester, db);
  });

  testWidgets('time and distance come across too, and any of it can still be changed', (tester) async {
    final (db, _) = await _boot(tester, before: [_e('walking', 2, secs: 1530, meters: 2100)]);
    await tester.tap(find.byKey(const Key('again_walking')));
    await settle(tester, frames: 30);
    await tester.scrollUntilVisible(find.widgetWithText(TextField, 'Minutes'), 300, scrollable: find.byType(Scrollable).first);
    expect(_text(tester, 'Minutes'), '25');
    expect(_text(tester, 'Seconds'), '30');
    expect(_text(tester, 'Distance (Optional)'), '2.10');
    await tester.enterText(find.widgetWithText(TextField, 'Minutes'), '40');
    expect(_text(tester, 'Minutes'), '40');
    await shutDown(tester, db);
  });

  testWidgets('the shelf fits a small phone at large text and leaves the search and warm-up usable', (tester) async {
    final (db, _) = await _boot(tester, phoneSurface: false, before: [
      _e('dumbbell_press', 4, sets: 3, reps: 8, kg: 15),
      _e('walking', 3, secs: 1800, meters: 2500),
      _e('stretching', 2, secs: 420),
      _e('plank', 1, sets: 2, secs: 30),
    ]);
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await settle(tester, frames: 10);
    for (var i = 0; i < 5; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -260));
      await settle(tester, frames: 3);
    }
    expect(tester.takeException(), isNull);
    await shutDown(tester, db);
  });
}
