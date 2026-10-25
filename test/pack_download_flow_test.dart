import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/content_packs.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/story.dart';
import 'package:i_am_chad/features/story/chronicle_screen.dart';

import 'helpers.dart';

final _chapter = Story.byNumber(8)!; // Season Two's prologue.

Future<AppDatabase> _boot(
  WidgetTester tester, {
  TestPackSource? source,
  PackStore? store,
  bool usePhoneSurface = true,
}) async {
  if (usePhoneSurface) usePhone(tester);
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
    // Plenty of experience, so every chapter is open.
    await repo.recordExpedition(seed: 1, victory: true, battlesWon: 3, xp: 200000, coins: 0, lootItemId: '');
    for (var n = 0; n < 8; n++) {
      await repo.markChapterRead(n, at: DateTime(2026, 10, 1));
    }
  });
  await bootApp(tester, db, packSource: source ?? TestPackSource(packs: publishedPacks()), packStore: store ?? MemoryPackStore());
  return db;
}

void _open(WidgetTester tester, StoryChapter chapter) {
  final context = tester.element(find.byTooltip('Settings'));
  // ignore: unawaited_futures
  openChapter(context, chapter);
}

Future<void> _openChronicle(WidgetTester tester) async {
  await tester.tap(find.text('Quests'));
  await settle(tester, frames: 30);
  await tester.scrollUntilVisible(find.text('Open the Chronicle'), 300, scrollable: find.byType(Scrollable).last);
  await tester.ensureVisible(find.text('Open the Chronicle'));
  await settle(tester, frames: 2);
  await tester.tap(find.text('Open the Chronicle'));
  await settle(tester, frames: 30);
}

void main() {
  testWidgets('a season that is not on the phone is offered with its size, downloads, and then opens', (tester) async {
    final store = MemoryPackStore();
    final db = await _boot(tester, store: store);

    _open(tester, _chapter);
    await settle(tester, frames: 20);
    expect(find.text('Download Season Two?'), findsOneWidget);
    expect(find.text(Story.seasonOf(2).title), findsOneWidget);
    expect(find.textContaining('KB'), findsOneWidget, reason: 'the size is stated before anything is downloaded');
    expect(find.textContaining('only do this once'), findsOneWidget);
    expect(find.textContaining('Nothing about you is sent'), findsOneWidget);
    expect(store.files, isEmpty, reason: 'nothing is downloaded until the player says so');

    await tester.tap(find.byKey(const Key('pack_download')));
    await settle(tester, frames: 40);
    expect(find.text('Download Season Two?'), findsNothing);
    expect(find.text(_chapter.title), findsOneWidget, reason: 'the chapter opens straight away');
    expect(find.text('Tap to begin'), findsOneWidget);
    expect(store.files.keys, [2]);

    await shutDown(tester, db);
  });

  testWidgets('a season already on the phone opens with no question', (tester) async {
    final db = await _boot(tester, store: MemoryPackStore(publishedPacks()));
    _open(tester, _chapter);
    await settle(tester, frames: 40);
    expect(find.textContaining('Download'), findsNothing);
    expect(find.text('Tap to begin'), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('Season One is part of the app and never asks', (tester) async {
    final source = TestPackSource(packs: publishedPacks());
    final db = await _boot(tester, source: source);
    _open(tester, Story.chapters.first);
    await settle(tester, frames: 40);
    expect(find.textContaining('Download'), findsNothing);
    expect(find.text('Tap to begin'), findsOneWidget);
    expect(source.manifestRequests, 0, reason: 'nothing is fetched');
    await shutDown(tester, db);
  });

  testWidgets('Not Now leaves the chapter unread and loses nothing', (tester) async {
    final store = MemoryPackStore();
    final source = TestPackSource(packs: publishedPacks());
    final db = await _boot(tester, source: source, store: store);
    _open(tester, _chapter);
    await settle(tester, frames: 20);
    await tester.tap(find.byKey(const Key('pack_not_now')));
    await settle(tester, frames: 20);
    expect(find.text('Download Season Two?'), findsNothing);
    expect(find.text('Tap to begin'), findsNothing);
    expect(store.files, isEmpty);
    expect(source.fileRequests, 0);
    await shutDown(tester, db);
  });

  testWidgets('with no connection it says so kindly, and trying again works once there is one', (tester) async {
    final source = TestPackSource(packs: publishedPacks(), problem: PackProblem.offline);
    final store = MemoryPackStore();
    final db = await _boot(tester, source: source, store: store);
    _open(tester, _chapter);
    await settle(tester, frames: 20);

    expect(find.textContaining('could not be reached'), findsOneWidget);
    expect(find.textContaining('Nothing is lost'), findsOneWidget);
    expect(find.byKey(const Key('pack_download')), findsNothing);

    source.problem = null;
    await tester.tap(find.byKey(const Key('pack_retry')));
    await settle(tester, frames: 20);
    expect(find.textContaining('KB'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pack_download')));
    await settle(tester, frames: 40);
    expect(find.text('Tap to begin'), findsOneWidget);
    expect(store.files.keys, [2]);
    await shutDown(tester, db);
  });

  testWidgets('a download that comes back damaged is not kept, and can be tried again', (tester) async {
    final source = TestPackSource(packs: publishedPacks());
    final store = MemoryPackStore();
    final db = await _boot(tester, source: source, store: store);
    final good = publishedPacks()[2]!;
    _open(tester, _chapter);
    await settle(tester, frames: 20);
    source.corrupt(2, Uint8List.fromList(List.filled(good.length, 65)));
    await tester.tap(find.byKey(const Key('pack_download')));
    await settle(tester, frames: 20);
    expect(find.textContaining('did not arrive in one piece'), findsOneWidget);
    expect(store.files, isEmpty);
    expect(find.byKey(const Key('pack_retry')), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('a pack for a newer game asks for an update instead of offering a retry', (tester) async {
    final source = TestPackSource(packs: publishedPacks(), problem: PackProblem.newerApp);
    final db = await _boot(tester, source: source);
    _open(tester, _chapter);
    await settle(tester, frames: 20);
    expect(find.textContaining('newer version of the game'), findsOneWidget);
    expect(find.byKey(const Key('pack_retry')), findsNothing);
    expect(find.byKey(const Key('pack_not_now')), findsOneWidget);
    await shutDown(tester, db);
  });

  testWidgets('the Chronicle says a season downloads once, and stops saying it after', (tester) async {
    final db = await _boot(tester, store: MemoryPackStore());
    await _openChronicle(tester);
    await tester.scrollUntilVisible(find.text(_chapter.title), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text('Downloads once, the first time you read it.'), findsWidgets);
    await shutDown(tester, db);

    final installed = await _boot(tester, store: MemoryPackStore(publishedPacks()), usePhoneSurface: false);
    await _openChronicle(tester);
    await tester.scrollUntilVisible(find.text(_chapter.title), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text('Downloads once, the first time you read it.'), findsNothing);
    await shutDown(tester, installed);
  });

  testWidgets('the download card fits a small phone at large text, in every state', (tester) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final source = TestPackSource(packs: publishedPacks(), problem: PackProblem.offline);
    final db = await _boot(tester, source: source, usePhoneSurface: false);

    _open(tester, _chapter);
    await settle(tester, frames: 20);
    expect(tester.takeException(), isNull, reason: 'the offline message');
    expect(find.byKey(const Key('pack_retry')), findsOneWidget);

    source.problem = null;
    // At this size the card scrolls, so bring the button into view first.
    await tester.ensureVisible(find.byKey(const Key('pack_retry')));
    await settle(tester, frames: 4);
    await tester.tap(find.byKey(const Key('pack_retry')));
    await settle(tester, frames: 20);
    expect(tester.takeException(), isNull, reason: 'the offer');
    expect(find.byKey(const Key('pack_download')), findsOneWidget);
    await shutDown(tester, db);
  });
}
