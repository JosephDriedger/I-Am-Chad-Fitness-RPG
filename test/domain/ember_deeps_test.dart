import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/chad.dart';
import 'package:i_am_chad/domain/difficulty.dart';
import 'package:i_am_chad/domain/expedition.dart';
import 'package:i_am_chad/domain/items.dart';
import 'package:i_am_chad/domain/shop.dart';
import 'package:i_am_chad/game/art/painters.dart';
import 'package:i_am_chad/game/look.dart';
import 'dart:ui';

/// The eighth region, which opens after the Starlit Isles for heroes past level 65.
void main() {
  const tier = 8;

  test('it is the last region and opens after the Isles', () {
    expect(Difficulty.maxTier, tier);
    expect(Difficulty.region(tier).name, 'The Ember Deeps');
    expect(Difficulty.region(tier).minLevel, greaterThan(Difficulty.region(7).minLevel));
    expect(Difficulty.tierFor(65), 7);
    expect(Difficulty.tierFor(66), tier);
    expect(Difficulty.tierFor(99), tier);
    expect(Difficulty.stepsFor(tier), lessThanOrEqualTo(6));
  });

  test('it has its own enemies, two bosses and four pieces of gear', () {
    expect(EnemyPool.regular.where((e) => e.tier == tier), hasLength(3));
    expect(EnemyPool.bossesFor(tier), hasLength(2));
    expect(ItemCatalog.inTier(tier), hasLength(4));
    expect({for (final i in ItemCatalog.inTier(tier)) i.slot}, hasLength(4), reason: 'one piece for each slot');
  });

  test('every piece is for sale, and costs more than anything from the region before', () {
    final dearestBefore = [for (final i in ItemCatalog.inTier(7)) Shop.priceOf(i.id)!].reduce((a, b) => a > b ? a : b);
    for (final i in ItemCatalog.inTier(tier)) {
      expect(Shop.priceOf(i.id), isNotNull, reason: i.name);
      expect(Shop.priceOf(i.id)!, greaterThan(dearestBefore), reason: i.name);
    }
  });

  test('its gear is a little stronger than the last region\'s', () {
    int power(EquipmentItem i) => i.attack + i.defense + i.hp ~/ 3;
    final before = [for (final i in ItemCatalog.inTier(7)) power(i)]..sort();
    final now = [for (final i in ItemCatalog.inTier(tier)) power(i)]..sort();
    for (var k = 0; k < now.length; k++) {
      expect(now[k], greaterThanOrEqualTo(before[k]));
    }
  });

  test('an expedition there has a boss, camps of its own and a fork', () {
    final camps = ExpeditionEvent.poolFor(tier);
    expect(camps.where((e) => e.tier == tier), hasLength(greaterThanOrEqualTo(4)));
    expect(camps.any((e) => e.tier == tier && e.hasChoice), isTrue);
    for (var seed = 1; seed <= 60; seed++) {
      final e = Expedition.generate(seed: seed, heroLevel: 70, tier: tier);
      expect(e.tier, tier);
      expect(e.steps.last.enemy!.boss, isTrue);
      expect(e.steps.last.enemy!.tier, tier);
      for (final s in e.steps.where((s) => s.kind == StepKind.battle)) {
        expect(s.enemy!.tier, inInclusiveRange(7, tier));
      }
    }
  });

  test('every enemy has its own drawing and Chad has tips for the region', () {
    final canvas = Canvas(PictureRecorder());
    final plain = enemyPainter('No Such Enemy');
    for (final e in EnemyPool.everyone.where((e) => e.tier == tier)) {
      final painter = enemyPainter(e.name);
      expect(painter, isNot(same(plain)), reason: '${e.name} falls back to the slime');
      painter(canvas, ActorState()..time = 1.3);
      painter(canvas, ActorState()..time = 2.1..windUp = 1..attack = 1);
    }
    expect(ChadDialogue.tipRegions, contains(tier));
  });

  test('the new enemies use the tactics the region teaches', () {
    final moves = EnemyPool.regularFor(tier).where((e) => e.tier == tier).map((e) => e.behavior).toList();
    expect(moves.any((b) => b.flurry > 0), isTrue);
    expect(moves.any((b) => b.brace > 0), isTrue);
    expect(moves.any((b) => b.mend > 0), isTrue);
  });
}
