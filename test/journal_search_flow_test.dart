import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

final _now = DateTime(2026, 10, 22, 10);

const _hero = HeroProfile(
  name: 'Ada',
  appearanceStyle: 0,
  appearanceColor: 0,
  experience: ExperienceLevel.returning,
  preferredCategories: {},
  hasDumbbells: false,
);

Future<AppDatabase> _boot(WidgetTester tester, List<WorkoutEntry> entries) async {
  usePhone(tester);
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

WorkoutEntry _walk(int d, {String? notes, int? effort}) => WorkoutEntry(
      activityId: 'walking',
      performedAt: DateTime(2026, 10, d, 9),
      durationSeconds: 600,
      notes: notes,
      perceivedEffort: effort,
    );

WorkoutEntry _squat(int d, {String? notes}) =>
    WorkoutEntry(activityId: 'squat', performedAt: DateTime(2026, 10, d, 9), sets: 2, reps: 10, notes: notes);

void main() {
  test('how it felt and the note are found by search, ignoring case', () {
    final e = _squat(20, notes: 'Left knee felt tight on the way down').copyWith(variant: 'Box');
    expect(e.matches(''), isTrue);
    expect(e.matches('  '), isTrue);
    expect(e.matches('squat'), isTrue);
    expect(e.matches('KNEE'), isTrue);
    expect(e.matches('box'), isTrue);
    expect(e.matches('swim'), isFalse);
    expect(_squat(20).matches('knee'), isFalse);
  });

  test('the feeling has a word for each rating and none outside them', () {
    expect([for (var i = 1; i <= 5; i++) _walk(1, effort: i).feel], WorkoutEntry.feelLabels);
    expect(_walk(1).feel, isNull);
    expect(_walk(1, effort: 0).feel, isNull);
    expect(_walk(1, effort: 9).feel, isNull);
  });

  testWidgets('the Journal shows how a workout felt and its note', (tester) async {
    final db = await _boot(tester, [_walk(20, notes: 'Sunny and slow', effort: 3), _walk(19)]);
    await tester.scrollUntilVisible(find.text('Felt Okay · Sunny and slow'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Felt Okay · Sunny and slow'), findsOneWidget);
    // A workout with neither has no extra line.
    expect(find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('note_')), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('searching narrows the Journal to matching workouts, and clearing brings it all back', (tester) async {
    final db = await _boot(tester, [_walk(20), _squat(19, notes: 'Knee felt fine'), _squat(18)]);
    expect(find.text('Chronicle'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('journal_search')), 'knee');
    await settle(tester, frames: 10);
    expect(find.text('1 workout matches "knee".'), findsOneWidget);
    // The overview panels step aside while looking for something.
    expect(find.text('Chronicle'), findsNothing);
    expect(find.text('Squats'), findsOneWidget);
    expect(find.text('Walking'), findsNothing);

    await tester.enterText(find.byKey(const Key('journal_search')), 'squat');
    await settle(tester, frames: 10);
    expect(find.text('2 workouts match "squat".'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('journal_search')), 'zzz');
    await settle(tester, frames: 10);
    expect(find.byKey(const Key('journal_search_result')), findsOneWidget);
    expect(find.textContaining('Nothing matches'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear Search'));
    await settle(tester, frames: 10);
    expect(find.text('Chronicle'), findsOneWidget);
    expect(find.byKey(const Key('journal_search_result')), findsNothing);
    await shutDown(tester, db);
  });

  testWidgets('the search and a long note fit on the smallest phone with the largest text', (tester) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.runAsync(() async {
      final repo = GameRepository(db);
      await repo.createHero(_hero);
      await repo.addWorkout(_walk(20, notes: 'A very long note about how the whole walk went, with the hills, the wind and the dog. ' * 3, effort: 4));
    });
    await bootApp(tester, db, now: _now);
    await tester.tap(find.text('Journal'));
    await settle(tester, frames: 30);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byKey(const Key('journal_search')), 'dog');
    await settle(tester, frames: 10);
    expect(tester.takeException(), isNull);
    expect(find.text('1 workout matches "dog".'), findsOneWidget);
    await shutDown(tester, db);
  });
}
