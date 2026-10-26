import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/player_state.dart';
import 'package:i_am_chad/domain/reminders.dart';

void main() {
  test('v11 saves upgrade to v12 with their settings intact and reminders off', () async {
    // A database as schema version 11 shipped: settings without any reminder columns.
    final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE app_settings (
          id INTEGER NOT NULL PRIMARY KEY,
          use_metric INTEGER NOT NULL DEFAULT 1,
          reduced_motion INTEGER NOT NULL DEFAULT 0,
          quiet_chad INTEGER NOT NULL DEFAULT 0,
          sound_on INTEGER NOT NULL DEFAULT 1,
          haptics_on INTEGER NOT NULL DEFAULT 1,
          music_on INTEGER NOT NULL DEFAULT 0
        );
        INSERT INTO app_settings (id, use_metric, reduced_motion, sound_on, haptics_on, music_on)
          VALUES (1, 0, 1, 0, 1, 1);
        CREATE TABLE heroes (id INTEGER NOT NULL PRIMARY KEY);
        PRAGMA user_version = 11;
      ''');
    }));
    addTearDown(db.close);
    final repo = GameRepository(db);

    final prefs = await repo.watchSettings().first;
    expect(prefs.useMetric, isFalse);
    expect(prefs.reducedMotion, isTrue);
    expect(prefs.soundOn, isFalse);
    expect(prefs.musicOn, isTrue, reason: 'earlier switches are untouched');
    expect(prefs.reminders.enabled, isFalse, reason: 'reminders are only ever on because the player asked');
    expect(prefs.reminders.hour, 18);
    expect(prefs.reminders.days, {DateTime.monday, DateTime.wednesday, DateTime.friday});

    await repo.saveSettings(prefs.copyWith(
      reminders: const ReminderPrefs(enabled: true, hour: 9, days: {DateTime.tuesday, DateTime.sunday}),
    ));
    final saved = await repo.watchSettings().first;
    expect(saved.reminders.enabled, isTrue);
    expect(saved.reminders.hour, 9);
    expect(saved.reminders.days, {DateTime.tuesday, DateTime.sunday});
    expect(saved.musicOn, isTrue);
    expect(saved.soundOn, isFalse);
  });

  test('a fresh install starts with reminders off, at six in the evening on Monday, Wednesday and Friday', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final prefs = await GameRepository(db).watchSettings().first;
    expect(prefs.reminders.enabled, isFalse);
    expect(prefs.reminders.hour, 18);
    expect(prefs.reminders.days, {1, 3, 5});
  });

  test('an hour outside the allowed range in a save is brought back inside it', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = GameRepository(db);
    await repo.saveSettings(const AppPrefs()); // creates the row
    await db.customUpdate(
      'UPDATE app_settings SET reminder_on = 1, reminder_hour = 3, reminder_days = 127 WHERE id = 1',
      updates: {db.appSettings},
    );
    final prefs = await repo.watchSettings().first;
    expect(prefs.reminders.hour, ReminderPrefs.earliestHour, reason: 'never in the small hours');
    expect(prefs.reminders.days, {1, 2, 3, 4, 5, 6, 7});
  });
}
