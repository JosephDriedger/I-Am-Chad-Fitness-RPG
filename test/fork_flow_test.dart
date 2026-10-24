import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/expedition.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

/// A seed whose camp, in a region-2 expedition, is the general fork in the road.
int _forkSeed() {
  for (var seed = 1; seed < 5000; seed++) {
    final e = Expedition.generate(seed: seed, heroLevel: 5, tier: 2);
    if (e.steps[1].event?.title == 'A Fork in the Road') return seed;
  }
  fail('no seed has a fork at the first camp');
}

Future<void> _standAtFork(WidgetTester tester, int way) async {
  usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = GameRepository(db);
  final now = DateTime(2026, 10, 22, 10);
  final seed = _forkSeed();
  await tester.runAsync(() async {
    await repo.createHero(const HeroProfile(
      name: 'Ada',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.starting,
      preferredCategories: {},
      hasDumbbells: false,
    ));
    await repo.addWorkout(WorkoutEntry(activityId: 'walking', performedAt: now, durationSeconds: 600));
    // A hurt hero, standing at the camp after the first battle.
    await repo.saveExpeditionProgress(ExpeditionProgress(
      seed: seed,
      heroLevel: 5,
      stepIndex: 1,
      heroHp: 20,
      potions: 2,
      battlesWon: 1,
      xp: 17,
      coins: 6,
      tier: 2,
    ));
  });
  await bootApp(tester, db, now: now);
  await tester.tap(find.text('Adventure'));
  await settle(tester, frames: 30);
  await tester.ensureVisible(find.text('Resume Expedition'));
  await tester.tap(find.text('Resume Expedition'));
  await settle(tester, frames: 30);

  // The path splits: two buttons, each saying what it gives, and no plain "Onward".
  expect(find.text('A Fork in the Road'), findsOneWidget);
  expect(find.text('Either way is a good way.'), findsOneWidget);
  expect(find.text('Take the sunny path'), findsOneWidget);
  expect(find.text('Take the shady path'), findsOneWidget);
  expect(find.text('Start the next fight with 2 focus'), findsOneWidget);
  expect(find.text('Recover 25% of your max HP'), findsOneWidget);
  expect(find.text('Onward'), findsNothing);

  await tester.ensureVisible(find.byKey(Key('fork_$way')));
  await tester.tap(find.byKey(Key('fork_$way')));
  await settle(tester, frames: 40);

  // On to the next fight, with the effect of the way taken and nothing else.
  final after = (await tester.runAsync(() => repo.activeExpedition()))!;
  expect(after.stepIndex, 2);
  if (way == 0) {
    expect(after.focus, 2, reason: 'the sunny path starts the next fight with focus');
    expect(after.heroHp, 20, reason: 'and heals nothing');
  } else {
    expect(after.heroHp, greaterThan(20), reason: 'the shady path heals');
    expect(after.focus, 0);
  }
  await shutDown(tester, db);
}

void main() {
  testWidgets('a fork in the road: taking the sunny path starts the next fight with focus', (tester) async {
    await _standAtFork(tester, 0);
  });

  testWidgets('a fork in the road: taking the shady path heals', (tester) async {
    await _standAtFork(tester, 1);
  });
}
