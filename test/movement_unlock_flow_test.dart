import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/app.dart';
import 'package:i_am_chad/app/providers.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/story.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

/// Season Seven opens by days of movement after the Season Six finale was read, because
/// the levels have run out. These check the real providers, from the saved journal.
final _now = DateTime(2026, 12, 20, 10);

Future<AppDatabase> _boot(WidgetTester tester, {required int daysMoved, bool finaleRead = true, int readThrough = 47}) async {
  usePhone(tester);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await tester.runAsync(() async {
    final repo = GameRepository(db);
    await repo.createHero(const HeroProfile(
      name: 'Ada',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.regular,
      preferredCategories: {},
      hasDumbbells: false,
    ));
    // Level 144, with the whole story up to the Season Six finale read on 1 December.
    await repo.recordExpedition(seed: 1, victory: true, battlesWon: 3, xp: Progression.xpForLevel(144), coins: 0, lootItemId: '');
    if (finaleRead) {
      for (var n = 0; n <= readThrough; n++) {
        await repo.markChapterRead(n, at: DateTime(2026, 12, 1, 20));
      }
    }
    // The day it was read, and then one walk on each of the next [daysMoved] days.
    await repo.addWorkout(WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 12, 1, 9), durationSeconds: 600));
    for (var d = 0; d < daysMoved; d++) {
      await repo.addWorkout(WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 12, 2 + d, 9), durationSeconds: 600));
    }
  });
  await bootApp(tester, db, now: _now);
  await settle(tester, frames: 20);
  return db;
}

StoryStatus _status(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(IAmChadApp))).read(storyStatusProvider)!;

void main() {
  testWidgets('once the finale is read, the prologue opens, and the rest wait for days of moving', (tester) async {
    final db = await _boot(tester, daysMoved: 0);
    final s = _status(tester);
    expect(s.isUnlocked(Story.byNumber(48)!), isTrue);
    expect(s.isUnlocked(Story.byNumber(49)!), isFalse);
    expect(s.whenOpens(Story.byNumber(49)!), 'after 10 more days of moving');
    expect(s.next!.number, 49);
    await shutDown(tester, db);
  });

  testWidgets('each day moved after reading counts, and the day of reading does not', (tester) async {
    final db = await _boot(tester, daysMoved: 10);
    final s = _status(tester);
    expect(s.daysSince[47], 10, reason: 'ten days after the day of reading');
    expect(s.isUnlocked(Story.byNumber(49)!), isTrue);
    expect(s.isUnlocked(Story.byNumber(50)!), isFalse);
    expect(s.whenOpens(Story.byNumber(50)!), 'after 10 more days of moving');
    await shutDown(tester, db);
  });

  testWidgets('with the finale not yet read, none of Season Seven is open, and it says why', (tester) async {
    final db = await _boot(tester, daysMoved: 5, finaleRead: false);
    final s = _status(tester);
    expect(s.isUnlocked(Story.byNumber(48)!), isFalse);
    expect(s.whenOpens(Story.byNumber(48)!), 'once The Comet Road is read');
    await shutDown(tester, db);
  });

  testWidgets('the Chronicle shows how many days are left, kindly, for the next chapter', (tester) async {
    // The whole story up to the prologue of Season Seven has been read, so the Chronicle has
    // caught up and says what is next.
    final db = await _boot(tester, daysMoved: 3, readThrough: 48);
    await tester.tap(find.text('Quests'));
    await settle(tester, frames: 30);
    final panel = find.text('Chronicle');
    await tester.scrollUntilVisible(panel, 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(panel);
    await settle(tester, frames: 3);
    expect(find.textContaining('opens after 7 more days of moving'), findsWidgets);
    expect(find.textContaining('Level 144'), findsNothing);
    await shutDown(tester, db);
  });
}
