import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/hero.dart';

import 'helpers.dart';

/// The hall is a portrait scene, so held sideways its menu moves to a rail down the
/// right-hand side and the room gets the whole height, instead of a bar along the
/// bottom covering half of it.
const _destinations = ['Train', 'Quests', 'Adventure', 'Hero', 'Journal'];

Future<AppDatabase> _boot(WidgetTester tester, Size size, {double textScale = 1.0}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
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
  await settle(tester, frames: 10);
  return db;
}

Rect _button(WidgetTester tester, String label) => tester.getRect(find.text(label));

void main() {
  testWidgets('upright, the menu is a bar along the bottom', (tester) async {
    final db = await _boot(tester, const Size(360, 640));
    final rects = [for (final d in _destinations) _button(tester, d)];
    // Side by side along one line near the bottom of the screen.
    final ys = [for (final r in rects) r.center.dy];
    expect(ys.reduce((a, b) => a > b ? a : b) - ys.reduce((a, b) => a < b ? a : b), lessThan(6), reason: 'all on one line');
    expect(rects.first.center.dy, greaterThan(640 * 0.8));
    for (var i = 1; i < rects.length; i++) {
      expect(rects[i].center.dx, greaterThan(rects[i - 1].center.dx));
    }
    await shutDown(tester, db);
  });

  for (final scale in [1.0, 1.5]) {
    testWidgets('held sideways at text ${scale}x, the menu is a rail down the right and every destination works', (tester) async {
      final db = await _boot(tester, const Size(640, 360), textScale: scale);
      expect(tester.takeException(), isNull);
      final rects = [for (final d in _destinations) _button(tester, d)];
      // Stacked in one column at the right-hand edge, top to bottom, all on screen.
      expect({for (final r in rects) r.center.dx.round()}.length, lessThanOrEqualTo(2), reason: 'one column');
      for (final r in rects) {
        expect(r.center.dx, greaterThan(640 * 0.8), reason: 'at the right-hand edge');
        expect(r.top, greaterThanOrEqualTo(0));
        expect(r.bottom, lessThanOrEqualTo(360));
      }
      for (var i = 1; i < rects.length; i++) {
        expect(rects[i].center.dy, greaterThan(rects[i - 1].center.dy));
      }
      // The hall itself is not covered by a bar along the bottom.
      for (final r in rects) {
        expect(r.center.dy, lessThan(360));
      }

      // And each one still works.
      for (final d in _destinations) {
        await tester.tap(find.text(d));
        await settle(tester, frames: 40);
        expect(tester.takeException(), isNull, reason: 'opening $d');
        await tester.pageBack();
        await settle(tester, frames: 15);
      }
      await shutDown(tester, db);
    });
  }
}
