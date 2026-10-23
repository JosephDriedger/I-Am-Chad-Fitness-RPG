import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

final _now = DateTime(2026, 10, 22, 10);

WorkoutEntry _on(int daysAgo) => WorkoutEntry(
      activityId: 'walking',
      performedAt: DateTime(2026, 10, 22 - daysAgo, 18),
      durationSeconds: 600,
    );

Future<(AppDatabase, GameRepository)> _boot(WidgetTester tester, List<int> before) async {
  usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = GameRepository(db);
  await tester.runAsync(() async {
    await repo.createHero(const HeroProfile(
      name: 'Ada',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.returning,
      preferredCategories: {ActivityCategory.cardio},
      hasDumbbells: false,
    ));
    for (final d in before) {
      await repo.addWorkout(_on(d));
    }
  });
  await bootApp(tester, db, now: _now);
  return (db, repo);
}

Future<void> _logWalk(WidgetTester tester) async {
  await tester.tap(find.text('Train'));
  await settle(tester, frames: 30);
  await openExercise(tester, 'Walking');
  await tester.enterText(find.widgetWithText(TextField, 'Minutes'), '10');
  await tester.scrollUntilVisible(find.text('Save Workout'), 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(find.text('Save Workout'));
  await tester.tap(find.text('Save Workout'));
  await settle(tester);
}

void main() {
  testWidgets('reaching three days in a row pays a streak reward once', (tester) async {
    final (db, repo) = await _boot(tester, [1, 2]);

    await _logWalk(tester);
    expect(find.text('Workout Saved!'), findsOneWidget);
    expect(find.text('Streak Reward!'), findsOneWidget);
    expect(find.textContaining('Getting Started: 3 active days in a row'), findsOneWidget);
    expect(find.text('+15 Coins'), findsOneWidget);
    expect(find.text('+20 XP'), findsOneWidget);

    final hero = (await tester.runAsync(() => repo.watchHero().first))!;
    expect(hero.coins, 15);
    expect(hero.streakXp, 20);

    await tester.tap(find.text('Nice'));
    await settle(tester, frames: 30);

    // Logging again the same day pays nothing more, and says where it stands.
    await _logWalk(tester);
    expect(find.text('Streak Reward!'), findsNothing);
    expect(find.textContaining('3 active days in a row'), findsOneWidget);
    expect((await tester.runAsync(() => repo.watchHero().first))!.coins, 15);

    await shutDown(tester, db);
  });

  testWidgets('no reward before a milestone, just a quiet note about the streak', (tester) async {
    final (db, repo) = await _boot(tester, [1]);
    await _logWalk(tester);
    expect(find.text('Streak Reward!'), findsNothing);
    expect(find.textContaining('2 active days in a row'), findsOneWidget);
    expect(find.textContaining('Next reward at 3'), findsOneWidget);
    expect((await tester.runAsync(() => repo.watchHero().first))!.coins, 0);
    await shutDown(tester, db);
  });

  testWidgets('the streak shows on the hall HUD and on the quest board', (tester) async {
    final semantics = tester.ensureSemantics();
    final (db, repo) = await _boot(tester, [0, 1, 2]);
    expect(find.bySemanticsLabel('Streak: 3 active days in a row'), findsOneWidget);

    await tester.tap(find.text('Quests'));
    await settle(tester, frames: 30);
    await tester.scrollUntilVisible(find.text('Streak'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Streak'), findsOneWidget);
    expect(find.text('active days in a row'), findsOneWidget);
    expect(find.text('Best 3'), findsOneWidget);
    expect(find.textContaining('Next: On a Roll, at 5 days'), findsOneWidget);
    expect(find.textContaining('Rest days are built in'), findsOneWidget);
    expect(find.textContaining('lose'), findsNothing);
    expect(find.textContaining('break your'), findsNothing);

    semantics.dispose();
    await shutDown(tester, db);
  });

  testWidgets('after a long break, it is a fresh start and nothing is lost', (tester) async {
    final (db, repo) = await _boot(tester, [30, 31, 32, 33, 34]);
    // A claimed milestone from the earlier run stays claimed.
    await tester.runAsync(() => repo.claimStreakRewards(today: DateTime(2026, 9, 22, 12)));
    final before = (await tester.runAsync(() => repo.watchHero().first))!;
    expect(before.coins, greaterThan(0));

    expect(find.bySemanticsLabel(RegExp('Streak:')), findsNothing);
    await _logWalk(tester);
    expect(find.text('Streak Reward!'), findsNothing);
    final after = (await tester.runAsync(() => repo.watchHero().first))!;
    expect(after.coins, before.coins);
    expect(after.streakXp, before.streakXp);

    await shutDown(tester, db);
  });
}
