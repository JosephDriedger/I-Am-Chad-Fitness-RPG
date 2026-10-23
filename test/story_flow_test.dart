import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/story.dart';

import 'helpers.dart';

final _prologue = Story.chapters.first;

Future<(AppDatabase, GameRepository)> _boot(WidgetTester tester, {bool offer = false}) async {
  usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = GameRepository(db);
  await tester.runAsync(() => repo.createHero(const HeroProfile(
        name: 'Ada',
        appearanceStyle: 0,
        appearanceColor: 0,
        experience: ExperienceLevel.returning,
        preferredCategories: {ActivityCategory.cardio},
        hasDumbbells: false,
      )));
  await bootApp(tester, db, storyOffers: offer);
  return (db, repo);
}

/// Reads on until the closing card, picking the first answer when asked.
Future<void> _readToEnd(WidgetTester tester) async {
  final firstAnswers = <String>{
    for (final s in _prologue.scenes)
      for (final n in s.nodes)
        if (n is StoryChoice) n.options.first.label,
  };
  for (var i = 0; i < 300; i++) {
    if (find.text('Back to the Hall').evaluate().isNotEmpty) return;
    final answer = firstAnswers.where((a) => find.text(a).evaluate().isNotEmpty);
    if (answer.isNotEmpty) {
      await tester.tap(find.text(answer.first));
    } else {
      await tester.tapAt(const Offset(225, 300));
    }
    await settle(tester, frames: 3);
  }
  fail('the prologue never reached its end card');
}

void main() {
  testWidgets('the hall offers an unread chapter, and Later leaves it unread', (tester) async {
    final (db, repo) = await _boot(tester, offer: true);

    expect(find.text('A New Chapter!'), findsOneWidget);
    expect(find.textContaining(_prologue.title), findsOneWidget);

    await tester.tap(find.text('Later'));
    await settle(tester);
    expect(find.text('A New Chapter!'), findsNothing);
    expect(await tester.runAsync(() => repo.watchStoryRead().first), isEmpty);

    await shutDown(tester, db);
  });

  testWidgets('reading a chapter through marks it read and remembers the answers', (tester) async {
    final (db, repo) = await _boot(tester, offer: true);

    await tester.tap(find.text('Read Now'));
    await settle(tester, frames: 20);
    expect(find.text(_prologue.label), findsOneWidget);
    expect(find.text(_prologue.title), findsOneWidget);
    expect(find.text('Tap to begin'), findsOneWidget);

    await tester.tapAt(const Offset(225, 300));
    await settle(tester);
    await _readToEnd(tester);

    expect(find.text('${_prologue.label} Complete'), findsOneWidget);
    expect(find.textContaining('opens at Level'), findsOneWidget);
    final read = await tester.runAsync(() => repo.watchStoryRead().first);
    final choices = await tester.runAsync(() => repo.watchStoryChoices().first);
    expect(read, {0});
    expect(choices!.keys, containsAll(['motivation', 'help']));

    await tester.tap(find.text('Back to the Hall'));
    await settle(tester, frames: 20);
    expect(find.text('A New Chapter!'), findsNothing);

    await shutDown(tester, db);
  });

  testWidgets('skipping counts as read, and leaving with the cross does not', (tester) async {
    final (db, repo) = await _boot(tester, offer: true);

    await tester.tap(find.text('Read Now'));
    await settle(tester, frames: 20);
    await tester.tap(find.byTooltip('Leave the Story'));
    await settle(tester, frames: 20);
    expect(await tester.runAsync(() => repo.watchStoryRead().first), isEmpty);

    // Offered again from the Chronicle on the Quests screen.
    await tester.tap(find.text('Quests'));
    await settle(tester, frames: 30);
    await tester.scrollUntilVisible(find.text('Open the Chronicle'), 300,
        scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(find.text('Read ${_prologue.label}'));
    await settle(tester, frames: 2);
    await tester.tap(find.text('Read ${_prologue.label}'));
    await settle(tester, frames: 20);
    await tester.tap(find.text('Skip'));
    await settle(tester, frames: 20);
    expect(await tester.runAsync(() => repo.watchStoryRead().first), {0});

    await shutDown(tester, db);
  });

  testWidgets('the Chronicle lists every chapter, hides locked titles and allows a replay', (tester) async {
    final (db, repo) = await _boot(tester);
    await tester.runAsync(() => repo.markChapterRead(0, at: DateTime(2026, 10, 22)));

    await tester.tap(find.text('Quests'));
    await settle(tester, frames: 30);
    await tester.scrollUntilVisible(find.text('Open the Chronicle'), 300,
        scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(find.text('Open the Chronicle'));
    await settle(tester, frames: 2);
    await tester.tap(find.text('Open the Chronicle'));
    await settle(tester, frames: 30);

    expect(find.text(Story.seasonTitle), findsOneWidget);
    expect(find.text(_prologue.title), findsOneWidget);
    expect(find.text('Read Again'), findsOneWidget);
    // Chapters still to come say when they open, and keep their titles secret.
    final second = Story.chapters[2];
    expect(find.text('Opens at Level ${second.unlockLevel}'), findsWidgets);
    expect(find.text(second.title), findsNothing);

    await tester.tap(find.text('Read Again'));
    await settle(tester, frames: 20);
    expect(find.text('Tap to begin'), findsOneWidget);

    await shutDown(tester, db);
  });
}
