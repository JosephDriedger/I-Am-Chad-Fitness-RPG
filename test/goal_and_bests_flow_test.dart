import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/rewards.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

final _now = DateTime(2026, 10, 22, 10);

Future<(AppDatabase, GameRepository)> _boot(WidgetTester tester, {List<WorkoutEntry> before = const []}) async {
  usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = GameRepository(db);
  await tester.runAsync(() async {
    await repo.createHero(const HeroProfile(
      name: 'Ada',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.returning,
      preferredCategories: {ActivityCategory.resistance},
      hasDumbbells: true,
    ));
    for (final e in before) {
      await repo.addWorkout(e);
    }
  });
  await bootApp(tester, db, now: _now);
  return (db, repo);
}

WorkoutEntry _press(int daysAgo, double kg) => WorkoutEntry(
      activityId: 'dumbbell_press',
      performedAt: DateTime(2026, 10, 22 - daysAgo, 9),
      sets: 3,
      reps: 8,
      loadKg: kg,
    );

Future<void> _logPress(WidgetTester tester, String kg) async {
  await tester.tap(find.text('Train'));
  await settle(tester, frames: 30);
  await openExercise(tester, 'Dumbbell Shoulder Press');
  await tester.enterText(find.widgetWithText(TextField, 'Sets'), '3');
  await tester.enterText(find.widgetWithText(TextField, 'Reps per Set'), '8');
  await tester.enterText(find.widgetWithText(TextField, 'Weight (Optional)'), kg);
  await tester.scrollUntilVisible(find.text('Save Workout'), 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(find.text('Save Workout'));
  await tester.pump();
  await tester.ensureVisible(find.text('Save Workout'));
  await tester.ensureVisible(find.text('Save Workout'));
  await tester.tap(find.text('Save Workout'));
  await settle(tester);
}

void main() {
  testWidgets('beating an earlier lift is celebrated, and pays nothing extra', (tester) async {
    final (db, repo) = await _boot(tester, before: [_press(3, 10)]);

    await _logPress(tester, '12.5');
    expect(find.text('Workout Saved!'), findsOneWidget);
    expect(find.text('New Personal Best!'), findsOneWidget);
    // Named in the dialog, and now also among the marks on the log screen behind it.
    expect(find.text('Heaviest: 12.5 kg × 8'), findsWidgets);
    // 3 sets of 8 is the same effort whatever the weight (REWARD_RULES).
    final after = await tester.runAsync(() => repo.rewardForDay(_now));
    expect(after!.xp, RewardRules.v1.rewardForDay([_press(0, 99)]).xp);

    await shutDown(tester, db);
  });

  testWidgets('a lighter lift, or the very first one, is not called a record', (tester) async {
    final (db, _) = await _boot(tester, before: [_press(3, 20)]);
    await _logPress(tester, '15');
    expect(find.text('Workout Saved!'), findsOneWidget);
    expect(find.text('New Personal Best!'), findsNothing);
    await shutDown(tester, db);

    final (db2, _) = await _boot(tester);
    await _logPress(tester, '15');
    expect(find.text('Workout Saved!'), findsOneWidget);
    expect(find.text('New Personal Best!'), findsNothing);
    await shutDown(tester, db2);
  });

  testWidgets('the journal lists personal bests and says they change nothing', (tester) async {
    final (db, _) = await _boot(tester, before: [_press(3, 10), _press(1, 14)]);
    await tester.tap(find.text('Journal'));
    await settle(tester, frames: 30);
    await tester.scrollUntilVisible(find.text('Personal Bests'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Personal Bests'), findsOneWidget);
    expect(find.text('Dumbbell Shoulder Press: Heaviest'), findsOneWidget);
    expect(find.text('14 kg × 8'), findsOneWidget);
    expect(find.textContaining('never change what you earn'), findsOneWidget);
    await shutDown(tester, db);
  });

  Future<void> openBest(WidgetTester tester, String key) async {
    await tester.tap(find.text('Journal'));
    await settle(tester, frames: 30);
    await tester.scrollUntilVisible(find.byKey(Key(key)), 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.byKey(Key(key)));
    await settle(tester, frames: 2);
    await tester.tap(find.byKey(Key(key)));
    await settle(tester, frames: 20);
  }

  testWidgets('tapping a personal best shows how it has moved, and a lighter day is just shown', (tester) async {
    final (db, _) = await _boot(tester, before: [_press(10, 10), _press(6, 12), _press(3, 14), _press(1, 13)]);
    await openBest(tester, 'best_dumbbell_press_heaviest');

    expect(find.text('Your Progress'), findsOneWidget);
    expect(find.text('Dumbbell Shoulder Press: Heaviest'), findsWidgets);
    expect(find.byKey(const Key('progress_chart')), findsOneWidget);
    expect(find.text('10 kg × 8 (Oct 12)'), findsOneWidget, reason: 'the first day');
    expect(find.text('13 kg × 8 (Oct 21)'), findsOneWidget, reason: 'the latest day, lighter than the best');
    expect(find.text('14 kg × 8 (Oct 19)'), findsOneWidget, reason: 'the best day');
    expect(find.textContaining('A line wobbles, and that is normal'), findsOneWidget);
    expect(find.textContaining('never changes what you earn'), findsOneWidget);
    // Nothing that compares, grades or pushes.
    for (final word in ['behind', 'target', 'goal', 'improve', 'should', 'beat', 'drop']) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }

    await tester.tap(find.byKey(const Key('progress_close')));
    await settle(tester, frames: 20);
    expect(find.text('Your Progress'), findsNothing);
    await shutDown(tester, db);
  });

  testWidgets('one day is not a line yet, and says so kindly', (tester) async {
    final (db, _) = await _boot(tester, before: [_press(2, 12)]);
    await openBest(tester, 'best_dumbbell_press_heaviest');
    expect(find.byKey(const Key('progress_chart')), findsNothing);
    expect(find.byKey(const Key('progress_empty')), findsOneWidget);
    expect(find.textContaining('Do it again and a line will start to appear'), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('the progress card fits a small phone at large text', (tester) async {
    final (db, _) = await _boot(tester, before: [_press(10, 10), _press(6, 12), _press(3, 14), _press(1, 13)]);
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await settle(tester, frames: 10);
    await openBest(tester, 'best_dumbbell_press_heaviest');
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('progress_chart')), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('the weekly goal can be changed on the quest board and goes back to the suggestion', (tester) async {
    final (db, repo) = await _boot(tester);
    await tester.tap(find.text('Quests'));
    await settle(tester, frames: 30);
    await tester.scrollUntilVisible(find.text('My goal, in days a week'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('Move on 3 days this week'), findsOneWidget);
    expect(find.textContaining('Chad suggests 3 for you'), findsOneWidget);

    await _bringIntoView(tester, find.byKey(const Key('goal_5')));
    await tester.tap(find.byKey(const Key('goal_5')));
    await settle(tester, frames: 20);
    expect(find.textContaining('Move on 5 days this week'), findsOneWidget);
    expect(find.textContaining('Your own goal'), findsOneWidget);
    expect((await tester.runAsync(() => repo.watchHero().first))!.weeklyGoalDays, 5);

    // Tapping the suggested number hands the choice back.
    await _bringIntoView(tester, find.byKey(const Key('goal_3')));
    await tester.tap(find.byKey(const Key('goal_3')));
    await settle(tester, frames: 20);
    expect(find.textContaining('Move on 3 days this week'), findsOneWidget);
    expect((await tester.runAsync(() => repo.watchHero().first))!.weeklyGoalDays, 0);

    await shutDown(tester, db);
  });
}

/// Scrolls the list until [target] is inside the screen, not merely built.
Future<void> _bringIntoView(WidgetTester tester, Finder target) async {
  final height = tester.view.physicalSize.height / tester.view.devicePixelRatio;
  for (var i = 0; i < 10 && tester.getCenter(target).dy > height - 80; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await settle(tester, frames: 5);
  }
}
