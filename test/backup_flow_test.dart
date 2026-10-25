import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/backup_files.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

final _now = DateTime(2026, 10, 22, 10);

HeroProfile _hero(String name) => HeroProfile(
      name: name,
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.returning,
      preferredCategories: const {ActivityCategory.cardio},
      hasDumbbells: false,
    );

/// A backup of a different player's game, as one copied from another phone.
Future<String> _otherPhonesBackup(WidgetTester tester) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = GameRepository(db);
  final text = await tester.runAsync(() async {
    await repo.createHero(_hero('Ada'));
    await repo.addWorkout(WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 20, 9), durationSeconds: 1800));
    await repo.addWorkout(WorkoutEntry(activityId: 'squat', performedAt: DateTime(2026, 10, 21, 9), sets: 2, reps: 8));
    final backup = await repo.backupJson();
    await db.close();
    return backup;
  });
  return text!;
}

Future<(AppDatabase, GameRepository)> _boot(WidgetTester tester, {bool phoneSurface = true, BackupFiles? files}) async {
  if (phoneSurface) usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = GameRepository(db);
  await tester.runAsync(() async {
    await repo.createHero(_hero('Bo'));
    await repo.addWorkout(WorkoutEntry(activityId: 'dumbbell_press', performedAt: DateTime(2026, 10, 19, 9), sets: 3, reps: 8, loadKg: 10));
  });
  await bootApp(tester, db, now: _now, overrides: [if (files != null) backupFilesProvider.overrideWithValue(files)]);
  return (db, repo);
}

/// A pretend clipboard.
String? _clip;

void _mockClipboard(WidgetTester tester) {
  _clip = null;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') _clip = (call.arguments as Map)['text'] as String?;
    if (call.method == 'Clipboard.getData') return {'text': _clip};
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await settle(tester, frames: 30);
}

Future<void> _reveal(WidgetTester tester, Key key) async {
  final f = find.byKey(key);
  await tester.scrollUntilVisible(f, 250, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(f);
  await settle(tester, frames: 3);
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await settle(tester, frames: 2);
  await tester.tap(find.byKey(key));
  await settle(tester, frames: 15);
}

void main() {
  testWidgets('Copy a Full Backup puts a restorable backup on the clipboard', (tester) async {
    _mockClipboard(tester);
    final (db, repo) = await _boot(tester);
    await _openSettings(tester);
    await _reveal(tester, const Key('copy_backup'));
    await tester.tap(find.byKey(const Key('copy_backup')));
    await settle(tester, frames: 10);

    expect(find.textContaining('It restores on this phone or a new one'), findsOneWidget);
    expect(_clip, isNotNull);
    final backup = repo.readBackup(_clip!);
    expect(backup.rows('heroes').single['name'], 'Bo');
    expect(backup.rows('workouts').length, 1);
    expect((jsonDecode(_clip!) as Map)['tables'], isNot(contains('app_settings')));
    await shutDown(tester, db);
  });

  testWidgets('pasting a backup shows what it holds, and restoring replaces the game', (tester) async {
    _mockClipboard(tester);
    final other = await _otherPhonesBackup(tester);
    final (db, repo) = await _boot(tester);
    await _openSettings(tester);
    await _reveal(tester, const Key('restore_backup'));
    await tester.tap(find.byKey(const Key('restore_backup')));
    await settle(tester, frames: 20);

    expect(find.text('Restore a Backup'), findsOneWidget);
    // Nothing is touched while the backup is only being read.
    await tester.enterText(find.byKey(const Key('restore_text')), other);
    await _tap(tester, const Key('restore_check'));
    expect(find.byKey(const Key('restore_summary')), findsOneWidget);
    expect(find.textContaining('A backup of Ada'), findsOneWidget);
    expect(find.textContaining('2 workouts'), findsOneWidget);
    expect(find.textContaining('replaces everything on this phone'), findsOneWidget);
    expect(find.textContaining('settings, such as units and sound, stay'), findsOneWidget);
    expect((await tester.runAsync(() => repo.watchHero().first))!.name, 'Bo', reason: 'not restored until they say so');

    await _tap(tester, const Key('restore_go'));
    await settle(tester, frames: 40);
    expect((await tester.runAsync(() => repo.watchHero().first))!.name, 'Ada');
    expect((await tester.runAsync(() => repo.watchWorkouts().first))!.length, 2);
    expect(find.textContaining('Restored. Welcome back, Ada.'), findsOneWidget);
    expect(find.text('Ada'), findsWidgets, reason: 'back in the hall, as the restored hero');
    await shutDown(tester, db);
  });

  testWidgets('Paste From Clipboard fills the box', (tester) async {
    _mockClipboard(tester);
    final other = await _otherPhonesBackup(tester);
    _clip = other;
    final (db, _) = await _boot(tester);
    await _openSettings(tester);
    await _reveal(tester, const Key('restore_backup'));
    await tester.tap(find.byKey(const Key('restore_backup')));
    await settle(tester, frames: 20);
    await _tap(tester, const Key('restore_paste'));
    expect(tester.widget<TextField>(find.byKey(const Key('restore_text'))).controller!.text, other);
    await shutDown(tester, db);
  });

  testWidgets('something that is not a backup is refused kindly and changes nothing', (tester) async {
    _mockClipboard(tester);
    // Made before the app starts: a second database cannot be opened while the card is showing.
    final newer = jsonDecode(await _otherPhonesBackup(tester)) as Map<String, dynamic>;
    newer['schemaVersion'] = 999;
    final (db, repo) = await _boot(tester);
    await _openSettings(tester);
    await _reveal(tester, const Key('restore_backup'));
    await tester.tap(find.byKey(const Key('restore_backup')));
    await settle(tester, frames: 20);

    await tester.enterText(find.byKey(const Key('restore_text')), 'just some words');
    await _tap(tester, const Key('restore_check'));
    expect(find.textContaining('does not look like a backup from this game'), findsOneWidget);
    expect(find.textContaining('Nothing was changed'), findsOneWidget);
    expect(find.byKey(const Key('restore_go')), findsNothing);

    // A backup from a newer game says to update.
    await tester.enterText(find.byKey(const Key('restore_text')), jsonEncode(newer));
    await _tap(tester, const Key('restore_check'));
    expect(find.textContaining('newer version of the game'), findsOneWidget);

    await _tap(tester, const Key('restore_cancel'));
    expect(find.text('Restore a Backup'), findsNothing);
    expect((await tester.runAsync(() => repo.watchHero().first))!.name, 'Bo');
    await shutDown(tester, db);
  });

  testWidgets('Back and Cancel at the last step leave the game as it was', (tester) async {
    _mockClipboard(tester);
    final other = await _otherPhonesBackup(tester);
    final (db, repo) = await _boot(tester);
    await _openSettings(tester);
    await _reveal(tester, const Key('restore_backup'));
    await tester.tap(find.byKey(const Key('restore_backup')));
    await settle(tester, frames: 20);
    await tester.enterText(find.byKey(const Key('restore_text')), other);
    await _tap(tester, const Key('restore_check'));
    await _tap(tester, const Key('restore_back'));
    expect(find.byKey(const Key('restore_text')), findsOneWidget);
    await _tap(tester, const Key('restore_check'));
    // The last step offers Back, not Cancel; leave through Back and then Cancel.
    await _tap(tester, const Key('restore_back'));
    await _tap(tester, const Key('restore_cancel'));
    expect(find.text('Restore a Backup'), findsNothing);
    expect((await tester.runAsync(() => repo.watchHero().first))!.name, 'Bo');
    await shutDown(tester, db);
  });

  testWidgets('a backup that checks out but cannot be stored leaves the game as it was', (tester) async {
    _mockClipboard(tester);
    final broken = jsonDecode(await _otherPhonesBackup(tester)) as Map<String, dynamic>;
    (broken['tables']['workouts'] as List).last.remove('activity_id');
    final (db, repo) = await _boot(tester);
    await _openSettings(tester);
    await _reveal(tester, const Key('restore_backup'));
    await tester.tap(find.byKey(const Key('restore_backup')));
    await settle(tester, frames: 20);
    await tester.enterText(find.byKey(const Key('restore_text')), jsonEncode(broken));
    await _tap(tester, const Key('restore_check'));
    await _tap(tester, const Key('restore_go'));
    await settle(tester, frames: 30);
    expect(find.textContaining('Your game on this phone is as it was'), findsOneWidget);
    expect((await tester.runAsync(() => repo.watchHero().first))!.name, 'Bo');
    expect((await tester.runAsync(() => repo.watchWorkouts().first))!.length, 1);
    await shutDown(tester, db);
  });

  testWidgets('the restore card fits a small phone at large text', (tester) async {
    _mockClipboard(tester);
    final other = await _otherPhonesBackup(tester);
    final (db, _) = await _boot(tester, phoneSurface: false);
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await settle(tester, frames: 10);
    await _openSettings(tester);
    await _reveal(tester, const Key('restore_backup'));
    await tester.tap(find.byKey(const Key('restore_backup')));
    await settle(tester, frames: 20);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byKey(const Key('restore_text')), other);
    await tester.ensureVisible(find.byKey(const Key('restore_check')));
    await settle(tester, frames: 3);
    await tester.tap(find.byKey(const Key('restore_check')));
    await settle(tester, frames: 15);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('restore_summary')), findsOneWidget);
    await shutDown(tester, db);
  });

  group('saving the backup to a file and bringing it back', () {
    testWidgets('where the phone cannot share files, only copy and paste are offered', (tester) async {
      _mockClipboard(tester);
      final (db, _) = await _boot(tester);
      await _openSettings(tester);
      await _reveal(tester, const Key('restore_backup'));
      expect(find.byKey(const Key('send_backup')), findsNothing);
      await tester.tap(find.byKey(const Key('restore_backup')));
      await settle(tester, frames: 20);
      expect(find.byKey(const Key('restore_file')), findsNothing);
      expect(find.textContaining('Paste a backup you copied from Settings'), findsOneWidget);
      await shutDown(tester, db);
    });

    testWidgets('Save or Send a Backup shares the whole game as a plain file named for the day', (tester) async {
      _mockClipboard(tester);
      final files = TestBackupFiles();
      final (db, repo) = await _boot(tester, files: files);
      await _openSettings(tester);
      await _reveal(tester, const Key('send_backup'));
      await tester.tap(find.byKey(const Key('send_backup')));
      await settle(tester, frames: 15);

      expect(files.sent.length, 1);
      expect(files.sent.single.fileName, 'I-Am-Chad-backup-2026-10-22.txt', reason: 'a plain text file, not a technical one');
      final backup = repo.readBackup(files.sent.single.text);
      expect(backup.rows('heroes').single['name'], 'Bo');
      await shutDown(tester, db);
    });

    testWidgets('Choose a Backup File reads it and goes straight to showing what it holds', (tester) async {
      _mockClipboard(tester);
      final other = await _otherPhonesBackup(tester);
      final files = TestBackupFiles(toChoose: other);
      final (db, repo) = await _boot(tester, files: files);
      await _openSettings(tester);
      await _reveal(tester, const Key('restore_backup'));
      await tester.tap(find.byKey(const Key('restore_backup')));
      await settle(tester, frames: 20);
      expect(find.textContaining('Choose the backup file you saved'), findsOneWidget);

      await _tap(tester, const Key('restore_file'));
      expect(files.chooseCalls, 1);
      expect(find.textContaining('A backup of Ada'), findsOneWidget);
      expect((await tester.runAsync(() => repo.watchHero().first))!.name, 'Bo', reason: 'still not restored');
      await _tap(tester, const Key('restore_go'));
      await settle(tester, frames: 40);
      expect((await tester.runAsync(() => repo.watchHero().first))!.name, 'Ada');
      await shutDown(tester, db);
    });

    testWidgets('changing their mind in the file chooser changes nothing and says nothing', (tester) async {
      _mockClipboard(tester);
      final files = TestBackupFiles(toChoose: null);
      final (db, _) = await _boot(tester, files: files);
      await _openSettings(tester);
      await _reveal(tester, const Key('restore_backup'));
      await tester.tap(find.byKey(const Key('restore_backup')));
      await settle(tester, frames: 20);
      await _tap(tester, const Key('restore_file'));
      expect(files.chooseCalls, 1);
      expect(find.byKey(const Key('restore_text')), findsOneWidget);
      expect(find.byKey(const Key('restore_problem')), findsNothing);
      await shutDown(tester, db);
    });

    testWidgets('choosing a file that is not a backup is refused kindly', (tester) async {
      _mockClipboard(tester);
      final files = TestBackupFiles(toChoose: 'Shopping list: milk, eggs');
      final (db, repo) = await _boot(tester, files: files);
      await _openSettings(tester);
      await _reveal(tester, const Key('restore_backup'));
      await tester.tap(find.byKey(const Key('restore_backup')));
      await settle(tester, frames: 20);
      await _tap(tester, const Key('restore_file'));
      expect(find.textContaining('does not look like a backup from this game'), findsOneWidget);
      expect(find.byKey(const Key('restore_go')), findsNothing);
      expect((await tester.runAsync(() => repo.watchHero().first))!.name, 'Bo');
      await shutDown(tester, db);
    });
  });
}
