/// Equipment, earned from expeditions or bought with coins in the Guild Shop
/// (see shop.dart). Bonuses are deliberately small.
library;

import 'rng.dart';

enum EquipmentSlot {
  head('Head'),
  body('Body'),
  weapon('Weapon'),
  trinket('Trinket');

  const EquipmentSlot(this.label);
  final String label;
}

class EquipmentItem {
  const EquipmentItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.description,
    this.hp = 0,
    this.attack = 0,
    this.defense = 0,
    this.tier = 1,
    this.accent,
  });

  /// Stable identifier persisted in the inventory. Never rename.
  final String id;
  final String name;
  final EquipmentSlot slot;
  final String description;
  final int hp;
  final int attack;
  final int defense;

  /// The region whose expeditions drop this (1 to 6). Pieces from a tougher
  /// region are a little stronger, still within a few points.
  final int tier;

  /// The colour the hero's gear is drawn in, for pieces without hand-drawn art
  /// of their own (null for the original eight).
  final int? accent;

  String get bonusLabel {
    final parts = <String>[
      if (hp > 0) '+$hp HP',
      if (attack > 0) '+$attack ATK',
      if (defense > 0) '+$defense DEF',
    ];
    return parts.isEmpty ? 'Cosmetic' : parts.join('  ');
  }
}

class ItemCatalog {
  const ItemCatalog._();

  static const all = <EquipmentItem>[
    EquipmentItem(
      id: 'wooden_sword',
      name: 'Practice Sword',
      slot: EquipmentSlot.weapon,
      description: 'Well-loved and slightly chewed by a guild dog.',
      attack: 1,
    ),
    EquipmentItem(
      id: 'sweatband',
      name: 'Hero\'s Sweatband',
      slot: EquipmentSlot.head,
      description: 'Absorbs sweat. Boosts morale.',
      hp: 4,
    ),
    EquipmentItem(
      id: 'guild_tunic',
      name: 'Guild Tunic',
      slot: EquipmentSlot.body,
      description: 'Standard issue, extremely breathable.',
      defense: 1,
    ),
    EquipmentItem(
      id: 'lucky_pebble',
      name: 'Lucky Pebble',
      slot: EquipmentSlot.trinket,
      description: 'Chad swears it came from a dragon. It did not.',
      hp: 3,
    ),
    EquipmentItem(
      id: 'iron_blade',
      name: 'Iron Blade',
      slot: EquipmentSlot.weapon,
      description: 'A proper sword. Mind the edges.',
      attack: 2,
    ),
    EquipmentItem(
      id: 'wayfarer_cap',
      name: 'Wayfarer Cap',
      slot: EquipmentSlot.head,
      description: 'For long walks and longer stories.',
      hp: 6,
      defense: 1,
    ),
    EquipmentItem(
      id: 'trail_vest',
      name: 'Trailblazer Vest',
      slot: EquipmentSlot.body,
      description: 'Lots of pockets. Most of them empty.',
      defense: 2,
    ),
    EquipmentItem(
      id: 'stopwatch_charm',
      name: 'Stopwatch Charm',
      slot: EquipmentSlot.trinket,
      description: 'Ticks reassuringly. Always five minutes slow.',
      attack: 1,
      hp: 4,
    ),

    // ---- The Gullhaven Coast (region 2) -------------------------------------
    EquipmentItem(
      id: 'coral_cutlass',
      name: 'Coral Cutlass',
      slot: EquipmentSlot.weapon,
      description: 'Grown, not forged. Smells faintly of seaside.',
      attack: 3,
      tier: 2,
      accent: 0xFFFF8A80,
    ),
    EquipmentItem(
      id: 'sailor_cap',
      name: 'Sailor\'s Cap',
      slot: EquipmentSlot.head,
      description: 'Keeps the gulls off. Mostly.',
      hp: 8,
      defense: 1,
      tier: 2,
      accent: 0xFF1E88E5,
    ),
    EquipmentItem(
      id: 'oilskin_coat',
      name: 'Oilskin Coat',
      slot: EquipmentSlot.body,
      description: 'Sheds rain, spray and the odd opinion.',
      defense: 3,
      tier: 2,
      accent: 0xFFF2C94C,
    ),
    EquipmentItem(
      id: 'sea_glass_charm',
      name: 'Sea-Glass Charm',
      slot: EquipmentSlot.trinket,
      description: 'Worn smooth by a patient tide.',
      hp: 6,
      attack: 1,
      tier: 2,
      accent: 0xFF4DD0E1,
    ),

    // ---- The Glimmer Caverns (region 3) --------------------------------------
    EquipmentItem(
      id: 'crystal_blade',
      name: 'Crystal Blade',
      slot: EquipmentSlot.weapon,
      description: 'Hums a note when swung. Always the same note.',
      attack: 4,
      tier: 3,
      accent: 0xFFB388FF,
    ),
    EquipmentItem(
      id: 'miner_helm',
      name: 'Miner\'s Helm',
      slot: EquipmentSlot.head,
      description: 'A lamp on the front, and a dent on top.',
      hp: 9,
      defense: 2,
      tier: 3,
      accent: 0xFFFFB300,
    ),
    EquipmentItem(
      id: 'stonestitch_vest',
      name: 'Stone-Stitched Vest',
      slot: EquipmentSlot.body,
      description: 'Sewn by someone with a lot of patience and a lot of gravel.',
      defense: 4,
      tier: 3,
      accent: 0xFF8D8D99,
    ),
    EquipmentItem(
      id: 'glowcap_lantern',
      name: 'Glowcap Lantern',
      slot: EquipmentSlot.trinket,
      description: 'A mushroom in a jar. It glows when it is happy.',
      hp: 8,
      attack: 1,
      tier: 3,
      accent: 0xFF69F0AE,
    ),

    // ---- Frostpeak Pass (region 4) -------------------------------------------
    EquipmentItem(
      id: 'frostbrand',
      name: 'Frostbrand',
      slot: EquipmentSlot.weapon,
      description: 'Cold to the touch, warm to the heart.',
      attack: 5,
      tier: 4,
      accent: 0xFF80D8FF,
    ),
    EquipmentItem(
      id: 'snow_hood',
      name: 'Snow Hood',
      slot: EquipmentSlot.head,
      description: 'Lined with something very fluffy.',
      hp: 10,
      defense: 2,
      tier: 4,
      accent: 0xFFECEFF1,
    ),
    EquipmentItem(
      id: 'yeti_mantle',
      name: 'Yeti Mantle',
      slot: EquipmentSlot.body,
      description: 'Given freely by a yeti who had plenty.',
      defense: 5,
      hp: 4,
      tier: 4,
      accent: 0xFFB0BEC5,
    ),
    EquipmentItem(
      id: 'summit_compass',
      name: 'Summit Compass',
      slot: EquipmentSlot.trinket,
      description: 'Always points to the next hill. Cheerfully.',
      attack: 2,
      hp: 8,
      tier: 4,
      accent: 0xFFFF7043,
    ),

    // ---- Thunder Heights (region 5) ------------------------------------------
    EquipmentItem(
      id: 'storm_edge',
      name: 'Storm Edge',
      slot: EquipmentSlot.weapon,
      description: 'Crackles faintly. Do not lick.',
      attack: 6,
      tier: 5,
      accent: 0xFFFFEA00,
    ),
    EquipmentItem(
      id: 'thunder_crown',
      name: 'Thunder Crown',
      slot: EquipmentSlot.head,
      description: 'Rumbles when it is about to be proud of you.',
      hp: 12,
      defense: 3,
      tier: 5,
      accent: 0xFFFFD740,
    ),
    EquipmentItem(
      id: 'gale_cloak',
      name: 'Gale Cloak',
      slot: EquipmentSlot.body,
      description: 'Billows even indoors.',
      defense: 6,
      hp: 4,
      tier: 5,
      accent: 0xFF7E57C2,
    ),
    EquipmentItem(
      id: 'lightning_bottle',
      name: 'Lightning in a Bottle',
      slot: EquipmentSlot.trinket,
      description: 'Chad says he caught it himself. He did not.',
      attack: 3,
      hp: 10,
      tier: 5,
      accent: 0xFFFFF176,
    ),

    // ---- The Sunstone Dunes (region 6) ---------------------------------------
    EquipmentItem(
      id: 'sunstone_blade',
      name: 'Sunstone Blade',
      slot: EquipmentSlot.weapon,
      description: 'Warm to hold, even at night.',
      attack: 7,
      tier: 6,
      accent: 0xFFFFB300,
    ),
    EquipmentItem(
      id: 'nomad_hood',
      name: 'Nomad\'s Hood',
      slot: EquipmentSlot.head,
      description: 'Shades the eyes and keeps a few secrets.',
      hp: 14,
      defense: 3,
      tier: 6,
      accent: 0xFFD7A86E,
    ),
    EquipmentItem(
      id: 'dune_robe',
      name: 'Dune Robe',
      slot: EquipmentSlot.body,
      description: 'Light as air and dry in a minute.',
      defense: 7,
      hp: 4,
      tier: 6,
      accent: 0xFFFFCC80,
    ),
    EquipmentItem(
      id: 'oasis_flask',
      name: 'Pocket Oasis',
      slot: EquipmentSlot.trinket,
      description: 'A tiny pond in a flask. There is a tiny duck.',
      attack: 3,
      hp: 12,
      tier: 6,
      accent: 0xFF26C6DA,
    ),
  ];

  static final Map<String, EquipmentItem> _byId = {
    for (final i in all) i.id: i,
  };

  static EquipmentItem? byId(String id) => _byId[id];

  /// Everything a region drops.
  static List<EquipmentItem> inTier(int tier) => [
        for (final i in all)
          if (i.tier == tier) i,
      ];

  /// The piece an expedition in region [tier] leaves in its chest. Mostly from
  /// that region's own gear, sometimes from an earlier region's, so the early
  /// pieces keep dropping and nothing is ever out of reach.
  static EquipmentItem lootFor(int tier, GameRng rng) {
    final own = inTier(tier);
    final earlier = [
      for (final i in all)
        if (i.tier < tier) i,
    ];
    if (own.isNotEmpty && (earlier.isEmpty || rng.chance(0.65))) {
      return own[rng.nextInt(own.length)];
    }
    final pool = earlier.isEmpty ? all : earlier;
    return pool[rng.nextInt(pool.length)];
  }
}
