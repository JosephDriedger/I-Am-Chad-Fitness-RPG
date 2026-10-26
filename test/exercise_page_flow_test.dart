import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

final _now = DateTime(2026, 10, 22, 10);

WorkoutEntry _squat(int d, {double? kg}) =>
    WorkoutEntry(activityId: 'squat', performedAt: DateTime(2026, 10, d, 9), sets: 3, reps: 8, loadKg: kg);

const _hero = HeroProfile(
  name: 'Ada',
  appearanceStyle: 0,
  appearanceColor: 0,
  experience: ExperienceLevel.returning,
  preferredCategories: {},
  hasDumbbells: false,
);

Future<AppDatabase> _boot(WidgetTester tester, List<WorkoutEntry> entries) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await tester.runAsync(() async {
    final repo = GameRepository(db);
    await repo.createHero(_hero);
    for (final e in entries) {
      await repo.addWorkout(e);
    }
  });
  await bootApp(tester, db, now: _now);
  await tester.tap(find.text('Journal'));
  await settle(tester, frames: 30);
  return db;
}

Future<void> _open(WidgetTester tester) async {
  final tile = find.byKey(const Key('exercise_squat'));
  await tester.scrollUntilVisible(tile, 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(tile);
  await settle(tester, frames: 5);
  await tester.tap(tile);
  await settle(tester, frames: 30);
}

void main() {
  testWidgets('the Journal lists exercises, and one opens to its own story', (tester) async {
    usePhone(tester);
    final db = await _boot(tester, [_squat(6, kg: 40), _squat(13, kg: 45), _squat(20, kg: 50)]);
    await tester.scrollUntilVisible(find.text('Your Exercises'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Your Exercises'), findsOneWidget);
    await _open(tester);

    expect(find.text('The Story So Far'), findsOneWidget);
    expect(find.text('3 Days'), findsOneWidget);
    expect(find.byKey(const Key('exercise_weeks')), findsOneWidget);
    // Weight was logged, so the total lifted is shown.
    expect(find.byKey(const Key('exercise_lifted')), findsOneWidget);
    expect(find.textContaining('weight × reps × sets'), findsOneWidget);

    // A mark opens the same progress line as in the Journal.
    await tester.scrollUntilVisible(find.byKey(const Key('exercise_mark_heaviest')), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('exercise_mark_heaviest')));
    await settle(tester, frames: 20);
    expect(find.text('Your Progress'), findsOneWidget);
    await tester.tap(find.byKey(const Key('progress_close')));
    await settle(tester, frames: 20);

    await tester.scrollUntilVisible(find.textContaining('never changes what you earn'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('never changes what you earn'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await shutDown(tester, db);
  });

  testWidgets('without a weight there is no total lifted, and nothing is shown as missed', (tester) async {
    usePhone(tester);
    final db = await _boot(tester, [_squat(20)]);
    await _open(tester);
    expect(find.text('1 Day'), findsOneWidget);
    expect(find.byKey(const Key('exercise_lifted')), findsNothing);
    final all = find.byType(Text).evaluate().map((e) => (e.widget as Text).data ?? '').join(' ').toLowerCase();
    for (final w in ['missed', 'streak', 'behind', 'lazy']) {
      expect(all, isNot(contains(w)), reason: w);
    }
    await shutDown(tester, db);
  });

  testWidgets('deleting the only entry from its page leaves the empty story, not a crash', (tester) async {
    usePhone(tester);
    final db = await _boot(tester, [_squat(20)]);
    await _open(tester);
    await tester.runAsync(() async {
      final repo = GameRepository(db);
      final all = await repo.watchWorkouts().first;
      await repo.deleteWorkout(all.single.id!);
    });
    await settle(tester, frames: 20);
    expect(find.byKey(const Key('exercise_empty')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await shutDown(tester, db);
  });

  testWidgets('the page fits on the smallest phone with the largest text', (tester) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = await _boot(tester, [for (final d in [6, 13, 20]) _squat(d, kg: 40)]);
    await _open(tester);
    expect(find.text('The Story So Far'), findsOneWidget, reason: 'the page opened');
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await settle(tester, frames: 3);
      expect(tester.takeException(), isNull);
    }
    await shutDown(tester, db);
  });
}
