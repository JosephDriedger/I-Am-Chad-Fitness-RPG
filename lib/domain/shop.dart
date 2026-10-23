/// The Guild Shop: what coins buy. Coins are earned only through play (exercise
/// streaks, expeditions, practice duels), never with real money, and nothing
/// here is random. See docs/REWARD_RULES.md ("Coins and the shop").
library;

import 'items.dart';

enum PurchaseResult {
  bought,
  notEnoughCoins,
  alreadyOwned,

  /// The potion pouch is already full.
  pouchFull,

  /// Not for sale, or no hero yet.
  unavailable,
}

class Shop {
  const Shop._();

  /// Coin prices for gear. Starter pieces are cheap; the upgrades are a real
  /// goal. Items also still drop from expeditions, so buying is never the only
  /// way, and a duplicate drop pays coins back.
  static const _gearPrices = <String, int>{
    'wooden_sword': 60,
    'sweatband': 60,
    'guild_tunic': 60,
    'lucky_pebble': 70,
    'iron_blade': 240,
    'wayfarer_cap': 220,
    'trail_vest': 220,
    'stopwatch_charm': 240,
  };

  /// The coin price of an item, or null if it is not sold.
  static int? priceOf(String itemId) => _gearPrices[itemId];

  /// Everything for sale as gear, cheapest first.
  static List<EquipmentItem> get gear {
    final items = [for (final i in ItemCatalog.all) if (priceOf(i.id) != null) i];
    items.sort((a, b) {
      final byPrice = priceOf(a.id)!.compareTo(priceOf(b.id)!);
      return byPrice != 0 ? byPrice : a.slot.index.compareTo(b.slot.index);
    });
    return items;
  }

  // ---- Potions --------------------------------------------------------------

  /// What one healing potion costs.
  static const potionPrice = 25;

  /// How many bought potions the pouch holds.
  static const potionPouchMax = 5;

  /// Every expedition starts with this many potions, free.
  static const basePotions = 2;

  /// At most this many pouch potions come along on an expedition. Any that are
  /// not used come home again.
  static const maxPotionsBrought = 3;

  /// How many potions to take from the pouch for a new expedition.
  static int potionsToBring(int stock) => stock < maxPotionsBrought ? stock : maxPotionsBrought;

  /// How many pouch potions go back after an expedition that ended with
  /// [potionsLeft] potions. The free ones are used first.
  static int potionsReturned(int potionsLeft) => potionsLeft > basePotions ? potionsLeft - basePotions : 0;
}
