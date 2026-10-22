import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/app.dart';
import 'package:i_am_chad/app/providers.dart';
import 'package:i_am_chad/data/database.dart';

Future<void> _settle(WidgetTester tester) async {
  // Drift streams deliver on microtasks/timers; pump a few frames.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));

  Future<void> boot(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 22, 10)),
      ],
      child: const IAmChadApp(),
    ));
    await _settle(tester);
  }

  Future<void> teardown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await db.close();
  }

  testWidgets('first run: onboarding, then guild, then log a workout',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await boot(tester);

    // Step 1: welcome + safety messaging.
    expect(find.text('I Am Chad'), findsOneWidget);
    expect(find.textContaining('not medical advice'), findsOneWidget);
    await tester.tap(find.text('Let\'s go'));
    await _settle(tester);

    // Step 2: can't continue without a name.
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Next')).onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField).first, 'Ada');
    await _settle(tester);
    await tester.tap(find.text('Next'));
    await _settle(tester);

    // Step 3: pick a level and finish.
    await tester.tap(find.text('Getting back into it'));
    await _settle(tester);
    await tester.tap(find.text('Enter the Guild'));
    await _settle(tester);

    // Guild screen shows the hero and a first suggestion.
    expect(find.text('The Guild'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Next up'), findsOneWidget);

    // Log a walk from the Workout tab.
    await tester.tap(find.text('Workout').last);
    await _settle(tester);
    await tester.tap(find.text('Walking'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Minutes'), '10');
    await tester.ensureVisible(find.text('Save workout'));
    await tester.tap(find.text('Save workout'));
    await _settle(tester);

    // Reward explanation is shown.
    expect(find.text('Workout saved!'), findsOneWidget);
    expect(find.text('40 XP'), findsOneWidget);
    expect(find.text('2 energy'), findsOneWidget);
    await tester.tap(find.text('Nice'));
    await _settle(tester);

    // It is in the history with its reward.
    await tester.tap(find.text('History').last);
    await _settle(tester);
    expect(find.text('Walking'), findsOneWidget);
    expect(find.textContaining('+40 XP'), findsOneWidget);

    // And the hero now has energy to spend.
    await tester.tap(find.text('Guild').last);
    await _settle(tester);
    expect(find.text('2 energy'), findsOneWidget);

    await teardown(tester);
  });

  testWidgets('an empty entry is rejected with a helpful message',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await boot(tester);
    await tester.tap(find.text('Let\'s go'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Bo');
    await _settle(tester);
    await tester.tap(find.text('Next'));
    await _settle(tester);
    await tester.tap(find.text('Enter the Guild'));
    await _settle(tester);

    await tester.tap(find.text('Workout').last);
    await _settle(tester);
    await tester.tap(find.text('Push-ups'));
    await _settle(tester);
    await tester.ensureVisible(find.text('Save workout'));
    await tester.tap(find.text('Save workout'));
    await _settle(tester);

    expect(find.textContaining('Add at least'), findsOneWidget);
    expect(await db.select(db.workouts).get(), isEmpty);

    await teardown(tester);
  });
}
