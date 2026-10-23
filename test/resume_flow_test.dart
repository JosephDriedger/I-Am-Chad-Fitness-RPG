import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/game_ui.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

bool _enabled(WidgetTester tester, String label) {
  final f = find.widgetWithText(FilledButton, label);
  if (f.evaluate().isNotEmpty) return tester.widget<FilledButton>(f).onPressed != null;
  final g = find.widgetWithText(GameButton, label);
  return g.evaluate().isNotEmpty && tester.widget<GameButton>(g).onPressed != null;
}

Future<void> _smartMove(WidgetTester tester) async {
  if (_enabled(tester, 'Potion')) {
    await tester.tap(find.text('Potion'));
  } else if (_enabled(tester, 'Power Strike')) {
    await tester.tap(find.text('Power Strike'));
  } else if (_enabled(tester, 'Attack')) {
    await tester.tap(find.text('Attack'));
  }
}

/// Plays until [stop] is true, tapping whatever is available.
Future<void> _playUntil(WidgetTester tester, bool Function() stop) async {
  for (var guard = 0; guard < 600; guard++) {
    if (stop()) return;
    if (_enabled(tester, 'Onward')) {
      await tester.tap(find.text('Onward'));
    } else if (_enabled(tester, 'Continue')) {
      await tester.tap(find.text('Continue'));
    } else if (_enabled(tester, 'See Results')) {
      await tester.tap(find.text('See Results'));
    } else {
      await _smartMove(tester);
    }
    await settle(tester, frames: 6);
  }
  fail('never reached the expected state');
}

void main() {
  testWidgets('leave an expedition mid-way, come back, and finish it', (tester) async {
    final semantics = tester.ensureSemantics();
    usePhone(tester);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = GameRepository(db);
    final now = DateTime(2026, 10, 22, 10);
    await tester.runAsync(() async {
      await repo.createHero(const HeroProfile(
        name: 'Ada',
        appearanceStyle: 0,
        appearanceColor: 0,
        experience: ExperienceLevel.starting,
        preferredCategories: {ActivityCategory.cardio},
        hasDumbbells: false,
      ));
      await repo.addWorkout(WorkoutEntry(activityId: 'walking', performedAt: now, durationSeconds: 600));
    });
    await bootApp(tester, db, now: now);

    // Set out.
    await tester.tap(find.text('Adventure'));
    await settle(tester, frames: 30);
    await tester.tap(find.text('Set Out'));
    await settle(tester, frames: 30);
    expect(find.text('Attack'), findsOneWidget);
    expect((await tester.runAsync(() => repo.activeExpedition()))!.stepIndex, 0);

    // Win the first battle and reach the camp (step 1), which is saved.
    await _playUntil(tester, () => _enabled(tester, 'Onward'));
    final before = (await tester.runAsync(() => repo.activeExpedition()))!;
    expect(before.stepIndex, 1);
    expect(before.battlesWon, 1);
    expect(before.xp, greaterThan(0));

    // Leave by going back and choosing "come back later".
    await tester.pageBack();
    await settle(tester, frames: 10);
    expect(find.text('Retreat from the Expedition?'), findsOneWidget);
    await tester.tap(find.text('Leave and Come Back Later'));
    await settle(tester, frames: 20);

    // Back on the Adventure screen the expedition is waiting, nothing lost.
    expect(find.text('Expedition in Progress'), findsOneWidget);
    expect(find.text('Resume Expedition'), findsOneWidget);
    expect((await tester.runAsync(() => repo.watchHero().first))!.energySpent, 2);

    // Resume: we are at the camp again, with the same HP and rewards.
    await tester.ensureVisible(find.text('Resume Expedition'));
    await tester.tap(find.text('Resume Expedition'));
    await settle(tester, frames: 30);
    expect(_enabled(tester, 'Onward'), isTrue);
    expect(find.bySemanticsLabel(RegExp('Expedition progress: step 2 of 4')), findsOneWidget);

    // Finish it.
    await _playUntil(tester, () => find.text('Back to the Guild').evaluate().isNotEmpty);
    await tester.tap(find.text('Back to the Guild'));
    await settle(tester, frames: 20);

    // It is over: no resume card, the save is cleared, energy was spent once.
    expect(find.text('Resume Expedition'), findsNothing);
    expect(await tester.runAsync(() => repo.activeExpedition()), isNull);
    final hero = (await tester.runAsync(() => repo.watchHero().first))!;
    expect(hero.energySpent, 2);
    expect(hero.adventureXp, greaterThanOrEqualTo(before.xp));

    semantics.dispose();
    await shutDown(tester, db);
  });

  testWidgets('abandoning keeps rewards earned so far and clears the save', (tester) async {
    usePhone(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = GameRepository(db);
    final now = DateTime(2026, 10, 22, 10);
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
    });
    await bootApp(tester, db, now: now);

    await tester.tap(find.text('Adventure'));
    await settle(tester, frames: 30);
    await tester.tap(find.text('Set Out'));
    await settle(tester, frames: 30);
    await _playUntil(tester, () => _enabled(tester, 'Onward'));
    final saved = (await tester.runAsync(() => repo.activeExpedition()))!;

    await tester.pageBack();
    await settle(tester, frames: 10);
    await tester.tap(find.text('Leave and Come Back Later'));
    await settle(tester, frames: 20);

    await tester.ensureVisible(find.text('Abandon and Keep Rewards'));
    await tester.tap(find.text('Abandon and Keep Rewards'));
    await settle(tester, frames: 10);
    await tester.tap(find.text('Abandon'));
    await settle(tester, frames: 20);

    expect(find.text('Resume Expedition'), findsNothing);
    expect(await tester.runAsync(() => repo.activeExpedition()), isNull);
    final hero = (await tester.runAsync(() => repo.watchHero().first))!;
    expect(hero.adventureXp, saved.xp);
    expect(hero.coins, saved.coins);
    expect(await tester.runAsync(() => repo.watchItems().first), isEmpty);

    await shutDown(tester, db);
  });
}
