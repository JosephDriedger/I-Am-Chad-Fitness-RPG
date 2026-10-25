import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/hud_legend.dart';

import 'helpers.dart';

Future<AppDatabase> _boot(WidgetTester tester, {bool phoneSurface = true}) async {
  if (phoneSurface) usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await tester.runAsync(() => GameRepository(db).createHero(const HeroProfile(
        name: 'Ada',
        appearanceStyle: 0,
        appearanceColor: 0,
        experience: ExperienceLevel.returning,
        preferredCategories: {ActivityCategory.cardio},
        hasDumbbells: false,
      )));
  await bootApp(tester, db);
  return db;
}

void main() {
  testWidgets('tapping the numbers at the top of the hall explains each one, and Settings still opens', (tester) async {
    final db = await _boot(tester);
    expect(find.text(HudLegend.title), findsNothing);

    await tester.tap(find.byKey(const Key('hud_info')));
    await settle(tester, frames: 20);
    expect(find.text(HudLegend.title), findsOneWidget);
    for (final e in HudLegend.entries()) {
      expect(find.text(e.title), findsOneWidget, reason: e.title);
    }
    expect(find.text(HudLegend.footnote), findsOneWidget);

    await tester.tap(find.byKey(const Key('hud_legend_close')));
    await settle(tester, frames: 20);
    expect(find.text(HudLegend.title), findsNothing);

    // The settings cog next to it is a separate button and still goes to Settings.
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester, frames: 30);
    expect(find.text('Settings'), findsWidgets);
    expect(find.text(HudLegend.title), findsNothing);
    await shutDown(tester, db);
  });

  testWidgets('the tap area is big enough for a thumb and is named for a screen reader', (tester) async {
    final db = await _boot(tester);
    final size = tester.getSize(find.byKey(const Key('hud_info')));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(find.bySemanticsLabel(RegExp('What these numbers mean')), findsWidgets);
    await shutDown(tester, db);
  });

  testWidgets('the explanation fits a small phone at large text and scrolls', (tester) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = await _boot(tester, phoneSurface: false);
    await tester.tap(find.byKey(const Key('hud_info')));
    await settle(tester, frames: 20);
    expect(find.text(HudLegend.title), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('hud_legend_close')));
    await settle(tester, frames: 3);
    expect(find.byKey(const Key('hud_legend_close')), findsOneWidget);
    await shutDown(tester, db);
  });
}
