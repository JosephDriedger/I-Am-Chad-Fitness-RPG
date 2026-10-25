import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/cosmetics.dart';
import 'package:i_am_chad/domain/patronage.dart';
import 'package:i_am_chad/domain/story.dart';

void main() {
  group('what money can buy', () {
    test('there is one pack, Premium and a few tips, each with a unique id', () {
      final ids = Patronage.all.map((p) => p.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(Patronage.all.where((p) => !p.isTip), [Patronage.patronPack, Patronage.premium]);
      expect(Patronage.tips, hasLength(3));
      for (final p in Patronage.all) {
        expect(Patronage.byId(p.id), same(p));
      }
      expect(Patronage.byId('xp_boost'), isNull);
    });

    test('no product is described as power, currency or a timed offer', () {
      // The promise is in words, so the words are checked: nothing offered may
      // sound like it makes the game easier, or press the player to hurry.
      const power = ['xp', 'energy', 'coin', 'potion', 'boost', 'double', 'faster', 'skip', 'unlock all'];
      const pressure = ['limited', 'hurry', 'last chance', 'only today', 'expires', 'miss out', 'sale', 'discount', 'special offer', 'best value', 'starter'];
      for (final p in Patronage.all) {
        final text = '${p.name} ${p.blurb}'.toLowerCase();
        for (final w in [...power, ...pressure]) {
          // The pack's blurb says what it does NOT change; allow the word there.
          if (p == Patronage.patronPack && power.contains(w) && text.contains('changes nothing')) continue;
          expect(text, isNot(contains(w)), reason: '${p.id} mentions "$w"');
        }
      }
    });

    test('the pack and Premium are one-time and the tips are the only repeatable purchases', () {
      expect(Patronage.patronPack.kind, ProductKind.cosmeticPack);
      expect(Patronage.premium.kind, ProductKind.premium);
      expect(Patronage.tips.every((t) => t.kind == ProductKind.tip), isTrue);
      expect(Patronage.tipPerk, contains('nothing'));
    });

    test('the "never sold" list names every kind of power', () {
      final text = Patronage.neverSold.join(' ').toLowerCase();
      for (final w in ['xp', 'energy', 'coins', 'potions', 'gear', 'story', 'random', 'timed']) {
        expect(text, contains(w));
      }
    });

    test('Chad\'s words are warm and never pushy', () {
      const banned = [
        'lazy', 'fat ', 'ugly', 'pathetic', 'weak', 'failure', 'failed', 'loser', 'excuse',
        'limited', 'hurry', 'last chance', 'only today', 'expires', 'miss out', 'don\'t miss', 'sale', 'discount',
        'you must', 'you should buy', 'unlock more', 'be a real', 'support me or',
      ];
      for (final line in PatronDialogue.all) {
        final lower = line.toLowerCase();
        for (final w in banned) {
          expect(lower, isNot(contains(w)), reason: '"$line" contains "$w"');
        }
        expect(line.length, lessThan(320), reason: 'keep it short: "$line"');
      }
    });
  });

  group('receipts', () {
    test('a restored pack counts once, however many times the store sends it', () {
      final e = Entitlements.fromReceipts([
        (key: Entitlements.receiptKey(Patronage.patronPack, 'a'), productId: Patronage.patronPackId),
        (key: Entitlements.receiptKey(Patronage.patronPack, 'b'), productId: Patronage.patronPackId),
      ]);
      expect(e.hasPatronPack, isTrue);
      expect(e.ownedPacks, {Patronage.patronPackId});
      expect(e.tipCount, 0);
    });

    test('each tip counts once per transaction, and a tip never grants the pack', () {
      final k1 = Entitlements.receiptKey(Patronage.tipSmall, 'GPA.1');
      final k2 = Entitlements.receiptKey(Patronage.tipSmall, 'GPA.2');
      expect(k1, isNot(k2));
      final e = Entitlements.fromReceipts([
        (key: k1, productId: Patronage.tipSmall.id),
        (key: k1, productId: Patronage.tipSmall.id), // a repeated delivery
        (key: k2, productId: Patronage.tipLarge.id),
      ]);
      expect(e.tipCount, 2);
      expect(e.hasPatronPack, isFalse);
    });

    test('unknown products are ignored', () {
      final e = Entitlements.fromReceipts([(key: 'x', productId: 'gold_pile')]);
      expect(e.hasPatronPack, isFalse);
      expect(e.tipCount, 0);
    });
  });

  group('cosmetics', () {
    test('ids are unique, the first cape is the free classic one', () {
      expect(Cosmetics.capes.map((c) => c.id).toSet(), hasLength(Cosmetics.capes.length));
      expect(Cosmetics.dyes.map((d) => d.id).toSet(), hasLength(Cosmetics.dyes.length));
      expect(Cosmetics.pennants.map((p) => p.id).toSet(), hasLength(Cosmetics.pennants.length));
      expect(Cosmetics.capes.first.id, Cosmetics.classicCapeId);
      expect(Cosmetics.capes.first.unlock.kind, UnlockKind.free);
      expect(Cosmetics.dyes.map((d) => d.id), isNot(contains(Cosmetics.naturalDyeId)));
    });

    test('there is a free or earned choice of every kind, so no one is left out', () {
      expect(Cosmetics.capes.where((c) => !c.unlock.isPatron), hasLength(greaterThan(1)));
      expect(Cosmetics.dyes.where((d) => !d.unlock.isPatron), isNotEmpty);
      // Every pennant is earned by playing; none is sold.
      expect(Cosmetics.pennants.every((p) => p.unlock.isEarned), isTrue);
      // The bunting has room for each pennant.
      expect(Cosmetics.pennants.length, lessThanOrEqualTo(10));
    });

    test('the pack adds looks only, and the first-time player owns none of it', () {
      const none = CosmeticContext();
      for (final c in Cosmetics.capes.where((c) => c.unlock.isPatron)) {
        expect(c.unlock.isMet(none), isFalse);
        expect(c.unlock.isMet(const CosmeticContext(patron: true)), isTrue);
      }
      expect(Cosmetics.patronDecor(none), isEmpty);
      expect(Cosmetics.patronDecor(const CosmeticContext(patron: true)), PatronDecor.all);
      expect(Cosmetics.patronPackContents, hasLength(3 + 4 + 3));
    });

    test('a look the player does not have is drawn as the default', () {
      const none = CosmeticContext();
      expect(Cosmetics.wornCape('crimson', none).id, Cosmetics.classicCapeId);
      expect(Cosmetics.wornCape('no_such_cape', none).id, Cosmetics.classicCapeId);
      expect(Cosmetics.wornDye('mint', none), isNull);
      expect(Cosmetics.wornDye('', none), isNull);
      const patron = CosmeticContext(patron: true);
      expect(Cosmetics.wornCape('crimson', patron).id, 'crimson');
      expect(Cosmetics.wornDye('mint', patron)!.id, 'mint');
    });

    test('earned looks open through play and stay open', () {
      expect(Cosmetics.wornDye('sunrise', const CosmeticContext(level: 4)), isNull);
      expect(Cosmetics.wornDye('sunrise', const CosmeticContext(level: 5))!.id, 'sunrise');
      expect(Cosmetics.wornDye('moonlit', const CosmeticContext(level: 10))!.id, 'moonlit');

      final finale = Story.inSeason(1).last.number;
      expect(Cosmetics.wornCape('dawn', const CosmeticContext()).id, Cosmetics.classicCapeId);
      expect(Cosmetics.wornCape('dawn', CosmeticContext(chaptersRead: {finale})).id, 'dawn');
    });

    test('the Dawn Mantle really is tied to the last chapter of Season One', () {
      final dawn = Cosmetics.capeById('dawn');
      expect(dawn.unlock.kind, UnlockKind.chapter);
      expect(dawn.unlock.n, Story.inSeason(1).last.number);
    });

    test('each finished season earns its own mantle, and the earned looks outnumber none', () {
      for (final (id, season) in [('dawn', 1), ('lantern', 2), ('chime', 3)]) {
        final cape = Cosmetics.capeById(id);
        expect(cape.unlock.kind, UnlockKind.chapter, reason: id);
        expect(cape.unlock.n, Story.inSeason(season).last.number, reason: id);
        expect(Cosmetics.wornCape(id, const CosmeticContext()).id, Cosmetics.classicCapeId);
        expect(Cosmetics.wornCape(id, CosmeticContext(chaptersRead: {cape.unlock.n})).id, id);
      }
      // As many earned looks as paid ones, so the pack is extra choice, not better standing.
      final earnedCapes = Cosmetics.capes.where((c) => c.unlock.isEarned).length;
      final patronCapes = Cosmetics.capes.where((c) => c.unlock.isPatron).length;
      expect(earnedCapes, greaterThanOrEqualTo(patronCapes - 1));
      final earnedDyes = Cosmetics.dyes.where((d) => d.unlock.isEarned).length;
      final patronDyes = Cosmetics.dyes.where((d) => d.unlock.isPatron).length;
      expect(earnedDyes, greaterThanOrEqualTo(patronDyes - 1));
    });

    test('earned dyes open at their levels, none before', () {
      for (final (id, level) in [('ember', 20), ('glacier', 30), ('sunstone', 40)]) {
        expect(Cosmetics.wornDye(id, CosmeticContext(level: level - 1)), isNull, reason: id);
        expect(Cosmetics.wornDye(id, CosmeticContext(level: level))!.id, id);
      }
    });

    test('pennants hang in a fixed order and only for what was earned', () {
      expect(Cosmetics.earnedPennants(const CosmeticContext()), isEmpty);
      final some = Cosmetics.earnedPennants(const CosmeticContext(workouts: 1, victories: 1, level: 5));
      expect(some.map((p) => p.id), ['first_workout', 'first_victory', 'level_5']);
      final streak = Cosmetics.earnedPennants(const CosmeticContext(claimedStreakDays: {3, 7}));
      expect(streak.map((p) => p.id), ['streak_7']);
      // A bigger claimed streak also earns the smaller milestone's pennant.
      final month = Cosmetics.earnedPennants(const CosmeticContext(claimedStreakDays: {3, 7, 14, 30}));
      expect(month.map((p) => p.id), containsAll(['streak_7', 'streak_30']));
    });

    test('trophies are earned by playing, none is sold, and the shelf has room for all', () {
      expect(Cosmetics.trophies.map((t) => t.id).toSet(), hasLength(Cosmetics.trophies.length));
      expect(Cosmetics.trophies.every((t) => t.unlock.isEarned), isTrue);
      expect(Cosmetics.trophies.length, lessThanOrEqualTo(12), reason: 'two rows of six on the shelf');
      expect({for (final t in Cosmetics.trophies) t.shape}, hasLength(Cosmetics.trophies.length), reason: 'each looks different');
    });

    test('the shelf starts bare and trophies are set out only for what was earned', () {
      expect(Cosmetics.earnedTrophies(const CosmeticContext()), isEmpty);
      // The early game earns none: they are for the long haul.
      expect(Cosmetics.earnedTrophies(const CosmeticContext(level: 30, victories: 24, workouts: 100)), isEmpty);

      final lantern = Story.inSeason(2).last.number;
      final chime = Story.inSeason(3).last.number;
      expect(
        Cosmetics.earnedTrophies(CosmeticContext(chaptersRead: {lantern})).map((t) => t.id),
        ['story_two'],
      );
      expect(
        Cosmetics.earnedTrophies(CosmeticContext(level: 40, victories: 25, chaptersRead: {lantern, chime})).map((t) => t.id),
        ['story_two', 'level_40', 'twenty_five_victories', 'story_three'],
      );
      expect(
        Cosmetics.earnedTrophies(const CosmeticContext(level: 50, victories: 99, claimedStreakDays: {90})).length,
        4,
      );
      // Reading chapter 15 alone earns nothing but its own trophy; a bigger level also keeps the smaller one.
      expect(Cosmetics.earnedTrophies(const CosmeticContext(level: 99)).map((t) => t.id), ['level_40', 'level_50']);
    });

    test('a season trophy is tied to the last chapter of that season', () {
      expect(Cosmetics.trophies.firstWhere((t) => t.id == 'story_two').unlock.n, Story.inSeason(2).last.number);
      expect(Cosmetics.trophies.firstWhere((t) => t.id == 'story_three').unlock.n, Story.inSeason(3).last.number);
    });

    test('the later seasons and the new top levels have looks of their own, all earned', () {
      final table = Story.inSeason(4).last.number;
      final hearth = Story.inSeason(5).last.number;
      expect(Cosmetics.capeById('table').unlock.n, table);
      expect(Cosmetics.capeById('hearth').unlock.n, hearth);
      expect(Cosmetics.capeById('table').unlock.isEarned, isTrue);
      expect(Cosmetics.capeById('hearth').unlock.isEarned, isTrue);
      expect(Cosmetics.trophies.firstWhere((t) => t.id == 'story_four').unlock.n, table);
      expect(Cosmetics.trophies.firstWhere((t) => t.id == 'story_five').unlock.n, hearth);
      expect(Cosmetics.trophies.firstWhere((t) => t.id == 'story_six').unlock.n, Story.inSeason(6).last.number);
      expect(Cosmetics.capeById('road').unlock.n, Story.inSeason(6).last.number);
      expect(Cosmetics.dyeById('comet')!.unlock.n, 50);
      expect(Cosmetics.dyeById('cinder')!.unlock.n, 66);
      // Level 100 is a level the game could not reach before the cap moved to 120.
      expect(Cosmetics.trophies.firstWhere((t) => t.id == 'level_100').unlock.n, 100);
      expect(Cosmetics.earnedTrophies(const CosmeticContext(level: 100)).map((t) => t.id), contains('level_100'));
      expect(Cosmetics.earnedTrophies(const CosmeticContext(level: 99)).map((t) => t.id), isNot(contains('level_100')));
      expect(
        Cosmetics.earnedTrophies(CosmeticContext(level: 120, chaptersRead: {table, hearth})).map((t) => t.id),
        containsAll(['story_four', 'story_five', 'level_100']),
      );
    });

    test('capes keep their saved ids, and no cape or dye id repeats', () {
      expect(Cosmetics.capes.map((c) => c.id).toSet(), hasLength(Cosmetics.capes.length));
      expect(Cosmetics.dyes.map((d) => d.id).toSet(), hasLength(Cosmetics.dyes.length));
      expect(Cosmetics.capes.take(4).map((c) => c.id), [Cosmetics.classicCapeId, 'dawn', 'lantern', 'chime']);
    });

    test('keepsakes stand on the hall floor for the later seasons, earned and never sold', () {
      expect(Cosmetics.keepsakes.map((k) => k.id).toSet(), hasLength(Cosmetics.keepsakes.length));
      expect(Cosmetics.keepsakes.every((k) => k.unlock.isEarned), isTrue);
      expect(Cosmetics.keepsakes.length, lessThanOrEqualTo(5), reason: 'the floor has five places');
      expect({for (final k in Cosmetics.keepsakes) k.shape}, hasLength(Cosmetics.keepsakes.length), reason: 'each looks different');
      for (var i = 0; i < Cosmetics.keepsakes.length; i++) {
        expect(Cosmetics.keepsakes[i].unlock.n, Story.inSeason(i + 2).last.number, reason: Cosmetics.keepsakes[i].name);
      }
    });

    test('a keepsake appears only when its season is finished, and stays', () {
      expect(Cosmetics.earnedKeepsakes(const CosmeticContext()), isEmpty);
      expect(Cosmetics.earnedKeepsakes(const CosmeticContext(level: 120, victories: 99, claimedStreakDays: {365})), isEmpty,
          reason: 'only the story earns them');
      final lamp = Story.inSeason(2).last.number;
      final hearth = Story.inSeason(5).last.number;
      expect(Cosmetics.earnedKeepsakes(CosmeticContext(chaptersRead: {lamp})).map((k) => k.id), ['lamp']);
      expect(Cosmetics.earnedKeepsakes(CosmeticContext(chaptersRead: {Story.inSeason(6).last.number})).map((k) => k.id), ['comet']);
      // Reading a later season's finale does not set out the earlier seasons' pieces for it.
      expect(Cosmetics.earnedKeepsakes(CosmeticContext(chaptersRead: {hearth})).map((k) => k.id), ['hearth']);
      expect(Cosmetics.earnedKeepsakes(CosmeticContext(chaptersRead: {lamp, hearth})).map((k) => k.id), ['lamp', 'hearth']);
    });

    test('hints for a finished season name the season', () {
      expect(Unlock.chapter(Story.inSeason(1).last.number).hint, 'Earned by finishing the Season One story');
      expect(Unlock.chapter(Story.inSeason(2).last.number).hint, 'Earned by finishing the Season Two story');
      expect(Unlock.chapter(Story.inSeason(3).last.number).hint, 'Earned by finishing the Season Three story');
      expect(Unlock.chapter(Story.inSeason(5).last.number).hint, 'Earned by finishing the Season Five story');
      expect(Unlock.chapter(3).hint, 'Earned by reading chapter 3');
    });

    test('unlock hints are calm', () {
      for (final u in [
        ...Cosmetics.capes.map((c) => c.unlock),
        ...Cosmetics.dyes.map((d) => d.unlock),
        ...Cosmetics.pennants.map((p) => p.unlock),
        ...Cosmetics.trophies.map((t) => t.unlock),
      ]) {
        final h = u.hint.toLowerCase();
        for (final w in ['must', 'only', 'hurry', 'limited', 'before', 'miss']) {
          expect(h, isNot(contains(w)), reason: u.hint);
        }
      }
    });
  });
}
