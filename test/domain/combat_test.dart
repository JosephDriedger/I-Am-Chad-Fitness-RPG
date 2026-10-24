import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/combat.dart';
import 'package:i_am_chad/domain/expedition.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/rng.dart';

import 'fork_policy.dart';

Combatant _hero(int level) => Combatant.fresh(
      name: 'Hero',
      maxHp: Progression.maxHp(level),
      attack: Progression.attack(level),
      defense: Progression.defense(level),
    );

/// A reasonable but unspectacular player: guards against heavy blows,
/// uses Power Strike when it can, and heals when low.
BattleAction _bot(BattleState s) {
  if (s.player.hp < s.player.maxHp * 0.35 && s.canUseItem) {
    return BattleAction.item;
  }
  if (s.intent == EnemyMove.windUp && s.player.hp < s.player.maxHp * 0.7) {
    return BattleAction.guard;
  }
  if (s.canUseSkill) return BattleAction.skill;
  return BattleAction.attack;
}

BattleState _fight(BattleState s, GameRng rng) {
  var guard = 0;
  while (!s.isOver && guard++ < 200) {
    s = BattleEngine.act(s, _bot(s), rng);
  }
  return s;
}

ExpeditionRun _run(int seed, int level) {
  final run = ExpeditionRun(
    expedition: Expedition.generate(seed: seed, heroLevel: level),
    hero: _hero(level),
    rng: GameRng(seed + 1),
  );
  while (!run.finished) {
    if (run.current!.kind == StepKind.event) {
      run.resolveEvent(choice: wayAtFork(run));
    } else {
      run.finishBattle(_fight(run.startBattle(), run.rng));
    }
  }
  return run;
}

void main() {
  eventTests();
  group('GameRng', () {
    test('same seed gives same sequence; different seeds differ', () {
      final a = GameRng(42), b = GameRng(42), c = GameRng(43);
      final sa = [for (var i = 0; i < 20; i++) a.nextInt(1000)];
      expect([for (var i = 0; i < 20; i++) b.nextInt(1000)], sa);
      expect([for (var i = 0; i < 20; i++) c.nextInt(1000)], isNot(sa));
    });

    test('nextInt stays in range and covers it', () {
      final r = GameRng(7);
      final seen = <int>{};
      for (var i = 0; i < 500; i++) {
        final v = r.nextInt(6);
        expect(v, inInclusiveRange(0, 5));
        seen.add(v);
      }
      expect(seen.length, 6);
    });

    test('shuffle keeps all elements', () {
      final l = GameRng(1).shuffle([1, 2, 3, 4, 5, 6]);
      expect(l..sort(), [1, 2, 3, 4, 5, 6]);
    });
  });

  group('BattleEngine', () {
    BattleState start({int level = 1}) => BattleEngine.start(
          player: _hero(level),
          enemy: EnemyPool.regular.first.build(level),
          rng: GameRng(3),
        );

    test('is deterministic for a given seed and action list', () {
      BattleState play() {
        final rng = GameRng(99);
        var s = BattleEngine.start(
          player: _hero(1),
          enemy: EnemyPool.regular[2].build(1),
          rng: rng,
        );
        for (final a in [
          BattleAction.attack,
          BattleAction.guard,
          BattleAction.attack,
          BattleAction.skill,
        ]) {
          s = BattleEngine.act(s, a, rng);
        }
        return s;
      }

      final x = play(), y = play();
      expect(x.player.hp, y.player.hp);
      expect(x.enemy.hp, y.enemy.hp);
      expect(x.log, y.log);
    });

    test('skill needs focus; item needs potions and missing health', () {
      final s = start();
      expect(s.canUseSkill, isFalse);
      expect(s.canUseItem, isFalse);
      final unchanged = BattleEngine.act(s, BattleAction.skill, GameRng(1));
      expect(identical(unchanged, s), isTrue);
    });

    test('attack and guard build focus up to the cap', () {
      final rng = GameRng(5);
      var s = BattleEngine.start(
        player: Combatant.fresh(name: 'T', maxHp: 9999, attack: 1, defense: 99),
        enemy: Combatant.fresh(name: 'E', maxHp: 9999, attack: 1, defense: 99),
        rng: rng,
      );
      for (var i = 0; i < 10; i++) {
        s = BattleEngine.act(s, BattleAction.guard, rng);
      }
      expect(s.focus, BattleState.maxFocus);
    });

    test('guarding reduces damage taken', () {
      int taken(BattleAction a) {
        final rng = GameRng(11);
        final s = BattleEngine.start(
          player: Combatant.fresh(name: 'T', maxHp: 500, attack: 1, defense: 0),
          enemy:
              Combatant.fresh(name: 'E', maxHp: 500, attack: 40, defense: 99),
          rng: rng,
        );
        final after = BattleEngine.act(s, a, rng);
        return 500 - after.player.hp;
      }

      expect(taken(BattleAction.guard), lessThan(taken(BattleAction.attack)));
    });

    test('potion heals but cannot exceed max HP, and is consumed', () {
      final rng = GameRng(2);
      var s = BattleEngine.start(
        player: Combatant.fresh(name: 'T', maxHp: 90, attack: 1, defense: 99)
            .withHp(10),
        enemy: Combatant.fresh(name: 'E', maxHp: 999, attack: 1, defense: 99),
        rng: rng,
      );
      s = BattleEngine.act(s, BattleAction.item, rng);
      expect(s.potions, 1);
      expect(s.player.hp, greaterThan(10));
      expect(s.player.hp, lessThanOrEqualTo(90));
    });

    test('finished battles ignore further actions', () {
      final rng = GameRng(8);
      var s = BattleEngine.start(
        player: Combatant.fresh(name: 'T', maxHp: 99, attack: 500, defense: 5),
        enemy: Combatant.fresh(name: 'E', maxHp: 5, attack: 1, defense: 0),
        rng: rng,
      );
      s = BattleEngine.act(s, BattleAction.attack, rng);
      expect(s.phase, BattlePhase.victory);
      expect(
          identical(BattleEngine.act(s, BattleAction.attack, rng), s), isTrue);
    });
  });

  group('Expedition', () {
    test('same seed + level reproduces the same expedition', () {
      final a = Expedition.generate(seed: 123, heroLevel: 4);
      final b = Expedition.generate(seed: 123, heroLevel: 4);
      expect(a.lootItemId, b.lootItemId);
      expect([for (final s in a.steps) s.enemy?.name ?? s.event!.title],
          [for (final s in b.steps) s.enemy?.name ?? s.event!.title]);
    });

    test('has three battles ending in a boss with one event between', () {
      for (var seed = 0; seed < 50; seed++) {
        final e = Expedition.generate(seed: seed, heroLevel: 1);
        expect(e.battleCount, 3);
        expect(e.steps[1].kind, StepKind.event);
        expect(e.steps.last.enemy!.boss, isTrue);
        final names = [
          for (final s in e.steps)
            if (s.enemy != null) s.enemy!.name
        ];
        expect(names.toSet().length, names.length, reason: 'no repeat foes');
      }
    });

    test('varied seeds give varied encounters', () {
      final firsts = {
        for (var s = 0; s < 40; s++)
          Expedition.generate(seed: s, heroLevel: 1).steps.first.enemy!.name
      };
      expect(firsts.length, greaterThan(2));
    });
  });

  group('Balance (bot policy)', () {
    for (final level in [1, 5, 15, 40]) {
      test('level $level: a sensible player usually clears an expedition', () {
        var wins = 0;
        const n = 200;
        for (var seed = 0; seed < n; seed++) {
          if (_run(seed, level).victory) wins++;
        }
        final rate = wins / n;
        // Never a wall. This script is deliberately simple: it ignores the newer enemy
        // moves (flurry, brace, mend), so it plays worse than the one in balance_test.dart,
        // which is the real guard on the curve. About 90% at level 1 and 70% or more later (see docs/ROADMAP.md).
        expect(rate, inInclusiveRange(0.65, 1.0),
            reason: 'win rate at level $level was $rate');
      });
    }
  });
}

void eventTests() {
  group('BattleEvent', () {
    test('every action reports what happened, in order', () {
      final rng = GameRng(21);
      var s = BattleEngine.start(
        player: Combatant.fresh(name: 'T', maxHp: 300, attack: 10, defense: 5),
        enemy: Combatant.fresh(name: 'E', maxHp: 900, attack: 12, defense: 2),
        rng: rng,
      );
      s = BattleEngine.act(s, BattleAction.attack, rng);
      expect(s.events.first, isA<PlayerAttacked>());
      expect(s.events[1], isA<EnemyAttacked>());
      expect((s.events.first as PlayerAttacked).damage, greaterThan(0));

      s = BattleEngine.act(s, BattleAction.guard, rng);
      expect(s.events.first, isA<PlayerGuarded>());
      expect((s.events[1] as EnemyAttacked).guarded, isTrue);

      s = BattleEngine.act(s, BattleAction.attack, rng);
      s = BattleEngine.act(s, BattleAction.skill, rng);
      expect(s.events.first, isA<PlayerUsedSkill>());

      s = BattleEngine.act(s, BattleAction.item, rng);
      expect(s.events.first, isA<PlayerHealed>());
    });

    test('a kill ends with EnemyDefeated and no enemy reply', () {
      final rng = GameRng(4);
      final s = BattleEngine.act(
        BattleEngine.start(
          player: Combatant.fresh(name: 'T', maxHp: 99, attack: 500, defense: 5),
          enemy: Combatant.fresh(name: 'E', maxHp: 5, attack: 9, defense: 0),
          rng: rng,
        ),
        BattleAction.attack,
        rng,
      );
      expect(s.events.map((e) => e.runtimeType), [PlayerAttacked, EnemyDefeated]);
    });

    test('being knocked out ends with PlayerDefeated', () {
      final rng = GameRng(4);
      final s = BattleEngine.act(
        BattleEngine.start(
          player: Combatant.fresh(name: 'T', maxHp: 1, attack: 1, defense: 0),
          enemy: Combatant.fresh(name: 'E', maxHp: 999, attack: 99, defense: 99),
          rng: rng,
        ),
        BattleAction.attack,
        rng,
      );
      expect(s.events.last, isA<PlayerDefeated>());
      expect(s.phase, BattlePhase.defeat);
    });
  });
}
