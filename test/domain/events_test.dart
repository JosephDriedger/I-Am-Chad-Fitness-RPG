import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/combat.dart';
import 'package:i_am_chad/domain/difficulty.dart';
import 'package:i_am_chad/domain/expedition.dart';
import 'package:i_am_chad/domain/rng.dart';

void main() {
  final everyCamp = [...ExpeditionEvent.all, ...ExpeditionEvent.forks, ...ExpeditionEvent.regional];

  test('the first region only meets the original three camps, with nothing regional', () {
    final pool = ExpeditionEvent.poolFor(1);
    expect(pool, hasLength(3));
    expect(pool.every((e) => e.tier == 0), isTrue);
  });

  test('every later region has camps of its own, on top of the general five', () {
    for (var tier = 2; tier <= Difficulty.maxTier; tier++) {
      final pool = ExpeditionEvent.poolFor(tier);
      final own = pool.where((e) => e.tier == tier).toList();
      expect(own.length, greaterThanOrEqualTo(2), reason: 'region $tier');
      expect(pool, containsAll(ExpeditionEvent.all), reason: 'region $tier');
      // Never a camp that belongs to somewhere else.
      expect(pool.every((e) => e.tier == 0 || e.tier == tier), isTrue, reason: 'region $tier');
    }
  });

  test('regional camps are only in regions that exist, and a region does not have only one kind', () {
    for (final e in ExpeditionEvent.regional) {
      expect(e.tier, inInclusiveRange(2, Difficulty.maxTier), reason: e.title);
    }
    for (var tier = 2; tier <= Difficulty.maxTier; tier++) {
      expect({for (final e in ExpeditionEvent.regional.where((e) => e.tier == tier)) e.kind}.length, greaterThan(1), reason: 'region $tier');
    }
  });

  test('camps have unique Title Case names and kind, finished sentences', () {
    const small = {'a', 'the', 'and', 'of', 'to', 'for', 'with', 'from', 'in', 'at', 'on', 'or'};
    expect({for (final e in everyCamp) e.title}.length, everyCamp.length);
    for (final e in everyCamp) {
      final words = e.title.split(' ');
      for (var i = 0; i < words.length; i++) {
        if (i > 0 && small.contains(words[i])) continue;
        expect(words[i][0], words[i][0].toUpperCase(), reason: '"${e.title}"');
      }
      expect(e.text.length, inInclusiveRange(30, 160), reason: e.title);
      expect(RegExp(r'[.!?"]$').hasMatch(e.text), isTrue, reason: e.title);
    }
  });

  test('camp words stay kind: nothing pressures, shames or talks about bodies', () {
    const banned = ['lazy', 'weak', 'failure', 'failed', 'excuse', 'weight', 'in shape', 'burn off', 'hurry', 'must '];
    for (final e in everyCamp) {
      final t = '${e.title} ${e.text}'.toLowerCase();
      for (final w in banned) {
        expect(t.contains(w), isFalse, reason: '"$w" in ${e.title}');
      }
    }
  });

  test('an expedition in each region draws its camps from that region\'s pool, deterministically', () {
    for (var tier = 1; tier <= Difficulty.maxTier; tier++) {
      for (var seed = 1; seed <= 40; seed++) {
        final a = Expedition.generate(seed: seed, heroLevel: 40, tier: tier);
        final b = Expedition.generate(seed: seed, heroLevel: 40, tier: tier);
        final pool = ExpeditionEvent.poolFor(tier);
        final camps = [for (final s in a.steps) if (s.event != null) s.event!];
        expect([for (final c in camps) c.title], [for (final s in b.steps) if (s.event != null) s.event!.title]);
        expect(camps.toSet().length, camps.length, reason: 'the same camp twice');
        for (final c in camps) {
          expect(pool, contains(c), reason: 'region $tier seed $seed');
        }
      }
    }
  });

  group('forks in the road', () {
    test('the first region has none, and every later region has the general one and its own', () {
      expect(ExpeditionEvent.poolFor(1).any((e) => e.hasChoice), isFalse);
      for (var tier = 2; tier <= Difficulty.maxTier; tier++) {
        final forks = ExpeditionEvent.poolFor(tier).where((e) => e.hasChoice).toList();
        expect(forks.where((e) => e.tier == 0), hasLength(1), reason: 'region $tier: the general fork');
        expect(forks.where((e) => e.tier == tier), hasLength(1), reason: 'region $tier: its own fork');
      }
    });

    test('each fork offers two different ways, each an ordinary camp, with short labels', () {
      for (final f in ExpeditionEvent.forks) {
        expect(f.kind, EventKind.fork, reason: f.title);
        expect(f.choices, hasLength(2), reason: f.title);
        expect(f.choices.map((c) => c.kind).toSet(), hasLength(2), reason: '${f.title}: two different effects');
        for (final c in f.choices) {
          expect(c.kind, isNot(EventKind.fork), reason: f.title);
          expect(c.label.length, inInclusiveRange(8, 32), reason: c.label);
        }
        expect({for (final c in f.choices) c.label}.length, 2);
      }
      // Camps that are not forks have no choice.
      for (final e in [...ExpeditionEvent.all, ...ExpeditionEvent.regional]) {
        expect(e.hasChoice, isFalse, reason: e.title);
        expect(e.kind, isNot(EventKind.fork), reason: e.title);
      }
    });

    test('a fork never offers more than a camp already could, so nothing needs rebalancing', () {
      for (final f in ExpeditionEvent.forks) {
        for (var i = 0; i < f.choices.length; i++) {
          expect(f.chosenKind(i), f.choices[i].kind);
        }
      }
      // A choice out of range is kept in range, and an ordinary camp ignores the choice.
      final f = ExpeditionEvent.forks.first;
      expect(f.chosenKind(-3), f.choices.first.kind);
      expect(f.chosenKind(99), f.choices.last.kind);
      final plain = ExpeditionEvent.all.first;
      expect(plain.chosenKind(1), plain.kind);
    });

    ExpeditionRun runAtFork(int tier, ExpeditionEvent fork) {
      // Find an expedition in this region whose first camp is this fork.
      for (var seed = 1; seed < 20000; seed++) {
        final e = Expedition.generate(seed: seed, heroLevel: 20, tier: tier);
        if (e.steps.any((s) => s.event?.title == fork.title)) {
          final run = ExpeditionRun(
            expedition: e,
            hero: Combatant.fresh(name: 'H', maxHp: 100, attack: 10, defense: 5).withHp(30),
            rng: GameRng(seed),
          );
          while (run.current!.event?.title != fork.title) {
            run.stepIndex++;
          }
          return run;
        }
      }
      fail('no expedition reaches ${fork.title} in region $tier');
    }

    test('taking each way does exactly what that camp does, and moves on', () {
      for (final f in ExpeditionEvent.forks) {
        final tier = f.tier == 0 ? 2 : f.tier;
        for (var way = 0; way < f.choices.length; way++) {
          final run = runAtFork(tier, f);
          final step = run.stepIndex;
          final potions = run.potions;
          final coins = run.coins;
          run.resolveEvent(choice: way);
          expect(run.stepIndex, step + 1, reason: '${f.title} way $way moves on');
          switch (f.choices[way].kind) {
            case EventKind.restock:
              expect(run.potions, potions + 1, reason: f.title);
            case EventKind.rest:
              expect(run.hero.hp, 70, reason: '${f.title}: 30 + 40% of 100');
            case EventKind.spring:
              expect(run.hero.hp, 55, reason: '${f.title}: 30 + 25% of 100');
            case EventKind.treasure:
              expect(run.coins, coins + Expedition.stashCoins(tier), reason: f.title);
            case EventKind.bard:
              expect(run.focus, 2, reason: f.title);
            case EventKind.fork:
              fail('a fork is not an effect');
          }
        }
      }
    });

    test('without a choice, a fork takes its first way, so any older caller still works', () {
      final f = ExpeditionEvent.forks.first;
      final run = runAtFork(2, f);
      run.resolveEvent();
      expect(run.focus, 2, reason: 'the first way of the general fork is the sunny path');
    });
  });

  test('over many expeditions, the regional camps do turn up', () {
    for (var tier = 2; tier <= Difficulty.maxTier; tier++) {
      final seen = <String>{
        for (var seed = 1; seed <= 200; seed++)
          for (final s in Expedition.generate(seed: seed, heroLevel: 40, tier: tier).steps)
            if (s.event != null && s.event!.tier == tier) s.event!.title,
      };
      expect(seen.length, greaterThanOrEqualTo(2), reason: 'region $tier');
    }
  });
}
