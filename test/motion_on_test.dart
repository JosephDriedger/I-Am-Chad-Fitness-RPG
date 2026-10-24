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

/// Nearly every other test runs with Reduce Motion on, so scenes finish each
/// animation in one frame. These run the real animations (battle moves, the logo,
/// the pulsing button, particles) for a few seconds at a time and fail on any
/// exception, as a smoke test for code that only runs when motion is on.
bool _enabled(WidgetTester tester, String label) {
  final f = find.widgetWithText(FilledButton, label);
  if (f.evaluate().isNotEmpty) return tester.widget<FilledButton>(f).onPressed != null;
  final g = find.widgetWithText(GameButton, label);
  return g.evaluate().isNotEmpty && tester.widget<GameButton>(g).onPressed != null;
}

/// Lets real time pass in small steps, so animations play frame by frame.
Future<void> _play(WidgetTester tester, {int ms = 1000, int step = 50}) async {
  for (var t = 0; t < ms; t += step) {
    await tester.pump(Duration(milliseconds: step));
  }
}

void _noProblem(WidgetTester tester, String step) {
  final problem = tester.takeException();
  if (problem != null) fail('$step threw: ${problem is FlutterError ? problem.toStringDeep() : problem}');
}

Future<AppDatabase> _withHero(WidgetTester tester, {bool workout = false}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await tester.runAsync(() async {
    final repo = GameRepository(db);
    await repo.createHero(const HeroProfile(
      name: 'Ada',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.starting,
      preferredCategories: {ActivityCategory.cardio},
      hasDumbbells: false,
    ));
    if (workout) {
      await repo.addWorkout(WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 22, 9), durationSeconds: 600));
    }
  });
  return db;
}

/// Taps whatever moves the battle on, then lets the animation play.
Future<void> _playBattle(WidgetTester tester, {required String until}) async {
  for (var guard = 0; guard < 900; guard++) {
    if (find.text(until).evaluate().isNotEmpty) return;
    if (_enabled(tester, 'Onward')) {
      await tester.tap(find.text('Onward'));
    } else if (_enabled(tester, 'Continue')) {
      await tester.tap(find.text('Continue'));
    } else if (_enabled(tester, 'See Results')) {
      await tester.tap(find.text('See Results'));
    } else if (_enabled(tester, 'Potion')) {
      await tester.tap(find.text('Potion'));
    } else if (_enabled(tester, 'Power Strike')) {
      await tester.tap(find.text('Power Strike'));
    } else if (_enabled(tester, 'Attack')) {
      await tester.tap(find.text('Attack'));
    }
    await _play(tester, ms: 200);
    _noProblem(tester, 'playing the battle, step $guard');
  }
  fail('the battle never reached "$until"');
}

void main() {
  for (final size in [const Size(450, 950), const Size(320, 568)]) {
    final label = '${size.width.round()} x ${size.height.round()}';

    testWidgets('the logo and the pulsing button animate on the title screen, at $label', (tester) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      final db = await _withHero(tester);
      await bootApp(tester, db, showTitle: true, reducedMotion: false);
      await _play(tester, ms: 2500);
      _noProblem(tester, 'the animated title screen');
      expect(find.text('Tap to Continue'), findsOneWidget);
      await tester.tap(find.text('Tap to Continue'));
      await _play(tester, ms: 1500);
      _noProblem(tester, 'leaving the animated title screen');
      expect(find.byTooltip('Settings'), findsOneWidget);
      await shutDown(tester, db);
    });

    testWidgets('onboarding plays with its animated logo, at $label', (tester) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await bootApp(tester, db, reducedMotion: false);
      await _play(tester, ms: 2000);
      _noProblem(tester, 'the animated welcome');
      await tester.tap(find.text("Let's Go"));
      await _play(tester, ms: 800);
      await tester.enterText(find.byType(TextField).first, 'Ada');
      await _play(tester, ms: 300);
      await tester.tap(find.text('Next'));
      await _play(tester, ms: 800);
      await tester.tap(find.text('Enter the Guild'));
      await _play(tester, ms: 2500);
      _noProblem(tester, 'entering the guild with motion on');
      expect(find.byTooltip('Settings'), findsOneWidget);
      await shutDown(tester, db);
    });

    testWidgets('the hall and its menu animate while you walk between them, at $label', (tester) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      final db = await _withHero(tester, workout: true);
      await bootApp(tester, db, now: DateTime(2026, 10, 22, 10), reducedMotion: false);
      await _play(tester, ms: 3000);
      _noProblem(tester, 'the animated hall');
      for (final dest in ['Train', 'Quests', 'Hero', 'Journal', 'Adventure']) {
        await tester.tap(find.text(dest));
        await _play(tester, ms: 2500); // the hero walks to it, then the page opens
        _noProblem(tester, 'walking to $dest');
        await tester.pageBack();
        await _play(tester, ms: 1500);
        _noProblem(tester, 'coming back from $dest');
      }
      await shutDown(tester, db);
    });
  }

  testWidgets('a practice duel and a full expedition play out with every animation on', (tester) async {
    tester.view.physicalSize = const Size(900, 1900);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final db = await _withHero(tester, workout: true);
    await bootApp(tester, db, now: DateTime(2026, 10, 22, 10), reducedMotion: false);
    await _play(tester, ms: 1500);

    await tester.tap(find.text('Adventure'));
    await _play(tester, ms: 3000);
    await tester.scrollUntilVisible(find.text('Practice Duel'), 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Practice Duel'));
    await _play(tester, ms: 300);
    await tester.tap(find.text('Practice Duel'));
    await _play(tester, ms: 2500);
    expect(find.text('Attack'), findsOneWidget);
    await _playBattle(tester, until: 'Back to the Guild');
    await tester.tap(find.text('Back to the Guild'));
    await _play(tester, ms: 1500);
    _noProblem(tester, 'back from the duel');

    await tester.ensureVisible(find.text('Set Out'));
    await tester.tap(find.text('Set Out'));
    await _play(tester, ms: 2500);
    await _playBattle(tester, until: 'Back to the Guild');
    _noProblem(tester, 'the expedition finale');
    await tester.tap(find.text('Back to the Guild'));
    await _play(tester, ms: 2000);
    _noProblem(tester, 'back from the expedition');

    // It really was played through: the energy was spent once and the rewards were saved.
    final hero = await tester.runAsync(() => GameRepository(db).watchHero().first);
    expect(hero!.energySpent, 2);
    expect(hero.adventureXp, greaterThan(0));
    await shutDown(tester, db);
  });
}
