import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/game_ui.dart';
import 'package:i_am_chad/app/providers.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

/// A repository whose first save fails, the way a full disk or a locked
/// database would, and which works after that.
class _FlakyRepository extends GameRepository {
  _FlakyRepository(super.db);

  var failures = 1;

  @override
  Future<int> addWorkout(WorkoutEntry e) async {
    if (failures > 0) {
      failures--;
      throw StateError('disk full');
    }
    return super.addWorkout(e);
  }
}

void main() {
  testWidgets('a save that fails says so and leaves Save ready to try again', (tester) async {
    usePhone(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.runAsync(() => GameRepository(db).createHero(const HeroProfile(
          name: 'Ada',
          appearanceStyle: 0,
          appearanceColor: 0,
          experience: ExperienceLevel.starting,
          preferredCategories: {ActivityCategory.cardio},
          hasDumbbells: false,
        )));
    final repo = _FlakyRepository(db);
    await bootApp(tester, db, now: DateTime(2026, 10, 22, 10), overrides: [repositoryProvider.overrideWithValue(repo)]);

    await tester.tap(find.text('Train'));
    await settle(tester, frames: 30);
    await openExercise(tester, 'Walking');
    await tester.enterText(find.widgetWithText(TextField, 'Minutes'), '10');
    await tester.scrollUntilVisible(find.text('Save Workout'), 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Save Workout'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save Workout'));
    await tester.ensureVisible(find.text('Save Workout'));
    await tester.tap(find.text('Save Workout'));
    await settle(tester);

    expect(find.text('That could not be saved. Please try again.'), findsOneWidget);
    expect(find.text('Workout Saved!'), findsNothing);
    final button = tester.widget<GameButton>(find.widgetWithText(GameButton, 'Save Workout'));
    expect(button.onPressed, isNotNull, reason: 'Save must not stay disabled after a failure');

    await tester.tap(find.text('Save Workout'));
    await settle(tester);
    expect(find.text('Workout Saved!'), findsOneWidget);
    expect(await tester.runAsync(() => GameRepository(db).watchWorkouts().first), hasLength(1));

    await shutDown(tester, db);
  });
}
