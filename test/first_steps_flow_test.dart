import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/first_steps.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

const _otherLine = 'Pick what you did. Any version counts, and you can edit or delete it later.';

Future<AppDatabase> _boot(WidgetTester tester, {required bool withWorkout}) async {
  usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await tester.runAsync(() async {
    final repo = GameRepository(db);
    await repo.createHero(const HeroProfile(
      name: 'Ada',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.starting,
      preferredCategories: {},
      hasDumbbells: false,
    ));
    if (withWorkout) {
      await repo.addWorkout(WorkoutEntry(activityId: 'walking', performedAt: DateTime.now(), durationSeconds: 600));
    }
  });
  await bootApp(tester, db);
  await tester.tap(find.text('Train'));
  await settle(tester, frames: 30);
  return db;
}

void main() {
  testWidgets('a first-timer is welcomed on Train and shown three steps on the log screen', (tester) async {
    final db = await _boot(tester, withWorkout: false);
    expect(find.text(FirstSteps.trainLine), findsOneWidget);
    expect(find.text(_otherLine), findsNothing);

    await openExercise(tester, 'Walking');
    expect(find.byKey(const Key('first_log_panel')), findsOneWidget);
    expect(find.text(FirstSteps.logTitle), findsOneWidget);
    expect(find.text(FirstSteps.logIntro), findsOneWidget);
    for (final s in FirstSteps.logSteps) {
      expect(find.textContaining(s.title), findsOneWidget, reason: s.title);
    }

    // It never gets in the way: the normal form is still right below it.
    await tester.scrollUntilVisible(find.widgetWithText(TextField, 'Minutes'), 300, scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.widgetWithText(TextField, 'Minutes'), '10');
    await tester.scrollUntilVisible(find.text('Save Workout'), 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Save Workout'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save Workout'));
    await tester.tap(find.text('Save Workout'));
    await settle(tester);
    expect(find.text('Workout Saved!'), findsOneWidget);
    await tester.tap(find.text('Nice'));
    await settle(tester);

    // After the first workout it is gone for good.
    expect(find.byKey(const Key('first_log_panel')), findsNothing);
    await tester.pageBack();
    await settle(tester, frames: 12);
    await tester.tap(find.text('Train'));
    await settle(tester, frames: 30);
    expect(find.text(FirstSteps.trainLine), findsNothing);
    expect(find.text(_otherLine), findsOneWidget);

    await openExercise(tester, 'Walking');
    expect(find.byKey(const Key('first_log_panel')), findsNothing);
    await shutDown(tester, db);
  });

  testWidgets('the first-time guidance fits on the smallest phone with the largest text', (tester) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.runAsync(() => GameRepository(db).createHero(const HeroProfile(
          name: 'Ada',
          appearanceStyle: 0,
          appearanceColor: 0,
          experience: ExperienceLevel.starting,
          preferredCategories: {},
          hasDumbbells: false,
        )));
    await bootApp(tester, db);
    await tester.tap(find.text('Train'));
    await settle(tester, frames: 30);
    expect(tester.takeException(), isNull);
    expect(find.text(FirstSteps.trainLine), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(TextField), 250, scrollable: find.byType(Scrollable).first);
    await openExercise(tester, 'Walking');
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.byKey(const Key('first_log_panel')), 250, scrollable: find.byType(Scrollable).first);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('first_log_panel')), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('someone who has logged before never sees the first-time guidance', (tester) async {
    final db = await _boot(tester, withWorkout: true);
    expect(find.text(FirstSteps.trainLine), findsNothing);
    expect(find.text(_otherLine), findsOneWidget);
    await openExercise(tester, 'Walking');
    expect(find.byKey(const Key('first_log_panel')), findsNothing);
    await shutDown(tester, db);
  });

  test('the steps name things that really are on the log screen', () {
    expect(FirstSteps.logSteps.length, 3);
    expect(FirstSteps.logSteps.last.title, contains('Save Workout'));
    // The effort fields it describes exist for walking: time and distance.
    expect(ActivityCatalog.byId('walking')!.metrics, contains(Metric.duration));
  });

  test('the words are kind, short and finished sentences', () {
    const banned = ['lazy', 'weak', 'failure', 'failed', 'excuse', 'weight', 'in shape', 'hurry', 'must ', 'no pain', 'deadline', 'streak'];
    for (final w in FirstSteps.words) {
      final lower = w.toLowerCase();
      for (final b in banned) {
        expect(lower.contains(b), isFalse, reason: '"$b" in: $w');
      }
      expect(w.length, lessThan(150), reason: w);
    }
    for (final s in [FirstSteps.trainLine, FirstSteps.logIntro, ...FirstSteps.logSteps.map((s) => s.text)]) {
      expect(RegExp(r'[.!?]$').hasMatch(s), isTrue, reason: s);
    }
    // Rough numbers are fine, and easier is the same, as the rest of the game says.
    final all = FirstSteps.words.join(' ').toLowerCase();
    expect(all, contains('exactly the same'));
    expect(all, contains('rough numbers are fine'));
  });
}
