import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/first_steps.dart';
import 'package:i_am_chad/domain/hero.dart';

import 'helpers.dart';

Future<AppDatabase> _openPracticeDuel(WidgetTester tester, {int victories = 0}) async {
  usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await tester.runAsync(() async {
    await GameRepository(db).createHero(const HeroProfile(
      name: 'Ada',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.starting,
      preferredCategories: {},
      hasDumbbells: false,
    ));
    if (victories > 0) await db.customStatement('UPDATE heroes SET victories = $victories WHERE id = 1');
  });
  await bootApp(tester, db);
  await tester.tap(find.text('Adventure'));
  await settle(tester, frames: 30);
  await tester.scrollUntilVisible(find.text('Practice Duel'), 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(find.text('Practice Duel'));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.text('Practice Duel'));
  await settle(tester, frames: 40);
  return db;
}

void main() {
  testWidgets('a new hero\'s first fight says what the buttons do', (tester) async {
    final db = await _openPracticeDuel(tester);
    expect(find.text('Attack'), findsOneWidget);
    expect(find.byKey(const Key('battle_hint')), findsOneWidget);
    expect(find.text(FirstSteps.battleHint), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('once an expedition has been won, the hint is gone for good', (tester) async {
    final db = await _openPracticeDuel(tester, victories: 1);
    expect(find.text('Attack'), findsOneWidget);
    expect(find.byKey(const Key('battle_hint')), findsNothing);
    await shutDown(tester, db);
  });

  test('the hint names every button and stays short and kind', () {
    for (final name in ['Attack', 'Guard', 'Power Strike', 'Potion']) {
      expect(FirstSteps.battleHint, contains(name));
    }
    expect(FirstSteps.battleHint.length, lessThan(150));
  });
}
