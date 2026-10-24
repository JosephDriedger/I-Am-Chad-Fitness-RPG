import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/ads.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/patronage.dart';
import 'package:i_am_chad/domain/story.dart';

import 'helpers.dart';

final _prologue = Story.chapters.first;

Future<(AppDatabase, GameRepository)> _boot(
  WidgetTester tester,
  TestAdGateway ads, {
  bool premium = false,
  bool alreadyRead = false,
}) async {
  usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = GameRepository(db);
  await tester.runAsync(() async {
    await repo.createHero(const HeroProfile(
      name: 'Ada',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.returning,
      preferredCategories: {ActivityCategory.cardio},
      hasDumbbells: false,
    ));
    if (premium) await repo.recordPurchase(Patronage.premium, 'premium-1', at: DateTime(2026, 10, 22));
    if (alreadyRead) await repo.markChapterRead(0, at: DateTime(2026, 10, 22));
  });
  await bootApp(tester, db, storyOffers: true, ads: ads);
  return (db, repo);
}

/// Opens the prologue from the hall's offer ("Read Now") or, if it has been read,
/// from the Chronicle's "Read Again".
Future<void> _open(WidgetTester tester, {required bool again}) async {
  if (!again) {
    await tester.tap(find.text('Read Now'));
  } else {
    await tester.tap(find.text('Quests'));
    await settle(tester, frames: 30);
    await tester.scrollUntilVisible(find.text('Open the Chronicle'), 300, scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(find.text('Open the Chronicle'));
    await settle(tester, frames: 2);
    await tester.tap(find.text('Open the Chronicle'));
    await settle(tester, frames: 30);
    await tester.tap(find.text('Read Again').first);
  }
  await settle(tester, frames: 20);
}

void main() {
  testWidgets('the first time a chapter opens, an ad comes before the story, which waits for it', (tester) async {
    final ads = TestAdGateway(delay: const Duration(seconds: 3));
    final (db, _) = await _boot(tester, ads);

    await tester.tap(find.text('Read Now'));
    await settle(tester, frames: 8);
    // While the ad is on its way, the story cannot begin underneath it.
    expect(find.text('One moment...'), findsOneWidget);
    await tester.tapAt(const Offset(225, 300));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('One moment...'), findsOneWidget, reason: 'a tap during the ad must not start the story');

    await settle(tester, frames: 80);
    expect(ads.shown, 1);
    expect(find.text('Tap to begin'), findsOneWidget);

    await tester.tapAt(const Offset(225, 300));
    await settle(tester);
    expect(find.text('Tap to begin'), findsNothing, reason: 'now the story is under way');
    await shutDown(tester, db);
  });

  testWidgets('with nothing to show, or no connection, the story just begins', (tester) async {
    final ads = TestAdGateway(available: false);
    final (db, _) = await _boot(tester, ads);

    await tester.tap(find.text('Read Now'));
    await settle(tester, frames: 20);
    expect(ads.shown, 0);
    expect(find.text('Tap to begin'), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('a chapter that has been read opens without an ad', (tester) async {
    final ads = TestAdGateway();
    final (db, _) = await _boot(tester, ads, alreadyRead: true);

    await _open(tester, again: true);
    expect(find.text('Tap to begin'), findsOneWidget);
    expect(ads.shown, 0);
    await shutDown(tester, db);
  });

  testWidgets('with Premium there is never an ad, and every chapter still opens', (tester) async {
    final ads = TestAdGateway();
    final (db, _) = await _boot(tester, ads, premium: true);

    await tester.tap(find.text('Read Now'));
    await settle(tester, frames: 20);
    expect(ads.shown, 0);
    expect(find.text('Tap to begin'), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('leaving a chapter before it starts marks nothing read, and no chapter is ever locked behind a price', (tester) async {
    final ads = TestAdGateway();
    final (db, repo) = await _boot(tester, ads);

    await tester.tap(find.text('Read Now'));
    await settle(tester, frames: 20);
    await tester.tap(find.byTooltip('Leave the Story'));
    await settle(tester, frames: 20);
    expect(await tester.runAsync(() => repo.watchStoryRead().first), isEmpty);
    // Opening is by level and nothing else: the first chapter never needed Premium.
    expect(_prologue.unlockLevel, 1);
    await shutDown(tester, db);
  });
}
