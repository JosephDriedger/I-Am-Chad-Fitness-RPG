import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/game_ui.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

final _now = DateTime(2026, 10, 22, 10);

WorkoutEntry _on(int m, int d) => WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, m, d, 9), durationSeconds: 600);

Future<AppDatabase> _boot(WidgetTester tester, List<WorkoutEntry> entries, {bool phoneSurface = true, bool open = true}) async {
  if (phoneSurface) usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await tester.runAsync(() async {
    final repo = GameRepository(db);
    await repo.createHero(const HeroProfile(
      name: 'Ada',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.returning,
      preferredCategories: {ActivityCategory.cardio},
      hasDumbbells: false,
    ));
    for (final e in entries) {
      await repo.addWorkout(e);
    }
  });
  await bootApp(tester, db, now: _now);
  await tester.tap(find.text('Journal'));
  await settle(tester, frames: 30);
  await tester.scrollUntilVisible(find.text('Your Month'), 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(find.text('Your Month'));
  await settle(tester, frames: 3);
  if (open) {
    await tester.ensureVisible(find.byKey(const Key('month_toggle')));
    await tester.tap(find.byKey(const Key('month_toggle')));
    await settle(tester, frames: 5);
  }
  return db;
}

/// Whether the day's circle is filled gold.
bool _gold(WidgetTester tester, String key) {
  final c = find.descendant(of: find.byKey(Key(key)), matching: find.byType(Container));
  return tester.widgetList<Container>(c).any((w) => w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).color == GameColors.gold);
}

void main() {
  testWidgets('the month starts as one line, so the workouts stay near the top, and opens when asked', (tester) async {
    final db = await _boot(tester, [_on(10, 5), _on(10, 19)], open: false);
    expect(find.text('2 days you moved in October. Rest days are part of the plan.'), findsOneWidget);
    expect(find.byKey(const Key('month_grid')), findsNothing);
    expect(find.text('Show Calendar'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('month_toggle')));
    await tester.tap(find.byKey(const Key('month_toggle')));
    await settle(tester, frames: 5);
    expect(find.byKey(const Key('month_grid')), findsOneWidget);
    expect(find.text('Hide Calendar'), findsOneWidget);
    await tester.tap(find.byKey(const Key('month_toggle')));
    await settle(tester, frames: 5);
    expect(find.byKey(const Key('month_grid')), findsNothing);
    await shutDown(tester, db);
  });

  testWidgets('the month shows a gold dot on each day moved, and counts them kindly', (tester) async {
    final db = await _boot(tester, [_on(10, 5), _on(10, 19), _on(10, 21), _on(9, 14)]);
    expect(find.text('October 2026'), findsOneWidget);
    expect(_gold(tester, 'day_2026-10-19'), isTrue);
    expect(_gold(tester, 'day_2026-10-21'), isTrue);
    expect(_gold(tester, 'day_2026-10-20'), isFalse, reason: 'a day without movement is just a day');
    expect(find.text('3 days you moved in October. Rest days are part of the plan.'), findsOneWidget);
    // Nothing that counts what was not done.
    for (final w in ['missed', 'streak', 'broken', 'behind']) {
      expect(find.textContaining(w), findsNothing, reason: w);
    }
    await shutDown(tester, db);
  });

  testWidgets('earlier and later months can be looked at, and the arrows stop where the journal does', (tester) async {
    final db = await _boot(tester, [_on(10, 19), _on(8, 3), _on(8, 4)]);
    IconButton arrow(String key) => tester.widget<IconButton>(find.byKey(Key(key)));
    expect(arrow('month_later').onPressed, isNull, reason: 'nothing after this month');
    expect(arrow('month_earlier').onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('month_earlier')));
    await settle(tester, frames: 5);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('A quiet month. Rest counts too.'), findsOneWidget, reason: 'nothing logged in September, and that is fine');

    await tester.tap(find.byKey(const Key('month_earlier')));
    await settle(tester, frames: 5);
    expect(find.text('August 2026'), findsOneWidget);
    expect(find.text('2 days you moved in August. Rest days are part of the plan.'), findsOneWidget);
    expect(_gold(tester, 'day_2026-08-03'), isTrue);
    expect(arrow('month_earlier').onPressed, isNull, reason: 'August is where the journal begins');

    await tester.tap(find.byKey(const Key('month_later')));
    await settle(tester, frames: 5);
    await tester.tap(find.byKey(const Key('month_later')));
    await settle(tester, frames: 5);
    expect(find.text('October 2026'), findsOneWidget);
    expect(arrow('month_later').onPressed, isNull);
    await shutDown(tester, db);
  });

  testWidgets('today is marked with a ring, and a month with one day says "1 day"', (tester) async {
    final db = await _boot(tester, [_on(10, 22)]);
    final today = find.descendant(of: find.byKey(const Key('day_2026-10-22')), matching: find.byType(Container));
    expect(
      tester.widgetList<Container>(today).any((w) => w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).border != null),
      isTrue,
    );
    expect(find.text('1 day you moved in October. Rest days are part of the plan.'), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('the month fits a small phone at large text, and is read out as one sentence', (tester) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = await _boot(tester, [_on(10, 5), _on(10, 19)], phoneSurface: false);
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel(RegExp('October 2026: you moved on 2 days')), findsWidgets);
    await shutDown(tester, db);
  });
}
