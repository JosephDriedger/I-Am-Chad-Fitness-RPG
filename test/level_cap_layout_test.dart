import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/hero.dart';

import 'helpers.dart';

/// The level cap is 120, so a level can be three digits. The numbers that show it
/// have to fit at the smallest phone and the largest text.
void main() {
  test('the cap is where the last season ends, and the XP curve reaches it', () {
    expect(Progression.maxLevel, 120);
    expect(Progression.levelForXp(Progression.xpForLevel(120)), 120);
    expect(Progression.levelForXp(Progression.xpForLevel(120) * 3), 120, reason: 'XP past the cap changes nothing');
    expect(Progression.levelProgress(Progression.xpForLevel(120)), 1);
  });

  test('stats still grow only a little past level 99', () {
    expect(Progression.attack(120) - Progression.attack(99), lessThanOrEqualTo(2));
    expect(Progression.maxHp(120) - Progression.maxHp(99), lessThanOrEqualTo(7));
  });

  testWidgets('three-digit levels fit on the hall, the hero page and the journal', (tester) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.runAsync(() async {
      final repo = GameRepository(db);
      await repo.createHero(const HeroProfile(
        name: 'Ada the Very Long Named',
        appearanceStyle: 0,
        appearanceColor: 0,
        experience: ExperienceLevel.starting,
        preferredCategories: {},
        hasDumbbells: false,
      ));
      await repo.recordExpedition(seed: 1, victory: true, battlesWon: 3, xp: Progression.xpForLevel(120), coins: 0, lootItemId: '');
    });
    await bootApp(tester, db);
    expect(tester.takeException(), isNull);
    expect(find.text('Lv 120'), findsOneWidget);

    for (final page in ['Hero', 'Journal', 'Quests']) {
      await tester.tap(find.text(page));
      await settle(tester, frames: 30);
      expect(tester.takeException(), isNull, reason: page);
      await tester.pageBack();
      await settle(tester, frames: 20);
    }
    await shutDown(tester, db);
  });
}
