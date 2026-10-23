import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/quests.dart';
import 'package:i_am_chad/domain/rewards.dart';
import 'package:i_am_chad/domain/streaks.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

final _now = DateTime(2026, 10, 22, 10);

/// A workout performed at [performed] and logged at [logged].
WorkoutEntry _w(DateTime performed, DateTime? logged, {int seconds = 600}) => WorkoutEntry(
      activityId: 'walking',
      performedAt: performed,
      durationSeconds: seconds,
      loggedAt: logged,
    );

void main() {
  group('which workouts earn rewards', () {
    test('logging a workout when you do it counts', () {
      expect(_w(_now, _now).countsForRewards, isTrue);
      expect(_w(_now.subtract(const Duration(hours: 2)), _now).countsForRewards, isTrue);
    });

    test('a workout logged later the same day still counts', () {
      final morning = DateTime(2026, 10, 22, 6);
      final night = DateTime(2026, 10, 22, 22);
      expect(_w(morning, night).countsForRewards, isTrue);
    });

    test('a late-night workout logged just after midnight still counts', () {
      final late = DateTime(2026, 10, 21, 23, 30);
      final after = DateTime(2026, 10, 22, 0, 40);
      expect(_w(late, after).countsForRewards, isTrue);
      // Up to six hours later, across midnight, is still fine.
      expect(_w(late, DateTime(2026, 10, 22, 5, 30)).countsForRewards, isTrue);
    });

    test('anything from an earlier day, beyond the grace window, does not', () {
      expect(_w(DateTime(2026, 10, 21, 18), _now).countsForRewards, isFalse);
      expect(_w(DateTime(2026, 10, 21, 23, 30), DateTime(2026, 10, 22, 7)).countsForRewards, isFalse);
      expect(_w(DateTime(2026, 9, 1, 12), _now).countsForRewards, isFalse);
    });

    test('a workout dated in the future never counts', () {
      expect(_w(_now.add(const Duration(days: 1)), _now).countsForRewards, isFalse);
      expect(_w(_now.add(const Duration(hours: 3)), _now).countsForRewards, isFalse);
      // A few minutes of clock slop is fine.
      expect(_w(_now.add(const Duration(minutes: 5)), _now).countsForRewards, isTrue);
    });

    test('entries from before logging times were kept count as before', () {
      expect(_w(DateTime(2026, 1, 1), null).countsForRewards, isTrue);
    });
  });

  group('where the rule applies', () {
    final backDated = _w(DateTime(2026, 10, 20, 18), _now);
    final real = _w(_now, _now);

    test('XP and energy', () {
      const rules = RewardRules.v1;
      expect(rules.rewardForDay([backDated]).xp, 0);
      expect(rules.rewardForDay([backDated]).energy, 0);
      expect(rules.rewardForDay([real]).xp, 40);
      // A back-dated entry on the same day adds nothing to a real one.
      expect(rules.rewardForDay([real, backDated]).xp, 40);
    });

    test('the streak', () {
      final s = StreakRules.evaluate(
        workouts: [real, _w(DateTime(2026, 10, 21, 18), _now), _w(DateTime(2026, 10, 20, 18), _now)],
        today: _now,
        experience: ExperienceLevel.returning,
      );
      expect(s.current, 1, reason: 'only today was logged on the day');
    });

    test('the weekly goal and the week tokens', () {
      final entries = [real, backDated, _w(DateTime(2026, 10, 19, 18), _now)];
      final goal = QuestBoard.weeklyGoal(level: ExperienceLevel.returning, now: _now, entries: entries);
      expect(goal.daysActive, 1);
      expect(QuestBoard.activeWeekdays(now: _now, entries: entries), {_now.weekday});
    });

    test('a quest is only done by a workout that counts', () {
      final quest = QuestBoard.dailySuggestions(
        level: ExperienceLevel.returning,
        day: _now,
        preferred: const {},
        hasDumbbells: false,
        count: 4,
      ).first;
      final mine = WorkoutEntry(
        activityId: quest.activityId,
        performedAt: DateTime(2026, 10, 21, 12),
        durationSeconds: 600,
        loggedAt: _now,
      );
      expect(quest.isDoneBy([mine]), isFalse);
      expect(quest.isDoneBy([mine.copyWith(performedAt: _now)]), isTrue);
    });
  });

  group('in the saved data', () {
    late AppDatabase db;
    late GameRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = GameRepository(db);
      await repo.createHero(const HeroProfile(
        name: 'Tester',
        appearanceStyle: 0,
        appearanceColor: 0,
        experience: ExperienceLevel.returning,
        preferredCategories: {},
        hasDumbbells: false,
      ));
    });
    tearDown(() => db.close());

    test('a back-dated workout is kept in the journal and pays nothing', () async {
      await repo.addWorkout(_w(DateTime(2026, 10, 15, 18), _now));
      expect(await repo.watchWorkouts().first, hasLength(1));
      expect(await repo.watchGrants().first, isEmpty);
      expect((await repo.rewardForDay(DateTime(2026, 10, 15))).xp, 0);
    });

    test('a real workout and a back-dated one on the same day pay for the real one', () async {
      await repo.addWorkout(_w(DateTime(2026, 10, 22, 7), DateTime(2026, 10, 22, 7, 5)));
      await repo.addWorkout(_w(DateTime(2026, 10, 15, 18), _now));
      final grants = await repo.watchGrants().first;
      expect(grants, hasLength(1));
      expect(grants.single.xp, 40);
    });

    test('back-dating cannot farm streak rewards', () async {
      for (final d in [20, 21, 22]) {
        await repo.addWorkout(_w(DateTime(2026, 10, d, 12), _now));
      }
      // Only the one logged on the day counts toward the streak.
      expect(await repo.claimStreakRewards(today: _now), isEmpty);
      final hero = (await repo.watchHero().first)!;
      expect(hero.coins, 0);
      expect(hero.streakXp, 0);
    });

    test('editing a workout cannot make it count by changing its day', () async {
      final id = await repo.addWorkout(_w(_now, _now));
      expect((await repo.watchGrants().first).single.xp, 40);

      // Moved to an earlier day: now back-dated, and the reward goes.
      final saved = (await repo.watchWorkouts().first).single;
      await repo.updateWorkout(saved.copyWith(performedAt: DateTime(2026, 10, 18, 12)));
      expect(await repo.watchGrants().first, isEmpty);

      // Moving it back does not need a new log: it was logged today after all.
      await repo.updateWorkout(saved.copyWith(id: id, performedAt: _now));
      expect((await repo.watchGrants().first).single.xp, 40);
    });

    test('the time something was logged never changes when it is edited', () async {
      await repo.addWorkout(_w(_now, _now));
      final saved = (await repo.watchWorkouts().first).single;
      await repo.updateWorkout(saved.copyWith(loggedAt: DateTime(2030, 1, 1), durationSeconds: 900));
      final after = (await repo.watchWorkouts().first).single;
      expect(after.loggedAt, saved.loggedAt);
      expect(after.durationSeconds, 900);
    });

    test('older entries from before logging times were kept keep their rewards when edited', () async {
      await repo.addWorkout(_w(DateTime(2026, 9, 1, 12), null));
      expect((await repo.watchGrants().first).single.xp, 40);
      final saved = (await repo.watchWorkouts().first).single;
      await repo.updateWorkout(saved.copyWith(durationSeconds: 1200));
      expect((await repo.watchGrants().first).single.xp, 80);
      // But moving one to another day is a back-date like any other.
      await repo.updateWorkout(saved.copyWith(performedAt: DateTime(2026, 8, 20, 12)));
      expect(await repo.watchGrants().first, isEmpty);
    });

    test('the export says which entries earned rewards', () async {
      await repo.addWorkout(_w(DateTime(2026, 10, 15, 18), _now));
      final json = await repo.exportJson();
      expect(json, contains('"countsForRewards": false'));
      expect(json, contains('"loggedAt"'));
    });
  });

  group('on the log screen', () {
    testWidgets('picking an earlier day warns, saves to the journal and pays nothing', (tester) async {
      usePhone(tester);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = GameRepository(db);
      await tester.runAsync(() => repo.createHero(const HeroProfile(
            name: 'Ada',
            appearanceStyle: 0,
            appearanceColor: 0,
            experience: ExperienceLevel.returning,
            preferredCategories: {ActivityCategory.cardio},
            hasDumbbells: false,
          )));
      await bootApp(tester, db, now: _now);

      await tester.tap(find.text('Train'));
      await settle(tester, frames: 30);
      await openExercise(tester, 'Walking');
      await tester.enterText(find.widgetWithText(TextField, 'Minutes'), '10');
      await tester.scrollUntilVisible(find.text('When'), 300, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.text('When'));
      await settle(tester, frames: 4);

      // Today: nothing to warn about.
      expect(find.textContaining('Back-dated'), findsNothing);

      // Pick the 15th, keep the time.
      await tester.tap(find.text('When'));
      await settle(tester);
      await tester.tap(find.text('15'));
      await settle(tester);
      await tester.tap(find.text('OK'));
      await settle(tester);
      await tester.tap(find.text('OK'));
      await settle(tester);

      expect(find.textContaining('Back-dated: this goes in your journal but earns no rewards'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Save Workout'), 300, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.text('Save Workout'));
      await tester.tap(find.text('Save Workout'));
      await settle(tester);

      expect(find.text('Saved to Your Journal'), findsOneWidget);
      expect(find.text('Workout Saved!'), findsNothing);
      expect(find.textContaining('earns no rewards'), findsWidgets);
      expect(find.text('40 XP'), findsNothing);

      final workouts = await tester.runAsync(() => repo.watchWorkouts().first);
      expect(workouts, hasLength(1));
      expect(workouts!.single.performedAt.day, 15);
      expect(workouts.single.countsForRewards, isFalse);
      expect(await tester.runAsync(() => repo.watchGrants().first), isEmpty);

      await tester.tap(find.text('Got It'));
      await settle(tester, frames: 20);

      // It shows in the journal, marked.
      await tester.pageBack(); // back from the Train list to the hall
      await settle(tester, frames: 20);
      await tester.tap(find.text('Journal'));
      await settle(tester, frames: 30);
      expect(find.textContaining('Journal Only'), findsOneWidget);

      await shutDown(tester, db);
    });
  });
}
