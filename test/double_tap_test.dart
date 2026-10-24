import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/game_ui.dart';
import 'package:i_am_chad/app/providers.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/expedition.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

bool _enabled(WidgetTester tester, String label) {
  final g = find.widgetWithText(GameButton, label);
  if (g.evaluate().isNotEmpty) return tester.widget<GameButton>(g).onPressed != null;
  final f = find.widgetWithText(FilledButton, label);
  return f.evaluate().isNotEmpty && tester.widget<FilledButton>(f).onPressed != null;
}

Future<void> _fightUntil(WidgetTester tester, String label) async {
  for (var guard = 0; guard < 300 && !_enabled(tester, label); guard++) {
    if (_enabled(tester, 'Potion')) {
      await tester.tap(find.text('Potion'));
    } else if (_enabled(tester, 'Power Strike')) {
      await tester.tap(find.text('Power Strike'));
    } else if (_enabled(tester, 'Attack')) {
      await tester.tap(find.text('Attack'));
    }
    await settle(tester, frames: 6);
  }
}

/// A phone writes to storage in the background, so saving takes a moment. Slow it
/// down so a second tap can land while the first is still being handled.
class _SlowRepository extends GameRepository {
  _SlowRepository(super.db);

  @override
  Future<void> saveExpeditionProgress(ExpeditionProgress p) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await super.saveExpeditionProgress(p);
  }
}

void main() {
  testWidgets('tapping Continue twice in a row moves on one step, not two', (tester) async {
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
    await bootApp(tester, db, now: now, overrides: [repositoryProvider.overrideWithValue(_SlowRepository(db))]);

    await tester.tap(find.text('Adventure'));
    await settle(tester, frames: 30);
    await tester.tap(find.text('Set Out'));
    await settle(tester, frames: 30);

    await _fightUntil(tester, 'Continue');
    expect(_enabled(tester, 'Continue'), isTrue, reason: 'the first battle should be won');

    // Two taps before the screen has had a frame to react to the first.
    await tester.tap(find.text('Continue'));
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await settle(tester, frames: 40);

    final saved = await tester.runAsync(() => repo.activeExpedition());
    expect(saved, isNotNull);
    expect(saved!.battlesWon, 1, reason: 'one battle was won');
    expect(saved.stepIndex, 1, reason: 'the camp is next; the second tap must not skip it');
    expect(find.text('Onward'), findsOneWidget);

    await shutDown(tester, db);
  });
}
