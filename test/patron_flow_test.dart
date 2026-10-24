import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/game_ui.dart';
import 'package:i_am_chad/app/store.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/patronage.dart';

import 'helpers.dart';

Future<(AppDatabase, GameRepository)> _boot(WidgetTester tester, TestStoreGateway store) async {
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
  });
  await bootApp(tester, db, store: store);
  return (db, repo);
}

Future<void> _openPatronHall(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings));
  await settle(tester, frames: 30);
  final open = find.text("Open the Patron's Hall");
  await tester.scrollUntilVisible(open, 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(open);
  await settle(tester, frames: 4);
  await tester.tap(open);
  await settle(tester, frames: 30);
}

Finder _button(String label) => find.widgetWithText(GameButton, label);

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(f);
  await settle(tester, frames: 4);
  await tester.tap(f);
  await settle(tester, frames: 20);
}

void main() {
  testWidgets('nothing in the game points at the store until the player goes looking', (tester) async {
    final (db, _) = await _boot(tester, TestStoreGateway());
    expect(find.textContaining('Patron'), findsNothing);
    expect(find.textContaining(r'$'), findsNothing);
    for (final tab in ['Train', 'Quests', 'Adventure', 'Hero', 'Journal']) {
      await tester.tap(find.text(tab).first);
      await settle(tester, frames: 30);
      expect(find.textContaining('Patron'), findsNothing, reason: tab);
      expect(find.textContaining(r'$'), findsNothing, reason: tab);
      await tester.pageBack();
      await settle(tester, frames: 20);
    }
    await shutDown(tester, db);
  });

  testWidgets('the Patron\'s Hall leads with the promise and shows the store\'s prices', (tester) async {
    final (db, _) = await _boot(tester, TestStoreGateway());
    await _openPatronHall(tester);

    expect(find.text("Patron's Hall"), findsWidgets);
    expect(find.text('Our Promise'), findsOneWidget);
    expect(find.textContaining('never buy'), findsOneWidget);
    expect(find.text('XP, energy, coins or potions'), findsOneWidget);
    expect(find.textContaining('Test store'), findsOneWidget);

    // The list builds lazily, so scroll to each price in turn.
    for (final label in [r'Get It · $3.99', r'$1.99', r'$4.99', r'$9.99', 'Restore Purchases']) {
      await tester.scrollUntilVisible(_button(label), 300, scrollable: find.byType(Scrollable).first);
      expect(_button(label), findsOneWidget, reason: label);
    }
    await shutDown(tester, db);
  });

  testWidgets('a tip asks first, says thanks, saves a receipt and unlocks nothing', (tester) async {
    final store = TestStoreGateway();
    final (db, repo) = await _boot(tester, store);
    await _openPatronHall(tester);

    await _tap(tester, _button(r'$1.99'));
    expect(find.text('Say Thanks?'), findsOneWidget);

    // Backing out costs nothing and never reaches the store.
    await tester.tap(find.text('Not Now'));
    await settle(tester);
    expect(store.bought, isEmpty);

    await tester.tap(_button(r'$1.99'));
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester, frames: 30);

    expect(store.bought, ['tip_shake']);
    expect(store.confirmed, 1, reason: 'the purchase is confirmed to the store only after it is saved');
    final e = (await tester.runAsync(() => repo.entitlements()))!;
    expect(e.tipCount, 1);
    expect(e.hasPatronPack, isFalse);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await settle(tester);
    expect(find.textContaining('lump in my throat'), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('the Patron Pack is bought once and then shows as owned', (tester) async {
    final store = TestStoreGateway();
    final (db, repo) = await _boot(tester, store);
    final before = (await tester.runAsync(() => repo.watchHero().first))!;
    await _openPatronHall(tester);

    await _tap(tester, _button(r'Get It · $3.99'));
    expect(find.text('Get the Patron Pack?'), findsOneWidget);
    expect(find.textContaining('looks only'), findsWidgets);
    await tester.tap(find.text('Continue'));
    await settle(tester, frames: 30);

    expect((await tester.runAsync(() => repo.entitlements()))!.hasPatronPack, isTrue);
    expect(_button('Owned. Thank You!'), findsOneWidget);
    expect(tester.widget<GameButton>(_button('Owned. Thank You!')).onPressed, isNull);

    // Nothing about the hero's progress moved.
    final after = (await tester.runAsync(() => repo.watchHero().first))!;
    expect((after.coins, after.adventureXp, after.potionStock, after.energySpent),
        (before.coins, before.adventureXp, before.potionStock, before.energySpent));
    await shutDown(tester, db);
  });

  testWidgets('cancelling or failing at the store saves nothing and says so kindly', (tester) async {
    final store = TestStoreGateway();
    final (db, repo) = await _boot(tester, store);
    await _openPatronHall(tester);

    store.nextOutcome = TestOutcome.cancel;
    await _tap(tester, _button(r'$4.99'));
    await tester.tap(find.text('Continue'));
    await settle(tester, frames: 30);
    expect((await tester.runAsync(() => repo.entitlements()))!.tipCount, 0);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await settle(tester);
    expect(find.textContaining('Nothing was bought'), findsOneWidget);

    store.nextOutcome = TestOutcome.fail;
    await _tap(tester, _button(r'$4.99'));
    await tester.tap(find.text('Continue'));
    await settle(tester, frames: 30);
    expect((await tester.runAsync(() => repo.entitlements()))!.tipCount, 0);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await settle(tester);
    expect(find.textContaining('Nothing is lost on this end'), findsOneWidget);
    // And it can be tried again straight away.
    await tester.scrollUntilVisible(_button(r'$4.99'), 300, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<GameButton>(_button(r'$4.99')).onPressed, isNotNull);
    await shutDown(tester, db);
  });

  testWidgets('with no store, everything says so and nothing can be bought', (tester) async {
    final (db, _) = await _boot(tester, TestStoreGateway(available: false));
    await _openPatronHall(tester);

    expect(find.textContaining('cannot be reached'), findsOneWidget);
    expect(_button('Not Available Right Now'), findsOneWidget);
    await tester.scrollUntilVisible(_button('Restore Purchases'), 300, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<GameButton>(_button('Restore Purchases')).onPressed, isNull);
    await shutDown(tester, db);
  });

  testWidgets('Restore Purchases brings the pack back, and says when there is nothing', (tester) async {
    final empty = TestStoreGateway();
    final (db, repo) = await _boot(tester, empty);
    await _openPatronHall(tester);
    await _tap(tester, _button('Restore Purchases'));
    await settle(tester, frames: 20);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await settle(tester);
    expect(find.textContaining('nothing to restore'), findsOneWidget);
    expect((await tester.runAsync(() => repo.entitlements()))!.hasPatronPack, isFalse);
    await shutDown(tester, db);

    final owned = TestStoreGateway(owned: {Patronage.patronPackId});
    final (db2, repo2) = await _boot(tester, owned);
    await _openPatronHall(tester);
    await _tap(tester, _button('Restore Purchases'));
    await settle(tester, frames: 20);
    expect((await tester.runAsync(() => repo2.entitlements()))!.hasPatronPack, isTrue);
    expect(_button('Owned. Thank You!'), findsOneWidget);
    await shutDown(tester, db2);
  });

  testWidgets('a purchase delivered while the app was closed is saved at launch', (tester) async {
    final store = TestStoreGateway();
    final (db, repo) = await _boot(tester, store);
    // The store hands over a purchase that finished earlier (a parent approving one).
    store.deliver(Patronage.patronPackId);
    await settle(tester, frames: 20);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester, frames: 5);
    expect((await tester.runAsync(() => repo.entitlements()))!.hasPatronPack, isTrue);
    expect(store.confirmed, 1);
    await shutDown(tester, db);
  });

  testWidgets('patron looks are locked in the wardrobe, explained kindly, and open with the pack', (tester) async {
    final store = TestStoreGateway();
    final (db, repo) = await _boot(tester, store);
    await tester.tap(find.text('Hero'));
    await settle(tester, frames: 30);
    await _tap(tester, find.text('Customise'));

    // The classic cape and natural hair are free; patron looks are locked.
    expect(find.text('Classic Cape'), findsOneWidget);
    await tester.ensureVisible(find.text('Crimson Mantle'));
    await tester.tap(find.text('Crimson Mantle'));
    await settle(tester);
    expect(find.textContaining('optional Patron Pack'), findsOneWidget);
    expect(find.textContaining('changes nothing about how'), findsOneWidget);
    await tester.tap(find.text('Not Now'));
    await settle(tester);
    expect((await tester.runAsync(() => repo.watchHero().first))!.cape, 'classic');

    // An earned look says how to earn it, without pressure.
    await tester.ensureVisible(find.text('Sunrise'));
    await tester.tap(find.text('Sunrise'));
    await settle(tester);
    expect(find.textContaining('Earned at Level 5'), findsOneWidget);
    await tester.tap(find.text('Got It'));
    await settle(tester);

    // Once the pack is owned the same chip works and the choice is saved.
    await tester.runAsync(() => repo.recordPurchase(Patronage.patronPack, 't1', at: DateTime(2026, 10, 22)));
    await settle(tester, frames: 10);
    await tester.ensureVisible(find.text('Crimson Mantle'));
    await tester.tap(find.text('Crimson Mantle'));
    await settle(tester);
    await tester.ensureVisible(find.text('Mint'));
    await tester.tap(find.text('Mint'));
    await settle(tester);
    await tester.tap(find.text('Save'));
    await settle(tester, frames: 20);
    final hero = (await tester.runAsync(() => repo.watchHero().first))!;
    expect((hero.cape, hero.hairDye), ('crimson', 'mint'));
    await shutDown(tester, db);
  });
}
