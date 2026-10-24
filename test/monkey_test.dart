import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/game_ui.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

/// Taps, types and goes back at random all over the real app, many times over.
/// It is not looking for anything in particular: any exception thrown while
/// the screens build or react fails the test, and the failing seed and step are
/// printed so the run can be replayed.
void main() {
  for (final seed in List.generate(12, (i) => i + 1)) {
    testWidgets('random play, seed $seed, never throws', (tester) async {
      final random = math.Random(seed);
      usePhone(tester);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = GameRepository(db);
      final now = DateTime(2026, 10, 22, 10);
      await tester.runAsync(() async {
        await repo.createHero(const HeroProfile(
          name: 'Ada',
          appearanceStyle: 0,
          appearanceColor: 0,
          experience: ExperienceLevel.returning,
          preferredCategories: {ActivityCategory.cardio, ActivityCategory.resistance},
          hasDumbbells: true,
        ));
        for (var d = 0; d < 6; d++) {
          await repo.addWorkout(WorkoutEntry(
            activityId: d.isEven ? 'walking' : 'push_up',
            performedAt: DateTime(2026, 10, 22 - d, 18),
            durationSeconds: d.isEven ? 900 : null,
            sets: d.isEven ? null : 3,
            reps: d.isEven ? null : 10,
          ));
        }
      });
      await bootApp(tester, db, now: now);

      final steps = <String>[];
      final visited = <String>{};
      // Things a player can press. Switches that delete or buy are left out:
      // "Delete All My Data" would just end the run, and purchases use a pretend store.
      final pressable = [
        find.byType(GameButton),
        find.byType(ChoiceChip),
        find.byType(ListTile),
        find.byType(IconButton),
        find.byType(Switch),
        find.byType(FilterChip),
      ];

      for (var step = 0; step < 160; step++) {
        final roll = random.nextInt(10);
        if (roll == 3) {
          // A tap anywhere at all, including on the game scenes.
          final size = tester.view.physicalSize / tester.view.devicePixelRatio;
          final p = Offset(random.nextDouble() * size.width, random.nextDouble() * size.height);
          steps.add('tap at ${p.dx.round()},${p.dy.round()}');
          await tester.tapAt(p);
        } else if (roll == 0) {
          steps.add('back');
          await tester.pageBack().catchError((Object _) {});
        } else if (roll == 1) {
          final fields = find.byType(TextField).evaluate().toList();
          if (fields.isNotEmpty) {
            final i = random.nextInt(fields.length);
            final text = ['', '0', '7', '12', '99999', 'abc', '3.5', '-4', ' '][random.nextInt(9)];
            steps.add('type "$text" in field $i');
            await tester.enterText(find.byType(TextField).at(i), text);
          }
        } else if (roll == 2) {
          steps.add('scroll');
          final s = find.byType(Scrollable).evaluate().toList();
          if (s.isNotEmpty) {
            await tester.drag(find.byType(Scrollable).at(random.nextInt(s.length)), Offset(0, random.nextBool() ? -300 : 300), warnIfMissed: false);
          }
        } else {
          final finder = pressable[random.nextInt(pressable.length)];
          final all = finder.evaluate().toList();
          if (all.isNotEmpty) {
            final i = random.nextInt(all.length);
            final label = all[i].widget.runtimeType;
            final target = finder.at(i);
            // Skip anything that deletes the save or sits off screen.
            final onScreen = tester.getRect(target).overlaps(Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio);
            final destructive = find.descendant(of: target, matching: find.textContaining('Delete All')).evaluate().isNotEmpty;
            if (onScreen && !destructive) {
              steps.add('tap $label #$i');
              await tester.tap(target, warnIfMissed: false);
            }
          }
        }
        await tester.pump(const Duration(milliseconds: 80));
        await tester.pump(const Duration(milliseconds: 80));
        for (final e in find.byType(GameScaffold).evaluate()) {
          visited.add((e.widget as GameScaffold).title);
        }
        final problem = tester.takeException();
        if (problem != null) {
          fail('seed $seed, step $step threw: $problem\nlast steps: ${steps.reversed.take(8).toList().reversed.join(' > ')}');
        }
      }

      // The random walk has to actually go places, or it proves nothing.
      expect(visited.length, greaterThanOrEqualTo(2), reason: 'only saw $visited');
      await shutDown(tester, db);
    });
  }
}
