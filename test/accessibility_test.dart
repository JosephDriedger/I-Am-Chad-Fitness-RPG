import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

/// Runs Flutter's own accessibility checks on each main screen: every control
/// big enough to press, every control named for a screen reader, and text that
/// can be read against its background.
void main() {
  testWidgets('every main screen meets the tap target, label and contrast guidelines', (tester) async {
    final semantics = tester.ensureSemantics();
    usePhone(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = GameRepository(db);
    final now = DateTime(2026, 10, 22, 10);
    await tester.runAsync(() async {
      await repo.createHero(const HeroProfile(
        name: 'Ada',
        appearanceStyle: 1,
        appearanceColor: 2,
        experience: ExperienceLevel.returning,
        preferredCategories: {ActivityCategory.cardio, ActivityCategory.resistance},
        hasDumbbells: true,
      ));
      for (var d = 0; d < 4; d++) {
        await repo.addWorkout(WorkoutEntry(
          activityId: d.isEven ? 'walking' : 'dumbbell_press',
          performedAt: DateTime(2026, 10, 22 - d, 18),
          durationSeconds: d.isEven ? 900 : null,
          sets: d.isEven ? null : 3,
          reps: d.isEven ? null : 10,
          loadKg: d.isEven ? null : 10,
        ));
      }
      await repo.addCoins(300);
    });
    await bootApp(tester, db, now: now);

    final problems = <String>[];
    Future<void> check(String screen) async {
      await settle(tester, frames: 10);
      for (final (name, guideline) in [
        ('tap target size', androidTapTargetGuideline),
        ('tap target label', labeledTapTargetGuideline),
        ('text contrast', textContrastGuideline),
      ]) {
        try {
          await expectLater(tester, meetsGuideline(guideline));
        } on TestFailure catch (e) {
          problems.add('$screen, $name: ${e.message?.replaceAll(RegExp(r'\s+'), ' ')}');
        }
      }
    }

    Future<void> openFromHall(String label) async {
      await tester.tap(find.text(label));
      await settle(tester, frames: 30);
    }

    Future<void> backToHall() async {
      for (var i = 0; i < 6 && find.byTooltip('Settings').evaluate().isEmpty; i++) {
        await tester.pageBack();
        await settle(tester, frames: 12);
      }
    }

    await check('hall');
    for (final label in ['Quests', 'Adventure', 'Hero', 'Journal', 'Train']) {
      await openFromHall(label);
      await check(label);
      if (label == 'Train') {
        await tester.enterText(find.byType(TextField).first, 'Dumbbell Shoulder Press');
        await settle(tester);
        await tester.tap(find.byWidgetPredicate((w) => w is Text && w.data == 'Dumbbell Shoulder Press'));
        await settle(tester, frames: 20);
        await check('exercise log');
      }
      await backToHall();
    }
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester, frames: 30);
    await check('settings');
    await tester.scrollUntilVisible(find.text("Open the Patron's Hall"), 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text("Open the Patron's Hall"));
    await settle(tester, frames: 5);
    await tester.tap(find.text("Open the Patron's Hall"));
    await settle(tester, frames: 30);
    await check("patron's hall");

    expect(problems, isEmpty, reason: problems.join('\n'));
    semantics.dispose();
    await shutDown(tester, db);
  });
}
