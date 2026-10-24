import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/combat.dart';
import 'package:i_am_chad/domain/difficulty.dart';
import 'package:i_am_chad/domain/expedition.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/rng.dart';

Combatant _hero(int level) => Combatant.fresh(
      name: 'Hero',
      maxHp: Progression.maxHp(level),
      attack: Progression.attack(level),
      defense: Progression.defense(level),
    );

/// A sensible but unspectacular player with no gear: heals when low, guards
/// against heavy blows and double strikes when hurt, builds focus instead of
/// wasting a big hit on a brace, and hits hard while an enemy is mending.
BattleAction _bot(BattleState s) {
  final hurt = s.player.hp < s.player.maxHp * 0.7;
  if (s.player.hp < s.player.maxHp * 0.35 && s.canUseItem) return BattleAction.item;
  switch (s.intent) {
    case EnemyMove.windUp:
    case EnemyMove.flurry:
      if (hurt) return BattleAction.guard;
    case EnemyMove.brace:
      return BattleAction.guard;
    case EnemyMove.mend:
    case EnemyMove.strike:
      break;
  }
  if (s.canUseSkill) return BattleAction.skill;
  return BattleAction.attack;
}

BattleState _fight(BattleState s, GameRng rng) {
  var guard = 0;
  while (!s.isOver && guard++ < 300) {
    s = BattleEngine.act(s, _bot(s), rng);
  }
  return s;
}

/// Plays one expedition and reports whether it was cleared and how many turns
/// the longest battle took.
({bool won, int longest}) _play(int seed, int level, int tier) {
  final run = ExpeditionRun(
    expedition: Expedition.generate(seed: seed, heroLevel: level, tier: tier),
    hero: _hero(level),
    rng: GameRng(seed + 1),
  );
  var longest = 0;
  while (!run.finished) {
    if (run.current!.kind == StepKind.event) {
      run.resolveEvent();
    } else {
      final end = _fight(run.startBattle(), run.rng);
      if (end.turn > longest) longest = end.turn;
      run.finishBattle(end);
    }
  }
  return (won: run.victory, longest: longest);
}

double _winRate(int level, int tier, {int n = 250}) {
  var wins = 0;
  for (var seed = 1; seed <= n; seed++) {
    if (_play(seed, level, tier).won) wins++;
  }
  return wins / n;
}

/// Levels to try in each region: where it opens, a little later, and well past.
const _levels = <int, List<int>>{
  1: [1, 4, 10],
  2: [5, 9, 16],
  3: [10, 15, 24],
  4: [16, 22, 35],
  5: [24, 35, 60],
};

void main() {
  late final Map<int, List<double>> rates;

  setUpAll(() {
    rates = {
      for (final e in _levels.entries) e.key: [for (final l in e.value) _winRate(l, e.key)],
    };
  });

  double average(int tier) => rates[tier]!.reduce((a, b) => a + b) / rates[tier]!.length;

  test('each region is tougher than the one before, on average', () {
    for (var tier = 2; tier <= Difficulty.maxTier; tier++) {
      expect(average(tier), lessThan(average(tier - 1)), reason: 'region $tier should be harder than region ${tier - 1}');
    }
  });

  test('the first region is gentle, and no region is a wall for a sensible player with no gear', () {
    expect(average(1), greaterThan(0.85));
    for (final e in rates.entries) {
      for (final r in e.value) {
        expect(r, greaterThan(0.45), reason: 'region ${e.key} was too hard: ${e.value}');
      }
    }
    // The toughest region is still beatable most of the time.
    expect(average(Difficulty.maxTier), greaterThan(0.55));
  });

  test('the steps up are noticeable but not cliffs', () {
    for (var tier = 2; tier <= Difficulty.maxTier; tier++) {
      final drop = average(tier - 1) - average(tier);
      expect(drop, inInclusiveRange(0.02, 0.2), reason: 'region $tier dropped ${(drop * 100).round()} points');
    }
  });

  test('battles stay short enough for a phone: the longest takes under 30 turns', () {
    var longest = 0;
    for (final e in _levels.entries) {
      for (var seed = 1; seed <= 60; seed++) {
        final r = _play(seed, e.value.first, e.key);
        if (r.longest > longest) longest = r.longest;
      }
    }
    expect(longest, lessThan(30));
  });

  test('higher regions bring the new tactics, and the first region has none of them', () {
    bool hasTactics(int tier) => EnemyPool.regularFor(tier).any((e) {
          final b = e.behavior;
          return b.flurry > 0 || b.brace > 0 || b.mend > 0;
        });
    expect(hasTactics(1), isFalse);
    for (var tier = 2; tier <= Difficulty.maxTier; tier++) {
      expect(hasTactics(tier), isTrue, reason: 'region $tier');
    }
  });
}
