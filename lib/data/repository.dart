import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/activity.dart';
import '../domain/expedition.dart';
import '../domain/hero.dart';
import '../domain/items.dart';
import '../domain/patronage.dart';
import '../domain/player_state.dart';
import '../domain/rewards.dart';
import '../domain/shop.dart';
import '../domain/streaks.dart';
import '../domain/workout.dart';
import 'database.dart';

/// Single access point for saved data. Workouts are written first and
/// rewards are re-derived from them, never the other way around.
class GameRepository {
  GameRepository(this._db, {this.rules = RewardRules.v1});

  final AppDatabase _db;
  final RewardRules rules;

  // ---- Workouts -----------------------------------------------------------

  Stream<List<WorkoutEntry>> watchWorkouts() {
    final q = _db.select(_db.workouts)
      ..orderBy([(t) => OrderingTerm.desc(t.performedAt)]);
    return q.watch().map((rows) => rows.map(_toEntry).toList());
  }

  Future<int> addWorkout(WorkoutEntry e) async {
    return _db.transaction(() async {
      final id = await _db.into(_db.workouts).insert(_toCompanion(e));
      await _recomputeDay(e.performedAt);
      return id;
    });
  }

  Future<void> updateWorkout(WorkoutEntry e) async {
    final id = e.id;
    if (id == null) throw ArgumentError('Cannot update an unsaved workout');
    await _db.transaction(() async {
      final old = await (_db.select(_db.workouts)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      // When an entry was logged never changes, and an old entry from before
      // that was recorded counts as logged when it was performed. So moving a
      // workout to an earlier day makes it a back-dated one.
      final logged = old?.loggedAt ?? old?.performedAt ?? e.loggedAt;
      await (_db.update(_db.workouts)..where((t) => t.id.equals(id)))
          .write(_toCompanion(e.copyWith(loggedAt: logged)));
      await _recomputeDay(e.performedAt);
      if (old != null && dayKey(old.performedAt) != dayKey(e.performedAt)) {
        await _recomputeDay(old.performedAt);
      }
    });
  }

  Future<void> deleteWorkout(int id) async {
    await _db.transaction(() async {
      final old = await (_db.select(_db.workouts)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (old == null) return;
      await (_db.delete(_db.workouts)..where((t) => t.id.equals(id))).go();
      await _recomputeDay(old.performedAt);
    });
  }

  /// Reward currently granted for the day containing [t].
  Future<DayReward> rewardForDay(DateTime t) async {
    final rows = await _workoutsOnDay(t);
    return rules.rewardForDay(rows.map(_toEntry));
  }

  Future<List<WorkoutRow>> _workoutsOnDay(DateTime t) {
    final start = startOfDay(t);
    final end = DateTime(start.year, start.month, start.day + 1);
    return (_db.select(_db.workouts)
          ..where((w) =>
              w.performedAt.isBiggerOrEqualValue(start) &
              w.performedAt.isSmallerThanValue(end)))
        .get();
  }

  Future<void> _recomputeDay(DateTime t) async {
    final key = dayKey(t);
    final rows = await _workoutsOnDay(t);
    // Back-dated workouts are kept in the journal but earn nothing.
    final eligible = rows.map(_toEntry).where((e) => e.countsForRewards).toList();
    if (eligible.isEmpty) {
      await (_db.delete(_db.rewardGrants)..where((g) => g.day.equals(key))).go();
      return;
    }
    final r = rules.rewardForDay(eligible);
    await _db.into(_db.rewardGrants).insertOnConflictUpdate(
          RewardGrantsCompanion.insert(
            day: key,
            effortMinutes: r.rawEffortMinutes,
            creditedMinutes: r.creditedMinutes,
            xp: r.xp,
            energy: r.energy,
            rulesVersion: r.rulesVersion,
          ),
        );
  }

  Stream<List<DayGrant>> watchGrants() =>
      _db.select(_db.rewardGrants).watch().map((rows) => [
            for (final g in rows)
              DayGrant(
                day: g.day,
                effortMinutes: g.effortMinutes,
                creditedMinutes: g.creditedMinutes,
                xp: g.xp,
                energy: g.energy,
                rulesVersion: g.rulesVersion,
              ),
          ]);

  // ---- Hero ---------------------------------------------------------------

  Stream<HeroProfile?> watchHero() => (_db.select(_db.heroes)
        ..where((h) => h.id.equals(1)))
      .watchSingleOrNull()
      .map((r) => r == null ? null : _toHero(r));

  Future<void> createHero(HeroProfile h) async {
    await _db.into(_db.heroes).insertOnConflictUpdate(HeroesCompanion.insert(
          id: const Value(1),
          name: h.name,
          appearanceStyle: Value(h.appearanceStyle),
          appearanceColor: Value(h.appearanceColor),
          appearanceSkin: Value(h.appearanceSkin),
          experience: h.experience.name,
          preferredCategories:
              Value(h.preferredCategories.map((c) => c.name).join(',')),
          hasDumbbells: Value(h.hasDumbbells),
          createdAt: DateTime.now(),
        ));
  }

  /// Updates the player-editable parts of the hero only.
  Future<void> updateHeroDetails({
    String? name,
    int? appearanceStyle,
    int? appearanceColor,
    int? appearanceSkin,
    String? cape,
    String? hairDye,
  }) async {
    await (_db.update(_db.heroes)..where((h) => h.id.equals(1))).write(
      HeroesCompanion(
        cape: cape == null ? const Value.absent() : Value(cape),
        hairDye: hairDye == null ? const Value.absent() : Value(hairDye),
        name: name == null ? const Value.absent() : Value(name),
        appearanceStyle: appearanceStyle == null
            ? const Value.absent()
            : Value(appearanceStyle),
        appearanceColor: appearanceColor == null
            ? const Value.absent()
            : Value(appearanceColor),
        appearanceSkin: appearanceSkin == null
            ? const Value.absent()
            : Value(appearanceSkin),
      ),
    );
  }

  Future<void> spendEnergy(int amount) async {
    await _db.customUpdate(
      'UPDATE heroes SET energy_spent = energy_spent + ? WHERE id = 1',
      variables: [Variable.withInt(amount)],
      updates: {_db.heroes},
    );
  }

  // ---- Expedition in progress ---------------------------------------------

  Stream<ExpeditionProgress?> watchActiveExpedition() =>
      (_db.select(_db.activeExpeditions)..where((e) => e.id.equals(1)))
          .watchSingleOrNull()
          .map((r) => r == null ? null : _toProgress(r));

  Future<ExpeditionProgress?> activeExpedition() async {
    final r = await (_db.select(_db.activeExpeditions)..where((e) => e.id.equals(1)))
        .getSingleOrNull();
    return r == null ? null : _toProgress(r);
  }

  /// Spends the energy and saves the starting point in one step, so closing
  /// the app at any moment can never lose the energy without the expedition.
  ///
  /// [broughtPotions] come out of the potion pouch and are part of
  /// `p.potions`. Any not used come back when the expedition ends.
  Future<void> startExpedition(ExpeditionProgress p, {required int energyCost, int broughtPotions = 0}) {
    return _db.transaction(() async {
      await spendEnergy(energyCost);
      await saveExpeditionProgress(p);
      if (broughtPotions > 0) {
        await _db.customUpdate(
          'UPDATE heroes SET potion_stock = MAX(0, potion_stock - ?) WHERE id = 1',
          variables: [Variable.withInt(broughtPotions)],
          updates: {_db.heroes},
        );
      }
    });
  }

  Future<void> saveExpeditionProgress(ExpeditionProgress p) async {
    await _db.into(_db.activeExpeditions).insertOnConflictUpdate(
          ActiveExpeditionsCompanion.insert(
            id: const Value(1),
            seed: p.seed,
            heroLevel: p.heroLevel,
            stepIndex: p.stepIndex,
            heroHp: p.heroHp,
            potions: p.potions,
            battlesWon: p.battlesWon,
            xp: p.xp,
            coins: p.coins,
          ),
        );
  }

  static ExpeditionProgress _toProgress(ActiveExpeditionRow r) => ExpeditionProgress(
        seed: r.seed,
        heroLevel: r.heroLevel,
        stepIndex: r.stepIndex,
        heroHp: r.heroHp,
        potions: r.potions,
        battlesWon: r.battlesWon,
        xp: r.xp,
        coins: r.coins,
      );

  /// Persists the result of an expedition, which also ends it (the saved
  /// in-progress state is cleared). Returns true if the loot was new.
  Future<bool> recordExpedition({
    required int seed,
    required bool victory,
    required int battlesWon,
    required int xp,
    required int coins,
    required String lootItemId,
    int potionsLeft = 0,
  }) {
    return _db.transaction(() async {
      var newItem = false;
      var bonusCoins = 0;
      if (victory) {
        final owned = await (_db.select(_db.ownedItems)
              ..where((o) => o.itemId.equals(lootItemId)))
            .getSingleOrNull();
        if (owned == null) {
          await _db.into(_db.ownedItems).insert(OwnedItemsCompanion.insert(
                itemId: lootItemId,
                acquiredAt: DateTime.now(),
              ));
          newItem = true;
        } else {
          bonusCoins = 10; // duplicates convert to coins
        }
      }
      await _db.into(_db.expeditionRuns).insert(ExpeditionRunsCompanion.insert(
            seed: seed,
            finishedAt: DateTime.now(),
            victory: victory,
            battlesWon: battlesWon,
            xp: xp,
            coins: coins + bonusCoins,
            lootItemId: Value(victory ? lootItemId : null),
          ));
      await _db.delete(_db.activeExpeditions).go();
      await _db.customUpdate(
        'UPDATE heroes SET adventure_xp = adventure_xp + ?, '
        'coins = coins + ?, victories = victories + ? WHERE id = 1',
        variables: [
          Variable.withInt(xp),
          Variable.withInt(coins + bonusCoins),
          Variable.withInt(victory ? 1 : 0),
        ],
        updates: {_db.heroes},
      );
      // Unused pouch potions come home with the hero.
      final back = Shop.potionsReturned(potionsLeft);
      if (back > 0) {
        await _db.customUpdate(
          'UPDATE heroes SET potion_stock = MIN(?, potion_stock + ?) WHERE id = 1',
          variables: [Variable.withInt(Shop.potionPouchMax), Variable.withInt(back)],
          updates: {_db.heroes},
        );
      }
      return newItem;
    });
  }

  Future<void> addCoins(int coins) => _db.customUpdate(
        'UPDATE heroes SET coins = coins + ? WHERE id = 1',
        variables: [Variable.withInt(coins)],
        updates: {_db.heroes},
      );

  // ---- Story --------------------------------------------------------------

  /// The numbers of the chapters the player has read.
  Stream<Set<int>> watchStoryRead() =>
      _db.select(_db.storyProgress).watch().map((rows) => {for (final r in rows) r.chapter});

  /// The player's remembered story choices, by key.
  Stream<Map<String, int>> watchStoryChoices() =>
      _db.select(_db.storyChoices).watch().map((rows) => {for (final r in rows) r.key: r.option});

  /// Marks a chapter read. Reading it again later changes nothing.
  Future<void> markChapterRead(int chapter, {required DateTime at}) =>
      _db.into(_db.storyProgress).insert(
            StoryProgressCompanion.insert(chapter: Value(chapter), readAt: at),
            mode: InsertMode.insertOrIgnore,
          );

  /// Remembers a choice. Choosing differently on a replay replaces it.
  Future<void> saveStoryChoice(String key, int option) =>
      _db.into(_db.storyChoices).insertOnConflictUpdate(
            StoryChoicesCompanion.insert(key: key, option: option),
          );

  // ---- Shop ---------------------------------------------------------------

  /// Buys a piece of gear with coins. Nothing is charged unless it is bought.
  Future<PurchaseResult> buyItem(String itemId) {
    return _db.transaction(() async {
      final price = Shop.priceOf(itemId);
      if (price == null || ItemCatalog.byId(itemId) == null) return PurchaseResult.unavailable;
      final hero = await (_db.select(_db.heroes)..where((h) => h.id.equals(1))).getSingleOrNull();
      if (hero == null) return PurchaseResult.unavailable;
      final owned = await (_db.select(_db.ownedItems)..where((o) => o.itemId.equals(itemId))).getSingleOrNull();
      if (owned != null) return PurchaseResult.alreadyOwned;
      if (hero.coins < price) return PurchaseResult.notEnoughCoins;
      await _db.customUpdate(
        'UPDATE heroes SET coins = coins - ? WHERE id = 1',
        variables: [Variable.withInt(price)],
        updates: {_db.heroes},
      );
      await _db.into(_db.ownedItems).insert(
            OwnedItemsCompanion.insert(itemId: itemId, acquiredAt: DateTime.now()),
          );
      return PurchaseResult.bought;
    });
  }

  /// Buys one healing potion for the pouch.
  Future<PurchaseResult> buyPotion() {
    return _db.transaction(() async {
      final hero = await (_db.select(_db.heroes)..where((h) => h.id.equals(1))).getSingleOrNull();
      if (hero == null) return PurchaseResult.unavailable;
      if (hero.potionStock >= Shop.potionPouchMax) return PurchaseResult.pouchFull;
      if (hero.coins < Shop.potionPrice) return PurchaseResult.notEnoughCoins;
      await _db.customUpdate(
        'UPDATE heroes SET coins = coins - ?, potion_stock = potion_stock + 1 WHERE id = 1',
        variables: [Variable.withInt(Shop.potionPrice)],
        updates: {_db.heroes},
      );
      return PurchaseResult.bought;
    });
  }

  // ---- Real-money purchases -----------------------------------------------

  /// What the saved purchase receipts add up to.
  Stream<Entitlements> watchEntitlements() => _db.select(_db.purchaseReceipts).watch().map(_toEntitlements);

  Future<Entitlements> entitlements() async => _toEntitlements(await _db.select(_db.purchaseReceipts).get());

  static Entitlements _toEntitlements(List<PurchaseReceiptRow> rows) =>
      Entitlements.fromReceipts([for (final r in rows) (key: r.key, productId: r.productId)]);

  /// Saves a completed store purchase. Safe to call again with the same
  /// purchase: a pack is stored once and a tip once per transaction, so a
  /// repeated delivery from the store never grants anything twice. Returns
  /// true if it was new. Nothing here touches XP, energy, coins or any stat.
  Future<bool> recordPurchase(StoreProduct product, String transactionId, {required DateTime at}) async {
    final key = Entitlements.receiptKey(product, transactionId);
    return _db.transaction(() async {
      final existing = await (_db.select(_db.purchaseReceipts)..where((r) => r.key.equals(key))).getSingleOrNull();
      if (existing != null) return false;
      await _db.into(_db.purchaseReceipts).insert(
            PurchaseReceiptsCompanion.insert(key: key, productId: product.id, grantedAt: at),
          );
      return true;
    });
  }

  // ---- Streaks ------------------------------------------------------------

  /// Where the streak stands right now, from everything ever logged.
  Future<StreakStatus> streakStatus({required DateTime today}) async {
    final heroRow = await (_db.select(_db.heroes)..where((h) => h.id.equals(1))).getSingleOrNull();
    final experience = heroRow == null ? ExperienceLevel.starting : _toHero(heroRow).experience;
    final workouts = (await _db.select(_db.workouts).get()).map(_toEntry);
    return StreakRules.evaluate(workouts: workouts, today: today, experience: experience);
  }

  /// The milestones the player has already been paid for.
  Stream<Set<int>> watchClaimedStreaks() =>
      _db.select(_db.streakRewards).watch().map((rows) => {for (final r in rows) r.days});

  /// Pays every streak milestone that has been reached and not yet claimed, in
  /// one transaction, and returns what was paid. Safe to call any time: with
  /// nothing due it does nothing, and a claimed milestone is never paid twice
  /// or taken back.
  Future<List<StreakMilestone>> claimStreakRewards({required DateTime today}) {
    return _db.transaction(() async {
      final heroRow = await (_db.select(_db.heroes)..where((h) => h.id.equals(1))).getSingleOrNull();
      if (heroRow == null) return const <StreakMilestone>[];
      final hero = _toHero(heroRow);
      final workouts = (await _db.select(_db.workouts).get()).map(_toEntry);
      final status = StreakRules.evaluate(workouts: workouts, today: today, experience: hero.experience);
      final claimed = {for (final r in await _db.select(_db.streakRewards).get()) r.days};
      final due = StreakRules.due(current: status.current, claimed: claimed);
      for (final m in due) {
        await _db.into(_db.streakRewards).insert(
              StreakRewardsCompanion.insert(days: Value(m.days), claimedAt: today, coins: m.coins, xp: m.xp),
            );
        await _db.customUpdate(
          'UPDATE heroes SET coins = coins + ?, streak_xp = streak_xp + ? WHERE id = 1',
          variables: [Variable.withInt(m.coins), Variable.withInt(m.xp)],
          updates: {_db.heroes},
        );
      }
      return due;
    });
  }

  // ---- Inventory ----------------------------------------------------------

  Stream<List<OwnedItem>> watchItems() => _db.select(_db.ownedItems).watch().map(
        (rows) => [
          for (final r in rows)
            OwnedItem(
              itemId: r.itemId,
              acquiredAt: r.acquiredAt,
              equipped: r.equipped,
            ),
        ],
      );

  /// Equips or unequips an item; only one item per slot can be worn.
  Future<void> setEquipped(String itemId, bool equipped) async {
    final item = ItemCatalog.byId(itemId);
    if (item == null) return;
    await _db.transaction(() async {
      if (equipped) {
        final sameSlot = ItemCatalog.all
            .where((i) => i.slot == item.slot)
            .map((i) => i.id)
            .toList();
        await (_db.update(_db.ownedItems)
              ..where((o) => o.itemId.isIn(sameSlot)))
            .write(const OwnedItemsCompanion(equipped: Value(false)));
      }
      await (_db.update(_db.ownedItems)..where((o) => o.itemId.equals(itemId)))
          .write(OwnedItemsCompanion(equipped: Value(equipped)));
    });
  }

  // ---- Settings -----------------------------------------------------------

  Stream<AppPrefs> watchSettings() => (_db.select(_db.appSettings)
        ..where((s) => s.id.equals(1)))
      .watchSingleOrNull()
      .map((r) => r == null
          ? const AppPrefs()
          : AppPrefs(
              useMetric: r.useMetric,
              reducedMotion: r.reducedMotion,
              quietChad: r.quietChad,
              soundOn: r.soundOn,
              hapticsOn: r.hapticsOn,
            ));

  Future<void> saveSettings(AppPrefs p) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            id: const Value(1),
            useMetric: Value(p.useMetric),
            reducedMotion: Value(p.reducedMotion),
            quietChad: Value(p.quietChad),
            soundOn: Value(p.soundOn),
            hapticsOn: Value(p.hapticsOn),
          ),
        );
  }

  // ---- Privacy tools ------------------------------------------------------

  /// Everything the app stores, as JSON the player can keep.
  Future<String> exportJson() async {
    final workouts = await (_db.select(_db.workouts)
          ..orderBy([(t) => OrderingTerm.asc(t.performedAt)]))
        .get();
    final hero = await (_db.select(_db.heroes)).getSingleOrNull();
    final grants = await _db.select(_db.rewardGrants).get();
    final storyRead = await _db.select(_db.storyProgress).get();
    final storyChoices = await _db.select(_db.storyChoices).get();
    final streaks = await (_db.select(_db.streakRewards)..orderBy([(t) => OrderingTerm.asc(t.days)])).get();
    final receipts = await (_db.select(_db.purchaseReceipts)..orderBy([(t) => OrderingTerm.asc(t.grantedAt)])).get();
    final data = {
      'app': 'I Am Chad: Fitness RPG',
      'exportVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'workouts': workouts.map((w) => _toEntry(w).toJson()).toList(),
      'rewardGrants': [
        for (final g in grants)
          {
            'day': g.day,
            'effortMinutes': g.effortMinutes,
            'creditedMinutes': g.creditedMinutes,
            'xp': g.xp,
            'energy': g.energy,
            'rulesVersion': g.rulesVersion,
          }
      ],
      if (hero != null)
        'hero': {
          'name': hero.name,
          'experience': hero.experience,
          'adventureXp': hero.adventureXp,
          'coins': hero.coins,
          'victories': hero.victories,
          'streakXp': hero.streakXp,
          'potionStock': hero.potionStock,
          'cape': hero.cape,
          'hairDye': hero.hairDye,
        },
      'purchases': [
        for (final r in receipts) {'productId': r.productId, 'grantedAt': r.grantedAt.toIso8601String()}
      ],
      'story': {
        'chaptersRead': [for (final r in storyRead) r.chapter],
        'choices': {for (final r in storyChoices) r.key: r.option},
      },
      'streakRewards': [
        for (final r in streaks)
          {'days': r.days, 'claimedAt': r.claimedAt.toIso8601String(), 'coins': r.coins, 'xp': r.xp}
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Wipes all saved data from the device.
  Future<void> deleteEverything() async {
    await _db.transaction(() async {
      for (final table in _db.allTables) {
        await _db.delete(table).go();
      }
    });
  }

  // ---- Mapping ------------------------------------------------------------

  static WorkoutEntry _toEntry(WorkoutRow r) => WorkoutEntry(
        id: r.id,
        activityId: r.activityId,
        performedAt: r.performedAt,
        variant: r.variant,
        sets: r.sets,
        reps: r.reps,
        durationSeconds: r.durationSeconds,
        distanceMeters: r.distanceMeters,
        loadKg: r.loadKg,
        perceivedEffort: r.perceivedEffort,
        notes: r.notes,
        cameraCounted: r.cameraCounted,
        loggedAt: r.loggedAt,
      );

  static WorkoutsCompanion _toCompanion(WorkoutEntry e) => WorkoutsCompanion(
        activityId: Value(e.activityId),
        performedAt: Value(e.performedAt),
        variant: Value(e.variant),
        sets: Value(e.sets),
        reps: Value(e.reps),
        durationSeconds: Value(e.durationSeconds),
        distanceMeters: Value(e.distanceMeters),
        loadKg: Value(e.loadKg),
        perceivedEffort: Value(e.perceivedEffort),
        notes: Value(e.notes),
        cameraCounted: Value(e.cameraCounted),
        loggedAt: Value(e.loggedAt),
      );

  static HeroProfile _toHero(HeroRow r) => HeroProfile(
        name: r.name,
        appearanceStyle: r.appearanceStyle,
        appearanceColor: r.appearanceColor,
        appearanceSkin: r.appearanceSkin,
        experience: ExperienceLevel.values.firstWhere(
          (e) => e.name == r.experience,
          orElse: () => ExperienceLevel.starting,
        ),
        preferredCategories: {
          for (final n in r.preferredCategories.split(','))
            for (final c in ActivityCategory.values)
              if (c.name == n) c,
        },
        hasDumbbells: r.hasDumbbells,
        energySpent: r.energySpent,
        adventureXp: r.adventureXp,
        coins: r.coins,
        victories: r.victories,
        streakXp: r.streakXp,
        potionStock: r.potionStock,
        cape: r.cape,
        hairDye: r.hairDye,
      );
}
