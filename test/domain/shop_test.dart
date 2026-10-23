import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/items.dart';
import 'package:i_am_chad/domain/shop.dart';

void main() {
  test('every piece of gear can be bought, at a sensible price', () {
    for (final i in ItemCatalog.all) {
      final price = Shop.priceOf(i.id);
      expect(price, isNotNull, reason: '${i.id} should be for sale');
      // More than a duplicate drop pays back (10), so selling-by-looting is no exploit.
      expect(price, greaterThan(10), reason: i.id);
    }
    expect(Shop.priceOf('no_such_item'), isNull);
    expect(Shop.gear.length, ItemCatalog.all.length);
  });

  test('stronger gear costs more, and the shop lists the cheapest first', () {
    final prices = [for (final i in Shop.gear) Shop.priceOf(i.id)!];
    expect([...prices]..sort(), prices);
    int power(EquipmentItem i) => i.hp ~/ 2 + i.attack * 2 + i.defense * 2;
    final cheapest = Shop.gear.first;
    final dearest = Shop.gear.last;
    expect(power(dearest), greaterThanOrEqualTo(power(cheapest)));
    expect(Shop.priceOf('iron_blade')!, greaterThan(Shop.priceOf('wooden_sword')!));
  });

  test('a potion costs about what an expedition earns, so coins keep moving', () {
    expect(Shop.potionPrice, inInclusiveRange(10, 60));
    expect(Shop.potionPouchMax, greaterThanOrEqualTo(Shop.maxPotionsBrought));
  });

  test('how many potions go on an expedition', () {
    expect(Shop.potionsToBring(0), 0);
    expect(Shop.potionsToBring(1), 1);
    expect(Shop.potionsToBring(3), 3);
    expect(Shop.potionsToBring(5), 3, reason: 'there is a limit on what you carry');
  });

  test('unused pouch potions come home, and the free ones are used first', () {
    // Started with 2 free + 3 brought = 5.
    expect(Shop.potionsReturned(5), 3, reason: 'none used');
    expect(Shop.potionsReturned(4), 2, reason: 'one free potion used');
    expect(Shop.potionsReturned(2), 0, reason: 'only the free ones are left, so nothing comes home');
    expect(Shop.potionsReturned(0), 0);
    expect(Shop.potionsReturned(1), 0);
  });
}
