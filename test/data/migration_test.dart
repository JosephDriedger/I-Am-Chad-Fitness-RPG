import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';

void main() {
  test('v1 saves upgrade to v2 without losing anything', () async {
    // Build a database exactly as schema version 1 shipped.
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
          quiet_chad INTEGER NOT NULL DEFAULT 0
        );
        INSERT INTO workouts (activity_id, performed_at, duration_seconds)
          VALUES ('walking', 1790000000, 600);
        INSERT INTO heroes (id, name, appearance_style, appearance_color,
          experience, coins, created_at)
          VALUES (1, 'Veteran', 3, 2, 'regular', 42, 1790000000);
        INSERT INTO app_settings (id, use_metric, reduced_motion)
          VALUES (1, 0, 1);
        PRAGMA user_version = 1;
      ''');
    }));
    addTearDown(db.close);
    final repo = GameRepository(db);

    final hero = (await repo.watchHero().first)!;
    expect(hero.name, 'Veteran');
    expect(hero.appearanceStyle, 3);
    expect(hero.coins, 42);
    expect(hero.appearanceSkin, 0, reason: 'new column gets its default');

    final prefs = await repo.watchSettings().first;
    expect(prefs.useMetric, isFalse);
    expect(prefs.reducedMotion, isTrue);
    expect(prefs.soundOn, isTrue);
    expect(prefs.hapticsOn, isTrue);

    final workouts = await repo.watchWorkouts().first;
    expect(workouts.single.activityId, 'walking');

    // And the new columns are writable.
    await repo.updateHeroDetails(appearanceSkin: 4);
    expect((await repo.watchHero().first)!.appearanceSkin, 4);
  });
}
