import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/first_steps.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

Future<AppDatabase> _openQuests(WidgetTester tester, {required bool withWorkout, bool smallest = false}) async {
  if (smallest) {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  } else {
    usePhone(tester);
  }
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
  await tester.tap(find.text('Quests'));
  await settle(tester, frames: 30);
  return db;
}

void main() {
  testWidgets('a first-timer is told what the quest board is for', (tester) async {
    final db = await _openQuests(tester, withWorkout: false);
    expect(find.byKey(const Key('quests_first_line')), findsOneWidget);
    expect(find.text(FirstSteps.questsLine), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('someone who has logged a workout never sees it', (tester) async {
    final db = await _openQuests(tester, withWorkout: true);
    expect(find.byKey(const Key('quests_first_line')), findsNothing);
    await shutDown(tester, db);
  });

  testWidgets('it fits on the smallest phone with the largest text', (tester) async {
    final db = await _openQuests(tester, withWorkout: false, smallest: true);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('quests_first_line')), findsOneWidget);
    await shutDown(tester, db);
  });

  test('it says the board is optional, and is kind and short', () {
    expect(FirstSteps.questsLine.toLowerCase(), contains('not orders'));
    expect(FirstSteps.questsLine.length, lessThan(150));
  });
}
