import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/patronage.dart';

void main() {
  test('v7 saves upgrade to v8 with their hero and workouts intact', () async {
    // A database as schema version 7 shipped: no purchase receipts, and no
    // cape or hair dye on the hero.
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
          created_at INTEGER NOT NULL
        );
        INSERT INTO workouts (activity_id, performed_at, sets, reps)
          VALUES ('push_up', 1790000000, 3, 10);
        INSERT INTO heroes (id, name, appearance_style, experience, coins, potion_stock, created_at)
          VALUES (1, 'Old Hero', 3, 'regular', 77, 2, 1790000000);
        PRAGMA user_version = 7;
      ''');
    }));
    addTearDown(db.close);
    final repo = GameRepository(db);

    final hero = (await repo.watchHero().first)!;
    expect(hero.name, 'Old Hero');
    expect(hero.coins, 77);
    expect(hero.potionStock, 2);
    expect(hero.cape, 'classic');
    expect(hero.hairDye, '');
    expect(await repo.watchWorkouts().first, hasLength(1));

    // The new table works and starts empty.
    expect((await repo.entitlements()).hasPatronPack, isFalse);
    await repo.recordPurchase(Patronage.patronPack, 't1', at: DateTime(2026, 10, 23));
    expect((await repo.entitlements()).hasPatronPack, isTrue);
  });
}
