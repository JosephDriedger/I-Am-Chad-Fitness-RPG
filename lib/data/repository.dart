import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/activity.dart';
import '../domain/expedition.dart';
import '../domain/hero.dart';
import '../domain/items.dart';
import '../domain/player_state.dart';
import '../domain/rewards.dart';
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
      await (_db.update(_db.workouts)..where((t) => t.id.equals(id)))
          .write(_toCompanion(e));
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
    if (rows.isEmpty) {
      await (_db.delete(_db.rewardGrants)..where((g) => g.day.equals(key))).go();
      return;
    }
    final r = rules.rewardForDay(rows.map(_toEntry));
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
  }) async {
    await (_db.update(_db.heroes)..where((h) => h.id.equals(1))).write(
      HeroesCompanion(
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
  Future<void> startExpedition(ExpeditionProgress p, {required int energyCost}) {
    return _db.transaction(() async {
      await spendEnergy(energyCost);
      await saveExpeditionProgress(p);
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
      return newItem;
    });
  }

  Future<void> addCoins(int coins) => _db.customUpdate(
        'UPDATE heroes SET coins = coins + ? WHERE id = 1',
        variables: [Variable.withInt(coins)],
        updates: {_db.heroes},
      );

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
        },
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
      );
}
