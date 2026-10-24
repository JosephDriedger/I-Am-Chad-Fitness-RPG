import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';

void main() {
  test('v8 saves upgrade to v9 with their hero intact and the suggested weekly goal', () async {
    // A database as schema version 8 shipped: no chosen weekly goal.
    final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE workouts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          activity_id TEXT NOT NULL,
          performed_at INTEGER NOT NULL,
          variant TEXT, sets INTEGER, reps INTEGER, duration_seconds INTEGER,
          distance_meters REAL, load_kg REAL, perceived_effort INTEGER,
          notes TEXT,
          camera_counted INTEGER NOT NULL DEFAULT 0,
          logged_at INTEGER
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
          potion_stock INTEGER NOT NULL DEFAULT 0,
          cape TEXT NOT NULL DEFAULT 'classic',
          hair_dye TEXT NOT NULL DEFAULT '',
          created_at INTEGER NOT NULL
        );
        INSERT INTO workouts (activity_id, performed_at, sets, reps)
          VALUES ('push_up', 1790000000, 3, 10);
        INSERT INTO heroes (id, name, experience, coins, cape, created_at)
          VALUES (1, 'Old Hero', 'regular', 41, 'crimson', 1790000000);
        CREATE TABLE app_settings (
          id INTEGER NOT NULL PRIMARY KEY,
          use_metric INTEGER NOT NULL DEFAULT 1,
          reduced_motion INTEGER NOT NULL DEFAULT 0,
          quiet_chad INTEGER NOT NULL DEFAULT 0,
          sound_on INTEGER NOT NULL DEFAULT 1,
          haptics_on INTEGER NOT NULL DEFAULT 1
        );
        PRAGMA user_version = 8;
      ''');
    }));
    addTearDown(db.close);
    final repo = GameRepository(db);

    final hero = (await repo.watchHero().first)!;
    expect(hero.name, 'Old Hero');
    expect(hero.coins, 41);
    expect(hero.cape, 'crimson');
    expect(hero.weeklyGoalDays, 0);
    expect(hero.weeklyGoalTarget, hero.experience.weeklyDaysGoal);
    expect(await repo.watchWorkouts().first, hasLength(1));

    await repo.setWeeklyGoalDays(6);
    expect((await repo.watchHero().first)!.weeklyGoalTarget, 6);
  });
}
