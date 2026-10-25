import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/calm.dart';
import 'package:i_am_chad/domain/hero.dart';

import 'helpers.dart';

const _hero = HeroProfile(
  name: 'Ada',
  appearanceStyle: 0,
  appearanceColor: 0,
  experience: ExperienceLevel.starting,
  preferredCategories: {},
  hasDumbbells: false,
);

Future<AppDatabase> _openCalm(WidgetTester tester, {bool smallest = false, bool reducedMotion = true}) async {
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
  await tester.runAsync(() => GameRepository(db).createHero(_hero));
  await bootApp(tester, db, reducedMotion: reducedMotion);
  await tester.tap(find.text('Train'));
  await settle(tester, frames: reducedMotion ? 30 : 90);
  await tester.scrollUntilVisible(find.byKey(const Key('calm_start')), 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(find.byKey(const Key('calm_start')));
  await settle(tester, frames: reducedMotion ? 5 : 40);
  await tester.tap(find.byKey(const Key('calm_start')));
  await settle(tester, frames: reducedMotion ? 20 : 90);
  return db;
}

String _phase(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('calm_phase'))).data!;

void main() {
  testWidgets('it is offered on the Train screen and breathes through to the end by itself', (tester) async {
    final db = await _openCalm(tester);
    expect(find.text(Calm.intro), findsOneWidget);
    expect(find.text(Calm.note), findsOneWidget);

    await tester.tap(find.byKey(const Key('calm_begin')));
    await settle(tester, frames: 5);
    expect(find.text('Breath 1 of ${Calm.breaths}'), findsOneWidget);
    expect(find.text(Calm.cues.first), findsOneWidget);
    expect(_phase(tester), CalmPhase.inhale.label);

    // Time moves the minute along.
    await tester.pump(Duration(seconds: CalmPhase.inhale.seconds));
    expect(_phase(tester), CalmPhase.hold.label);
    await tester.pump(Duration(seconds: CalmPhase.hold.seconds));
    expect(_phase(tester), CalmPhase.exhale.label);
    await tester.pump(Duration(seconds: CalmPhase.exhale.seconds));
    expect(find.text('Breath 2 of ${Calm.breaths}'), findsOneWidget);
    expect(_phase(tester), CalmPhase.inhale.label);

    await tester.pump(Duration(seconds: Calm.totalSeconds));
    await settle(tester, frames: 5);
    expect(find.text(Calm.finish), findsOneWidget);
    await tester.tap(find.byKey(const Key('calm_back')));
    await settle(tester, frames: 20);
    expect(find.byKey(const Key('calm_start')), findsOneWidget, reason: 'back on the Train screen');
    await shutDown(tester, db);
  });

  testWidgets('pausing holds the minute for as long as you like', (tester) async {
    final db = await _openCalm(tester);
    await tester.tap(find.byKey(const Key('calm_begin')));
    await settle(tester, frames: 5);
    await tester.tap(find.text('Pause'));
    await settle(tester, frames: 3);
    expect(_phase(tester), 'Paused');
    await tester.pump(const Duration(seconds: 120));
    expect(find.text('Breath 1 of ${Calm.breaths}'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await settle(tester, frames: 3);
    expect(_phase(tester), CalmPhase.inhale.label);
    await shutDown(tester, db);
  });

  testWidgets('it can be ended whenever, and it earns and saves nothing', (tester) async {
    final db = await _openCalm(tester);
    final before = await tester.runAsync(() => GameRepository(db).watchHero().first);
    await tester.tap(find.byKey(const Key('calm_begin')));
    await settle(tester, frames: 5);
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.byKey(const Key('calm_finish')));
    await settle(tester, frames: 5);
    expect(find.text(Calm.finish), findsOneWidget);
    await tester.tap(find.byKey(const Key('calm_back')));
    await settle(tester, frames: 20);
    // The timer died with the screen: time passing does nothing.
    await tester.pump(const Duration(seconds: 90));
    final after = await tester.runAsync(() => GameRepository(db).watchHero().first);
    expect(after!.coins, before!.coins);
    expect(await tester.runAsync(() => GameRepository(db).watchWorkouts().first), isEmpty);
    await shutDown(tester, db);
  });

  testWidgets('leaving part-way is fine', (tester) async {
    final db = await _openCalm(tester);
    await tester.tap(find.byKey(const Key('calm_begin')));
    await settle(tester, frames: 5);
    await tester.pump(const Duration(seconds: 5));
    await tester.pageBack();
    await settle(tester, frames: 20);
    expect(find.byKey(const Key('calm_start')), findsOneWidget);
    await tester.pump(const Duration(seconds: 90));
    expect(tester.takeException(), isNull);
    await shutDown(tester, db);
  });

  testWidgets('the circle swells and settles with the real animation, and it fits on the smallest phone', (tester) async {
    final db = await _openCalm(tester, smallest: true, reducedMotion: false);
    await tester.scrollUntilVisible(find.byKey(const Key('calm_begin')), 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.byKey(const Key('calm_begin')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('calm_begin')));
    await settle(tester, frames: 3);
    double width() => tester.getSize(find.byKey(const Key('calm_circle'))).width;
    final start = width();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 3));
    final inhaled = width();
    expect(inhaled, greaterThan(start), reason: 'it swells as you breathe in');
    await tester.pump(Duration(seconds: CalmPhase.hold.seconds));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 5));
    expect(width(), lessThan(inhaled), reason: 'it settles as you breathe out');
    expect(tester.takeException(), isNull);
    await shutDown(tester, db);
  });
}
