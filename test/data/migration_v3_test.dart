import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/expedition.dart';

void main() {
  test('v2 saves upgrade to v3 and can then save an expedition', () async {
    // A database exactly as schema version 2 shipped (no active_expeditions).
    final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE workouts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          activity_id TEXT NOT NULL,
          performed_at INTEGER NOT NULL,
          variant TEXT, sets INTEGER, reps INTEGER, duration_seconds INTEGER,
          distance_meters REAL, load_kg REAL, perceived_effort INTEGER,
          notes TEXT
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
          created_at INTEGER NOT NULL
        );
        CREATE TABLE app_settings (
          id INTEGER NOT NULL PRIMARY KEY,
          use_metric INTEGER NOT NULL DEFAULT 1,
          reduced_motion INTEGER NOT NULL DEFAULT 0,
          quiet_chad INTEGER NOT NULL DEFAULT 0,
          sound_on INTEGER NOT NULL DEFAULT 1,
          haptics_on INTEGER NOT NULL DEFAULT 1
        );
        INSERT INTO workouts (activity_id, performed_at, duration_seconds)
          VALUES ('walking', 1790000000, 600);
        INSERT INTO heroes (id, name, appearance_skin, experience, coins, created_at)
          VALUES (1, 'Veteran', 3, 'regular', 54, 1790000000);
        PRAGMA user_version = 2;
      ''');
    }));
    addTearDown(db.close);
    final repo = GameRepository(db);

    // Nothing was lost.
    expect((await repo.watchHero().first)!.name, 'Veteran');
    expect((await repo.watchHero().first)!.appearanceSkin, 3);
    expect((await repo.watchHero().first)!.coins, 54);
    expect((await repo.watchWorkouts().first).single.activityId, 'walking');

    // And the new table works.
    expect(await repo.activeExpedition(), isNull);
    await repo.startExpedition(
      ExpeditionProgress.fresh(seed: 7, heroLevel: 5, heroMaxHp: 66),
      energyCost: 2,
    );
    expect((await repo.activeExpedition())!.seed, 7);
    expect((await repo.watchHero().first)!.energySpent, 2);
  });
}
