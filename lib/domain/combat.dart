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

enum EnemyMove {
  strike('strikes'),
  windUp('is winding up a heavy blow');

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

class Combatant {
  const Combatant({
    required this.name,
    required this.maxHp,
    required this.hp,
    required this.attack,
    required this.defense,
  });

  factory Combatant.fresh({
    required String name,
    required int maxHp,
    required int attack,
    required int defense,
  }) =>
      Combatant(
        name: name,
        maxHp: maxHp,
        hp: maxHp,
        attack: attack,
        defense: defense,
      );

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
  });

  static const int maxFocus = 5;
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
      );
}

class BattleEngine {
  const BattleEngine._();

  static const double heavyChance = 0.25;

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
        intent: _rollIntent(rng),
        focus: focus,
        potions: potions,
        log: ['${enemy.name} appears!'],
      );

  static EnemyMove _rollIntent(GameRng rng) =>
      rng.chance(heavyChance) ? EnemyMove.windUp : EnemyMove.strike;

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

    switch (action) {
      case BattleAction.attack:
        final d = _damage(player.attack, enemy.defense, rng);
        enemy = enemy.withHp(enemy.hp - d);
        focus = (focus + 1).clamp(0, BattleState.maxFocus);
        log.add('${player.name} attacks for $d damage.');
        events.add(PlayerAttacked(d));
      case BattleAction.guard:
        guarding = true;
        focus = (focus + 1).clamp(0, BattleState.maxFocus);
        log.add('${player.name} braces for impact.');
        events.add(const PlayerGuarded());
      case BattleAction.skill:
        final d = _damage(player.attack, enemy.defense, rng, mult: 2) + 1;
        enemy = enemy.withHp(enemy.hp - d);
        focus -= BattleState.skillCost;
        log.add('${player.name} unleashes a Power Strike for $d damage!');
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
      );
    }

    // Enemy reply, using the intent the player could see.
    final heavy = s.intent == EnemyMove.windUp;
    var dmg = _damage(enemy.attack, player.defense, rng, mult: heavy ? 1.6 : 1);
    if (guarding) dmg = (dmg / 2).ceil();
    player = player.withHp(player.hp - dmg);
    log.add('${enemy.name} ${heavy ? 'slams down' : 'strikes'} for $dmg'
        '${guarding ? ' (guarded)' : ''}.');
    events.add(EnemyAttacked(damage: dmg, heavy: heavy, guarded: guarding));

    if (player.isDown) {
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
      );
    }

    final next = _rollIntent(rng);
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
    );
  }
}
