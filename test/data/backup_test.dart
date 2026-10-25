import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/backup.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/patronage.dart';
import 'package:i_am_chad/domain/player_state.dart';
import 'package:i_am_chad/domain/workout.dart';

class _Save {
  _Save(this.name)
      : db = AppDatabase.forTesting(NativeDatabase.memory()) {
    repo = GameRepository(db);
  }

  final AppDatabase db;
  late final GameRepository repo;
  final String name;

  Future<void> fill() async {
    await repo.createHero(HeroProfile(
      name: name,
      appearanceStyle: 2,
      appearanceColor: 3,
      appearanceSkin: 1,
      experience: ExperienceLevel.regular,
      preferredCategories: const {ActivityCategory.core, ActivityCategory.mobility},
      hasDumbbells: true,
    ));
    await repo.addWorkout(WorkoutEntry(
      activityId: 'dumbbell_press',
      performedAt: DateTime(2026, 10, 19, 9),
      sets: 3,
      reps: 8,
      loadKg: 15,
      notes: 'felt "great", honestly\nsecond line',
      perceivedEffort: 2,
    ));
    await repo.addWorkout(WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 20, 18), durationSeconds: 1800, distanceMeters: 2500.5));
    await repo.addWorkout(WorkoutEntry(activityId: 'push_up', performedAt: DateTime(2026, 10, 21, 8), sets: 2, reps: 9, variant: 'Knee', cameraCounted: true));
    await repo.recordExpedition(seed: 7, victory: true, battlesWon: 3, xp: 120, coins: 15, lootItemId: 'wooden_sword');
    await repo.setEquipped('wooden_sword', true);
    await repo.markChapterRead(0, at: DateTime(2026, 10, 20));
    await repo.saveStoryChoice('motivation', 1);
    await repo.recordPurchase(Patronage.patronPack, 'tx-1', at: DateTime(2026, 10, 21));
  }

  Future<Map<String, dynamic>> snapshot() async {
    final data = jsonDecode(await repo.backupJson()) as Map<String, dynamic>;
    return (data['tables'] as Map).cast<String, dynamic>();
  }

  Future<void> close() => db.close();
}

String _edited(String backup, void Function(Map<String, dynamic> json) change) {
  final json = jsonDecode(backup) as Map<String, dynamic>;
  change(json);
  return jsonEncode(json);
}

BackupProblem _problem(GameRepository repo, String text) {
  try {
    repo.readBackup(text);
  } on BackupException catch (e) {
    return e.problem;
  }
  fail('expected the backup to be refused');
}

void main() {
  group('a full backup and restore', () {
    test('everything about the player comes back exactly, on a fresh phone', () async {
      final a = _Save('Ada');
      await a.fill();
      final backup = await a.repo.backupJson();

      final b = _Save('unused');
      addTearDown(b.close);
      addTearDown(a.close);
      await b.repo.restoreBackup(b.repo.readBackup(backup));

      expect(await b.snapshot(), await a.snapshot());
      final hero = await b.repo.watchHero().first;
      expect(hero!.name, 'Ada');
      expect(hero.appearanceSkin, 1);
      final workouts = await b.repo.watchWorkouts().first;
      expect(workouts.length, 3);
      expect(workouts.map((w) => w.notes).whereType<String>().single, 'felt "great", honestly\nsecond line');
      expect(workouts.firstWhere((w) => w.activityId == 'walking').distanceMeters, 2500.5);
      expect(workouts.firstWhere((w) => w.activityId == 'push_up').cameraCounted, isTrue);
      expect((await b.repo.watchItems().first).where((i) => i.equipped).map((i) => i.itemId), ['wooden_sword']);
      expect(await b.repo.watchStoryRead().first, {0});
      expect(await b.repo.watchStoryChoices().first, {'motivation': 1});
      expect((await b.repo.entitlements()).hasPatronPack, isTrue);
      // Rewards were part of the backup, so they match too.
      expect((await b.repo.rewardForDay(DateTime(2026, 10, 19))).xp, (await a.repo.rewardForDay(DateTime(2026, 10, 19))).xp);
    });

    test('it replaces what was on the phone, and keeps the phone\'s own settings', () async {
      final a = _Save('Ada');
      await a.fill();
      final b = _Save('Bo');
      addTearDown(a.close);
      addTearDown(b.close);
      await b.fill();
      await b.repo.addWorkout(WorkoutEntry(activityId: 'squat', performedAt: DateTime(2026, 10, 22, 7), sets: 1, reps: 5));
      await b.repo.saveSettings(const AppPrefs(soundOn: false, useMetric: false));

      await b.repo.restoreBackup(b.repo.readBackup(await a.repo.backupJson()));

      expect((await b.repo.watchHero().first)!.name, 'Ada');
      expect((await b.repo.watchWorkouts().first).length, 3, reason: 'the extra workout is gone');
      final prefs = await b.repo.watchSettings().first;
      expect(prefs.soundOn, isFalse);
      expect(prefs.useMetric, isFalse);
    });

    test('a screen that is already open sees the restored game', () async {
      final a = _Save('Ada');
      await a.fill();
      final b = _Save('Bo');
      addTearDown(a.close);
      addTearDown(b.close);
      await b.fill();
      final seen = <String>[];
      final sub = b.repo.watchHero().listen((h) => seen.add(h?.name ?? ''));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await b.repo.restoreBackup(b.repo.readBackup(await a.repo.backupJson()));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await sub.cancel();
      expect(seen, containsAllInOrder(['Bo', 'Ada']));
    });

    test('a backup of an empty game restores to an empty game', () async {
      final empty = _Save('x');
      final full = _Save('Ada');
      addTearDown(empty.close);
      addTearDown(full.close);
      await full.fill();
      await full.repo.restoreBackup(full.repo.readBackup(await empty.repo.backupJson()));
      expect(await full.repo.watchHero().first, isNull);
      expect(await full.repo.watchWorkouts().first, isEmpty);
    });

    test('a backup from an earlier version restores, with newer columns left at their defaults', () async {
      final a = _Save('Ada');
      await a.fill();
      addTearDown(a.close);
      final old = _edited(await a.repo.backupJson(), (json) {
        json['schemaVersion'] = 11;
        // Version 11 had no weekly goal column on the hero, say: an older shape simply lacks it.
        for (final row in (json['tables']['heroes'] as List)) {
          (row as Map).remove('weekly_goal_days');
        }
      });
      final b = _Save('Bo');
      addTearDown(b.close);
      await b.repo.restoreBackup(b.repo.readBackup(old));
      expect((await b.repo.watchHero().first)!.name, 'Ada');
    });
  });

  group('a backup that cannot be trusted is refused before anything changes', () {
    late _Save phone;
    late String good;
    late Map<String, dynamic> before;

    setUp(() async {
      final a = _Save('Ada');
      await a.fill();
      good = await a.repo.backupJson();
      await a.close();
      phone = _Save('Bo');
      await phone.fill();
      before = await phone.snapshot();
    });

    tearDown(() => phone.close());

    Future<void> expectUntouched() async => expect(await phone.snapshot(), before);

    test('text that is not a backup', () async {
      for (final text in ['', 'hello', '[]', '{}', '{"app":"Something Else","tables":{}}', jsonEncode(await phone.repo.exportJson())]) {
        expect(_problem(phone.repo, text), BackupProblem.notABackup, reason: text);
      }
      await expectUntouched();
    });

    test('a backup from a newer version of the game', () async {
      expect(_problem(phone.repo, _edited(good, (j) => j['schemaVersion'] = 999)), BackupProblem.newerVersion);
      expect(_problem(phone.repo, _edited(good, (j) => j['backupVersion'] = 99)), BackupProblem.newerVersion);
      await expectUntouched();
    });

    test('an unknown table or column, or one that is not data to restore', () async {
      expect(_problem(phone.repo, _edited(good, (j) => (j['tables'] as Map)['evil'] = [{'a': 1}])), BackupProblem.damaged);
      expect(_problem(phone.repo, _edited(good, (j) => (j['tables']['workouts'] as List).first['evil'] = 1)), BackupProblem.damaged);
      expect(_problem(phone.repo, _edited(good, (j) => (j['tables'] as Map)['app_settings'] = [{'id': 1}])), BackupProblem.damaged,
          reason: 'device settings are never restored');
      expect(_problem(phone.repo, _edited(good, (j) => (j['tables'] as Map)['sqlite_master'] = [])), BackupProblem.damaged);
      await expectUntouched();
    });

    test('values of the wrong kind, nested data, and nothing where something is required', () async {
      expect(_problem(phone.repo, _edited(good, (j) => (j['tables']['workouts'] as List).first['reps'] = 'lots')), BackupProblem.damaged);
      expect(_problem(phone.repo, _edited(good, (j) => (j['tables']['workouts'] as List).first['activity_id'] = 5)), BackupProblem.damaged);
      expect(_problem(phone.repo, _edited(good, (j) => (j['tables']['workouts'] as List).first['notes'] = {'a': 1})), BackupProblem.damaged);
      expect(_problem(phone.repo, _edited(good, (j) => (j['tables']['workouts'] as List).first['activity_id'] = null)), BackupProblem.damaged);
      expect(_problem(phone.repo, _edited(good, (j) => (j['tables']['workouts'] as List).first['logged_at'] = 'yesterday')), BackupProblem.damaged);
      expect(_problem(phone.repo, _edited(good, (j) => (j['tables']['workouts'] as List).add(5))), BackupProblem.damaged);
      await expectUntouched();
    });

    test('a row that is missing something the game needs rolls the whole restore back', () async {
      final broken = _edited(good, (j) => (j['tables']['workouts'] as List).last.remove('activity_id'));
      final backup = phone.repo.readBackup(broken); // each value is fine; the row is incomplete
      await expectLater(phone.repo.restoreBackup(backup), throwsA(isA<BackupException>()));
      await expectUntouched();
    });
  });

  group('the backup file', () {
    test('says what it is, and holds the player\'s game but not the device\'s settings', () async {
      final a = _Save('Ada');
      addTearDown(a.close);
      await a.fill();
      final json = jsonDecode(await a.repo.backupJson()) as Map<String, dynamic>;
      expect(json['app'], Backup.appName);
      expect(json['backupVersion'], Backup.format);
      expect(json['schemaVersion'], a.db.schemaVersion);
      final tables = (json['tables'] as Map).keys.toSet();
      expect(tables, containsAll(['workouts', 'heroes', 'owned_items', 'expedition_runs', 'story_progress', 'story_choices', 'purchase_receipts', 'reward_grants']));
      expect(tables, isNot(contains('app_settings')));
    });

    test('every table the game keeps about the player is in it', () async {
      final a = _Save('Ada');
      addTearDown(a.close);
      final json = jsonDecode(await a.repo.backupJson()) as Map<String, dynamic>;
      final inBackup = (json['tables'] as Map).keys.toSet();
      final all = {for (final t in a.db.allTables) t.actualTableName};
      expect(inBackup, all.difference(Backup.deviceTables), reason: 'a new table must be backed up, or named as a device table');
    });
  });
}
