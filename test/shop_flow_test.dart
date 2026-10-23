import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/game_ui.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/shop.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

final _now = DateTime(2026, 10, 22, 10);

Future<(AppDatabase, GameRepository)> _boot(
  WidgetTester tester, {
  int coins = 0,
  int potions = 0,
  bool energy = false,
}) async {
  usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = GameRepository(db);
  await tester.runAsync(() async {
    await repo.createHero(const HeroProfile(
      name: 'Ada',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.returning,
      preferredCategories: {ActivityCategory.cardio},
      hasDumbbells: false,
    ));
    if (coins > 0) await repo.addCoins(coins);
    for (var i = 0; i < potions; i++) {
      await repo.addCoins(Shop.potionPrice);
      await repo.buyPotion();
    }
    if (energy) {
      // A walk logged on the day earns energy for an expedition.
      await repo.addWorkout(WorkoutEntry(
        activityId: 'walking',
        performedAt: _now,
        durationSeconds: 1200,
        loggedAt: _now,
      ));
    }
  });
  await bootApp(tester, db, now: _now);
  return (db, repo);
}

Future<void> _openShopFromHero(WidgetTester tester) async {
  await tester.tap(find.text('Hero'));
  await settle(tester, frames: 30);
  final button = find.text('Visit the Guild Shop');
  await tester.scrollUntilVisible(button, 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(button);
  await settle(tester, frames: 4);
  await tester.tap(button);
  await settle(tester, frames: 20);
}

void main() {
  testWidgets('the shop shows your coins and what you can afford', (tester) async {
    final (db, repo) = await _boot(tester, coins: 100);
    await _openShopFromHero(tester);

    expect(find.text('Guild Shop'), findsWidgets);
    expect(find.text('100 Coins'), findsOneWidget);
    expect(find.text('Healing Potion'), findsOneWidget);

    // Starter gear is affordable, upgrades are not yet, and say how far off they are.
    final tunic = find.widgetWithText(GameButton, '60 Coins');
    expect(tunic, findsWidgets);
    await tester.scrollUntilVisible(find.text('Iron Blade'), 300, scrollable: find.byType(Scrollable).first);
    // Both upgrades that cost 240 say how far off they are.
    expect(find.text('Need 140 more coins'), findsNWidgets(2));
    final blade = find.widgetWithText(GameButton, '240 Coins');
    expect(tester.widget<GameButton>(blade.first).onPressed, isNull);

    await shutDown(tester, db);
  });

  testWidgets('buying gear asks first, then spends the coins and marks it owned', (tester) async {
    final (db, repo) = await _boot(tester, coins: 100);
    await _openShopFromHero(tester);

    await tester.scrollUntilVisible(find.text('Guild Tunic'), 300, scrollable: find.byType(Scrollable).first);
    // Cheapest first, then by slot: Sweatband (head), Guild Tunic (body), Practice Sword (weapon).
    final tunicButton = find.widgetWithText(GameButton, '60 Coins').at(1);
    await tester.ensureVisible(tunicButton);
    await settle(tester, frames: 4);
    await tester.tap(tunicButton);
    await settle(tester);
    expect(find.text('Buy Guild Tunic?'), findsOneWidget);

    // Backing out costs nothing.
    await tester.tap(find.text('Not Now'));
    await settle(tester);
    expect((await tester.runAsync(() => repo.watchHero().first))!.coins, 100);

    await tester.tap(tunicButton);
    await settle(tester);
    await tester.tap(find.widgetWithText(GameButton, 'Buy'));
    await settle(tester, frames: 20);

    expect((await tester.runAsync(() => repo.watchHero().first))!.coins, 40);
    expect((await tester.runAsync(() => repo.watchItems().first))!.map((i) => i.itemId), ['guild_tunic']);
    // The reply and the coin count are at the top of the list.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await settle(tester);
    expect(find.textContaining('The Guild Tunic is yours'), findsOneWidget);
    expect(find.text('40 Coins'), findsOneWidget);
    await tester.scrollUntilVisible(find.widgetWithText(GameButton, 'Owned'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.widgetWithText(GameButton, 'Owned'), findsOneWidget);

    await shutDown(tester, db);
  });

  testWidgets('potions go in the pouch until it is full', (tester) async {
    final (db, repo) = await _boot(tester, coins: Shop.potionPrice * 2);
    await _openShopFromHero(tester);

    final buy = find.widgetWithText(GameButton, '${Shop.potionPrice} Coins').first;
    await tester.tap(buy);
    await settle(tester, frames: 20);
    expect((await tester.runAsync(() => repo.watchHero().first))!.potionStock, 1);
    expect(find.textContaining('Your pouch holds 1 of ${Shop.potionPouchMax}'), findsOneWidget);

    // With no coins left it cannot be bought.
    await tester.tap(find.widgetWithText(GameButton, '${Shop.potionPrice} Coins').first);
    await settle(tester, frames: 20);
    expect((await tester.runAsync(() => repo.watchHero().first))!.potionStock, 2);
    expect(find.textContaining('Need ${Shop.potionPrice} more coins'), findsOneWidget);

    await shutDown(tester, db);
  });

  testWidgets('a full pouch says so', (tester) async {
    final (db, repo) = await _boot(tester, potions: Shop.potionPouchMax, coins: 100);
    await _openShopFromHero(tester);
    expect(find.widgetWithText(GameButton, 'Pouch Full'), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('the shop is reachable from the Adventure screen too', (tester) async {
    final (db, repo) = await _boot(tester, coins: 12, potions: 2);
    await tester.tap(find.text('Adventure'));
    await settle(tester, frames: 30);
    await tester.scrollUntilVisible(find.text('Visit the Shop'), 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Visit the Shop'));
    await settle(tester, frames: 4);
    expect(find.text('12 Coins'), findsOneWidget);
    await tester.tap(find.text('Visit the Shop'));
    await settle(tester, frames: 20);
    expect(find.text('Healing Potion'), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('setting out takes potions from the pouch, and they come home if unused', (tester) async {
    final (db, repo) = await _boot(tester, potions: 4, energy: true);
    expect((await tester.runAsync(() => repo.watchHero().first))!.potionStock, 4);

    await tester.tap(find.text('Adventure'));
    await settle(tester, frames: 30);
    await tester.tap(find.text('Set Out'));
    await settle(tester, frames: 30);

    // 2 free potions plus 3 from the pouch.
    final saved = (await tester.runAsync(() => repo.activeExpedition()))!;
    expect(saved.potions, Shop.basePotions + 3);
    expect((await tester.runAsync(() => repo.watchHero().first))!.potionStock, 1);

    // Retreat without using any: they all come home.
    await tester.pageBack();
    await settle(tester, frames: 10);
    await tester.tap(find.text('Retreat'));
    await settle(tester, frames: 20);
    expect((await tester.runAsync(() => repo.watchHero().first))!.potionStock, 4);

    await shutDown(tester, db);
  });
}
