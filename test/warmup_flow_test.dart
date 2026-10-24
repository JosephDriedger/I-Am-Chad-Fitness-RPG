import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/warmup.dart';

import 'helpers.dart';

Future<AppDatabase> _openTrain(WidgetTester tester) async {
  usePhone(tester);
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
  return db;
}

Future<void> _tapLabel(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await settle(tester);
}

void main() {
  testWidgets('the warm-up is offered on the Train screen and plays through to the end', (tester) async {
    final db = await _openTrain(tester);
    expect(find.text(WarmUp.title), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('warmup_start')));
    await tester.tap(find.byKey(const Key('warmup_start')));
    await settle(tester, frames: 20);
    expect(find.text(WarmUp.intro), findsOneWidget);
    expect(find.text(WarmUp.note), findsOneWidget);

    await _tapLabel(tester, 'Begin');
    expect(find.text('Move 1 of ${WarmUp.steps.length}: Hip Circles'), findsOneWidget);
    expect(find.text('15 s'), findsOneWidget);

    // Time moves the guide along by itself.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('12 s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 12));
    expect(find.text('Move 2 of ${WarmUp.steps.length}: Side Bend'), findsOneWidget);

    // Pausing holds the countdown for as long as you like.
    await _tapLabel(tester, 'Pause');
    expect(find.text('Paused'), findsOneWidget);
    await tester.pump(const Duration(seconds: 60));
    expect(find.text('Move 2 of ${WarmUp.steps.length}: Side Bend'), findsOneWidget);
    await _tapLabel(tester, 'Resume');
    expect(find.text('15 s'), findsOneWidget);

    // Any move can be skipped, and the last button says Finish.
    await _tapLabel(tester, 'Next Move');
    expect(find.text('Move 3 of ${WarmUp.steps.length}: Shoulder Stretch'), findsOneWidget);
    await _tapLabel(tester, 'Next Move');
    expect(find.text('Finish'), findsOneWidget);
    await _tapLabel(tester, 'Finish');
    expect(find.text(WarmUp.finish), findsOneWidget);

    await _tapLabel(tester, 'Back to the Yard');
    expect(find.text(WarmUp.title), findsOneWidget, reason: 'back on the Train screen');
    await shutDown(tester, db);
  });

  testWidgets('leaving part-way is fine, and the warm-up earns and saves nothing', (tester) async {
    final db = await _openTrain(tester);
    await tester.ensureVisible(find.byKey(const Key('warmup_start')));
    await tester.tap(find.byKey(const Key('warmup_start')));
    await settle(tester, frames: 20);
    await _tapLabel(tester, 'Begin');
    await tester.pump(const Duration(seconds: 4));

    final before = await tester.runAsync(() => GameRepository(db).watchHero().first);
    await tester.pageBack();
    await settle(tester, frames: 20);
    expect(find.text(WarmUp.title), findsOneWidget);
    // The timer died with the screen: time passing does nothing.
    await tester.pump(const Duration(seconds: 90));
    final after = await tester.runAsync(() => GameRepository(db).watchHero().first);
    expect(after!.experience, before!.experience);
    expect(after.coins, before.coins);
    final workouts = await tester.runAsync(() => GameRepository(db).watchWorkouts().first);
    expect(workouts, isEmpty);
    await shutDown(tester, db);
  });
}
