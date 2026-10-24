import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/hero.dart';

import 'helpers.dart';

/// The first thing every new player sees. Walks all three onboarding steps on
/// the awkward screens (the smallest phone at the largest text, a small phone
/// at big text, and a phone on its side), scrolling each step from top to
/// bottom, and fails on any overflow or other exception.
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
  _Setup('phone on its side', 640, 360, 1.0),
  _Setup('phone on its side, big text', 640, 360, 1.5),
];

void _noProblem(WidgetTester tester, String step) {
  final problem = tester.takeException();
  if (problem != null) fail('$step threw: ${problem is FlutterError ? problem.toStringDeep() : problem}');
}

/// Scrolls the step's list to the bottom a screenful at a time and back, so a
/// panel far down the page is built and laid out.
Future<void> _scrollThrough(WidgetTester tester, String step) async {
  final list = find.byType(Scrollable).first;
  final position = tester.state<ScrollableState>(list).position;
  var last = -1.0;
  for (var i = 0; i < 60 && position.pixels != last; i++) {
    last = position.pixels;
    await tester.drag(list, const Offset(0, -200));
    await settle(tester, frames: 3);
    _noProblem(tester, '$step, after scrolling ${position.pixels.round()} px');
  }
  for (var i = 0; i < 60 && position.pixels > 0; i++) {
    await tester.drag(list, const Offset(0, 500));
    await settle(tester, frames: 2);
  }
}

void main() {
  for (final s in _setups) {
    testWidgets('onboarding fits: ${s.name}', (tester) async {
      tester.view.physicalSize = Size(s.width * 2, s.height * 2);
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = s.textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await bootApp(tester, db);
      _noProblem(tester, 'opening onboarding');

      // Step 1: the welcome, with its safety note.
      await _scrollThrough(tester, 'the welcome step');
      expect(find.text("Let's Go"), findsOneWidget);
      await tester.tap(find.text("Let's Go"));
      await settle(tester);
      _noProblem(tester, 'going to step 2');

      // Step 2: name and appearance, with the keyboard-sized name that is the longest allowed.
      await tester.enterText(find.byType(TextField).first, 'Ada the Very Long Nam');
      await settle(tester);
      await _scrollThrough(tester, 'the create step');
      await tester.tap(find.text('Next'));
      await settle(tester);
      _noProblem(tester, 'going to step 3');

      // Step 3: experience, interests and equipment, and the last button.
      await _scrollThrough(tester, 'the preferences step');
      expect(find.text('Enter the Guild'), findsOneWidget);
      // Going back works from here too.
      await tester.tap(find.text('Back'));
      await settle(tester);
      _noProblem(tester, 'going back');
      await tester.tap(find.text('Next'));
      await settle(tester);
      await tester.tap(find.text('Enter the Guild'));
      await settle(tester, frames: 30);
      _noProblem(tester, 'entering the guild');

      await shutDown(tester, db);
    });
  }

  for (final s in _setups) {
    testWidgets('the title screen fits: ${s.name}', (tester) async {
      tester.view.physicalSize = Size(s.width * 2, s.height * 2);
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = s.textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.runAsync(() => GameRepository(db).createHero(const HeroProfile(
            name: 'Ada the Very Long Named',
            appearanceStyle: 0,
            appearanceColor: 0,
            experience: ExperienceLevel.starting,
            preferredCategories: {},
            hasDumbbells: false,
          )));
      await bootApp(tester, db, showTitle: true);
      _noProblem(tester, 'the title screen');
      expect(find.text('Tap to Continue'), findsOneWidget);
      await tester.ensureVisible(find.text('Tap to Continue'));
      await tester.tap(find.text('Tap to Continue'));
      await settle(tester, frames: 30);
      _noProblem(tester, 'leaving the title screen');
      expect(find.byTooltip('Settings'), findsOneWidget, reason: 'in the hall');
      await shutDown(tester, db);
    });
  }
}
