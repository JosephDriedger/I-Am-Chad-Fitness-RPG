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

/// The same sensible, unspectacular player as the balance test, who knows what
/// their style is good at: a Striker does not guard to build focus it cannot get.
BattleAction _bot(BattleState s) {
  final hurt = s.player.hp < s.player.maxHp * 0.7;
  if (s.player.hp < s.player.maxHp * 0.35 && s.canUseItem) return BattleAction.item;
  switch (s.intent) {
    case EnemyMove.windUp:
    case EnemyMove.flurry:
      if (hurt) return BattleAction.guard;
    case EnemyMove.brace:
      // Guarding builds focus while a brace soaks up a blow, unless guarding builds none.
      return s.style.guardFocus > 0 ? BattleAction.guard : BattleAction.attack;
    case EnemyMove.mend:
    case EnemyMove.strike:
      break;
  }
  if (s.canUseSkill) return BattleAction.skill;
  return BattleAction.attack;
}

bool _play(int seed, int level, int tier, FightingStyle style) {
  final run = ExpeditionRun(
    expedition: Expedition.generate(seed: seed, heroLevel: level, tier: tier),
    hero: _hero(level),
    rng: GameRng(seed + 1),
  )..style = style;
  while (!run.finished) {
    if (run.current!.kind == StepKind.event) {
      run.resolveEvent(choice: wayAtFork(run));
    } else {
      var s = run.startBattle();
      var guard = 0;
      while (!s.isOver && guard++ < 300) {
        s = BattleEngine.act(s, _bot(s), run.rng);
      }
      run.finishBattle(s);
    }
  }
  return run.victory;
}

double _rate(FightingStyle style, int level, int tier, {int n = 250}) {
  var wins = 0;
  for (var seed = 1; seed <= n; seed++) {
    if (_play(seed, level, tier, style)) wins++;
  }
  return wins / n;
}

void main() {
  group('the rules', () {
    BattleState fresh(FightingStyle style, {int focus = 0}) => BattleEngine.start(
          player: Combatant.fresh(name: 'Hero', maxHp: 1000, attack: 30, defense: 20),
          enemy: Combatant.fresh(name: 'Dummy', maxHp: 5000, attack: 1, defense: 1, behavior: const EnemyBehavior(heavy: 0)),
          rng: GameRng(1),
          focus: focus,
          style: style,
        );

    test('attacking and guarding build the focus each style says', () {
      for (final st in FightingStyle.values) {
        expect(BattleEngine.act(fresh(st), BattleAction.attack, GameRng(2)).focus, st.attackFocus, reason: st.id);
        expect(BattleEngine.act(fresh(st), BattleAction.guard, GameRng(2)).focus, st.guardFocus, reason: st.id);
      }
    });

    test('a Power Strike costs what the style says, and cannot be used without it', () {
      for (final st in FightingStyle.values) {
        expect(fresh(st, focus: st.skillCost - 1).canUseSkill, isFalse, reason: st.id);
        final ready = fresh(st, focus: st.skillCost);
        expect(ready.canUseSkill, isTrue, reason: st.id);
        expect(BattleEngine.act(ready, BattleAction.skill, GameRng(3)).focus, 0, reason: st.id);
      }
    });

    test('the steady style is exactly the way the game has always fought', () {
      expect(FightingStyle.steady.attackFocus, 1);
      expect(FightingStyle.steady.guardFocus, 1);
      expect(FightingStyle.steady.skillCost, BattleState.skillCost);
      expect(FightingStyle.steady.skillMult, 2.0);
      // The same seed gives the same fight whether or not a style is passed.
      BattleState play(BattleState s) {
        final rng = GameRng(7);
        var guard = 0;
        while (!s.isOver && guard++ < 200) {
          s = BattleEngine.act(s, s.canUseSkill ? BattleAction.skill : BattleAction.attack, rng);
        }
        return s;
      }

      BattleState start({FightingStyle? style}) => style == null
          ? BattleEngine.start(
              player: Combatant.fresh(name: 'H', maxHp: 90, attack: 20, defense: 10),
              enemy: Combatant.fresh(name: 'E', maxHp: 80, attack: 18, defense: 8),
              rng: GameRng(5),
            )
          : BattleEngine.start(
              player: Combatant.fresh(name: 'H', maxHp: 90, attack: 20, defense: 10),
              enemy: Combatant.fresh(name: 'E', maxHp: 80, attack: 18, defense: 8),
              rng: GameRng(5),
              style: style,
            );
      expect(play(start()).log, play(start(style: FightingStyle.steady)).log);
    });

    test('the buttons say what the style does', () {
      expect(BattleAction.guard.helpFor(FightingStyle.striker), contains('no focus'));
      expect(BattleAction.guard.helpFor(FightingStyle.guardian), contains('2 focus'));
      expect(BattleAction.attack.helpFor(FightingStyle.striker), contains('2 focus'));
      expect(BattleAction.skill.helpFor(FightingStyle.guardian), contains('3 focus'));
      expect(BattleAction.item.helpFor(FightingStyle.striker), BattleAction.item.help);
    });

    test('an unknown id falls back to steady, and every id is unique', () {
      expect(FightingStyle.fromId('nonsense'), FightingStyle.steady);
      expect(FightingStyle.fromId('guardian'), FightingStyle.guardian);
      expect(FightingStyle.values.map((s) => s.id).toSet(), hasLength(FightingStyle.values.length));
    });
  });

  group('no style is the way to win', () {
    // The same few regions and levels each time, from the first region to a late one.
    const cases = <(int, int)>[(1, 5), (3, 14), (5, 28), (7, 54)];
    late final Map<FightingStyle, List<double>> rates;

    setUpAll(() {
      rates = {
        for (final st in FightingStyle.values) st: [for (final (tier, level) in cases) _rate(st, level, tier)],
      };
    });

    double avg(FightingStyle s) => rates[s]!.reduce((a, b) => a + b) / cases.length;

    test('on average each wins about as often as the steady style', () {
      for (final st in FightingStyle.values) {
        expect((avg(st) - avg(FightingStyle.steady)).abs(), lessThan(0.06), reason: '${st.id}: $rates');
      }
    });

    test('and in no region is one far ahead or far behind', () {
      for (var i = 0; i < cases.length; i++) {
        for (final st in FightingStyle.values) {
          expect((rates[st]![i] - rates[FightingStyle.steady]![i]).abs(), lessThan(0.12), reason: '${st.id} in region ${cases[i].$1}: $rates');
        }
      }
    });

    test('every style stays beatable and none is a wall', () {
      for (final st in FightingStyle.values) {
        for (final r in rates[st]!) {
          expect(r, greaterThan(0.4), reason: st.id);
        }
      }
    });
  });
}
