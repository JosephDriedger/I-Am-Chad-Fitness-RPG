import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

bool _enabled(WidgetTester tester, String label) {
  final f = find.widgetWithText(FilledButton, label);
  return f.evaluate().isNotEmpty && tester.widget<FilledButton>(f).onPressed != null;
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

/// Plays whatever is on screen until the result panel shows.
Future<void> _playToTheEnd(WidgetTester tester) async {
  for (var guard = 0; guard < 600; guard++) {
    if (find.text('Back to the Guild').evaluate().isNotEmpty) return;
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
}

void main() {
  testWidgets('earn energy, play a practice duel and a full expedition',
      (tester) async {
    final semantics = tester.ensureSemantics();
    usePhone(tester);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = GameRepository(db);
    final now = DateTime(2026, 10, 22, 10);
    await tester.runAsync(() => repo.createHero(const HeroProfile(
          name: 'Ada',
          appearanceStyle: 0,
          appearanceColor: 0,
          experience: ExperienceLevel.starting,
          preferredCategories: {ActivityCategory.cardio},
          hasDumbbells: false,
        )));

    await bootApp(tester, db, now: now);

    // No energy yet: the hall shows it, the expedition is locked, practice is free.
    expect(find.bySemanticsLabel('Adventure energy: 0'), findsOneWidget);
    await tester.tap(find.text('Adventure'));
    await settle(tester, frames: 30);
    expect(find.text('Need 2 Energy'), findsOneWidget);

    await tester.tap(find.text('Practice Duel'));
    await settle(tester, frames: 30);
    expect(find.text('Attack'), findsOneWidget);
    await _playToTheEnd(tester);
    expect(find.text('Back to the Guild'), findsOneWidget);
    await tester.tap(find.text('Back to the Guild'));
    await settle(tester, frames: 20);

    // Log a walk elsewhere (ten minutes -> 2 energy) and the expedition unlocks.
    await tester.runAsync(() => repo.addWorkout(WorkoutEntry(
          activityId: 'walking',
          performedAt: now,
          durationSeconds: 600,
        )));
    await settle(tester);
    expect(find.text('Set Out'), findsOneWidget);

    await tester.tap(find.text('Set Out'));
    await settle(tester, frames: 30);
    expect(find.text('Attack'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Expedition progress: step 1 of 4')), findsOneWidget);

    await _playToTheEnd(tester);
    expect(find.text('Back to the Guild'), findsOneWidget);
    expect(find.textContaining('XP'), findsWidgets);

    await tester.tap(find.text('Back to the Guild'));
    await settle(tester, frames: 20);

    // Energy was spent exactly once and results were saved.
    final hero = await tester.runAsync(() => repo.watchHero().first);
    expect(hero!.energySpent, 2);
    expect(hero.adventureXp, greaterThan(0));

    semantics.dispose();
    await shutDown(tester, db);
  });
}
