/// Short, readable turn-based combat. See docs/COMBAT_AND_EXPEDITIONS.md.
///
/// The engine is a pure function of (state, action, rng), so battles are
/// reproducible from a seed and easy to unit test.
library;

import 'rng.dart';

enum BattleAction {
  attack('Attack', 'A reliable strike. Builds 1 focus.'),
  guard('Guard', 'Halve incoming damage this turn. Builds 1 focus.'),
  skill('Power Strike', 'Hit hard for 2 focus.'),
  item('Potion', 'Restore about a third of your health.');

  const BattleAction(this.label, this.help);
  final String label;
  final String help;
}

/// What an enemy will do after the player's next action. It is always shown
/// first, so every one of these can be answered.
enum EnemyMove {
  /// A normal blow.
  strike('strikes'),

  /// A heavy blow. Guarding softens it.
  windUp('is winding up a heavy blow'),

  /// Two quicker blows. Guarding halves both.
  flurry('is getting ready to strike twice'),

  /// Takes half damage from the player's next blow and answers with a light
  /// counter. Best answered by building focus or healing, not by a big hit.
  brace('is bracing for your next blow'),

  /// Heals a little instead of attacking. Best answered by hitting harder first.
  mend('is about to mend its wounds');

  const EnemyMove(this.verb);
  final String verb;
}

enum BattlePhase { playerTurn, victory, defeat }

/// What happened during one action, in order. The log is text for reading;
/// events are structured so a scene can animate each beat.
sealed class BattleEvent {
  const BattleEvent();
}

class PlayerAttacked extends BattleEvent {
  const PlayerAttacked(this.damage);
  final int damage;
}

class PlayerUsedSkill extends BattleEvent {
  const PlayerUsedSkill(this.damage);
  final int damage;
}

class PlayerGuarded extends BattleEvent {
  const PlayerGuarded();
}

class PlayerHealed extends BattleEvent {
  const PlayerHealed(this.amount);
  final int amount;
}

class EnemyAttacked extends BattleEvent {
  const EnemyAttacked({
    required this.damage,
    required this.heavy,
    required this.guarded,
  });
  final int damage;
  final bool heavy;
  final bool guarded;
}

class EnemyDefeated extends BattleEvent {
  const EnemyDefeated();
}

class PlayerDefeated extends BattleEvent {
  const PlayerDefeated();
}

/// The enemy braced: the player's blow in this action landed at half strength.
class EnemyBraced extends BattleEvent {
  const EnemyBraced();
}

class EnemyMended extends BattleEvent {
  const EnemyMended(this.amount);
  final int amount;
}

/// A boss crossed its "fired up" line and now hits harder.
class EnemyEnraged extends BattleEvent {
  const EnemyEnraged();
}

/// How an enemy picks its next move. The chances are out of 1, and whatever is
/// left over is a normal strike.
class EnemyBehavior {
  const EnemyBehavior({
    this.heavy = 0.25,
    this.flurry = 0,
    this.brace = 0,
    this.mend = 0,
    this.enrageBelow = 0,
  });

  /// The way every enemy fought before the regions: a heavy blow one turn in four.
  static const standard = EnemyBehavior();

  final double heavy;
  final double flurry;
  final double brace;
  final double mend;

  /// Below this share of its health a boss is "fired up" and hits 25% harder.
  /// Zero means never.
  final double enrageBelow;

  double get total => heavy + flurry + brace + mend;
}

class Combatant {
  const Combatant({
    required this.name,
    required this.maxHp,
    required this.hp,
    required this.attack,
    required this.defense,
    this.behavior = EnemyBehavior.standard,
  });

  factory Combatant.fresh({
    required String name,
    required int maxHp,
    required int attack,
    required int defense,
    EnemyBehavior behavior = EnemyBehavior.standard,
  }) =>
      Combatant(
        name: name,
        maxHp: maxHp,
        hp: maxHp,
        attack: attack,
        defense: defense,
        behavior: behavior,
      );

  /// How this combatant chooses its moves (only enemies use it).
  final EnemyBehavior behavior;

  final String name;
  final int maxHp;
  final int hp;
  final int attack;
  final int defense;

  bool get isDown => hp <= 0;

  Combatant withHp(int value) => Combatant(
        name: name,
        maxHp: maxHp,
        hp: value.clamp(0, maxHp),
        attack: attack,
        defense: defense,
        behavior: behavior,
      );
}

class BattleState {
  const BattleState({
    required this.player,
    required this.enemy,
    required this.intent,
    this.focus = 0,
    this.potions = 2,
    this.turn = 1,
    this.phase = BattlePhase.playerTurn,
    this.log = const [],
    this.events = const [],
    this.enraged = false,
  });

  static const int maxFocus = 5;

  /// A boss that has crossed its "fired up" line stays fired up.
  final bool enraged;
  static const int skillCost = 2;

  final Combatant player;
  final Combatant enemy;

  /// What the enemy will do after the player's next action. Always visible,
  /// so combat is a readable tactics puzzle rather than a guessing game.
  final EnemyMove intent;
  final int focus;
  final int potions;
  final int turn;
  final BattlePhase phase;

  /// Events produced by the most recent action.
  final List<String> log;

  /// Structured version of [log], in the order things happened.
  final List<BattleEvent> events;

  bool get isOver => phase != BattlePhase.playerTurn;
  bool get canUseSkill => focus >= skillCost;
  bool get canUseItem => potions > 0 && player.hp < player.maxHp;

  bool canAct(BattleAction a) => switch (a) {
        BattleAction.skill => canUseSkill,
        BattleAction.item => canUseItem,
        _ => true,
      };

  BattleState copyWith({
    Combatant? player,
    Combatant? enemy,
    EnemyMove? intent,
    int? focus,
    int? potions,
    int? turn,
    BattlePhase? phase,
    List<String>? log,
    List<BattleEvent>? events,
    bool? enraged,
  }) =>
      BattleState(
        player: player ?? this.player,
        enemy: enemy ?? this.enemy,
        intent: intent ?? this.intent,
        focus: focus ?? this.focus,
        potions: potions ?? this.potions,
        turn: turn ?? this.turn,
        phase: phase ?? this.phase,
        log: log ?? this.log,
        events: events ?? this.events,
        enraged: enraged ?? this.enraged,
      );
}

class BattleEngine {
  const BattleEngine._();

  /// How often a standard enemy winds up a heavy blow.
  static const double heavyChance = 0.25;

  /// What a mending enemy recovers, as a share of its health, and what a
  /// bracing enemy's counter and a fired-up boss do to damage.
  static const double mendShare = 0.15;
  static const double counterMult = 0.5;
  static const double flurryMult = 0.65;
  static const double heavyMult = 1.6;
  static const double enrageMult = 1.25;

  static BattleState start({
    required Combatant player,
    required Combatant enemy,
    required GameRng rng,
    int focus = 0,
    int potions = 2,
  }) =>
      BattleState(
        player: player,
        enemy: enemy,
        intent: _rollIntent(rng, enemy),
        focus: focus,
        potions: potions,
        log: ['${enemy.name} appears!'],
      );

  /// One roll decides the move, so a standard enemy uses exactly as many random
  /// numbers as before and old seeds still play out the same way.
  static EnemyMove _rollIntent(GameRng rng, Combatant enemy) {
    final b = enemy.behavior;
    final r = rng.nextDouble();
    var edge = b.heavy;
    if (r < edge) return EnemyMove.windUp;
    edge += b.flurry;
    if (r < edge) return EnemyMove.flurry;
    edge += b.brace;
    if (r < edge) return EnemyMove.brace;
    edge += b.mend;
    // Nothing to mend at full health: it just strikes.
    if (r < edge && enemy.hp <= enemy.maxHp * 0.85) return EnemyMove.mend;
    return EnemyMove.strike;
  }

  static int _damage(int attack, int defense, GameRng rng, {double mult = 1}) {
    final base = attack - defense ~/ 2;
    final raw = ((base < 1 ? 1 : base) + rng.nextInt(3)) * mult;
    final dmg = raw.round();
    return dmg < 1 ? 1 : dmg;
  }

  /// Resolves the player's action, then the enemy's reply.
  static BattleState act(BattleState s, BattleAction action, GameRng rng) {
    if (s.isOver || !s.canAct(action)) return s;

    final log = <String>[];
    final events = <BattleEvent>[];
    var player = s.player;
    var enemy = s.enemy;
    var focus = s.focus;
    var potions = s.potions;
    var guarding = false;
    var enraged = s.enraged;

    // A bracing enemy takes half of whatever lands this turn.
    final bracing = s.intent == EnemyMove.brace;
    if (bracing) events.add(const EnemyBraced());
    int soften(int d) => bracing ? (d / 2).ceil() : d;
    String softened() => bracing ? ' (softened)' : '';

    switch (action) {
      case BattleAction.attack:
        final d = soften(_damage(player.attack, enemy.defense, rng));
        enemy = enemy.withHp(enemy.hp - d);
        focus = (focus + 1).clamp(0, BattleState.maxFocus);
        log.add('${player.name} attacks for $d damage${softened()}.');
        events.add(PlayerAttacked(d));
      case BattleAction.guard:
        guarding = true;
        focus = (focus + 1).clamp(0, BattleState.maxFocus);
        log.add('${player.name} braces for impact.');
        events.add(const PlayerGuarded());
      case BattleAction.skill:
        final d = soften(_damage(player.attack, enemy.defense, rng, mult: 2) + 1);
        enemy = enemy.withHp(enemy.hp - d);
        focus -= BattleState.skillCost;
        log.add('${player.name} unleashes a Power Strike for $d damage${softened()}!');
        events.add(PlayerUsedSkill(d));
      case BattleAction.item:
        final heal = (player.maxHp / 3).round();
        final before = player.hp;
        player = player.withHp(player.hp + heal);
        potions -= 1;
        log.add('${player.name} drinks a potion and recovers '
            '${player.hp - before} HP.');
        events.add(PlayerHealed(player.hp - before));
    }

    if (enemy.isDown) {
      log.add('${enemy.name} is defeated!');
      events.add(const EnemyDefeated());
      return s.copyWith(
        player: player,
        enemy: enemy,
        focus: focus,
        potions: potions,
        phase: BattlePhase.victory,
        log: log,
        events: events,
        enraged: enraged,
      );
    }

    // A boss that has taken enough gets fired up, and stays that way.
    final fireLine = enemy.behavior.enrageBelow;
    if (!enraged && fireLine > 0 && enemy.hp <= enemy.maxHp * fireLine) {
      enraged = true;
      log.add('${enemy.name} is fired up!');
      events.add(const EnemyEnraged());
    }
    final boost = enraged ? enrageMult : 1.0;

    // The enemy's reply, using the intent the player could see.
    bool hit(double mult, {required bool heavy, String verb = 'strikes'}) {
      var dmg = _damage(enemy.attack, player.defense, rng, mult: mult * boost);
      if (guarding) dmg = (dmg / 2).ceil();
      player = player.withHp(player.hp - dmg);
      log.add('${enemy.name} ${heavy ? 'slams down' : verb} for $dmg${guarding ? ' (guarded)' : ''}.');
      events.add(EnemyAttacked(damage: dmg, heavy: heavy, guarded: guarding));
      return player.isDown;
    }

    var down = false;
    switch (s.intent) {
      case EnemyMove.mend:
        final amount = (enemy.maxHp * mendShare).round().clamp(1, enemy.maxHp);
        final before = enemy.hp;
        enemy = enemy.withHp(enemy.hp + amount);
        final gained = enemy.hp - before;
        log.add('${enemy.name} mends itself for $gained HP.');
        events.add(EnemyMended(gained));
      case EnemyMove.flurry:
        down = hit(flurryMult, heavy: false);
        if (!down) down = hit(flurryMult, heavy: false);
      case EnemyMove.brace:
        down = hit(counterMult, heavy: false, verb: 'counters');
      case EnemyMove.windUp:
        down = hit(heavyMult, heavy: true);
      case EnemyMove.strike:
        down = hit(1, heavy: false);
    }

    if (down) {
      log.add('${player.name} is knocked out. Time to rest and regroup!');
      events.add(const PlayerDefeated());
      return s.copyWith(
        player: player,
        enemy: enemy,
        focus: focus,
        potions: potions,
        phase: BattlePhase.defeat,
        log: log,
        events: events,
        enraged: enraged,
      );
    }

    final next = _rollIntent(rng, enemy);
    log.add('${enemy.name} ${next.verb}.');
    return s.copyWith(
      player: player,
      enemy: enemy,
      intent: next,
      focus: focus,
      potions: potions,
      turn: s.turn + 1,
      log: log,
      events: events,
      enraged: enraged,
    );
  }
}
