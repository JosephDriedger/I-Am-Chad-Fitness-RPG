/// Equipment, earned from expeditions or bought with coins in the Guild Shop
/// (see shop.dart). Bonuses are deliberately small.
library;

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
  });

  /// Stable identifier persisted in the inventory. Never rename.
  final String id;
  final String name;
  final EquipmentSlot slot;
  final String description;
  final int hp;
  final int attack;
  final int defense;

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
  ];

  static final Map<String, EquipmentItem> _byId = {
    for (final i in all) i.id: i,
  };

  static EquipmentItem? byId(String id) => _byId[id];
}
