import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/guide.dart';
import 'package:i_am_chad/domain/hero.dart';

import 'helpers.dart';

void main() {
  testWidgets('the guide opens from Settings, shows every section, and goes back', (tester) async {
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
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester, frames: 30);

    await tester.tap(find.byKey(const Key('open_guide')));
    await settle(tester, frames: 20);
    expect(find.text(Guide.intro), findsOneWidget);

    // Every section can be reached by scrolling.
    for (final s in Guide.sections) {
      await tester.scrollUntilVisible(find.text(s.title), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text(s.title), findsOneWidget);
    }
    await tester.scrollUntilVisible(find.text('Stop If Anything Hurts'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Stop If Anything Hurts'), findsOneWidget);

    await tester.pageBack();
    await settle(tester, frames: 20);
    expect(find.byKey(const Key('open_guide')), findsOneWidget, reason: 'back on Settings');
    await shutDown(tester, db);
  });
}
