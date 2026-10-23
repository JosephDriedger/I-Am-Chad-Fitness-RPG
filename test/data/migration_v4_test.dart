import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/workout.dart';

void main() {
  test('v3 saves upgrade to v4 and keep every workout', () async {
    // A database exactly as schema version 3 shipped (no camera_counted).
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
        CREATE TABLE reward_grants (
          day TEXT NOT NULL PRIMARY KEY,
          effort_minutes REAL NOT NULL,
          credited_minutes REAL NOT NULL,
          xp INTEGER NOT NULL,
          energy INTEGER NOT NULL,
          rules_version INTEGER NOT NULL
        );
        INSERT INTO workouts (activity_id, performed_at, sets, reps)
          VALUES ('push_up', 1790000000, 3, 10);
        INSERT INTO workouts (activity_id, performed_at, duration_seconds)
          VALUES ('walking', 1790003600, 600);
        PRAGMA user_version = 3;
      ''');
    }));
    addTearDown(db.close);
    final repo = GameRepository(db);

    final old = await repo.watchWorkouts().first;
    expect(old, hasLength(2));
    expect(old.map((w) => w.cameraCounted), everyElement(isFalse));
    expect(old.map((w) => w.activityId), containsAll(['push_up', 'walking']));
    expect(old.firstWhere((w) => w.activityId == 'push_up').reps, 10);

    // And the new flag round-trips.
    await repo.addWorkout(WorkoutEntry(
      activityId: 'squat',
      performedAt: DateTime(2026, 10, 22, 10),
      sets: 2,
      reps: 12,
      cameraCounted: true,
    ));
    final all = await repo.watchWorkouts().first;
    expect(all.where((w) => w.cameraCounted).single.activityId, 'squat');
  });

  test('the flag survives an edit and appears in the export', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = GameRepository(db);
    await repo.addWorkout(WorkoutEntry(
      activityId: 'push_up',
      performedAt: DateTime(2026, 10, 22, 10),
      sets: 1,
      reps: 8,
      cameraCounted: true,
    ));
    final saved = (await repo.watchWorkouts().first).single;
    await repo.updateWorkout(saved.copyWith(reps: 9, cameraCounted: false));
    expect((await repo.watchWorkouts().first).single.cameraCounted, isFalse);
    expect(await repo.exportJson(), contains('"cameraCounted"'));
  });
}
