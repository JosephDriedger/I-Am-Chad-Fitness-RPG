import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/app.dart';
import 'package:i_am_chad/app/providers.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('earn energy, play a practice duel and a full expedition',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => now),
      ],
      child: const IAmChadApp(),
    ));
    await _settle(tester);

    await tester.tap(find.text('Adventure').last);
    await _settle(tester);

    // No energy yet: the expedition is locked, practice is free.
    expect(find.text('Need 2 energy'), findsOneWidget);

    await tester.tap(find.text('Practice duel'));
    await _settle(tester);
    await _fightToTheEnd(tester);
    expect(find.text('Rewards'), findsOneWidget);
    await tester.tap(find.text('Back to the Guild'));
    await _settle(tester);

    // Log a walk elsewhere (ten minutes -> 2 energy) and the expedition unlocks.
    await tester.runAsync(() => repo.addWorkout(WorkoutEntry(
          activityId: 'walking',
          performedAt: now,
          durationSeconds: 600,
        )));
    await _settle(tester);
    expect(find.text('Set out'), findsOneWidget);

    await tester.tap(find.text('Set out'));
    await _settle(tester);
    expect(find.text('Battle 1 of 3'), findsOneWidget);

    // Play through battles and the event until the result screen.
    for (var guard = 0; guard < 400; guard++) {
      if (find.text('Back to the Guild').evaluate().isNotEmpty) break;
      if (find.text('Onward').evaluate().isNotEmpty) {
        await tester.tap(find.text('Onward'));
      } else if (find.text('Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue'));
      } else if (find.text('See results').evaluate().isNotEmpty) {
        await tester.tap(find.text('See results'));
      } else {
        await _smartMove(tester);
      }
      await _settle(tester);
    }
    expect(find.text('Back to the Guild'), findsOneWidget);
    expect(find.textContaining('XP'), findsWidgets);

    await tester.tap(find.text('Back to the Guild'));
    await _settle(tester);

    // Energy was spent exactly once and results were saved.
    final hero = await tester.runAsync(() => repo.watchHero().first);
    expect(hero!.energySpent, 2);
    expect(hero.adventureXp, greaterThan(0));
    expect(find.text('0 energy'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  });
}

Future<void> _smartMove(WidgetTester tester) async {
  bool enabled(String label) {
    final f = find.widgetWithText(FilledButton, label);
    return f.evaluate().isNotEmpty &&
        tester.widget<FilledButton>(f).onPressed != null;
  }

  if (enabled('Potion') && find.textContaining('winding').evaluate().isEmpty) {
    // Only drink when the button is live (i.e. we are hurt).
    await tester.tap(find.text('Potion'));
  } else if (enabled('Power Strike')) {
    await tester.tap(find.text('Power Strike'));
  } else {
    await tester.tap(find.text('Attack'));
  }
}

Future<void> _fightToTheEnd(WidgetTester tester) async {
  for (var guard = 0; guard < 200; guard++) {
    if (find.text('Back to the Guild').evaluate().isNotEmpty) return;
    if (find.text('Continue').evaluate().isNotEmpty) {
      await tester.tap(find.text('Continue'));
    } else if (find.text('See results').evaluate().isNotEmpty) {
      await tester.tap(find.text('See results'));
    } else {
      await _smartMove(tester);
    }
    await _settle(tester);
  }
}
