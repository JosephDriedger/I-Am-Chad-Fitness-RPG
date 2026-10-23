import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Source of truth for everything the player records.
@DataClassName('WorkoutRow')
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get activityId => text()();
  DateTimeColumn get performedAt => dateTime()();
  TextColumn get variant => text().nullable()();
  IntColumn get sets => integer().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  RealColumn get distanceMeters => real().nullable()();
  RealColumn get loadKg => real().nullable()();
  IntColumn get perceivedEffort => integer().nullable()();
  TextColumn get notes => text().nullable()();

  /// The reps were counted by the camera rather than typed in.
  BoolColumn get cameraCounted => boolean().withDefault(const Constant(false))();

  /// When the workout was entered. Null for entries from before this was kept.
  DateTimeColumn get loggedAt => dateTime().nullable()();
}

/// One derived reward per local day, stamped with the rules version used.
/// Recomputed for a day whenever that day's workouts change; days the player
/// doesn't touch keep the rules they were granted under.
@DataClassName('RewardGrantRow')
class RewardGrants extends Table {
  TextColumn get day => text()();
  RealColumn get effortMinutes => real()();
  RealColumn get creditedMinutes => real()();
  IntColumn get xp => integer()();
  IntColumn get energy => integer()();
  IntColumn get rulesVersion => integer()();

  @override
  Set<Column> get primaryKey => {day};
}

/// The single player profile (id is always 1).
@DataClassName('HeroRow')
class Heroes extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  IntColumn get appearanceStyle => integer().withDefault(const Constant(0))();
  IntColumn get appearanceColor => integer().withDefault(const Constant(0))();
  IntColumn get appearanceSkin => integer().withDefault(const Constant(0))();
  TextColumn get experience => text()();
  TextColumn get preferredCategories =>
      text().withDefault(const Constant(''))();
  BoolColumn get hasDumbbells =>
      boolean().withDefault(const Constant(false))();
  IntColumn get energySpent => integer().withDefault(const Constant(0))();
  IntColumn get adventureXp => integer().withDefault(const Constant(0))();
  IntColumn get coins => integer().withDefault(const Constant(0))();
  IntColumn get victories => integer().withDefault(const Constant(0))();

  /// XP from streak rewards (activity XP is derived; this is paid out once).
  IntColumn get streakXp => integer().withDefault(const Constant(0))();

  /// Healing potions bought from the shop and kept in the pouch.
  IntColumn get potionStock => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OwnedItemRow')
class OwnedItems extends Table {
  TextColumn get itemId => text()();
  DateTimeColumn get acquiredAt => dateTime()();
  BoolColumn get equipped => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {itemId};
}

@DataClassName('ExpeditionRunRow')
class ExpeditionRuns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get seed => integer()();
  DateTimeColumn get finishedAt => dateTime()();
  BoolColumn get victory => boolean()();
  IntColumn get battlesWon => integer()();
  IntColumn get xp => integer()();
  IntColumn get coins => integer()();
  TextColumn get lootItemId => text().nullable()();
}

/// A streak milestone the player has been paid for. Once claimed it is never
/// taken back, even if workouts are later edited (see docs/REWARD_RULES.md).
@DataClassName('StreakRewardRow')
class StreakRewards extends Table {
  IntColumn get days => integer()();
  DateTimeColumn get claimedAt => dateTime()();
  IntColumn get coins => integer()();
  IntColumn get xp => integer()();

  @override
  Set<Column> get primaryKey => {days};
}

/// The expedition the player is in the middle of, if any (id is always 1).
/// Written at the start of every step so closing the app never loses it.
@DataClassName('ActiveExpeditionRow')
class ActiveExpeditions extends Table {
  IntColumn get id => integer()();
  IntColumn get seed => integer()();
  IntColumn get heroLevel => integer()();
  IntColumn get stepIndex => integer()();
  IntColumn get heroHp => integer()();
  IntColumn get potions => integer()();
  IntColumn get battlesWon => integer()();
  IntColumn get xp => integer()();
  IntColumn get coins => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SettingsRow')
class AppSettings extends Table {
  IntColumn get id => integer()();
  BoolColumn get useMetric => boolean().withDefault(const Constant(true))();
  BoolColumn get reducedMotion =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get quietChad => boolean().withDefault(const Constant(false))();
  BoolColumn get soundOn => boolean().withDefault(const Constant(true))();
  BoolColumn get hapticsOn => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Workouts,
    RewardGrants,
    Heroes,
    OwnedItems,
    ExpeditionRuns,
    ActiveExpeditions,
    StreakRewards,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(driftDatabase(
          name: 'i_am_chad',
          // Only used by the optional web preview (see docs/DEVELOPMENT.md).
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ));

  /// For tests: pass `NativeDatabase.memory()`.
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // Workout rows must always survive upgrades (see docs/DATA_MODEL.md).
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(heroes, heroes.appearanceSkin);
            await m.addColumn(appSettings, appSettings.soundOn);
            await m.addColumn(appSettings, appSettings.hapticsOn);
          }
          if (from < 3) {
            await m.createTable(activeExpeditions);
          }
          if (from < 4) {
            await m.addColumn(workouts, workouts.cameraCounted);
          }
          if (from < 5) {
            await m.createTable(streakRewards);
            await m.addColumn(heroes, heroes.streakXp);
          }
          if (from < 6) {
            await m.addColumn(workouts, workouts.loggedAt);
            await m.addColumn(heroes, heroes.potionStock);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
