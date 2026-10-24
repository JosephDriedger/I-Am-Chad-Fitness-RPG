import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/quests.dart';
import 'package:i_am_chad/domain/workout.dart';

const _hero = HeroProfile(
  name: 'Tester',
  appearanceStyle: 0,
  appearanceColor: 0,
  experience: ExperienceLevel.returning,
  preferredCategories: {ActivityCategory.cardio},
  hasDumbbells: false,
);

void main() {
  late AppDatabase db;
  late GameRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = GameRepository(db);
    await repo.createHero(_hero);
  });
  tearDown(() => db.close());

  Future<HeroProfile> hero() async => (await repo.watchHero().first)!;

  test('until the player chooses, the suggestion for their experience applies', () async {
    expect((await hero()).weeklyGoalDays, 0);
    expect((await hero()).weeklyGoalTarget, ExperienceLevel.returning.weeklyDaysGoal);
  });

  test('a chosen goal is kept, and zero goes back to the suggestion', () async {
    await repo.setWeeklyGoalDays(5);
    expect((await hero()).weeklyGoalTarget, 5);
    await repo.setWeeklyGoalDays(0);
    expect((await hero()).weeklyGoalTarget, ExperienceLevel.returning.weeklyDaysGoal);
  });

  test('goals outside one to seven days are ignored', () async {
    await repo.setWeeklyGoalDays(4);
    await repo.setWeeklyGoalDays(8);
    await repo.setWeeklyGoalDays(-1);
    expect((await hero()).weeklyGoalTarget, 4);
  });

  test('changing the experience level does not lose a chosen goal', () async {
    await repo.setWeeklyGoalDays(6);
    // The hero row is the same one; only the goal column decides the target.
    expect((await hero()).copyWith(experience: ExperienceLevel.starting).weeklyGoalTarget, 6);
  });

  test('the goal is part of the export', () async {
    await repo.setWeeklyGoalDays(3);
    final data = jsonDecode(await repo.exportJson()) as Map<String, dynamic>;
    expect((data['hero'] as Map)['weeklyGoalDays'], 3);
  });

  test('the weekly count uses the chosen target', () {
    final entries = [
      WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 19, 9), durationSeconds: 600),
      WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 20, 9), durationSeconds: 600),
    ];
    final now = DateTime(2026, 10, 22, 12);
    final suggested = QuestBoard.weeklyGoal(level: ExperienceLevel.returning, now: now, entries: entries);
    expect((suggested.target, suggested.met), (3, false));
    final own = QuestBoard.weeklyGoal(level: ExperienceLevel.returning, now: now, entries: entries, target: 2);
    expect((own.target, own.met), (2, true));
  });
}
