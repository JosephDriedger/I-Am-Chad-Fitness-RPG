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
  TextColumn get experience => text()();
  TextColumn get preferredCategories =>
      text().withDefault(const Constant(''))();
  BoolColumn get hasDumbbells =>
      boolean().withDefault(const Constant(false))();
  IntColumn get energySpent => integer().withDefault(const Constant(0))();
  IntColumn get adventureXp => integer().withDefault(const Constant(0))();
  IntColumn get coins => integer().withDefault(const Constant(0))();
  IntColumn get victories => integer().withDefault(const Constant(0))();
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

@DataClassName('SettingsRow')
class AppSettings extends Table {
  IntColumn get id => integer()();
  BoolColumn get useMetric => boolean().withDefault(const Constant(true))();
  BoolColumn get reducedMotion =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get quietChad => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Workouts, RewardGrants, Heroes, OwnedItems, ExpeditionRuns, AppSettings],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'i_am_chad'));

  /// For tests: pass `NativeDatabase.memory()`.
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // Add `onUpgrade` steps here as the schema evolves (see
        // docs/DATA_MODEL.md). Workout rows must always survive upgrades.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
