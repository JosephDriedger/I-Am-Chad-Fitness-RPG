import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';


import 'helpers.dart';

/// Visits every main screen and dialog on small phones and with large text,
/// where a layout that fits comfortably elsewhere tends to overflow. Any
/// exception (an overflow is one) fails the test.
class _Setup {
  const _Setup(this.name, this.width, this.height, this.textScale);

  final String name;
  final double width;
  final double height;
  final double textScale;
}

const _setups = [
  _Setup('smallest phone, largest text', 320, 568, 2.0),
  _Setup('small phone, big text', 360, 640, 1.5),
  _Setup('wide tablet-ish, normal text', 800, 600, 1.0),
  _Setup('phone on its side', 640, 360, 1.0),
  _Setup('phone on its side, big text', 640, 360, 1.5),
];

/// Finds [target] (scrolling a list or dialog to build it), brings it fully on
/// screen, and leaves it ready to use.
Future<void> _reveal(WidgetTester tester, Finder target) async {
  final lists = find.byType(Scrollable);
  if (target.evaluate().isEmpty && lists.evaluate().isNotEmpty) {
    await tester.scrollUntilVisible(target, 250, scrollable: lists.first, maxScrolls: 80);
  }
  if (target.evaluate().isEmpty) {
    final seen = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().take(40).toList();
    fail('could not find $target; on screen: $seen');
  }
  await tester.ensureVisible(target);
  await settle(tester, frames: 3);
}

/// Reveals [target] and taps it.
Future<void> _tap(WidgetTester tester, Finder target) async {
  await _reveal(tester, target);
  await tester.tap(target);
  await settle(tester, frames: 12);
  _noProblem(tester, 'tapping $target');
}

/// Types into the field labelled [label].
Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await _reveal(tester, field);
  await tester.enterText(field, text);
  await settle(tester, frames: 3);
}
Future<void> _back(WidgetTester tester) async {
  await tester.pageBack();
  await settle(tester, frames: 12);
  _noProblem(tester, 'going back');
}

/// Fails with the step named if anything has gone wrong on screen, so a
/// layout overflow says where it happened.
void _noProblem(WidgetTester tester, String step) {
  final problem = tester.takeException();
  if (problem != null) fail('$step threw: $problem');
}

void main() {
  for (final s in _setups) {
    testWidgets('every screen fits: ${s.name}', (tester) async {
      tester.view.physicalSize = Size(s.width * 2, s.height * 2);
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = s.textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = GameRepository(db);
      final now = DateTime(2026, 10, 22, 10);
      await tester.runAsync(() async {
        await repo.createHero(const HeroProfile(
          name: 'Ada the Very Long Named',
          appearanceStyle: 1,
          appearanceColor: 2,
          experience: ExperienceLevel.returning,
          preferredCategories: {ActivityCategory.cardio, ActivityCategory.resistance},
          hasDumbbells: true,
        ));
        for (var d = 0; d < 8; d++) {
          await repo.addWorkout(WorkoutEntry(
            activityId: d.isEven ? 'walking' : 'dumbbell_press',
            performedAt: DateTime(2026, 10, 22 - d, 18),
            durationSeconds: d.isEven ? 1800 : null,
            sets: d.isEven ? null : 3,
            reps: d.isEven ? null : 10,
            loadKg: d.isEven ? null : 12.5 + d,
          ));
        }
        await repo.addCoins(500);
      });
      await bootApp(tester, db, now: now);

      // The hall and its menu.
      for (final label in ['Quests', 'Adventure', 'Hero', 'Journal', 'Train']) {
        await tester.tap(find.text(label));
        await settle(tester, frames: 30);
        _noProblem(tester, 'opening $label');
        if (label == 'Quests') {
          // The panels further down the board are built lazily, so scroll to each one.
          for (final panel in ['Weekly Goal', 'Last Week', 'Self-Directed Adventures']) {
            await _reveal(tester, find.text(panel));
            _noProblem(tester, 'scrolling to $panel');
          }
        }
        if (label == 'Adventure') {
          await _tap(tester, find.text('Visit the Shop'));
          await _back(tester);
          await _tap(tester, find.text('Practice Duel'));
          expect(find.text('Attack'), findsOneWidget);
          await _back(tester);
          // The dialog scrolls when text is large, so scroll to the button.
          await _tap(tester, find.text('Retreat'));
          await settle(tester, frames: 30);
        }
        if (label == 'Hero') {
          await _tap(tester, find.text('Customise'));
          await _tap(tester, find.text('Save'));
        }
        if (label == 'Train') {
          // Chad's warm-up: its intro, every move, the end, and back out.
          await _tap(tester, find.byKey(const Key('warmup_start')));
          await _tap(tester, find.text('Begin'));
          for (var i = 0; i < 3; i++) {
            await _tap(tester, find.text('Next Move'));
          }
          await _tap(tester, find.text('Finish'));
          await _tap(tester, find.text('Back to the Yard'));
          // An exercise with every kind of field, its saved dialog and the honesty check.
          await _reveal(tester, find.byType(TextField));
          await tester.enterText(find.byType(TextField).first, 'Dumbbell Shoulder Press');
          await settle(tester);
          await _tap(tester, find.byWidgetPredicate((w) => w is Text && w.data == 'Dumbbell Shoulder Press'));
          await _enter(tester, 'Sets', '3');
          await _enter(tester, 'Reps per Set', '99');
          await _enter(tester, 'Weight (Optional)', '20');
          await _tap(tester, find.text('Save Workout'));
          expect(find.text('Quick Honesty Check'), findsOneWidget);
          await _tap(tester, find.text("It's Accurate"));
          await settle(tester, frames: 40);
          expect(find.text('Workout Saved!'), findsOneWidget);
          await _tap(tester, find.text('Nice'));
          await settle(tester, frames: 30);
        }
        // Back to the hall.
        for (var i = 0; i < 6 && find.byTooltip('Settings').evaluate().isEmpty; i++) {
          await _back(tester);
        }
        expect(find.byTooltip('Settings'), findsOneWidget, reason: 'back in the hall after $label');
      }

      // Settings and the Patron's Hall.
      await tester.tap(find.byTooltip('Settings'));
      await settle(tester, frames: 30);
      await _tap(tester, find.byKey(const Key('open_guide')));
      for (final s in ['Moving and Rewards', 'Adventures', 'Coins, Gear and Looks', 'Story', 'Your Data']) {
        await _reveal(tester, find.text(s));
      }
      await _back(tester);
      await _tap(tester, find.text("Open the Patron's Hall"));
      await _back(tester);
      await _back(tester);

      await shutDown(tester, db);
    });
  }
}
