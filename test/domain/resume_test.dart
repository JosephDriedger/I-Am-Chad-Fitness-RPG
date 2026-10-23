import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/combat.dart';
import 'package:i_am_chad/domain/expedition.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/rng.dart';

Combatant _hero(int level) => Combatant.fresh(
      name: 'Hero',
      maxHp: Progression.maxHp(level),
      attack: Progression.attack(level),
      defense: Progression.defense(level),
    );

void main() {
  test('a fresh expedition starts at step 0 with full HP and two potions', () {
    final p = ExpeditionProgress.fresh(seed: 5, heroLevel: 3, heroMaxHp: 60);
    expect(p.stepIndex, 0);
    expect(p.heroHp, 60);
    expect(p.potions, 2);
    expect(p.xp, 0);
    expect(p.coins, 0);
  });

  test('the expedition is regenerated identically from a saved seed', () {
    final p = ExpeditionProgress.fresh(seed: 77, heroLevel: 4, heroMaxHp: 66);
    final a = p.expedition, b = Expedition.generate(seed: 77, heroLevel: 4);
    expect(a.lootItemId, b.lootItemId);
    expect([for (final s in a.steps) s.enemy?.name ?? s.event!.title],
        [for (final s in b.steps) s.enemy?.name ?? s.event!.title]);
  });

  test('progress survives a save and restore exactly', () {
    final exp = Expedition.generate(seed: 123, heroLevel: 2);
    final run = ExpeditionRun(expedition: exp, hero: _hero(2), rng: GameRng(9));
    // Win the first battle by hand, then take the event.
    final end = BattleState(
      player: run.hero.withHp(31),
      enemy: _hero(1).withHp(0),
      intent: EnemyMove.strike,
      potions: 1,
      phase: BattlePhase.victory,
    );
    run.finishBattle(end);
    run.resolveEvent();

    final saved = run.progress;
    expect(saved.stepIndex, 2);
    expect(saved.battlesWon, 1);

    final back = ExpeditionRun.restore(progress: saved, hero: _hero(2));
    expect(back.stepIndex, saved.stepIndex);
    expect(back.battlesWon, 1);
    expect(back.xp, run.xp);
    expect(back.coins, run.coins);
    expect(back.potions, run.potions);
    expect(back.hero.hp, run.hero.hp);
    expect(back.current!.enemy!.name, run.current!.enemy!.name);
    expect(back.finished, isFalse);
  });

  test('restoring clamps HP to the hero\'s current maximum', () {
    final p = ExpeditionProgress(
      seed: 1,
      heroLevel: 1,
      stepIndex: 2,
      heroHp: 500, // more than any hero can have
      potions: 0,
      battlesWon: 1,
      xp: 15,
      coins: 5,
    );
    final run = ExpeditionRun.restore(progress: p, hero: _hero(1));
    expect(run.hero.hp, run.hero.maxHp);
  });

  test('a resumed expedition can still be won, with the same total rewards', () {
    // Play a whole expedition straight through, and again with a save and
    // restore after every step. The totals must match what was earned.
    int play({required bool interrupt}) {
      var run = ExpeditionRun(
        expedition: Expedition.generate(seed: 321, heroLevel: 30),
        hero: _hero(30),
        rng: GameRng(1),
      );
      while (!run.finished) {
        if (interrupt) {
          run = ExpeditionRun.restore(progress: run.progress, hero: _hero(30));
        }
        if (run.current!.kind == StepKind.event) {
          run.resolveEvent();
        } else {
          var s = run.startBattle();
          var guard = 0;
          while (!s.isOver && guard++ < 200) {
            s = BattleEngine.act(s, s.canUseSkill ? BattleAction.skill : BattleAction.attack, run.rng);
          }
          run.finishBattle(s);
        }
      }
      expect(run.victory, isTrue);
      return run.xp * 1000 + run.coins;
    }

    expect(play(interrupt: true), play(interrupt: false));
  });
}
