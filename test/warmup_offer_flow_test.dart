import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/first_steps.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/warmup.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

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
  await bootApp(tester, db, warmUpOffers: true);
  return db;
}

void main() {
  testWidgets('a first-timer is offered the warm-up in the hall, and can say not now', (tester) async {
    final db = await _boot(tester, withWorkout: false);
    expect(find.text(FirstSteps.warmUpOfferTitle), findsOneWidget);
    expect(find.text(FirstSteps.warmUpOfferText), findsOneWidget);

    await tester.tap(find.byKey(const Key('warmup_offer_no')));
    await settle(tester, frames: 20);
    expect(find.text(FirstSteps.warmUpOfferTitle), findsNothing);
    // The hall is as it was, and the warm-up is still on the Train screen.
    expect(find.text('Train'), findsWidgets);
    await tester.tap(find.text('Train'));
    await settle(tester, frames: 30);
    expect(find.byKey(const Key('warmup_start')), findsOneWidget);
    // Going round again does not bring the offer back.
    await tester.pageBack();
    await settle(tester, frames: 20);
    expect(find.text(FirstSteps.warmUpOfferTitle), findsNothing);
    await shutDown(tester, db);
  });

  testWidgets('saying yes opens the warm-up, and finishing it returns to the hall', (tester) async {
    final db = await _boot(tester, withWorkout: false);
    await tester.tap(find.byKey(const Key('warmup_offer_yes')));
    await settle(tester, frames: 20);
    expect(find.text(WarmUp.intro), findsOneWidget);

    await tester.pageBack();
    await settle(tester, frames: 20);
    expect(find.text(WarmUp.intro), findsNothing);
    expect(find.text(FirstSteps.warmUpOfferTitle), findsNothing);
    // It paid nothing and saved nothing.
    final workouts = await tester.runAsync(() => GameRepository(db).watchWorkouts().first);
    expect(workouts, isEmpty);
    await shutDown(tester, db);
  });

  testWidgets('the offer fits on the smallest phone with the largest text', (tester) async {
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
    await bootApp(tester, db, warmUpOffers: true);
    expect(find.text(FirstSteps.warmUpOfferTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('warmup_offer_yes')), findsOneWidget);
    expect(find.byKey(const Key('warmup_offer_no')), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('someone who has logged a workout is never offered it', (tester) async {
    final db = await _boot(tester, withWorkout: true);
    expect(find.text(FirstSteps.warmUpOfferTitle), findsNothing);
    await shutDown(tester, db);
  });

  test('the offer is kind and short', () {
    expect(FirstSteps.warmUpOfferText.length, lessThan(150));
    expect(FirstSteps.warmUpOfferText, contains('stop any time'));
    expect(FirstSteps.warmUpOfferText, contains('no rewards'));
  });
}
