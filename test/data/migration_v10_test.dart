import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';

void main() {
  test('v9 saves upgrade to v10 with their settings intact and music off', () async {
    // A database as schema version 9 shipped: settings without a music switch.
    final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE app_settings (
          id INTEGER NOT NULL PRIMARY KEY,
          use_metric INTEGER NOT NULL DEFAULT 1,
          reduced_motion INTEGER NOT NULL DEFAULT 0,
          quiet_chad INTEGER NOT NULL DEFAULT 0,
          sound_on INTEGER NOT NULL DEFAULT 1,
          haptics_on INTEGER NOT NULL DEFAULT 1
        );
        INSERT INTO app_settings (id, use_metric, reduced_motion, sound_on, haptics_on)
          VALUES (1, 0, 1, 0, 1);
        CREATE TABLE active_expeditions (
          id INTEGER NOT NULL PRIMARY KEY,
          seed INTEGER NOT NULL, hero_level INTEGER NOT NULL, step_index INTEGER NOT NULL,
          hero_hp INTEGER NOT NULL, potions INTEGER NOT NULL, battles_won INTEGER NOT NULL,
          xp INTEGER NOT NULL, coins INTEGER NOT NULL
        );
        PRAGMA user_version = 9;
      ''');
    }));
    addTearDown(db.close);
    final repo = GameRepository(db);

    final prefs = await repo.watchSettings().first;
    expect(prefs.useMetric, isFalse);
    expect(prefs.reducedMotion, isTrue);
    expect(prefs.soundOn, isFalse);
    expect(prefs.hapticsOn, isTrue);
    expect(prefs.musicOn, isFalse, reason: 'music is only ever on because the player asked');

    await repo.saveSettings(prefs.copyWith(musicOn: true));
    final saved = await repo.watchSettings().first;
    expect(saved.musicOn, isTrue);
    expect(saved.soundOn, isFalse, reason: 'other switches are untouched');
  });

  test('a fresh install starts with music off and sound and vibration on', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final prefs = await GameRepository(db).watchSettings().first;
    expect(prefs.musicOn, isFalse);
    expect(prefs.soundOn, isTrue);
    expect(prefs.hapticsOn, isTrue);
  });
}
