import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

final _now = DateTime(2026, 10, 22, 10);

WorkoutEntry _walk(int month, int day) =>
    WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, month, day, 9), durationSeconds: 600);

/// Two walks a week for the four weeks before this one.
List<WorkoutEntry> _twoADay() => [
      for (final monday in [DateTime(2026, 10, 12), DateTime(2026, 10, 5), DateTime(2026, 9, 28), DateTime(2026, 9, 21)]) ...[
        _walk(monday.month, monday.day),
        _walk(monday.month, monday.day + 2),
      ],
    ];

Future<AppDatabase> _boot(WidgetTester tester, List<WorkoutEntry> entries, {int goal = 0}) async {
  usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await tester.runAsync(() async {
    final repo = GameRepository(db);
    await repo.createHero(const HeroProfile(
      name: 'Ada',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.regular,
      preferredCategories: {},
      hasDumbbells: false,
    ));
    for (final e in entries) {
      await repo.addWorkout(e);
    }
    if (goal > 0) await repo.setWeeklyGoalDays(goal);
  });
  await bootApp(tester, db, now: _now);
  await tester.tap(find.text('Quests'));
  await settle(tester, frames: 30);
  await tester.scrollUntilVisible(find.text('My goal, in days a week'), 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(find.text('My goal, in days a week'));
  await settle(tester, frames: 5);
  return db;
}

bool _selected(WidgetTester tester, int d) => tester.widget<ChoiceChip>(find.byKey(Key('goal_$d'))).selected;

void main() {
  testWidgets('with a few weeks of history, the suggested goal is the player\'s own usual week', (tester) async {
    final db = await _boot(tester, _twoADay());
    expect(_selected(tester, 2), isTrue, reason: 'a regular who has been moving twice a week is not handed a four');
    expect(_selected(tester, 4), isFalse);
    expect(find.textContaining('about what you have been doing lately'), findsOneWidget);
    expect(find.textContaining('Move on 2 days this week'), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('with no history, it is the suggestion for their experience and says nothing about the past', (tester) async {
    final db = await _boot(tester, const []);
    expect(_selected(tester, ExperienceLevel.regular.weeklyDaysGoal), isTrue);
    expect(find.textContaining('lately'), findsNothing);
    await shutDown(tester, db);
  });

  testWidgets('a goal the player picked is never replaced by the suggestion', (tester) async {
    final db = await _boot(tester, _twoADay(), goal: 5);
    expect(_selected(tester, 5), isTrue);
    expect(find.textContaining('Your own goal'), findsOneWidget);
    // Tapping the suggestion goes back to it.
    await tester.tap(find.byKey(const Key('goal_2')));
    await settle(tester, frames: 15);
    expect(_selected(tester, 2), isTrue);
    expect(find.textContaining('about what you have been doing lately'), findsOneWidget);
    await shutDown(tester, db);
  });
}
