import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/expedition.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/shop.dart';

const _hero = HeroProfile(
  name: 'Tester',
  appearanceStyle: 0,
  appearanceColor: 0,
  experience: ExperienceLevel.returning,
  preferredCategories: {ActivityCategory.cardio},
  hasDumbbells: false,
);

void main() {
  late AppDatabase db;
  late GameRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = GameRepository(db);
    await repo.createHero(_hero);
  });
  tearDown(() => db.close());

  Future<HeroProfile> hero() async => (await repo.watchHero().first)!;

  group('gear', () {
    test('buying takes the coins and gives the item', () async {
      await repo.addCoins(100);
      expect(await repo.buyItem('guild_tunic'), PurchaseResult.bought);
      expect((await hero()).coins, 40);
      final items = await repo.watchItems().first;
      expect(items.map((i) => i.itemId), ['guild_tunic']);
      expect(items.single.equipped, isFalse, reason: 'you choose when to wear it');
    });

    test('too few coins buys nothing and charges nothing', () async {
      await repo.addCoins(30);
      expect(await repo.buyItem('iron_blade'), PurchaseResult.notEnoughCoins);
      expect((await hero()).coins, 30);
      expect(await repo.watchItems().first, isEmpty);
    });

    test('you cannot buy what you already have, even if it came from loot', () async {
      await repo.addCoins(500);
      await repo.startExpedition(
        ExpeditionProgress.fresh(seed: 1, heroLevel: 1, heroMaxHp: 46),
        energyCost: 0,
      );
      await repo.recordExpedition(
        seed: 1,
        victory: true,
        battlesWon: 3,
        xp: 10,
        coins: 0,
        lootItemId: 'iron_blade',
      );
      final before = (await hero()).coins;
      expect(await repo.buyItem('iron_blade'), PurchaseResult.alreadyOwned);
      expect((await hero()).coins, before);
      expect(await repo.buyItem('guild_tunic'), PurchaseResult.bought);
      expect(await repo.buyItem('guild_tunic'), PurchaseResult.alreadyOwned);
    });

    test('things that are not for sale, and a missing hero, are refused', () async {
      await repo.addCoins(500);
      expect(await repo.buyItem('mystery_hat'), PurchaseResult.unavailable);
      final empty = GameRepository(AppDatabase.forTesting(NativeDatabase.memory()));
      expect(await empty.buyItem('guild_tunic'), PurchaseResult.unavailable);
      expect(await empty.buyPotion(), PurchaseResult.unavailable);
    });

    test('coins can pay for several things in turn, down to the last one', () async {
      await repo.addCoins(Shop.priceOf('wooden_sword')! + Shop.priceOf('sweatband')!);
      expect(await repo.buyItem('wooden_sword'), PurchaseResult.bought);
      expect(await repo.buyItem('sweatband'), PurchaseResult.bought);
      expect((await hero()).coins, 0);
      expect(await repo.buyItem('guild_tunic'), PurchaseResult.notEnoughCoins);
    });
  });

  group('potions', () {
    test('a potion costs coins and goes in the pouch', () async {
      await repo.addCoins(60);
      expect(await repo.buyPotion(), PurchaseResult.bought);
      expect(await repo.buyPotion(), PurchaseResult.bought);
      final h = await hero();
      expect(h.potionStock, 2);
      expect(h.coins, 60 - 2 * Shop.potionPrice);
    });

    test('not enough coins, or a full pouch, buys nothing', () async {
      expect(await repo.buyPotion(), PurchaseResult.notEnoughCoins);
      await repo.addCoins(1000);
      for (var i = 0; i < Shop.potionPouchMax; i++) {
        expect(await repo.buyPotion(), PurchaseResult.bought);
      }
      final coins = (await hero()).coins;
      expect(await repo.buyPotion(), PurchaseResult.pouchFull);
      expect((await hero()).coins, coins);
      expect((await hero()).potionStock, Shop.potionPouchMax);
    });

    test('pouch potions come on an expedition, and unused ones come home', () async {
      await repo.addCoins(200);
      for (var i = 0; i < 4; i++) {
        await repo.buyPotion();
      }
      expect((await hero()).potionStock, 4);

      // Take the most the rules allow.
      final bring = Shop.potionsToBring(4);
      expect(bring, 3);
      final start = ExpeditionProgress.fresh(
        seed: 5,
        heroLevel: 1,
        heroMaxHp: 46,
        potions: Shop.basePotions + bring,
      );
      await repo.startExpedition(start, energyCost: 0, broughtPotions: bring);
      expect((await hero()).potionStock, 1, reason: '4 in the pouch, 3 taken along');
      expect((await repo.activeExpedition())!.potions, 5);

      // It ends with 4 potions left: one free one was used, so 2 come home.
      await repo.recordExpedition(
        seed: 5,
        victory: true,
        battlesWon: 3,
        xp: 10,
        coins: 0,
        lootItemId: 'guild_tunic',
        potionsLeft: 4,
      );
      expect((await hero()).potionStock, 3);
    });

    test('potions that were used up do not come back, and the pouch never overflows', () async {
      await repo.addCoins(500);
      for (var i = 0; i < Shop.potionPouchMax; i++) {
        await repo.buyPotion();
      }
      await repo.startExpedition(
        ExpeditionProgress.fresh(seed: 6, heroLevel: 1, heroMaxHp: 46, potions: 5),
        energyCost: 0,
        broughtPotions: 3,
      );
      expect((await hero()).potionStock, 2);

      // Everything used.
      await repo.recordExpedition(
        seed: 6,
        victory: false,
        battlesWon: 0,
        xp: 0,
        coins: 0,
        lootItemId: '',
        potionsLeft: 0,
      );
      expect((await hero()).potionStock, 2);

      // A later run that returns more than fits is capped at the pouch size.
      await repo.recordExpedition(
        seed: 7,
        victory: false,
        battlesWon: 0,
        xp: 0,
        coins: 0,
        lootItemId: '',
        potionsLeft: 20,
      );
      expect((await hero()).potionStock, Shop.potionPouchMax);
    });

    test('a retreat or abandon brings the unused potions home too', () async {
      await repo.addCoins(100);
      await repo.buyPotion();
      await repo.buyPotion();
      await repo.startExpedition(
        ExpeditionProgress.fresh(seed: 8, heroLevel: 1, heroMaxHp: 46, potions: 4),
        energyCost: 0,
        broughtPotions: 2,
      );
      expect((await hero()).potionStock, 0);
      await repo.recordExpedition(
        seed: 8,
        victory: false,
        battlesWon: 1,
        xp: 5,
        coins: 3,
        lootItemId: '',
        potionsLeft: 4,
      );
      expect((await hero()).potionStock, 2);
    });
  });

  test('the export includes the potion pouch', () async {
    await repo.addCoins(30);
    await repo.buyPotion();
    expect(await repo.exportJson(), contains('"potionStock": 1'));
  });

  test('v5 saves upgrade to v6 and keep their workouts, rewards and hero', () async {
    final old = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE workouts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          activity_id TEXT NOT NULL,
          performed_at INTEGER NOT NULL,
          variant TEXT, sets INTEGER, reps INTEGER, duration_seconds INTEGER,
          distance_meters REAL, load_kg REAL, perceived_effort INTEGER,
          notes TEXT, camera_counted INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE heroes (
          id INTEGER NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          appearance_style INTEGER NOT NULL DEFAULT 0,
          appearance_color INTEGER NOT NULL DEFAULT 0,
          appearance_skin INTEGER NOT NULL DEFAULT 0,
          experience TEXT NOT NULL,
          preferred_categories TEXT NOT NULL DEFAULT '',
          has_dumbbells INTEGER NOT NULL DEFAULT 0,
          energy_spent INTEGER NOT NULL DEFAULT 0,
          adventure_xp INTEGER NOT NULL DEFAULT 0,
          coins INTEGER NOT NULL DEFAULT 0,
          victories INTEGER NOT NULL DEFAULT 0,
          streak_xp INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        );
        CREATE TABLE reward_grants (
          day TEXT NOT NULL PRIMARY KEY,
          effort_minutes REAL NOT NULL,
          credited_minutes REAL NOT NULL,
          xp INTEGER NOT NULL,
          energy INTEGER NOT NULL,
          rules_version INTEGER NOT NULL
        );
        INSERT INTO workouts (activity_id, performed_at, duration_seconds)
          VALUES ('walking', 1790000000, 600);
        INSERT INTO heroes (id, name, experience, coins, streak_xp, created_at)
          VALUES (1, 'Veteran', 'regular', 54, 20, 1790000000);
        CREATE TABLE app_settings (
          id INTEGER NOT NULL PRIMARY KEY,
          use_metric INTEGER NOT NULL DEFAULT 1,
          reduced_motion INTEGER NOT NULL DEFAULT 0,
          quiet_chad INTEGER NOT NULL DEFAULT 0,
          sound_on INTEGER NOT NULL DEFAULT 1,
          haptics_on INTEGER NOT NULL DEFAULT 1
        );
        PRAGMA user_version = 5;
      ''');
    }));
    addTearDown(old.close);
    final r = GameRepository(old);

    final h = (await r.watchHero().first)!;
    expect(h.name, 'Veteran');
    expect(h.coins, 54);
    expect(h.streakXp, 20);
    expect(h.potionStock, 0);

    // The old entry has no logged-at time, and so still counts for rewards.
    final w = (await r.watchWorkouts().first).single;
    expect(w.loggedAt, isNull);
    expect(w.countsForRewards, isTrue);
  });
}
