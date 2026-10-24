/// Seeded expeditions: a short sequence of battles and events in one of six
/// regions, each tougher than the last. See docs/COMBAT_AND_EXPEDITIONS.md.
library;

import 'combat.dart';
import 'difficulty.dart';
import 'hero.dart';
import 'items.dart';
import 'rng.dart';

class EnemyTemplate {
  const EnemyTemplate({
    required this.name,
    required this.blurb,
    required this.hp,
    required this.attack,
    required this.defense,
    this.boss = false,
    this.tier = 1,
    this.behavior = EnemyBehavior.standard,
  });

  final String name;
  final String blurb;

  /// Multipliers relative to a hero of the same level (1.0 = even match).
  final double hp;
  final double attack;
  final double defense;
  final bool boss;

  /// The region this enemy belongs to (1 to 6).
  final int tier;

  /// How it picks its moves: whether it braces, mends, strikes twice, or gets
  /// fired up. The move it picks is always shown first.
  final EnemyBehavior behavior;

  /// The enemy as met in a region of [tier]: its own build, scaled by the
  /// hero's level and then by how tough that region is.
  Combatant build(int heroLevel, {int? tier}) {
    final r = Difficulty.region(tier ?? this.tier);
    return Combatant.fresh(
      name: name,
      maxHp: (Progression.maxHp(heroLevel) * hp * r.hpScale).round(),
      attack: (Progression.attack(heroLevel) * attack * r.attackScale).round(),
      defense: (Progression.defense(heroLevel) * defense * r.defenseScale).round(),
      behavior: behavior,
    );
  }
}

class EnemyPool {
  const EnemyPool._();

  static const regular = <EnemyTemplate>[
    // ---- Meadowmere (region 1) ------------------------------------------------
    EnemyTemplate(
      name: 'Snooze Slime',
      blurb: 'Soft, sleepy, and very bouncy.',
      hp: 0.55,
      attack: 0.55,
      defense: 0.6,
    ),
    EnemyTemplate(
      name: 'Fog Imp',
      blurb: 'Whispers "maybe tomorrow". Cannot be trusted.',
      hp: 0.5,
      attack: 0.65,
      defense: 0.7,
    ),
    EnemyTemplate(
      name: 'Rusty Gear Golem',
      blurb: 'Creaks loudly. Hits like a cart.',
      hp: 0.75,
      attack: 0.6,
      defense: 0.9,
    ),
    EnemyTemplate(
      name: 'Cobweb Wisp',
      blurb: 'Drifts out of old training halls.',
      hp: 0.45,
      attack: 0.75,
      defense: 0.5,
    ),
    EnemyTemplate(
      name: 'Pebble Gremlin',
      blurb: 'Collects pebbles. Throws pebbles.',
      hp: 0.6,
      attack: 0.6,
      defense: 0.7,
    ),
    EnemyTemplate(
      name: 'Mist Wisp',
      blurb: 'Glows faintly and startles very easily.',
      hp: 0.5,
      attack: 0.65,
      defense: 0.6,
    ),

    // ---- The Gullhaven Coast (region 2) ---------------------------------------
    EnemyTemplate(
      name: 'Sand Crab',
      blurb: 'Walks sideways, argues forwards.',
      hp: 0.7,
      attack: 0.7,
      defense: 1.0,
      tier: 2,
      behavior: EnemyBehavior(heavy: 0.15, brace: 0.25),
    ),
    EnemyTemplate(
      name: 'Tide Jelly',
      blurb: 'Wobbles. Glows. Heals when nobody is looking.',
      hp: 0.8,
      attack: 0.6,
      defense: 0.6,
      tier: 2,
      behavior: EnemyBehavior(heavy: 0.15, mend: 0.25),
    ),
    EnemyTemplate(
      name: 'Gull Bandit',
      blurb: 'Steals chips. Has never once been caught.',
      hp: 0.55,
      attack: 0.8,
      defense: 0.6,
      tier: 2,
      behavior: EnemyBehavior(heavy: 0.1, flurry: 0.3),
    ),

    // ---- The Glimmer Caverns (region 3) ---------------------------------------
    EnemyTemplate(
      name: 'Crystal Beetle',
      blurb: 'Polishes its shell. Sparkles at you aggressively.',
      hp: 0.85,
      attack: 0.75,
      defense: 1.05,
      tier: 3,
      behavior: EnemyBehavior(heavy: 0.15, brace: 0.3),
    ),
    EnemyTemplate(
      name: 'Glowcap Shroom',
      blurb: 'Lights up when it is feeling better.',
      hp: 0.9,
      attack: 0.65,
      defense: 0.7,
      tier: 3,
      behavior: EnemyBehavior(heavy: 0.15, mend: 0.3),
    ),
    EnemyTemplate(
      name: 'Echo Bat',
      blurb: 'Says everything twice. Hits twice, too.',
      hp: 0.6,
      attack: 0.85,
      defense: 0.65,
      tier: 3,
      behavior: EnemyBehavior(heavy: 0.1, flurry: 0.4),
    ),

    // ---- Frostpeak Pass (region 4) ---------------------------------------------
    EnemyTemplate(
      name: 'Frost Sprite',
      blurb: 'Tiny, fast, and delighted with itself.',
      hp: 0.65,
      attack: 0.95,
      defense: 0.7,
      tier: 4,
      behavior: EnemyBehavior(heavy: 0.15, flurry: 0.4),
    ),
    EnemyTemplate(
      name: 'Snow Yeti',
      blurb: 'Big, fluffy and hits very hard when it means it.',
      hp: 1.0,
      attack: 0.9,
      defense: 0.85,
      tier: 4,
      behavior: EnemyBehavior(heavy: 0.4),
    ),
    EnemyTemplate(
      name: 'Icicle Golem',
      blurb: 'Cold, stubborn and surprisingly polite.',
      hp: 1.0,
      attack: 0.8,
      defense: 1.15,
      tier: 4,
      behavior: EnemyBehavior(heavy: 0.2, brace: 0.3),
    ),

    // ---- Thunder Heights (region 5) --------------------------------------------
    EnemyTemplate(
      name: 'Thunder Cloud',
      blurb: 'Rumbles twice before it strikes. Sometimes thrice.',
      hp: 0.9,
      attack: 1.0,
      defense: 0.8,
      tier: 5,
      behavior: EnemyBehavior(heavy: 0.2, flurry: 0.35),
    ),
    EnemyTemplate(
      name: 'Gale Hawk',
      blurb: 'Rides the wind and does not wait for you.',
      hp: 0.75,
      attack: 1.05,
      defense: 0.8,
      tier: 5,
      behavior: EnemyBehavior(heavy: 0.15, flurry: 0.4),
    ),
    EnemyTemplate(
      name: 'Static Imp',
      blurb: 'Crackles. Fizzes. Recovers faster than it should.',
      hp: 0.8,
      attack: 0.95,
      defense: 0.9,
      tier: 5,
      behavior: EnemyBehavior(heavy: 0.2, brace: 0.2, mend: 0.2),
    ),

    // ---- The Sunstone Dunes (region 6) -----------------------------------------
    EnemyTemplate(
      name: 'Dust Devil',
      blurb: 'Spins, giggles and rearranges your hat.',
      hp: 0.75,
      attack: 1.05,
      defense: 0.8,
      tier: 6,
      behavior: EnemyBehavior(heavy: 0.1, flurry: 0.4),
    ),
    EnemyTemplate(
      name: 'Cactus Knight',
      blurb: 'Prickly manners, soft heart, very small sword.',
      hp: 1.05,
      attack: 0.95,
      defense: 1.1,
      tier: 6,
      behavior: EnemyBehavior(heavy: 0.3, brace: 0.2),
    ),
    EnemyTemplate(
      name: 'Scarab Roller',
      blurb: 'Rolls a mysterious ball. Heals when it finds shade.',
      hp: 0.95,
      attack: 0.9,
      defense: 1.15,
      tier: 6,
      behavior: EnemyBehavior(heavy: 0.15, brace: 0.25, mend: 0.2),
    ),
  ];

  static const bosses = <EnemyTemplate>[
    // ---- Meadowmere -------------------------------------------------------------
    EnemyTemplate(
      name: 'Grumbling Treant',
      blurb: 'An ancient tree with strong opinions.',
      hp: 1.0,
      attack: 0.7,
      defense: 0.95,
      boss: true,
    ),
    EnemyTemplate(
      name: 'Chad\'s Old Rival, Brad',
      blurb: 'Claims to have done everything first. He has not.',
      hp: 0.95,
      attack: 0.75,
      defense: 0.9,
      boss: true,
    ),

    // ---- The Gullhaven Coast ----------------------------------------------------
    EnemyTemplate(
      name: 'Captain Barnacle',
      blurb: 'A very old crab in a very large hat.',
      hp: 1.15,
      attack: 0.8,
      defense: 1.05,
      boss: true,
      tier: 2,
      behavior: EnemyBehavior(heavy: 0.25, brace: 0.2, enrageBelow: 0.4),
    ),
    EnemyTemplate(
      name: 'The Gull King',
      blurb: 'Rules the harbour mostly by volume.',
      hp: 1.0,
      attack: 0.9,
      defense: 0.85,
      boss: true,
      tier: 2,
      behavior: EnemyBehavior(heavy: 0.2, flurry: 0.35, enrageBelow: 0.35),
    ),

    // ---- The Glimmer Caverns ----------------------------------------------------
    EnemyTemplate(
      name: 'Crystal Colossus',
      blurb: 'Has been standing here since before it was cool.',
      hp: 1.3,
      attack: 0.85,
      defense: 1.15,
      boss: true,
      tier: 3,
      behavior: EnemyBehavior(heavy: 0.25, brace: 0.2, enrageBelow: 0.4),
    ),
    EnemyTemplate(
      name: 'Mother Glowcap',
      blurb: 'Looks after every mushroom in the cave. Fiercely.',
      hp: 1.25,
      attack: 0.8,
      defense: 0.9,
      boss: true,
      tier: 3,
      behavior: EnemyBehavior(heavy: 0.2, mend: 0.3, enrageBelow: 0.35),
    ),

    // ---- Frostpeak Pass -----------------------------------------------------------
    EnemyTemplate(
      name: 'The Avalanche Matron',
      blurb: 'Large, loud, and deeply fond of her mountain.',
      hp: 1.4,
      attack: 0.95,
      defense: 1.0,
      boss: true,
      tier: 4,
      behavior: EnemyBehavior(heavy: 0.35, brace: 0.15, enrageBelow: 0.4),
    ),
    EnemyTemplate(
      name: 'Old Man Winter',
      blurb: 'Has been grumpy since before the mountains.',
      hp: 1.3,
      attack: 1.0,
      defense: 0.95,
      boss: true,
      tier: 4,
      behavior: EnemyBehavior(heavy: 0.2, flurry: 0.25, mend: 0.15, enrageBelow: 0.4),
    ),

    // ---- Thunder Heights ------------------------------------------------------------
    EnemyTemplate(
      name: 'The Thunderhead',
      blurb: 'The weather, but with opinions.',
      hp: 1.5,
      attack: 1.05,
      defense: 1.0,
      boss: true,
      tier: 5,
      behavior: EnemyBehavior(heavy: 0.3, flurry: 0.2, enrageBelow: 0.4),
    ),
    EnemyTemplate(
      name: 'Stormcaller Skarn',
      blurb: 'A very small wizard with a very large storm.',
      hp: 1.4,
      attack: 1.1,
      defense: 1.05,
      boss: true,
      tier: 5,
      behavior: EnemyBehavior(heavy: 0.2, flurry: 0.25, brace: 0.15, mend: 0.1, enrageBelow: 0.45),
    ),

    // ---- The Sunstone Dunes -------------------------------------------------------
    EnemyTemplate(
      name: 'The Great Dune Worm',
      blurb: 'Surfaces to say hello. Hello is loud.',
      hp: 1.55,
      attack: 1.1,
      defense: 1.0,
      boss: true,
      tier: 6,
      behavior: EnemyBehavior(heavy: 0.3, flurry: 0.2, enrageBelow: 0.4),
    ),
    EnemyTemplate(
      name: 'The Riddling Sphinx',
      blurb: 'Asks a riddle. The answer is always "a nap".',
      hp: 1.45,
      attack: 1.1,
      defense: 1.1,
      boss: true,
      tier: 6,
      behavior: EnemyBehavior(heavy: 0.2, flurry: 0.2, brace: 0.15, mend: 0.15, enrageBelow: 0.45),
    ),
  ];

  /// The ordinary enemies met in a region of [tier]: its own, plus the ones from
  /// the region before, for variety. Never an enemy from a tougher region.
  static List<EnemyTemplate> regularFor(int tier) => [
        for (final e in regular)
          if (e.tier == tier || (tier > 1 && e.tier == tier - 1)) e,
      ];

  /// The bosses of a region of [tier].
  static List<EnemyTemplate> bossesFor(int tier) => [
        for (final e in bosses)
          if (e.tier == tier) e,
      ];

  /// Every enemy there is.
  static List<EnemyTemplate> get everyone => [...regular, ...bosses];
}

/// What a camp does. A [fork] gives the player a choice between two of the others.
enum EventKind { restock, rest, treasure, bard, spring, fork }

/// One way to go at a fork. It has the effect of an ordinary camp, so there is
/// nothing new to balance, and neither way is wrong.
class EventChoice {
  const EventChoice(this.label, this.kind);

  final String label;
  final EventKind kind;
}

class ExpeditionEvent {
  const ExpeditionEvent(this.kind, this.title, this.text, {this.tier = 0, this.choices = const []});

  final EventKind kind;
  final String title;
  final String text;

  /// The options at a [EventKind.fork]; empty for every other camp.
  final List<EventChoice> choices;

  bool get hasChoice => choices.isNotEmpty;

  /// The effect that happens when the player takes option [choice] (counted
  /// from 0, and kept in range), or just this camp's own for one with no choice.
  EventKind chosenKind(int choice) =>
      hasChoice ? choices[choice.clamp(0, choices.length - 1)].kind : kind;

  /// The region this camp belongs to, or 0 for one that can turn up anywhere.
  final int tier;

  static const all = <ExpeditionEvent>[
    ExpeditionEvent(
      EventKind.restock,
      'A Traveling Apothecary',
      'A friendly merchant tops up your potion satchel.',
    ),
    ExpeditionEvent(
      EventKind.rest,
      'A Quiet Campfire',
      'You catch your breath and recover some health. Rest is part of the '
          'adventure.',
    ),
    ExpeditionEvent(
      EventKind.treasure,
      'Chad\'s "Secret" Stash',
      'Chad insists he buried this here years ago. There are coins inside.',
    ),
    ExpeditionEvent(
      EventKind.bard,
      'A Wandering Bard',
      'A cheerful bard plays a tune that gets your blood pumping. You start the '
          'next fight with focus to spare.',
    ),
    ExpeditionEvent(
      EventKind.spring,
      'A Quiet Spring',
      'Cool, clear water. You sit by it a while and feel a good deal better.',
    ),
  ];

  /// Camps that belong to one region. They work exactly like the general ones
  /// of the same kind, and only the place and the words change.
  static const regional = <ExpeditionEvent>[
    ExpeditionEvent(
      EventKind.spring,
      'A Tide-Pool Picnic',
      'A basket, a blanket and a very polite hermit crab. You sit, you eat, and you feel a good deal better.',
      tier: 2,
    ),
    ExpeditionEvent(
      EventKind.rest,
      'A Driftwood Fire',
      'Someone has left a stack of dry driftwood and a note: "Sit as long as you like." You do.',
      tier: 2,
    ),
    ExpeditionEvent(
      EventKind.rest,
      'A Glowcap Grotto',
      'Soft green light and a patch of dry moss. A fine place to catch your breath.',
      tier: 3,
    ),
    ExpeditionEvent(
      EventKind.restock,
      'A Crystal Peddler',
      'A peddler who sells potion bottles and very long stories. You leave with a potion, minus the story.',
      tier: 3,
    ),
    ExpeditionEvent(
      EventKind.rest,
      'A Hut at the Snow Line',
      'A cousin of Hush keeps a stove going here. There is soup. There is always soup.',
      tier: 4,
    ),
    ExpeditionEvent(
      EventKind.treasure,
      'A Yeti\'s Spare Pocket',
      'A friendly yeti pats down his fur and finds some coins. "Ah. I wondered where those went."',
      tier: 4,
    ),
    ExpeditionEvent(
      EventKind.rest,
      'A Sheltered Alcove',
      'The wind howls around the rock and, for once, not at you. You rest a while.',
      tier: 5,
    ),
    ExpeditionEvent(
      EventKind.bard,
      'A Friendly Storm Chaser',
      'Someone on a ridge waves and sends a tune of rolling thunder your way. You start the next fight with focus to spare.',
      tier: 5,
    ),
    ExpeditionEvent(
      EventKind.spring,
      'An Oasis',
      'Palm trees, still water, and one very smug duck. You sit a while and feel a good deal better.',
      tier: 6,
    ),
    ExpeditionEvent(
      EventKind.restock,
      'A Passing Caravan',
      'A caravan shares its water and a spare potion. The camel has no opinions about you at all.',
      tier: 6,
    ),
    ExpeditionEvent(
      EventKind.treasure,
      'A Riddle for a Coin',
      'A sign in the sand: "Solve this riddle, win a coin." The answer is, once again, "a nap". You get the coin.',
      tier: 6,
    ),
  ];

  /// Camps where the path splits and the player picks a way. Each option is an
  /// ordinary camp's effect, and nothing is lost by either.
  static const forks = <ExpeditionEvent>[
    ExpeditionEvent(
      EventKind.fork,
      'A Fork in the Road',
      'The path splits in two. One way is sunny and bright, and the other is shady and quiet.',
      choices: [
        EventChoice('Take the sunny path', EventKind.bard),
        EventChoice('Take the shady path', EventKind.spring),
      ],
    ),
    ExpeditionEvent(
      EventKind.fork,
      'Tide or Cliff',
      'At low tide you could walk the wet sand, or climb the cliff path for the view.',
      tier: 2,
      choices: [
        EventChoice('Walk the tide line', EventKind.spring),
        EventChoice('Climb the cliff path', EventKind.bard),
      ],
    ),
    ExpeditionEvent(
      EventKind.fork,
      'Glow or Hush',
      'One tunnel glows with mushrooms and chatter. The other is dark and very quiet.',
      tier: 3,
      choices: [
        EventChoice('Follow the glow', EventKind.restock),
        EventChoice('Take the quiet tunnel', EventKind.rest),
      ],
    ),
    ExpeditionEvent(
      EventKind.fork,
      'Sled or Snowshoes',
      'Someone has left a sled at the top of a long slope, with a snowshoe trail beside it.',
      tier: 4,
      choices: [
        EventChoice('Ride the sled run', EventKind.bard),
        EventChoice('Follow the snowshoe trail', EventKind.treasure),
      ],
    ),
    ExpeditionEvent(
      EventKind.fork,
      'Ledge or Ridge',
      'A stone ledge offers shelter. The ridge beyond it is open, and the view is tremendous.',
      tier: 5,
      choices: [
        EventChoice('Wait under the ledge', EventKind.rest),
        EventChoice('Cross the ridge', EventKind.bard),
      ],
    ),
    ExpeditionEvent(
      EventKind.fork,
      'Oasis or Dunes',
      'Palm trees shimmer to one side. A smooth, bright dune rises to the other.',
      tier: 6,
      choices: [
        EventChoice('Rest at the oasis', EventKind.spring),
        EventChoice('Cross the dunes', EventKind.treasure),
      ],
    ),
  ];

  /// The first region only meets the original three. Later ones add the other
  /// two, a fork in the road, and the camps that belong to that region.
  static List<ExpeditionEvent> poolFor(int tier) => tier <= 1
      ? all.sublist(0, 3)
      : [
          ...all,
          for (final e in forks)
            if (e.tier == 0 || e.tier == tier) e,
          for (final e in regional)
            if (e.tier == tier) e,
        ];
}

enum StepKind { battle, event }

class ExpeditionStep {
  const ExpeditionStep.battle(EnemyTemplate this.enemy)
      : kind = StepKind.battle,
        event = null;
  const ExpeditionStep.event(ExpeditionEvent this.event)
      : kind = StepKind.event,
        enemy = null;

  final StepKind kind;
  final EnemyTemplate? enemy;
  final ExpeditionEvent? event;
}

/// The order of an expedition's steps: `b` a battle, `e` a camp, `B` the boss.
/// Later regions add a battle or two, but never more than six steps.
String _shapeFor(int tier) => switch (tier) {
      <= 2 => 'beb' 'B',
      3 => 'bebb' 'B',
      4 => 'bbeb' 'B',
      5 => 'bbebe' 'B',
      _ => 'bbebb' 'B',
    };

class Expedition {
  const Expedition({
    required this.seed,
    required this.heroLevel,
    required this.steps,
    required this.lootItemId,
    this.tier = 1,
  });

  /// Energy cost to start a reward-bearing expedition.
  static const int energyCost = 2;

  final int seed;
  final int heroLevel;
  final List<ExpeditionStep> steps;

  /// The region, 1 to 6. Decides the enemies, the scenery, the loot and how
  /// tough everything is.
  final int tier;

  /// Item granted on victory (a duplicate converts to coins in the UI layer).
  final String lootItemId;

  int get battleCount => steps.where((s) => s.kind == StepKind.battle).length;

  Region get region => Difficulty.region(tier);

  /// Same seed + level + region always yields the same expedition. With no
  /// [tier] it is the toughest region open at [heroLevel].
  factory Expedition.generate({required int seed, required int heroLevel, int? tier}) {
    final t = (tier ?? Difficulty.tierFor(heroLevel)).clamp(1, Difficulty.maxTier);
    final rng = GameRng(seed);
    final regulars = rng.shuffle([...EnemyPool.regularFor(t)]);
    final bosses = EnemyPool.bossesFor(t);
    final boss = bosses[rng.nextInt(bosses.length)];
    final events = rng.shuffle([...ExpeditionEvent.poolFor(t)]);
    final loot = ItemCatalog.lootFor(t, rng);

    var nextRegular = 0, nextEvent = 0;
    final steps = <ExpeditionStep>[];
    for (final c in _shapeFor(t).split('')) {
      steps.add(switch (c) {
        'b' => ExpeditionStep.battle(regulars[nextRegular++]),
        'e' => ExpeditionStep.event(events[nextEvent++]),
        _ => ExpeditionStep.battle(boss),
      });
    }
    return Expedition(seed: seed, heroLevel: heroLevel, lootItemId: loot.id, steps: steps, tier: t);
  }

  /// A single relaxed duel in the guild yard: free, pays nothing, and always
  /// against the gentle enemies of the first region.
  factory Expedition.practice({required int seed, required int heroLevel}) {
    final rng = GameRng(seed);
    final pool = EnemyPool.regularFor(1);
    final foe = pool[rng.nextInt(pool.length)];
    return Expedition(
      seed: seed,
      heroLevel: heroLevel,
      lootItemId: '',
      steps: [ExpeditionStep.battle(foe)],
    );
  }

  /// XP for a won battle: the usual 15 (30 for a boss), plus a bonus that grows
  /// with the region.
  static int xpForBattle(EnemyTemplate e, {int tier = 1}) =>
      (e.boss ? 30 : 15) + Difficulty.region(tier).xpBonus * (e.boss ? 2 : 1);

  static int coinsForBattle(EnemyTemplate e, {int tier = 1}) =>
      (e.boss ? 12 : 5) + Difficulty.region(tier).coinBonus * (e.boss ? 2 : 1);

  /// What a duplicate piece of gear is worth in coins.
  static int duplicateCoins(int tier) => 10 * tier.clamp(1, Difficulty.maxTier);

  /// What the camp's hidden stash holds.
  static int stashCoins(int tier) => 8 + 4 * (tier.clamp(1, Difficulty.maxTier) - 1);
}

/// Everything needed to put an expedition back exactly where the player left
/// it. The expedition itself is regenerated from [seed], [heroLevel] and the
/// region, so only the run's state is stored. It is saved at the start of every
/// step.
class ExpeditionProgress {
  const ExpeditionProgress({
    required this.seed,
    required this.heroLevel,
    required this.stepIndex,
    required this.heroHp,
    required this.potions,
    required this.battlesWon,
    required this.xp,
    required this.coins,
    this.tier = 0,
    this.focus = 0,
  });

  final int seed;
  final int heroLevel;
  final int stepIndex;
  final int heroHp;
  final int potions;
  final int battlesWon;
  final int xp;
  final int coins;

  /// The region, or 0 for a run saved before regions existed, which was the
  /// toughest region open at its level.
  final int tier;

  /// Focus the hero starts the next battle with (a bard's gift).
  final int focus;

  Expedition get expedition =>
      Expedition.generate(seed: seed, heroLevel: heroLevel, tier: tier == 0 ? null : tier);

  /// The very start of a new expedition in [tier].
  factory ExpeditionProgress.fresh({
    required int seed,
    required int heroLevel,
    required int heroMaxHp,
    int potions = 2,
    int? tier,
  }) =>
      ExpeditionProgress(
        seed: seed,
        heroLevel: heroLevel,
        stepIndex: 0,
        heroHp: heroMaxHp,
        potions: potions,
        battlesWon: 0,
        xp: 0,
        coins: 0,
        tier: tier ?? Difficulty.tierFor(heroLevel),
      );
}

/// Mutable-free progress tracker for an expedition in progress.
class ExpeditionRun {
  ExpeditionRun({
    required this.expedition,
    required this.hero,
    required this.rng,
  });

  /// Rebuilds a run from saved [progress]. [hero] supplies the hero's current
  /// stats (gear may have changed since); its HP is set from the save.
  factory ExpeditionRun.restore({
    required ExpeditionProgress progress,
    required Combatant hero,
  }) {
    // The battle in progress restarts, so its random stream is re-seeded from
    // the step instead of being carried over.
    final rng = GameRng((progress.seed ^ 0x5bd1e995) + progress.stepIndex * 7919);
    return ExpeditionRun(
      expedition: progress.expedition,
      hero: hero.withHp(progress.heroHp),
      rng: rng,
    )
      ..potions = progress.potions
      ..focus = progress.focus
      ..stepIndex = progress.stepIndex
      ..battlesWon = progress.battlesWon
      ..xp = progress.xp
      ..coins = progress.coins;
  }

  final Expedition expedition;
  final GameRng rng;

  ExpeditionProgress get progress => ExpeditionProgress(
        seed: expedition.seed,
        heroLevel: expedition.heroLevel,
        stepIndex: stepIndex,
        heroHp: hero.hp,
        potions: potions,
        battlesWon: battlesWon,
        xp: xp,
        coins: coins,
        tier: expedition.tier,
        focus: focus,
      );

  Combatant hero;
  int potions = 2;
  int focus = 0;
  int stepIndex = 0;
  int battlesWon = 0;
  int xp = 0;
  int coins = 0;
  bool defeated = false;

  bool get finished => defeated || stepIndex >= expedition.steps.length;
  bool get victory => !defeated && stepIndex >= expedition.steps.length;
  ExpeditionStep? get current =>
      stepIndex < expedition.steps.length ? expedition.steps[stepIndex] : null;

  /// Starts the battle for the current step.
  BattleState startBattle() {
    final enemy = current!.enemy!.build(expedition.heroLevel, tier: expedition.tier);
    return BattleEngine.start(
      player: hero,
      enemy: enemy,
      rng: rng,
      focus: focus,
      potions: potions,
    );
  }

  /// Records a finished battle and advances.
  void finishBattle(BattleState end) {
    hero = end.player;
    potions = end.potions;
    focus = 0;
    if (end.phase == BattlePhase.victory) {
      final e = current!.enemy!;
      battlesWon++;
      xp += Expedition.xpForBattle(e, tier: expedition.tier);
      coins += Expedition.coinsForBattle(e, tier: expedition.tier);
      stepIndex++;
    } else {
      defeated = true;
    }
  }

  /// Applies the current event's effect and advances. At a fork, [choice] says which way (0 or 1).
  void resolveEvent({int choice = 0}) {
    final ev = current!.event!;
    switch (ev.chosenKind(choice)) {
      case EventKind.fork:
        break; // only ever the name of a camp with choices; its options do the work
      case EventKind.restock:
        potions += 1;
      case EventKind.rest:
        hero = hero.withHp(hero.hp + (hero.maxHp * 0.4).round());
      case EventKind.treasure:
        coins += Expedition.stashCoins(expedition.tier);
      case EventKind.bard:
        focus = 2;
      case EventKind.spring:
        hero = hero.withHp(hero.hp + (hero.maxHp * 0.25).round());
    }
    stepIndex++;
  }
}
