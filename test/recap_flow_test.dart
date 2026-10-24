import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

// Wednesday 21 Oct 2026: last week was Monday 12 to Sunday 18.
final _now = DateTime(2026, 10, 21, 10);

Future<AppDatabase> _openQuests(WidgetTester tester, List<DateTime> days, {int goal = 3}) async {
  usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await tester.runAsync(() async {
    final repo = GameRepository(db);
    await repo.createHero(const HeroProfile(
      name: 'Ada',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.starting,
      preferredCategories: {},
      hasDumbbells: false,
    ));
    await repo.setWeeklyGoalDays(goal);
    for (final d in days) {
      await repo.addWorkout(WorkoutEntry(activityId: 'walking', performedAt: d, durationSeconds: 600));
    }
  });
  await bootApp(tester, db, now: _now);
  await tester.tap(find.text('Quests'));
  await settle(tester, frames: 30);
  return db;
}

Future<void> _reveal(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 250, scrollable: find.byType(Scrollable).first);
}

void main() {
  testWidgets('after a week with some movement, the board looks back on it kindly', (tester) async {
    final db = await _openQuests(tester, [
      DateTime(2026, 10, 12, 8),
      DateTime(2026, 10, 14, 8),
      DateTime(2026, 10, 16, 8),
    ]);
    await _reveal(tester, find.byKey(const Key('recap_panel')));
    expect(find.text('Last Week'), findsOneWidget);
    expect(find.text('3 of 3 Days'), findsOneWidget);
    expect(find.text('30 Effort Min'), findsOneWidget);
    expect(find.text('Most Logged: Walking'), findsOneWidget);
    expect(find.textContaining('goal'), findsWidgets);
    await shutDown(tester, db);
  });

  testWidgets('a quiet week is called a rest week, with no numbers to worry about', (tester) async {
    final db = await _openQuests(tester, [DateTime(2026, 10, 5, 8)]);
    await _reveal(tester, find.byKey(const Key('recap_panel')));
    expect(find.textContaining('rest', findRichText: true), findsWidgets);
    expect(find.textContaining('Effort Min'), findsNothing);
    expect(find.textContaining('Days'), findsNothing, reason: 'no day count in a quiet week');
    await shutDown(tester, db);
  });

  testWidgets('someone with nothing from before this week sees no recap at all', (tester) async {
    final db = await _openQuests(tester, [DateTime(2026, 10, 20, 8)]);
    await tester.scrollUntilVisible(find.text('Self-Directed Adventures'), 250, scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('recap_panel')), findsNothing);
    await shutDown(tester, db);
  });

  testWidgets('the recap fits on the smallest phone with the largest text', (tester) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.runAsync(() async {
      final repo = GameRepository(db);
      await repo.createHero(const HeroProfile(
        name: 'Ada the Very Long Named',
        appearanceStyle: 0,
        appearanceColor: 0,
        experience: ExperienceLevel.starting,
        preferredCategories: {},
        hasDumbbells: false,
      ));
      for (final d in [DateTime(2026, 10, 12, 8), DateTime(2026, 10, 13, 8), DateTime(2026, 10, 15, 8), DateTime(2026, 10, 17, 8)]) {
        await repo.addWorkout(WorkoutEntry(activityId: 'dumbbell_shoulder_press', performedAt: d, durationSeconds: 600));
      }
    });
    await bootApp(tester, db, now: _now);
    await tester.tap(find.text('Quests'));
    await settle(tester, frames: 30);
    await _reveal(tester, find.byKey(const Key('recap_panel')));
    expect(tester.takeException(), isNull);
    await shutDown(tester, db);
  });
}
