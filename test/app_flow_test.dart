import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/game/core.dart';
import 'package:i_am_chad/game/hub_scene.dart';
import 'package:i_am_chad/data/database.dart';

import 'helpers.dart';

Future<void> _onboard(WidgetTester tester, String name) async {
  await tester.tap(find.text('Let\'s Go'));
  await settle(tester);
  await tester.enterText(find.byType(TextField).first, name);
  await settle(tester);
  await tester.tap(find.text('Next'));
  await settle(tester);
  await tester.tap(find.text('Getting Back Into It'));
  await settle(tester);
  await tester.tap(find.text('Enter the Guild'));
  await settle(tester, frames: 20);
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));

  testWidgets('first run: onboarding, then the guild hall, then log a workout',
      (tester) async {
    final semantics = tester.ensureSemantics();
    usePhone(tester);
    await bootApp(tester, db);

    // Welcome + safety messaging.
    expect(find.text('I Am Chad'), findsOneWidget);
    expect(find.textContaining('not medical advice'), findsOneWidget);
    await tester.tap(find.text('Let\'s Go'));
    await settle(tester);

    // Can't continue without a name.
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Next')).onPressed,
      isNull,
    );
    // Appearance picker offers skin tones.
    expect(find.text('Skin Tone'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Ada');
    await settle(tester);
    await tester.tap(find.text('Next'));
    await settle(tester);
    await tester.tap(find.text('Getting Back Into It'));
    await settle(tester);
    await tester.tap(find.text('Enter the Guild'));
    await settle(tester, frames: 20);

    // The hall HUD shows the hero and the menu offers every destination.
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Lv 1'), findsOneWidget);
    for (final label in ['Train', 'Quests', 'Adventure', 'Hero', 'Journal']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.bySemanticsLabel('Adventure energy: 0'), findsOneWidget);

    // Train: the hero walks to the dummy, then the log screen opens.
    await tester.tap(find.text('Train'));
    await settle(tester, frames: 30);
    expect(find.text('Log a Workout'), findsOneWidget);
    await tester.tap(find.text('Walking'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Minutes'), '10');
    await tester.scrollUntilVisible(find.text('Save Workout'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Save Workout'));
    await settle(tester);

    // The reward is explained.
    expect(find.text('Workout Saved!'), findsOneWidget);
    expect(find.text('40 XP'), findsOneWidget);
    expect(find.text('2 Energy'), findsOneWidget);
    await tester.tap(find.text('Nice'));
    await settle(tester);

    // Back to the hall: the energy is on the HUD and the gate is open.
    await tester.pageBack();
    await settle(tester, frames: 12);
    // The hall celebrates what you earned with floating popups.
    final scene = tester.widget<GameWidget<HubScene>>(find.byType(GameWidget<HubScene>)).game!;
    final popups = scene.world.children.whereType<FloatingText>().length;
    expect(popups, greaterThanOrEqualTo(1), reason: 'no +XP popup after logging a workout');
    await settle(tester, frames: 40);
    expect(find.bySemanticsLabel('Adventure energy: 2'), findsOneWidget);

    // The journal lists it with its reward.
    await tester.tap(find.text('Journal'));
    await settle(tester, frames: 30);
    expect(find.text('Walking'), findsOneWidget);
    expect(find.textContaining('+40 XP'), findsOneWidget);

    semantics.dispose();
    await shutDown(tester, db);
  });

  testWidgets('an empty entry is rejected with a helpful message',
      (tester) async {
    usePhone(tester);
    await bootApp(tester, db);
    await _onboard(tester, 'Bo');

    await tester.tap(find.text('Train'));
    await settle(tester, frames: 30);
    await tester.tap(find.text('Push-ups'));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Save Workout'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Save Workout'));
    await settle(tester);

    expect(find.textContaining('Add at least'), findsOneWidget);
    expect(await tester.runAsync(() => db.select(db.workouts).get()), isEmpty);

    await shutDown(tester, db);
  });
}
