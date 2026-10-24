import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/story.dart';
import 'package:i_am_chad/features/story/chronicle_screen.dart';

import 'helpers.dart';

/// Reading is most of what the story is, so it has to work on a small phone at the
/// largest text and on a phone held sideways. Each chapter here is read through,
/// line by line, with every choice answered, and the test fails on any exception
/// and if an option cannot be reached and tapped.
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

/// The chapters to read: one with several choices from each season, and the
/// chapter with the longest single line, which is the hardest to fit.
List<StoryChapter> _chapters() {
  int choices(StoryChapter c) => [for (final s in c.scenes) ...s.nodes.whereType<StoryChoice>()].length;
  int longest(StoryChapter c) => [
        for (final s in c.scenes) ...s.nodes.whereType<StoryLine>().map((l) => l.text.length),
      ].fold(0, (a, b) => a > b ? a : b);
  final picked = <StoryChapter>{};
  for (final season in Story.seasons) {
    final inSeason = Story.inSeason(season.number);
    picked.add(inSeason.reduce((a, b) => choices(b) > choices(a) ? b : a));
  }
  picked.add(Story.chapters.reduce((a, b) => longest(b) > longest(a) ? b : a));
  return picked.toList();
}

void main() {
  for (final s in _setups) {
    testWidgets('reading fits: ${s.name}', (tester) async {
      tester.view.physicalSize = Size(s.width * 2, s.height * 2);
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = s.textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.runAsync(() async {
        final repo = GameRepository(db);
        await repo.createHero(const HeroProfile(
          name: 'Ada the Very Long Named',
          appearanceStyle: 0,
          appearanceColor: 0,
          experience: ExperienceLevel.starting,
          preferredCategories: {},
          hasDumbbells: false,
        ));
        // Plenty of experience, so every chapter is open.
        await repo.recordExpedition(seed: 1, victory: true, battlesWon: 3, xp: 200000, coins: 0, lootItemId: '');
      });
      await bootApp(tester, db);

      for (final chapter in _chapters()) {
        final context = tester.element(find.byTooltip('Settings'));
        // ignore: unawaited_futures
        openChapter(context, chapter);
        await settle(tester, frames: 20);
        _noProblem(tester, 'opening ${chapter.title}');
        expect(find.text(chapter.title), findsWidgets, reason: 'the title card');

        await tester.tapAt(Offset(s.width / 2, s.height * 0.25)); // past the title card
        await settle(tester, frames: 5);

        var answered = 0;
        for (var i = 0; i < 400 && find.text('Back to the Hall').evaluate().isEmpty; i++) {
          // A choice, if one is showing: every option must be reachable, then take the last.
          StoryChoice? showing;
          for (final scene in chapter.scenes) {
            for (final node in scene.nodes) {
              if (node is StoryChoice && find.text(node.prompt).evaluate().isNotEmpty) showing = node;
            }
          }
          if (showing != null) {
            for (final option in showing.options) {
              final f = find.text(option.label);
              expect(f, findsOneWidget, reason: '"${option.label}" in ${chapter.title}');
              await tester.ensureVisible(f);
              await tester.pump();
              await tester.ensureVisible(f);
              _noProblem(tester, 'showing "${option.label}"');
            }
            await tester.tap(find.text(showing.options.last.label));
            answered++;
          } else {
            await tester.tapAt(Offset(s.width / 2, s.height * 0.25));
          }
          await settle(tester, frames: 4);
          _noProblem(tester, '${chapter.title}, step $i');
        }
        expect(find.text('Back to the Hall'), findsOneWidget, reason: '${chapter.title} reaches its end card');
        final choices = [for (final sc in chapter.scenes) ...sc.nodes.whereType<StoryChoice>()].length;
        expect(answered, choices, reason: 'every choice in ${chapter.title} was shown and answered');

        await tester.ensureVisible(find.text('Back to the Hall'));
        await tester.tap(find.text('Back to the Hall'));
        await settle(tester, frames: 20);
        _noProblem(tester, 'leaving ${chapter.title}');
      }
      await shutDown(tester, db);
    });
  }
}
