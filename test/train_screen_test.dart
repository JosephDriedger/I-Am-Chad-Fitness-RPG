import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';

import 'helpers.dart';

/// A card title on the Train list (not the text typed in the search box).
Finder _card(String name) => find.byWidgetPredicate((w) => w is Text && w.data == name);

Future<AppDatabase> _openTrain(WidgetTester tester) async {
  usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await tester.runAsync(() => GameRepository(db).createHero(const HeroProfile(
        name: 'Ada',
        appearanceStyle: 0,
        appearanceColor: 0,
        experience: ExperienceLevel.starting,
        preferredCategories: {},
        hasDumbbells: false,
      )));
  await bootApp(tester, db);
  await tester.tap(find.text('Train'));
  await settle(tester, frames: 30);
  return db;
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  await settle(tester);
}

void main() {
  testWidgets('the whole catalog is listed, with a count', (tester) async {
    final db = await _openTrain(tester);
    expect(find.text('${ActivityCatalog.all.length} Exercises'), findsOneWidget);
    for (final c in ActivityCategory.values) {
      expect(find.text('All'), findsOneWidget);
      expect(find.text(c.label), findsWidgets, reason: 'a chip or heading for ${c.label}');
    }
    await shutDown(tester, db);
  });

  testWidgets('searching narrows the list by name, category and equipment', (tester) async {
    final db = await _openTrain(tester);

    await _type(tester, 'squat');
    final squats = ActivityCatalog.all.where((a) => a.name.toLowerCase().contains('squat')).length;
    expect(squats, greaterThan(3));
    expect(find.text('$squats Exercises'), findsOneWidget);
    expect(_card('Goblet Squat'), findsOneWidget);
    expect(_card('Push-ups'), findsNothing);

    // By equipment.
    await _type(tester, 'kettlebell');
    expect(_card('Kettlebell Swing'), findsOneWidget);
    expect(find.text('1 Exercise'), findsOneWidget);

    // Matches are case-insensitive.
    await _type(tester, 'BICEP');
    expect(_card('Bicep Curls'), findsOneWidget);

    await shutDown(tester, db);
  });

  testWidgets('category chips and the at-home switch filter, and can be combined', (tester) async {
    final db = await _openTrain(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Core'));
    await settle(tester);
    final core = ActivityCatalog.inCategory(ActivityCategory.core);
    expect(find.text('${core.length} Exercises'), findsOneWidget);
    expect(find.text('Core (${core.length})'), findsOneWidget);
    expect(_card('Plank'), findsOneWidget);
    expect(_card('Walking'), findsNothing);

    // Tapping the chip again clears it.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Core'));
    await settle(tester);
    expect(find.text('${ActivityCatalog.all.length} Exercises'), findsOneWidget);

    // At home only hides anything that needs gear.
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Resistance'));
    await settle(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Resistance'));
    await settle(tester);
    await tester.scrollUntilVisible(_card('Bench Press'), 300, scrollable: find.byType(Scrollable).first);
    expect(_card('Bench Press'), findsOneWidget);
    await tester.scrollUntilVisible(find.widgetWithText(FilterChip, 'At Home Only'), -300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.widgetWithText(FilterChip, 'At Home Only'));
    await settle(tester);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await settle(tester);
    final home = ActivityCatalog.inCategory(ActivityCategory.resistance).where((a) => a.equipment.atHome).length;
    expect(find.text(home == 1 ? '1 Exercise' : '$home Exercises'), findsOneWidget);
    expect(_card('Bench Press'), findsNothing);

    await shutDown(tester, db);
  });

  testWidgets('cards say what gear they need', (tester) async {
    final db = await _openTrain(tester);
    await _type(tester, 'Bicep Curls');
    expect(find.text('Dumbbells'), findsOneWidget);
    await _type(tester, 'Lunges');
    expect(find.text('Dumbbells'), findsNothing);
    expect(_card('Lunges'), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('no matches explains itself, and clearing brings everything back', (tester) async {
    final db = await _openTrain(tester);
    await _type(tester, 'zzzz');
    expect(find.text('No Exercises Match'), findsOneWidget);
    expect(find.text('0 Exercises'), findsOneWidget);

    await tester.tap(find.text('Clear Filters'));
    await settle(tester);
    expect(find.text('No Exercises Match'), findsNothing);
    expect(find.text('${ActivityCatalog.all.length} Exercises'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, isEmpty);
    await shutDown(tester, db);
  });

  testWidgets('a new exercise can be opened and logged like any other', (tester) async {
    final db = await _openTrain(tester);
    await openExercise(tester, 'Jumping Jacks');
    // The log screen shows its animated demonstration and its own cue.
    expect(find.text('Jumping Jacks'), findsWidgets);
    expect(find.textContaining('Jump your feet wide'), findsOneWidget);
    expect(find.text('Sets'), findsWidgets);
    await shutDown(tester, db);
  });
}
