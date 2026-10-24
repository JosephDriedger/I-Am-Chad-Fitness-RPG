import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/hero.dart';

import 'helpers.dart';

/// Every main screen as a brand-new player sees it: no workouts, no energy, no
/// records, nothing earned. The main layout tour uses a hero with history, so the
/// empty states (the "nothing yet" pages) only show up here.
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

/// Scrolls the screen's main list to the bottom a screenful at a time and back.
Future<void> _scrollThrough(WidgetTester tester, String screen) async {
  final lists = find.byType(Scrollable);
  if (lists.evaluate().isEmpty) return;
  final list = lists.first;
  final position = tester.state<ScrollableState>(list).position;
  var last = -1.0;
  for (var i = 0; i < 80 && position.pixels != last; i++) {
    last = position.pixels;
    await tester.drag(list, const Offset(0, -240));
    await settle(tester, frames: 3);
    _noProblem(tester, '$screen, after scrolling ${position.pixels.round()} px');
  }
  for (var i = 0; i < 80 && position.pixels > 0; i++) {
    await tester.drag(list, const Offset(0, 600));
    await settle(tester, frames: 2);
  }
}

void main() {
  for (final s in _setups) {
    testWidgets('a new player sees every screen fit: ${s.name}', (tester) async {
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
      await bootApp(tester, db);
      _noProblem(tester, 'the hall');

      for (final label in ['Quests', 'Adventure', 'Hero', 'Journal', 'Train']) {
        await tester.tap(find.text(label));
        await settle(tester, frames: 40);
        _noProblem(tester, 'opening $label');
        await _scrollThrough(tester, label);
        await tester.pageBack();
        await settle(tester, frames: 15);
        _noProblem(tester, 'coming back from $label');
      }

      await tester.tap(find.byTooltip('Settings'));
      await settle(tester, frames: 30);
      await _scrollThrough(tester, 'Settings');
      _noProblem(tester, 'Settings');
      await tester.pageBack();
      await settle(tester, frames: 15);
      await shutDown(tester, db);
    });
  }
}
