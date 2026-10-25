import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/backup_files.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/data/workout_csv.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

final _now = DateTime(2026, 10, 22, 10);

Future<AppDatabase> _boot(WidgetTester tester, {BackupFiles? files}) async {
  usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await tester.runAsync(() async {
    final repo = GameRepository(db);
    await repo.createHero(const HeroProfile(
      name: 'Bo',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.returning,
      preferredCategories: {},
      hasDumbbells: false,
    ));
    await repo.addWorkout(WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 20, 9), durationSeconds: 1200, notes: 'Sunny, slow'));
    await repo.addWorkout(WorkoutEntry(activityId: 'dumbbell_press', performedAt: DateTime(2026, 10, 19, 9), sets: 3, reps: 8, loadKg: 10));
  });
  await bootApp(tester, db, now: _now, overrides: [if (files != null) backupFilesProvider.overrideWithValue(files)]);
  await tester.tap(find.byTooltip('Settings'));
  await settle(tester, frames: 30);
  final button = find.byKey(const Key('workouts_csv'));
  await tester.scrollUntilVisible(button, 250, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(button);
  await settle(tester, frames: 3);
  return db;
}

void main() {
  testWidgets('where the phone can share, the spreadsheet goes to the share sheet as a CSV file', (tester) async {
    final files = TestBackupFiles();
    final db = await _boot(tester, files: files);
    await tester.tap(find.byKey(const Key('workouts_csv')));
    await settle(tester, frames: 15);
    expect(files.sent, hasLength(1));
    final sent = files.sent.single;
    expect(sent.fileName, 'I-Am-Chad-workouts-2026-10-22.csv');
    expect(sent.mimeType, 'text/csv');
    expect(sent.text.startsWith('﻿${WorkoutCsv.columns.join(',')}'), isTrue);
    expect(sent.text, contains('Dumbbell'));
    expect(sent.text, contains('"Sunny, slow"'));
    await shutDown(tester, db);
  });

  testWidgets('where it cannot, the same file is copied and the player is told it is not a backup', (tester) async {
    String? clip;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clip = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final db = await _boot(tester);
    await tester.tap(find.byKey(const Key('workouts_csv')));
    await settle(tester, frames: 10);
    expect(clip, isNotNull);
    expect(clip!.split('\r\n').length, 4, reason: 'headings, two workouts and the end');
    expect(find.textContaining('not a backup you can restore'), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('Settings says what the file is for, and the backup buttons are still there', (tester) async {
    final db = await _boot(tester);
    expect(find.textContaining('that file is only for looking at'), findsOneWidget);
    expect(find.byKey(const Key('copy_backup')), findsOneWidget);
    expect(find.byKey(const Key('restore_backup')), findsOneWidget);
    await shutDown(tester, db);
  });
}
