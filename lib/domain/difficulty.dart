/// How expeditions get harder as the hero levels up, without ever becoming a
/// wall. See docs/COMBAT_AND_EXPEDITIONS.md.
///
/// The world is seven regions. Each opens at a hero level, has its own enemies,
/// bosses, scenery and loot, and is a little tougher than the one before. A
/// region stays open for good, so a player can always go back to an easier one,
/// and being knocked out still keeps everything earned so far.
library;

/// What a region looks like. The game scenes map each to a backdrop.
enum Terrain { meadow, forest, coast, cave, peak, storm, dunes, isles }

class Region {
  const Region({
    required this.tier,
    required this.name,
    required this.blurb,
    required this.minLevel,
    required this.terrains,
    required this.hpScale,
    required this.attackScale,
    required this.defenseScale,
    required this.xpBonus,
    required this.coinBonus,
  });

  /// 1 to 7. Also what saved expeditions remember.
  final int tier;
  final String name;
  final String blurb;

  /// The hero level at which the region opens.
  final int minLevel;

  /// The scenery for its battles, in the order they are met.
  final List<Terrain> terrains;

  /// Multiply enemy HP, attack and defense on top of each enemy's own build.
  /// Kept as three dials so how long a fight lasts and how hard it hits can be
  /// tuned apart (see test/domain/balance_test.dart).
  final double hpScale;
  final double attackScale;
  final double defenseScale;

  /// Extra XP per regular battle (a boss gets double) and extra coins per battle.
  final int xpBonus;
  final int coinBonus;
}

class Difficulty {
  const Difficulty._();

  static const regions = <Region>[
    Region(
      tier: 1,
      name: 'Meadowmere',
      blurb: 'Rolling meadows and a friendly forest. A gentle place to start.',
      minLevel: 1,
      terrains: [Terrain.meadow, Terrain.forest],
      hpScale: 1.0,
      attackScale: 1.0,
      defenseScale: 1.0,
      xpBonus: 0,
      coinBonus: 0,
    ),
    Region(
      tier: 2,
      name: 'The Gullhaven Coast',
      blurb: 'Sandy beaches, tide pools and some very opinionated crabs.',
      minLevel: 5,
      terrains: [Terrain.coast, Terrain.coast],
      hpScale: 1.0,
      attackScale: 0.88,
      defenseScale: 0.9,
      xpBonus: 2,
      coinBonus: 1,
    ),
    Region(
      tier: 3,
      name: 'The Glimmer Caverns',
      blurb: 'Glowing crystals, dripping ceilings and things that echo.',
      minLevel: 10,
      terrains: [Terrain.cave, Terrain.cave],
      hpScale: 1.0,
      attackScale: 0.81,
      defenseScale: 0.9,
      xpBonus: 4,
      coinBonus: 2,
    ),
    Region(
      tier: 4,
      name: 'Frostpeak Pass',
      blurb: 'A high, snowy road where the wind has a lot to say.',
      minLevel: 16,
      terrains: [Terrain.peak, Terrain.cave],
      hpScale: 1.0,
      attackScale: 0.615,
      defenseScale: 0.9,
      xpBonus: 6,
      coinBonus: 3,
    ),
    Region(
      tier: 5,
      name: 'Thunder Heights',
      blurb: 'The tops of the tallest hills, where the weather lives.',
      minLevel: 24,
      terrains: [Terrain.storm, Terrain.peak],
      hpScale: 1.0,
      attackScale: 0.59,
      defenseScale: 0.9,
      xpBonus: 8,
      coinBonus: 4,
    ),
    Region(
      tier: 6,
      name: 'The Sunstone Dunes',
      blurb: 'Warm sand, long shadows and a great many riddles.',
      minLevel: 36,
      terrains: [Terrain.dunes, Terrain.dunes],
      hpScale: 1.015,
      attackScale: 0.49,
      defenseScale: 0.9,
      xpBonus: 10,
      coinBonus: 5,
    ),
    Region(
      tier: 7,
      name: 'The Starlit Isles',
      blurb: 'Floating islands under a very busy sky. Mind the comets.',
      minLevel: 50,
      terrains: [Terrain.isles, Terrain.isles],
      hpScale: 1.01,
      attackScale: 0.47,
      defenseScale: 0.9,
      xpBonus: 12,
      coinBonus: 6,
    ),
  ];

  static const maxTier = 7;

  /// The region with this tier, clamped to the ones that exist.
  static Region region(int tier) => regions[tier.clamp(1, maxTier) - 1];

  /// The toughest region that is open at [heroLevel].
  static int tierFor(int heroLevel) {
    var tier = 1;
    for (final r in regions) {
      if (heroLevel >= r.minLevel) tier = r.tier;
    }
    return tier;
  }

  /// Whether [tier] is open at [heroLevel].
  static bool isOpen(int tier, int heroLevel) => heroLevel >= region(tier).minLevel;

  /// How many steps an expedition in [tier] has: more as the regions get
  /// tougher, but never more than six, so a run stays a few minutes.
  static int stepsFor(int tier) => switch (tier) {
        <= 2 => 4,
        <= 4 => 5,
        _ => 6,
      };
}
