/// Seeded expeditions: a short sequence of battles and events.
library;

import 'combat.dart';
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
  });

  final String name;
  final String blurb;

  /// Multipliers relative to a hero of the same level (1.0 = even match).
  final double hp;
  final double attack;
  final double defense;
  final bool boss;

  Combatant build(int heroLevel) => Combatant.fresh(
        name: name,
        maxHp: (Progression.maxHp(heroLevel) * hp).round(),
        attack: (Progression.attack(heroLevel) * attack).round(),
        defense: (Progression.defense(heroLevel) * defense).round(),
      );
}

class EnemyPool {
  const EnemyPool._();

  static const regular = <EnemyTemplate>[
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
  ];

  static const bosses = <EnemyTemplate>[
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
  ];
}

enum EventKind { restock, rest, treasure }

class ExpeditionEvent {
  const ExpeditionEvent(this.kind, this.title, this.text);

  final EventKind kind;
  final String title;
  final String text;

  static const all = <ExpeditionEvent>[
    ExpeditionEvent(
      EventKind.restock,
      'A traveling apothecary',
      'A friendly merchant tops up your potion satchel.',
    ),
    ExpeditionEvent(
      EventKind.rest,
      'A quiet campfire',
      'You catch your breath and recover some health. Rest is part of the '
          'adventure.',
    ),
    ExpeditionEvent(
      EventKind.treasure,
      'Chad\'s "secret" stash',
      'Chad insists he buried this here years ago. There are coins inside.',
    ),
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

class Expedition {
  const Expedition({
    required this.seed,
    required this.heroLevel,
    required this.steps,
    required this.lootItemId,
  });

  /// Energy cost to start a reward-bearing expedition.
  static const int energyCost = 2;

  /// Coins from the free practice battle (no XP, no energy).
  static const int practiceCoins = 3;

  final int seed;
  final int heroLevel;
  final List<ExpeditionStep> steps;

  /// Item granted on victory (a duplicate converts to coins in the UI layer).
  final String lootItemId;

  int get battleCount => steps.where((s) => s.kind == StepKind.battle).length;

  /// Same seed + level always yields the same expedition.
  factory Expedition.generate({required int seed, required int heroLevel}) {
    final rng = GameRng(seed);
    final regular = rng.shuffle([...EnemyPool.regular]);
    final boss = EnemyPool.bosses[rng.nextInt(EnemyPool.bosses.length)];
    final event = ExpeditionEvent.all[rng.nextInt(ExpeditionEvent.all.length)];
    final loot = ItemCatalog.all[rng.nextInt(ItemCatalog.all.length)];
    return Expedition(
      seed: seed,
      heroLevel: heroLevel,
      lootItemId: loot.id,
      steps: [
        ExpeditionStep.battle(regular[0]),
        ExpeditionStep.event(event),
        ExpeditionStep.battle(regular[1]),
        ExpeditionStep.battle(boss),
      ],
    );
  }

  /// A single relaxed duel in the guild yard: free, no XP, pocket change only.
  factory Expedition.practice({required int seed, required int heroLevel}) {
    final rng = GameRng(seed);
    final foe = EnemyPool.regular[rng.nextInt(EnemyPool.regular.length)];
    return Expedition(
      seed: seed,
      heroLevel: heroLevel,
      lootItemId: '',
      steps: [ExpeditionStep.battle(foe)],
    );
  }

  static int xpForBattle(EnemyTemplate e) => e.boss ? 30 : 15;
  static int coinsForBattle(EnemyTemplate e) => e.boss ? 12 : 5;
}

/// Mutable-free progress tracker for an expedition in progress.
class ExpeditionRun {
  ExpeditionRun({
    required this.expedition,
    required this.hero,
    required this.rng,
  });

  final Expedition expedition;
  final GameRng rng;

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
    final enemy = current!.enemy!.build(expedition.heroLevel);
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
      xp += Expedition.xpForBattle(e);
      coins += Expedition.coinsForBattle(e);
      stepIndex++;
    } else {
      defeated = true;
    }
  }

  /// Applies the current event's effect and advances.
  void resolveEvent() {
    final ev = current!.event!;
    switch (ev.kind) {
      case EventKind.restock:
        potions += 1;
      case EventKind.rest:
        hero = hero.withHp(hero.hp + (hero.maxHp * 0.4).round());
      case EventKind.treasure:
        coins += 8;
    }
    stepIndex++;
  }
}
