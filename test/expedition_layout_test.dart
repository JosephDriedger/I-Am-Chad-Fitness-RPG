import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/game_ui.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/expedition.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

/// The expedition screens at the awkward sizes: a fork in the road with its two
/// buttons, a camp with the longest description, the battle with its four actions,
/// and the result panel. The panel under the scene is the part most likely to be
/// too tall when text is large.
class _Setup {
  const _Setup(this.name, this.width, this.height, this.textScale);

  final String name;
  final double width;
  final double height;
  final double textScale;
}

const _setups = [
  _Setup('smallest phone, largest text', 320, 568, 2.0),
  _Setup('small phone, big text', 360, 640, 1.5),
  _Setup('phone on its side', 640, 360, 1.0),
  _Setup('phone on its side, big text', 640, 360, 1.5),
];

void _noProblem(WidgetTester tester, String step) {
  final problem = tester.takeException();
  if (problem != null) fail('$step threw: ${problem is FlutterError ? problem.toStringDeep() : problem}');
}

/// Brings [target] fully on screen. Lists build lazily and their scroll extent grows as
/// they do, so one scroll can stop a few pixels short: scroll, let it settle, scroll again.
Future<void> _reveal(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(target, 250, scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.ensureVisible(target);
  await tester.pump();
}

bool _enabled(WidgetTester tester, String label) {
  final f = find.widgetWithText(FilledButton, label);
  if (f.evaluate().isNotEmpty) return tester.widget<FilledButton>(f).onPressed != null;
  final g = find.widgetWithText(GameButton, label);
  return g.evaluate().isNotEmpty && tester.widget<GameButton>(g).onPressed != null;
}

/// A seed and step whose expedition in [tier] has a camp with this [title].
(int, int) _campWithTitle(int tier, String title) {
  for (var seed = 1; seed < 20000; seed++) {
    final e = Expedition.generate(seed: seed, heroLevel: 20, tier: tier);
    for (var i = 0; i < e.steps.length; i++) {
      if (e.steps[i].event?.title == title) return (seed, i);
    }
  }
  fail('no seed has "$title" in region $tier');
}

/// Boots a hero standing at a camp [step] of an expedition in [tier].
Future<AppDatabase> _standAtCamp(WidgetTester tester, int tier, (int, int) camp) async {
  final (seed, step) = camp;
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = GameRepository(db);
  await tester.runAsync(() async {
    await repo.createHero(const HeroProfile(
      name: 'Ada the Very Long Named',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.starting,
      preferredCategories: {},
      hasDumbbells: false,
    ));
    await repo.addWorkout(WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 22, 9), durationSeconds: 600));
    await repo.saveExpeditionProgress(ExpeditionProgress(
      seed: seed,
      heroLevel: 20,
      stepIndex: step,
      heroHp: 30,
      potions: 2,
      battlesWon: 1,
      xp: 17,
      coins: 6,
      tier: tier,
    ));
  });
  await bootApp(tester, db, now: DateTime(2026, 10, 22, 10));
  await tester.tap(find.text('Adventure'));
  await settle(tester, frames: 30);
  await _reveal(tester, find.text('Resume Expedition'));
  await tester.tap(find.text('Resume Expedition'));
  await settle(tester, frames: 30);
  _noProblem(tester, 'resuming at a camp');
  return db;
}

void main() {
  for (final s in _setups) {
    void useSize(WidgetTester tester) {
      tester.view.physicalSize = Size(s.width * 2, s.height * 2);
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = s.textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    testWidgets('a fork in the road fits: ${s.name}', (tester) async {
      useSize(tester);
      final db = await _standAtCamp(tester, 2, _campWithTitle(2, 'A Fork in the Road'));
      expect(find.text('A Fork in the Road'), findsOneWidget);
      // Both ways can be reached, scrolling if the panel needs it.
      for (final key in const [Key('fork_0'), Key('fork_1')]) {
        await _reveal(tester, find.byKey(key));
        expect(find.byKey(key), findsOneWidget);
        _noProblem(tester, 'showing $key');
      }
      await tester.tap(find.byKey(const Key('fork_1')));
      await settle(tester, frames: 40);
      _noProblem(tester, 'taking the second way');
      expect(find.text('Attack'), findsOneWidget, reason: 'on to the next fight');
      await shutDown(tester, db);
    });

    testWidgets('a camp with a long description fits: ${s.name}', (tester) async {
      useSize(tester);
      final db = await _standAtCamp(tester, 6, _campWithTitle(6, 'A Riddle for a Coin'));
      expect(find.text('A Riddle for a Coin'), findsOneWidget);
      await _reveal(tester, find.text('Onward'));
      _noProblem(tester, 'the long camp');
      await tester.tap(find.text('Onward'));
      await settle(tester, frames: 40);
      _noProblem(tester, 'leaving the camp');
      await shutDown(tester, db);
    });

    testWidgets('a battle and its result fit: ${s.name}', (tester) async {
      useSize(tester);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.runAsync(() => GameRepository(db).createHero(const HeroProfile(
            name: 'Ada the Very Long Named',
            appearanceStyle: 0,
            appearanceColor: 0,
            experience: ExperienceLevel.starting,
            preferredCategories: {},
            hasDumbbells: false,
          )));
      await bootApp(tester, db, now: DateTime(2026, 10, 22, 10));
      await tester.tap(find.text('Adventure'));
      await settle(tester, frames: 30);
      await _reveal(tester, find.text('Practice Duel'));
      await tester.tap(find.text('Practice Duel'));
      await settle(tester, frames: 30);
      _noProblem(tester, 'opening the duel');

      // All four actions are there, and each can be reached.
      for (final a in ['Attack', 'Guard', 'Power Strike', 'Potion']) {
        expect(find.text(a), findsOneWidget, reason: a);
      }
      for (var guard = 0; guard < 400 && find.text('Back to the Guild').evaluate().isEmpty; guard++) {
        if (_enabled(tester, 'Continue')) {
          await tester.tap(find.text('Continue').first);
        } else if (_enabled(tester, 'See Results')) {
          await tester.tap(find.text('See Results').first);
        } else if (_enabled(tester, 'Attack')) {
          await tester.tap(find.text('Attack').first);
        }
        await settle(tester, frames: 6);
        _noProblem(tester, 'fighting, step $guard');
      }
      expect(find.text('Back to the Guild'), findsOneWidget);
      await _reveal(tester, find.text('Back to the Guild'));
      _noProblem(tester, 'the result panel');
      await shutDown(tester, db);
    });
  }
}
