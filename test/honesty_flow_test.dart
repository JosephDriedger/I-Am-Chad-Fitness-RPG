import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';

import 'helpers.dart';

Future<(AppDatabase, GameRepository)> _boot(WidgetTester tester) async {
  usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = GameRepository(db);
  await tester.runAsync(() => repo.createHero(const HeroProfile(
        name: 'Ada',
        appearanceStyle: 0,
        appearanceColor: 0,
        experience: ExperienceLevel.starting,
        preferredCategories: {},
        hasDumbbells: false,
      )));
  await bootApp(tester, db, now: DateTime(2026, 10, 22, 10));
  await tester.tap(find.text('Train'));
  await settle(tester, frames: 30);
  await tester.tap(find.text('Walking'));
  await settle(tester);
  return (db, repo);
}

Future<void> _fill(WidgetTester tester, {required String minutes, required String km}) async {
  await tester.enterText(find.widgetWithText(TextField, 'Minutes'), minutes);
  await tester.enterText(find.widgetWithText(TextField, 'Distance (Optional)'), km);
  await settle(tester);
}

Future<void> _save(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('Save Workout'), 300,
      scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(find.text('Save Workout'));
  await tester.tap(find.text('Save Workout'));
  await settle(tester);
}

void main() {
  testWidgets('an impossible pace warns, and the player can go back and fix it', (tester) async {
    final (db, repo) = await _boot(tester);

    // Normal numbers: no warning anywhere.
    await _fill(tester, minutes: '20', km: '2');
    expect(find.text('Does This Look Right?'), findsNothing);

    // 10 km in 20 minutes of walking: a heads-up appears as they type.
    await _fill(tester, minutes: '20', km: '10');
    expect(find.text('Does This Look Right?'), findsOneWidget);
    expect(find.textContaining('30 km/h'), findsOneWidget);

    // Saving asks first; "Let Me Fix It" saves nothing.
    await _save(tester);
    expect(find.text('Quick Honesty Check'), findsOneWidget);
    expect(find.textContaining('Nobody checks but you'), findsWidgets);
    await tester.tap(find.text('Let Me Fix It'));
    await settle(tester);
    expect(find.text('Workout Saved!'), findsNothing);
    expect(await tester.runAsync(() => repo.watchWorkouts().first), isEmpty);

    // Correcting the typo clears the warning and saves with no questions.
    await _fill(tester, minutes: '20', km: '2');
    expect(find.text('Does This Look Right?'), findsNothing);
    await _save(tester);
    expect(find.text('Quick Honesty Check'), findsNothing);
    expect(find.text('Workout Saved!'), findsOneWidget);
    expect(await tester.runAsync(() => repo.watchWorkouts().first), hasLength(1));

    await shutDown(tester, db);
  });

  testWidgets('"It\'s Accurate" saves exactly what was entered, with normal rewards', (tester) async {
    final (db, repo) = await _boot(tester);

    await _fill(tester, minutes: '20', km: '10');
    await _save(tester);
    await tester.tap(find.text('It\'s Accurate'));
    await settle(tester);

    // The warning is only a question: nothing is withheld or reduced.
    expect(find.text('Workout Saved!'), findsOneWidget);
    expect(find.text('80 XP'), findsOneWidget);
    final saved = (await tester.runAsync(() => repo.watchWorkouts().first))!.single;
    expect(saved.distanceMeters, 10000);
    expect(saved.durationSeconds, 1200);

    await shutDown(tester, db);
  });

  testWidgets('a rep-based entry that is far too quick is questioned too', (tester) async {
    usePhone(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = GameRepository(db);
    await tester.runAsync(() => repo.createHero(const HeroProfile(
          name: 'Ada',
          appearanceStyle: 0,
          appearanceColor: 0,
          experience: ExperienceLevel.starting,
          preferredCategories: {ActivityCategory.bodyweight},
          hasDumbbells: false,
        )));
    await bootApp(tester, db, now: DateTime(2026, 10, 22, 10));
    await tester.tap(find.text('Train'));
    await settle(tester, frames: 30);
    await tester.tap(find.text('Push-ups'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Sets'), '1');
    await tester.enterText(find.widgetWithText(TextField, 'Reps per Set'), '2');
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Does This Look Right?'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Does This Look Right?'), findsOneWidget);
    expect(find.textContaining('under 20 seconds'), findsOneWidget);
    await shutDown(tester, db);
  });
}
