import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/combat.dart';
import 'package:i_am_chad/domain/hero.dart';

import 'helpers.dart';

Future<AppDatabase> _boot(WidgetTester tester, {bool smallest = false}) async {
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
  await tester.runAsync(() => GameRepository(db).createHero(const HeroProfile(
        name: 'Ada',
        appearanceStyle: 0,
        appearanceColor: 0,
        experience: ExperienceLevel.starting,
        preferredCategories: {},
        hasDumbbells: false,
      )));
  await bootApp(tester, db);
  return db;
}

Future<void> _openHero(WidgetTester tester) async {
  await tester.tap(find.text('Hero'));
  await settle(tester, frames: 30);
  final f = find.byKey(const Key('style_guardian'));
  await tester.scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(f);
  await settle(tester, frames: 3);
}

void main() {
  test('a style that does not exist is ignored, and the choice is part of the saved hero', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = GameRepository(db);
    await repo.createHero(const HeroProfile(
      name: 'Ada',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.starting,
      preferredCategories: {},
      hasDumbbells: false,
    ));
    await repo.setFightingStyle('striker');
    await repo.setFightingStyle('no-such-style');
    expect((await repo.watchHero().first)!.fightingStyle, 'striker');
    expect(jsonDecodeHero(await repo.exportJson())['fightingStyle'], 'striker');
    // And it comes back with a full backup.
    final backup = await repo.backupJson();
    await repo.setFightingStyle('guardian');
    await repo.restoreBackup(repo.readBackup(backup));
    expect((await repo.watchHero().first)!.fightingStyle, 'striker');
  });

  testWidgets('the Hero screen offers three ways to fight, with Steady chosen to begin with', (tester) async {
    final db = await _boot(tester);
    await _openHero(tester);
    expect(find.text('Fighting Style'), findsOneWidget);
    for (final s in FightingStyle.values) {
      expect(find.byKey(Key('style_${s.id}')), findsOneWidget, reason: s.id);
    }
    expect(find.textContaining('No style is stronger than another'), findsOneWidget);
    final hero = await tester.runAsync(() => GameRepository(db).watchHero().first);
    expect(hero!.fightingStyle, 'steady');
    await shutDown(tester, db);
  });

  testWidgets('choosing a style saves it, and the battle buttons then follow it', (tester) async {
    final db = await _boot(tester);
    await _openHero(tester);
    await tester.tap(find.byKey(const Key('style_guardian')));
    await settle(tester, frames: 15);
    final hero = await tester.runAsync(() => GameRepository(db).watchHero().first);
    expect(hero!.fightingStyle, 'guardian');
    expect(hero.style, FightingStyle.guardian);

    // Into a practice duel: the Power Strike badge shows the Guardian's cost.
    await tester.pageBack();
    await settle(tester, frames: 20);
    await tester.tap(find.text('Adventure'));
    await settle(tester, frames: 30);
    await tester.scrollUntilVisible(find.text('Practice Duel'), 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Practice Duel'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Practice Duel'));
    await settle(tester, frames: 40);
    expect(find.text('0/3'), findsOneWidget, reason: 'no focus yet, and a Power Strike costs 3 for a Guardian');
    await shutDown(tester, db);
  });

  testWidgets('the panel fits on the smallest phone with the largest text', (tester) async {
    final db = await _boot(tester, smallest: true);
    await _openHero(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('style_striker')), findsOneWidget);
    await shutDown(tester, db);
  });
}

Map<String, Object?> jsonDecodeHero(String json) => (jsonDecode(json) as Map<String, Object?>)['hero']! as Map<String, Object?>;
