import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/combat.dart';
import 'package:i_am_chad/domain/expedition.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/honesty.dart';
import 'package:i_am_chad/domain/rewards.dart';
import 'package:i_am_chad/domain/rng.dart';
import 'package:i_am_chad/domain/streaks.dart';
import 'package:i_am_chad/domain/workout.dart';

/// Random play, many times over, checking the promises the rules make.
void main() {
  const rules = RewardRules.v1;
  final random = math.Random(20261023);

  WorkoutEntry randomEntry(DateTime day) {
    final a = ActivityCatalog.all[random.nextInt(ActivityCatalog.all.length)];
    int? maybe(int max) => random.nextBool() ? null : random.nextInt(max);
    return WorkoutEntry(
      activityId: a.id,
      performedAt: day.add(Duration(minutes: random.nextInt(24 * 60))),
      sets: maybe(30),
      reps: maybe(200),
      durationSeconds: maybe(4 * 3600),
      distanceMeters: random.nextBool() ? null : random.nextDouble() * 50000,
      loadKg: random.nextBool() ? null : random.nextDouble() * 300,
    );
  }

  test('no day of any size pays more than the daily limits, and never goes negative', () {
    final day = DateTime(2026, 6, 1);
    for (var i = 0; i < 2000; i++) {
      final entries = [for (var n = random.nextInt(12); n > 0; n--) randomEntry(day)];
      final r = rules.rewardForDay(entries);
      expect(r.xp, inInclusiveRange(0, rules.maxDailyXp), reason: 'run $i');
      expect(r.energy, inInclusiveRange(0, rules.maxDailyEnergy), reason: 'run $i');
      expect(r.creditedMinutes, inInclusiveRange(0, rules.maxCreditedMinutes));
      expect(r.rawEffortMinutes.isFinite, isTrue);
    }
  });

  test('logging more never earns less', () {
    final day = DateTime(2026, 6, 1);
    for (var i = 0; i < 500; i++) {
      final entries = [for (var n = 1 + random.nextInt(6); n > 0; n--) randomEntry(day)];
      final before = rules.rewardForDay(entries);
      final after = rules.rewardForDay([...entries, randomEntry(day)]);
      expect(after.xp, greaterThanOrEqualTo(before.xp), reason: 'run $i');
      expect(after.energy, greaterThanOrEqualTo(before.energy), reason: 'run $i');
    }
  });

  test('the order of entries never changes the reward', () {
    final day = DateTime(2026, 6, 1);
    for (var i = 0; i < 300; i++) {
      final entries = [for (var n = 2 + random.nextInt(8); n > 0; n--) randomEntry(day)];
      final shuffled = [...entries]..shuffle(random);
      final a = rules.rewardForDay(entries), b = rules.rewardForDay(shuffled);
      expect(a.xp, b.xp);
      expect(a.energy, b.energy);
    }
  });

  test('every measured entry is worth something and nothing else is', () {
    for (var i = 0; i < 2000; i++) {
      final e = randomEntry(DateTime(2026, 6, 1));
      final m = rules.effortMinutes(e);
      if (e.hasMeasurement && e.activity != null && rules.unflooredEffortMinutes(e) > 0) {
        expect(m, greaterThanOrEqualTo(rules.minEffortPerEntry));
      } else {
        expect(m, 0);
      }
      expect(m.isFinite && !m.isNaN, isTrue);
    }
  });

  test('the honesty check never throws and only ever asks, whatever is typed', () {
    const check = HonestyCheck();
    for (var i = 0; i < 2000; i++) {
      final day = DateTime(2026, 6, 1);
      final e = randomEntry(day);
      final others = [for (var n = random.nextInt(6); n > 0; n--) randomEntry(day)];
      final notes = check.review(e, sameDay: others, metric: random.nextBool());
      for (final n in notes) {
        expect(n.text, isNotEmpty);
        expect(n.text, isNot(contains('NaN')));
        expect(n.text, isNot(contains('Infinity')));
      }
    }
  });

  group('streaks', () {
    test('a run never outlives the days that were really worked, and never regresses a best', () {
      for (var i = 0; i < 400; i++) {
        final today = DateTime(2026, 10, 23, 12);
        final count = random.nextInt(60);
        final entries = [
          for (var n = 0; n < count; n++)
            WorkoutEntry(
              activityId: 'walking',
              performedAt: today.subtract(Duration(days: random.nextInt(200))),
              durationSeconds: 600,
            )
        ];
        final workedDays = {for (final e in entries) dayKey(e.performedAt)}.length;
        for (final level in ExperienceLevel.values) {
          final s = StreakRules.evaluate(workouts: entries, today: today, experience: level);
          expect(s.current, lessThanOrEqualTo(s.best), reason: 'run $i');
          expect(s.best, lessThanOrEqualTo(workedDays), reason: 'run $i');
          expect(s.current, greaterThanOrEqualTo(0));
          expect(s.next!.days, greaterThan(s.current));
          expect(s.progressToNext, inInclusiveRange(0, 1));
        }
      }
    });

    test('milestones due are unique, reached and never already claimed', () {
      for (var current = 0; current < 1500; current += 1 + random.nextInt(40)) {
        final claimed = {
          for (var n = random.nextInt(8); n > 0; n--) StreakRules.milestones[random.nextInt(StreakRules.milestones.length)].days
        };
        final due = StreakRules.due(current: current, claimed: claimed);
        final days = due.map((m) => m.days).toList();
        expect(days.toSet().length, days.length, reason: 'current $current');
        for (final m in due) {
          expect(m.days, lessThanOrEqualTo(current));
          expect(claimed, isNot(contains(m.days)));
          expect(StreakRules.milestoneAt(m.days), isNotNull, reason: '${m.days}');
        }
      }
    });

    test('next and before bracket every day count', () {
      for (var d = 0; d < 2000; d++) {
        final next = StreakRules.nextAfter(d);
        expect(next.days, greaterThan(d));
        expect(StreakRules.milestoneAt(next.days), isNotNull, reason: 'after $d');
        final before = StreakRules.milestoneBefore(d);
        if (before != null) expect(before.days, lessThan(d));
      }
    });
  });

  group('combat', () {
    BattleAction pick(BattleState s) {
      final options = BattleAction.values.where(s.canAct).toList();
      return options[random.nextInt(options.length)];
    }

    test('random play always ends, and health and focus stay in bounds', () {
      for (var seed = 0; seed < 600; seed++) {
        final level = 1 + seed % 40;
        final rng = GameRng(seed);
        final expedition = Expedition.generate(seed: seed, heroLevel: level);
        final run = ExpeditionRun(
          expedition: expedition,
          hero: Combatant.fresh(
            name: 'Hero',
            maxHp: Progression.maxHp(level),
            attack: Progression.attack(level),
            defense: Progression.defense(level),
          ),
          rng: rng,
        );
        var guard = 0;
        while (!run.finished) {
          expect(++guard, lessThan(500), reason: 'seed $seed never ended');
          if (run.current!.kind == StepKind.event) {
            run.resolveEvent();
            continue;
          }
          var battle = run.startBattle();
          var turns = 0;
          while (!battle.isOver) {
            expect(++turns, lessThan(400), reason: 'seed $seed battle never ended');
            battle = BattleEngine.act(battle, pick(battle), rng);
            expect(battle.player.hp, inInclusiveRange(0, battle.player.maxHp));
            expect(battle.enemy.hp, inInclusiveRange(0, battle.enemy.maxHp));
            expect(battle.focus, inInclusiveRange(0, BattleState.maxFocus));
            expect(battle.potions, greaterThanOrEqualTo(0));
          }
          run.finishBattle(battle);
        }
        expect(run.victory, isNot(run.defeated));
        expect(run.xp, greaterThanOrEqualTo(0));
      }
    });

    test('the same seed always plays the same way', () {
      for (var seed = 0; seed < 50; seed++) {
        List<String> play() {
          final rng = GameRng(seed);
          final hero = Combatant.fresh(name: 'Hero', maxHp: 46, attack: 10, defense: 5);
          final enemy = EnemyPool.regular[seed % EnemyPool.regular.length].build(1);
          var s = BattleEngine.start(player: hero, enemy: enemy, rng: rng);
          final log = <String>[];
          while (!s.isOver) {
            s = BattleEngine.act(s, s.canUseSkill ? BattleAction.skill : BattleAction.attack, rng);
            log.addAll(s.log);
          }
          return log;
        }

        expect(play(), play());
      }
    });
  });

  test('levels climb smoothly and never skip or go backwards', () {
    var last = 1;
    for (var xp = 0; xp < 400000; xp += 37) {
      final level = Progression.levelForXp(xp);
      expect(level, greaterThanOrEqualTo(last));
      expect(level - last, lessThanOrEqualTo(1), reason: 'xp $xp');
      expect(Progression.levelProgress(xp), inInclusiveRange(0, 1));
      last = level;
    }
  });
}
