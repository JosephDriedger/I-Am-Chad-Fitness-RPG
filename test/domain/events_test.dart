import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/difficulty.dart';
import 'package:i_am_chad/domain/expedition.dart';

void main() {
  final everyCamp = [...ExpeditionEvent.all, ...ExpeditionEvent.regional];

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
    const small = {'a', 'the', 'and', 'of', 'to', 'for', 'with', 'from', 'in', 'at', 'on'};
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
