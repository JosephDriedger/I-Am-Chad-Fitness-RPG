import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';

void main() {
  test('v12 saves upgrade to v13 and keep fighting the way they always did', () async {
    // A database as schema version 12 shipped: a hero with no fighting style column.
    final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE heroes (
          id INTEGER NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          appearance_style INTEGER NOT NULL,
          appearance_color INTEGER NOT NULL,
          appearance_skin INTEGER NOT NULL DEFAULT 0,
          experience TEXT NOT NULL,
          preferred_categories TEXT NOT NULL,
          has_dumbbells INTEGER NOT NULL,
          energy_spent INTEGER NOT NULL DEFAULT 0,
          adventure_xp INTEGER NOT NULL DEFAULT 0,
          coins INTEGER NOT NULL DEFAULT 0,
          victories INTEGER NOT NULL DEFAULT 0,
          streak_xp INTEGER NOT NULL DEFAULT 0,
          potion_stock INTEGER NOT NULL DEFAULT 0,
          cape TEXT NOT NULL DEFAULT 'classic',
          hair_dye TEXT NOT NULL DEFAULT '',
          weekly_goal_days INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        );
        INSERT INTO heroes (id, name, appearance_style, appearance_color, experience, preferred_categories, has_dumbbells, created_at)
          VALUES (1, 'Ada', 0, 0, 'returning', 'cardio', 0, 1760000000);
        PRAGMA user_version = 12;
      ''');
    }));
    addTearDown(db.close);
    final repo = GameRepository(db);
    final hero = (await repo.watchHero().first)!;
    expect(hero.name, 'Ada');
    expect(hero.fightingStyle, 'steady', reason: 'the way they always fought');
    await repo.setFightingStyle('guardian');
    expect((await repo.watchHero().first)!.fightingStyle, 'guardian');
  });
}
