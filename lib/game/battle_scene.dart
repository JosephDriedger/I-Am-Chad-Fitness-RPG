/// Animated battle stage. The rules live in `BattleEngine`; this scene only
/// plays back what happened, so it can never change the outcome.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart'
    show TextPainter, TextSpan, TextStyle, FontWeight, TextDirection;

import '../domain/combat.dart';
import '../domain/expedition.dart';
import '../domain/items.dart';
import 'art/painters.dart';
import 'core.dart';
import 'look.dart';

class _EnemyArt {
  const _EnemyArt(this.scale, this.height);
  final double scale;

  /// Unscaled height, used to place the intent badge above the head.
  final double height;
}

const _enemyArt = <String, _EnemyArt>{
  'Snooze Slime': _EnemyArt(1.9, 42),
  'Fog Imp': _EnemyArt(1.7, 74),
  'Rusty Gear Golem': _EnemyArt(1.75, 66),
  'Cobweb Wisp': _EnemyArt(1.8, 66),
  'Pebble Gremlin': _EnemyArt(1.85, 72),
  'Mist Wisp': _EnemyArt(2.0, 58),
  'Grumbling Treant': _EnemyArt(1.35, 112),
  'Chad\'s Old Rival, Brad': _EnemyArt(1.6, 74),
};

/// 0 meadow, 1 forest dusk, 2 boss arena, 3 night camp (events).
enum Biome { meadow, forest, arena, night }

class BattleScene extends GameScene {
  BattleScene({
    required this.look,
    required this.heroName,
    super.reducedMotion,
    super.onSfx,
    super.onHaptic,
  }) : super(designWidth: 360, designHeight: 340);

  static const groundY = 288.0;
  static final heroHome = Vector2(100, groundY);
  static final enemyHome = Vector2(262, groundY);
  static const heroScale = 1.8;

  final HeroLook look;
  final String heroName;

  @override
  Vector2 get focus => Vector2(180, 205);

  final _ready = Completer<void>();
  Future<void> get sceneReady => _ready.future;

  late final Backdrop _backdrop;
  late final ActorComponent hero;
  late final WorldBar _heroBar;
  late final WorldBar _enemyBar;
  late final _Pips _pips;
  late final _Hud _hud;
  late final _Label _heroLabel;
  late final _Label _enemyLabel;
  late final _IntentBadge _badge;
  ActorComponent? _enemy;
  _EnemyArt _art = const _EnemyArt(1.8, 60);
  PositionComponent? _prop;
  bool _guardUp = false;

  int _heroHp = 0;
  int _enemyHp = 0;

  @override
  Future<void> onLoad() async {
    _backdrop = Backdrop(Biome.meadow, groundY)..priority = -100;
    world.add(_backdrop);

    hero = ActorComponent(
      painter: (c, s) => paintHero(c, look, s),
      position: Vector2(-60, groundY),
      scaleFactor: heroScale,
    )..priority = 10;
    world.add(hero);

    _heroBar = WorldBar(
      position: Vector2.zero(),
      max: 1,
      fill: const Color(0xFF5CB85C),
    )..size.y = 12;
    _enemyBar = WorldBar(
      position: Vector2.zero(),
      max: 1,
      fill: const Color(0xFFE24B4A),
    )..size.y = 12;
    _heroLabel = _Label(heroName, Vector2.zero(), left: true);
    _enemyLabel = _Label('', Vector2.zero(), left: false);
    _pips = _Pips(Vector2.zero());
    _badge = _IntentBadge()..priority = 60;
    // The HUD lives in screen space so it hugs the top edge on any phone.
    _hud = _Hud(_heroBar, _enemyBar, _heroLabel, _enemyLabel, _pips);
    camera.viewport.add(_hud);
    world.add(_badge);
    _enemyBar.hidden = true;
    _enemyLabel.hidden = true;
  }

  @override
  void onMount() {
    super.onMount();
    if (!_ready.isCompleted) _ready.complete();
  }

  // -- Setup helpers ---------------------------------------------------------

  void setBiome(Biome b) => _backdrop.biome = b;

  void setHeroHp(int hp, int max) {
    _heroBar.snapTo(hp, max);
    _heroHp = hp;
  }

  void setFocus(int focus) => _pips.value = focus;

  // -- Battle flow -----------------------------------------------------------

  /// Walks the hero in and brings on the enemy.
  Future<void> beginBattle({
    required EnemyTemplate template,
    required Combatant foe,
    required Combatant heroNow,
    required EnemyMove intent,
    required Biome biome,
  }) async {
    setBiome(biome);
    _removeProp();
    _removeEnemy();
    _art = _enemyArt[template.name] ?? const _EnemyArt(1.8, 60);

    setHeroHp(heroNow.hp, heroNow.maxHp);
    hero
      ..state.down = 0
      ..state.attack = 0
      ..state.guard = 0
      ..nudge = Vector2.zero()
      ..alpha = 1
      ..flash = 0
      ..hop = 0
      ..lean = 0;
    _guardUp = false;

    _enemyHp = foe.hp;
    _enemyBar
      ..snapTo(foe.hp, foe.maxHp)
      ..hidden = false;
    _enemyLabel
      ..text = template.name
      ..hidden = false;
    _badge.visible = false;

    final enemy = ActorComponent(
      painter: enemyPainter(template.name),
      position: Vector2(enemyHome.x + 220, groundY),
      scaleFactor: _art.scale,
      faceLeft: true,
    )..priority = 10;
    _enemy = enemy;
    world.add(enemy);

    // Hero walks in from the left while the enemy slides in from the right.
    hero.position.x = -50;
    hero.state.walking = true;
    sfx(Sfx.whoosh);
    final heroFrom = hero.position.x;
    await tween(0.8, (t) {
      hero.position.x = heroFrom + (heroHome.x - heroFrom) * t;
      enemy.position.x = enemyHome.x + 220 * (1 - Curves.easeOut.transform(t));
    }, curve: Curves.easeOut);
    hero.state.walking = false;
    burst(Burst.puff(Vector2(enemyHome.x, groundY - 4)));
    setIntent(intent, announce: false);
    await pause(0.15);
  }

  /// Shows what the enemy will do next, with a telegraph pose for heavy blows.
  void setIntent(EnemyMove move, {bool announce = true}) {
    final enemy = _enemy;
    if (enemy == null) return;
    final heavy = move == EnemyMove.windUp;
    _badge
      ..heavy = heavy
      ..visible = true
      ..position = Vector2(
        enemyHome.x,
        groundY - _art.height * _art.scale - 26,
      );
    final from = enemy.state.windUp;
    final to = heavy ? 1.0 : 0.0;
    tween(0.25, (t) {
      final v = from + (to - from) * t;
      enemy.state.windUp = v;
      enemy.aura = v;
      enemy.lean = 0.12 * v;
    });
    if (heavy && announce) {
      sfx(Sfx.whoosh);
      haptic(Haptic.light);
    }
  }

  /// Plays back the events of one action, then snaps the bars to the truth.
  Future<void> play(
    List<BattleEvent> events, {
    required Combatant heroAfter,
    required Combatant enemyAfter,
    required int focusAfter,
  }) async {
    _badge.visible = false;
    for (final e in events) {
      switch (e) {
        case PlayerAttacked(:final damage):
          await _heroStrike(damage, skill: false);
        case PlayerUsedSkill(:final damage):
          await _heroStrike(damage, skill: true);
        case PlayerGuarded():
          await _raiseGuard();
        case PlayerHealed(:final amount):
          await _heal(amount);
        case EnemyAttacked():
          await _enemyStrike(e);
        case EnemyDefeated():
          await _enemyFalls();
        case PlayerDefeated():
          await _heroFalls();
      }
    }
    if (_guardUp) await _lowerGuard();
    _heroBar.setValue(heroAfter.hp);
    _enemyBar.setValue(enemyAfter.hp);
    _heroHp = heroAfter.hp;
    _enemyHp = enemyAfter.hp;
    _pips.value = focusAfter;
  }

  Vector2 get _enemyChest =>
      Vector2(enemyHome.x + (_enemy?.nudge.x ?? 0), groundY - _art.height * _art.scale * 0.55);
  Vector2 get _heroChest => Vector2(heroHome.x + hero.nudge.x, groundY - 60 * heroScale * 0.5);

  Future<void> _heroStrike(int damage, {required bool skill}) async {
    final enemy = _enemy;
    if (enemy == null) return;
    final reach = enemyHome.x - heroHome.x - 74;

    if (skill) {
      sfx(Sfx.skill);
      haptic(Haptic.light);
      burst(Burst.stars(Vector2(heroHome.x, groundY - 60), count: 14));
      await tween(0.3, (t) {
        hero.lean = -0.18 * t;
        hero.state.windUp = t;
        hero.hop = 6 * math.sin(t * math.pi);
      });
      hero.state.windUp = 0;
      hero.lean = 0;
    }
    sfx(Sfx.whoosh);
    await tween(skill ? 0.16 : 0.14, (t) {
      hero.nudge.x = reach * t;
      hero.state.attack = t * (skill ? 1 : 0.85);
    }, curve: Curves.easeIn);

    // Impact.
    final at = _enemyChest;
    world.add(_Slash(at.clone(), skill ? const Color(0xFFFFE082) : const Color(0xFFFFFFFF), skill ? 1.5 : 1)
      ..priority = 80);
    sfx(Sfx.hit);
    haptic(skill ? Haptic.heavy : Haptic.medium);
    burst(Burst.hit(at));
    if (skill) burst(Burst.stars(at, count: 10));
    floatText(
      '$damage',
      at + Vector2(-8, -34),
      color: skill ? const Color(0xFFFFE082) : const Color(0xFFFFFFFF),
      size: skill ? 30 : 22,
    );
    _enemyHp = math.max(0, _enemyHp - damage);
    _enemyBar.setValue(_enemyHp);
    shakeCamera(amount: skill ? 9 : 4, seconds: skill ? 0.3 : 0.18);
    unawaited(_hurt(enemy, push: 14, flashTime: 0.2));
    await pause(skill ? 0.14 : 0.08);

    await tween(0.22, (t) {
      hero.nudge.x = reach * (1 - t);
      hero.state.attack = (skill ? 1 : 0.85) * (1 - t);
    }, curve: Curves.easeOut);
    hero.state.attack = 0;
    hero.nudge.x = 0;
    await pause(0.1);
  }

  Future<void> _hurt(ActorComponent a, {double push = 10, double flashTime = 0.2}) async {
    final dir = a == hero ? -1.0 : 1.0;
    final base = a.nudge.x;
    await tween(flashTime, (t) {
      a.flash = 0.9 * (1 - t);
      a.nudge.x = base + dir * push * math.sin(t * math.pi) * (a == hero ? 1 : 1);
    });
    a.flash = 0;
    a.nudge.x = base;
  }

  Future<void> _raiseGuard() async {
    sfx(Sfx.guard);
    haptic(Haptic.light);
    _guardUp = true;
    burst(Burst(
      at: Vector2(heroHome.x + 26, groundY - 56),
      count: 8,
      colors: const [Color(0xFFB0BEC5), Color(0xFFFFFFFF)],
      shape: ParticleShape.spark,
      speed: 70,
      life: 0.4,
      gravity: 0,
    ));
    await tween(0.18, (t) => hero.state.guard = t, curve: Curves.easeOut);
    await pause(0.08);
  }

  Future<void> _lowerGuard() async {
    _guardUp = false;
    await tween(0.18, (t) => hero.state.guard = 1 - t);
    hero.state.guard = 0;
  }

  Future<void> _heal(int amount) async {
    sfx(Sfx.heal);
    haptic(Haptic.light);
    final at = Vector2(heroHome.x, groundY - 70);
    burst(Burst.heal(at));
    floatText('+$amount', at + Vector2(0, -26), color: const Color(0xFFA5D6A7), size: 24);
    _heroHp += amount;
    _heroBar.setValue(_heroHp);
    await tween(0.35, (t) {
      hero.hop = 5 * math.sin(t * math.pi);
      hero.flash = 0.35 * math.sin(t * math.pi);
    });
    hero.flash = 0;
    hero.hop = 0;
    await pause(0.1);
  }

  Future<void> _enemyStrike(EnemyAttacked e) async {
    final enemy = _enemy;
    if (enemy == null) return;
    final reach = -(enemyHome.x - heroHome.x - 64);
    final heavy = e.heavy;

    if (heavy) {
      await tween(0.3, (t) {
        enemy.lean = 0.12 + 0.12 * t;
        enemy.hop = 6 * t;
      });
    }
    sfx(Sfx.whoosh);
    await tween(heavy ? 0.14 : 0.18, (t) {
      enemy.nudge.x = reach * t;
      enemy.state.attack = t;
      enemy.lean = heavy ? 0.24 - 0.5 * t : -0.1 * t;
      enemy.hop = heavy ? 6 * (1 - t) : 0;
    }, curve: Curves.easeIn);

    final at = _heroChest;
    if (e.guarded) {
      sfx(Sfx.guard);
      haptic(Haptic.light);
      burst(Burst(
        at: at + Vector2(24, -4),
        count: 12,
        colors: const [Color(0xFFFFFFFF), Color(0xFFB0BEC5), Color(0xFF90CAF9)],
        shape: ParticleShape.spark,
        speed: 130,
        life: 0.4,
        gravity: 0,
      ));
      floatText('Blocked ${e.damage}', at + Vector2(0, -44), color: const Color(0xFFB3E5FC), size: 18);
      shakeCamera(amount: 2.5, seconds: 0.14);
      unawaited(tween(0.16, (t) => hero.nudge.x = -5 * math.sin(t * math.pi)));
    } else {
      sfx(Sfx.hit);
      haptic(heavy ? Haptic.heavy : Haptic.medium);
      burst(Burst.hit(at));
      floatText('${e.damage}', at + Vector2(0, -44), color: const Color(0xFFFF8A80), size: heavy ? 28 : 22);
      shakeCamera(amount: heavy ? 9 : 4.5, seconds: heavy ? 0.32 : 0.2);
      unawaited(_hurt(hero, push: heavy ? 16 : 10));
    }
    _heroHp = math.max(0, _heroHp - e.damage);
    _heroBar.setValue(_heroHp);
    await pause(heavy ? 0.2 : 0.12);

    await tween(0.26, (t) {
      enemy.nudge.x = reach * (1 - t);
      enemy.state.attack = 1 - t;
      enemy.lean = heavy ? -0.26 * (1 - t) : -0.1 * (1 - t);
    }, curve: Curves.easeOut);
    enemy
      ..state.attack = 0
      ..state.windUp = 0
      ..aura = 0
      ..lean = 0
      ..nudge.x = 0;
    await pause(0.08);
  }

  Future<void> _enemyFalls() async {
    final enemy = _enemy;
    if (enemy == null) return;
    sfx(Sfx.victory);
    haptic(Haptic.medium);
    enemy.aura = 0;
    burst(Burst.stars(_enemyChest, count: 18));
    await tween(0.5, (t) {
      enemy.flash = 0.7 * (1 - t);
      enemy.alpha = 1 - t;
      enemy.hop = -14 * t;
      enemy.state.down = 0.15 * t;
    });
    burst(Burst.puff(Vector2(enemyHome.x, groundY - 10)));
    _enemyBar.setValue(0);
    // Victory hop.
    for (var i = 0; i < 2; i++) {
      await tween(0.22, (t) => hero.hop = 12 * math.sin(t * math.pi));
    }
    hero.hop = 0;
    _badge.visible = false;
  }

  Future<void> _heroFalls() async {
    sfx(Sfx.defeat);
    haptic(Haptic.heavy);
    await tween(0.5, (t) => hero.state.down = t, curve: Curves.easeIn);
    await pause(0.2);
  }

  // -- Events and results ----------------------------------------------------

  /// Switches to a quiet stage for a between-battles event.
  Future<void> showEvent(EventKind kind) async {
    final enemy = _enemy;
    if (enemy != null) {
      await tween(0.25, (t) => enemy.alpha = 1 - t);
      _removeEnemy();
    }
    _enemyBar.hidden = true;
    _enemyLabel.hidden = true;
    _badge.visible = false;
    setBiome(Biome.night);
    _removeProp();
    final prop = _Prop(kind)
      ..position = Vector2(enemyHome.x, groundY)
      ..priority = 8;
    _prop = prop;
    world.add(prop);
    hero.state.walking = true;
    final from = hero.position.x;
    await tween(0.5, (t) => hero.position.x = from + (heroHome.x + 20 - from) * t);
    hero.state.walking = false;
    burst(Burst.puff(Vector2(enemyHome.x, groundY - 4)));
  }

  /// Shows the benefit of the event just taken.
  Future<void> applyEvent(EventKind kind, {required int heroHp}) async {
    final at = Vector2(heroHome.x + 20, groundY - 70);
    switch (kind) {
      case EventKind.restock:
        sfx(Sfx.heal);
        burst(Burst.stars(at));
        floatText('+1 potion', at + Vector2(0, -24), color: const Color(0xFF90CAF9), size: 20);
      case EventKind.rest:
        sfx(Sfx.heal);
        burst(Burst.heal(at));
        final gain = heroHp - _heroHp;
        floatText('+$gain HP', at + Vector2(0, -24), color: const Color(0xFFA5D6A7), size: 22);
        _heroHp = heroHp;
        _heroBar.setValue(heroHp);
      case EventKind.treasure:
        sfx(Sfx.coin);
        burst(Burst(
          at: Vector2(enemyHome.x, groundY - 40),
          count: 14,
          colors: const [Color(0xFFF2C94C), Color(0xFFFFE082)],
          shape: ParticleShape.star,
          speed: 140,
          life: 0.9,
        ));
        floatText('+8 coins', at + Vector2(0, -24), color: const Color(0xFFFFE082), size: 22);
    }
    await pause(0.6);
  }

  /// Chest-opening finale. [item] is null for a defeat (no chest).
  Future<void> showFinale({
    required bool victory,
    bool chest = true,
    EquipmentItem? item,
    bool isNew = true,
  }) async {
    _removeEnemy();
    _removeProp();
    _enemyBar.hidden = true;
    _enemyLabel.hidden = true;
    _badge.visible = false;
    setBiome(victory ? Biome.meadow : Biome.forest);
    if (!victory) {
      hero.state.down = 0;
      await tween(0.4, (t) => hero.state.guard = 0);
      return;
    }
    burst(Burst.confetti(Vector2(180, 110)));
    if (!chest) {
      sfx(Sfx.victory);
      for (var i = 0; i < 2; i++) {
        await tween(0.24, (t) => hero.hop = 12 * math.sin(t * math.pi));
      }
      hero.hop = 0;
      return;
    }
    sfx(Sfx.chest);
    final chestBox = _Chest()
      ..position = Vector2(enemyHome.x, groundY)
      ..priority = 8;
    world.add(chestBox);
    await tween(0.4, (t) => chestBox.pop = t, curve: Curves.easeOutBack);
    await pause(0.2);
    await tween(0.5, (t) {
      chestBox.open = t;
      chestBox.glow = t;
    });
    haptic(Haptic.medium);
    if (item != null) {
      final at = Vector2(enemyHome.x, groundY - 58);
      burst(Burst.stars(at, count: 24));
      floatText(item.name, at + Vector2(0, -40), color: const Color(0xFFFFF59D), size: 20, life: 1.6, rise: 24);
      floatText(isNew ? 'New!' : 'Duplicate: +10 coins', at + Vector2(0, -14),
          color: isNew ? const Color(0xFFA5D6A7) : const Color(0xFFFFE082), size: 15, life: 1.6, rise: 18);
      chestBox.item = item;
    }
    for (var i = 0; i < 2; i++) {
      await tween(0.24, (t) => hero.hop = 12 * math.sin(t * math.pi));
    }
    hero.hop = 0;
  }

  void _removeEnemy() {
    _enemy?.removeFromParent();
    _enemy = null;
  }

  void _removeProp() {
    _prop?.removeFromParent();
    _prop = null;
  }
}

// ---------------------------------------------------------------------------
// Scene pieces
// ---------------------------------------------------------------------------

class Backdrop extends Component {
  Backdrop(this.biome, this.groundY) {
    final r = math.Random(7);
    for (var i = 0; i < 46; i++) {
      _stars.add(Offset(-300 + r.nextDouble() * 960, -200 + r.nextDouble() * 360));
    }
    for (var i = 0; i < 7; i++) {
      _trees.add(r.nextDouble());
    }
  }

  Biome biome;
  final double groundY;
  final List<Offset> _stars = [];
  final List<double> _trees = [];
  double _t = 0;
  final Paint _paint = Paint();

  @override
  void update(double dt) => _t += dt;

  (Color, Color, Color, Color, Color) get _colors => switch (biome) {
        Biome.meadow => (const Color(0xFF8EC9EE), const Color(0xFFDFF3FB), const Color(0xFF8FC47A), const Color(0xFF7FB86A), const Color(0xFF6AA84F)),
        Biome.forest => (const Color(0xFF6D5A9C), const Color(0xFFF3B27A), const Color(0xFF3F6B4E), const Color(0xFF2F5A40), const Color(0xFF4C7A45)),
        Biome.arena => (const Color(0xFF2B1A3A), const Color(0xFFB5483A), const Color(0xFF4A3A55), const Color(0xFF3A2E44), const Color(0xFF5B4651)),
        Biome.night => (const Color(0xFF0F1B3D), const Color(0xFF2D3F6B), const Color(0xFF1F3A3A), const Color(0xFF18302F), const Color(0xFF2F4A3A)),
      };

  @override
  void render(Canvas canvas) {
    final (top, bottom, farHill, nearHill, ground) = _colors;
    const left = -900.0, width = 2160.0;
    _paint
      ..shader = Gradient.linear(Offset(0, -400), Offset(0, groundY), [top, bottom])
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(left, -400, width, groundY + 400), _paint);
    _paint.shader = null;

    if (biome == Biome.night) {
      for (var i = 0; i < _stars.length; i++) {
        final tw = 0.5 + 0.5 * math.sin(_t * 2 + i);
        _paint.color = Color.fromRGBO(255, 255, 255, 0.35 + 0.5 * tw);
        canvas.drawCircle(_stars[i], 0.9 + (i % 3) * 0.4, _paint);
      }
      _paint.color = const Color(0xFFF1F4C9);
      canvas.drawCircle(const Offset(290, 62), 17, _paint);
      _paint.color = top;
      canvas.drawCircle(const Offset(298, 58), 15, _paint);
    } else if (biome == Biome.meadow) {
      _paint.color = const Color(0x55FFF2A8);
      canvas.drawCircle(const Offset(292, 66), 34, _paint);
      _paint.color = const Color(0xFFFFF2A8);
      canvas.drawCircle(const Offset(292, 66), 20, _paint);
    } else if (biome == Biome.forest) {
      _paint.color = const Color(0x66FFD9A0);
      canvas.drawCircle(Offset(80, groundY - 90), 54, _paint);
    }

    if (biome == Biome.meadow || biome == Biome.forest) {
      for (var i = 0; i < 4; i++) {
        final x = ((_t * (4 + i * 1.5) + i * 190) % 1100) - 350;
        _paint.color = Color.fromRGBO(255, 255, 255, biome == Biome.meadow ? 0.9 : 0.45);
        canvas.drawOval(Rect.fromCenter(center: Offset(x, 56 + i * 22), width: 80, height: 22), _paint);
        canvas.drawOval(Rect.fromCenter(center: Offset(x + 22, 46 + i * 22), width: 46, height: 20), _paint);
      }
    }

    _paint.color = farHill;
    canvas.drawOval(Rect.fromCenter(center: Offset(60, groundY - 6), width: 440, height: 130), _paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(560, groundY - 4), width: 520, height: 110), _paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(-340, groundY - 4), width: 520, height: 110), _paint);
    _paint.color = nearHill;
    canvas.drawOval(Rect.fromCenter(center: Offset(250, groundY + 4), width: 380, height: 90), _paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(-60, groundY + 6), width: 300, height: 70), _paint);

    if (biome == Biome.forest) {
      for (var i = 0; i < _trees.length; i++) {
        final x = -300 + i * 150 + _trees[i] * 40;
        final h = 90 + _trees[i] * 50;
        _paint.color = const Color(0xFF244536);
        final p = Path()
          ..moveTo(x, groundY - h)
          ..lineTo(x - 26, groundY - 6)
          ..lineTo(x + 26, groundY - 6)
          ..close();
        canvas.drawPath(p, _paint);
        canvas.drawPath(p.shift(const Offset(0, -26)), _paint);
      }
    }
    if (biome == Biome.arena) {
      for (final x in [24.0, 336.0, -120.0, 480.0]) {
        _paint.color = const Color(0xFF3A2E3F);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 14, groundY - 150, 28, 150), const Radius.circular(3)), _paint);
        _paint.color = const Color(0xFF4A3C4F);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 20, groundY - 158, 40, 12), const Radius.circular(3)), _paint);
      }
      for (var i = 0; i < 18; i++) {
        final p = ((_t * 0.18 + i * 0.173) % 1);
        _paint.color = Color.fromRGBO(255, 160, 70, (1 - p) * 0.9);
        canvas.drawCircle(Offset(-60 + (i * 53) % 480 + math.sin(_t + i) * 8, groundY - p * 240), 1.6, _paint);
      }
    }

    _paint.color = ground;
    canvas.drawRect(Rect.fromLTWH(left, groundY - 8, width, 400), _paint);
    _paint.color = Color.alphaBlend(const Color(0x22000000), ground);
    for (var y = groundY + 14; y < groundY + 120; y += 26) {
      canvas.drawRect(Rect.fromLTWH(left, y, width, 2), _paint);
    }
    _paint.color = Color.alphaBlend(const Color(0x30FFFFFF), ground);
    canvas.drawRect(Rect.fromLTWH(left, groundY - 8, width, 3), _paint);
  }
}

class _Label extends PositionComponent {
  _Label(String text, Vector2 position, {required this.left}) : super(position: position) {
    this.text = text;
    priority = 50;
  }

  final bool left;
  bool hidden = false;
  String _text = '';
  TextPainter? _fill;
  TextPainter? _outline;

  set text(String v) {
    _text = v;
    TextPainter make(Paint? stroke) => TextPainter(
          text: TextSpan(
            text: v,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              foreground: stroke,
              color: stroke == null ? const Color(0xFFFFFFFF) : null,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
    _fill = make(null);
    _outline = make(Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF2B1A0E));
  }

  String get text => _text;

  @override
  void render(Canvas canvas) {
    if (hidden || _fill == null) return;
    final dx = left ? 0.0 : -_fill!.width;
    _outline!.paint(canvas, Offset(dx, 0));
    _fill!.paint(canvas, Offset(dx, 0));
  }
}

/// Focus pips under the hero's HP bar.
class _Pips extends PositionComponent {
  _Pips(Vector2 position) : super(position: position) {
    priority = 50;
  }

  int value = 0;

  @override
  void render(Canvas canvas) {
    final fill = Paint()..color = const Color(0xFFF2C94C);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFFFF3C4);
    final back = Paint()..color = const Color(0x66000000);
    for (var i = 0; i < 5; i++) {
      final c = Offset(i * 15.0, 0);
      canvas.drawCircle(c, 5.4, back);
      if (i < value) canvas.drawCircle(c, 4.4, fill);
      canvas.drawCircle(c, 5.4, edge);
    }
  }
}

/// "What will the enemy do next" marker above the enemy's head.
class _IntentBadge extends PositionComponent {
  bool heavy = false;
  bool visible = false;
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    if (!visible) return;
    final pulse = heavy ? 1 + math.sin(_t * 10) * 0.1 : 1.0;
    final bob = math.sin(_t * 3) * 2;
    canvas.save();
    canvas.translate(0, bob);
    canvas.scale(pulse, pulse);
    final base = heavy ? const Color(0xFFE65100) : const Color(0xFF546E7A);
    final p = Paint()..color = const Color(0x55000000);
    canvas.drawCircle(const Offset(1.5, 2.5), 15, p);
    p.color = base;
    canvas.drawCircle(Offset.zero, 15, p);
    canvas.drawPath(Path()..moveTo(-5, 12)..lineTo(0, 22)..lineTo(5, 12)..close(), p);
    p
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset.zero, 15, p..strokeWidth = 1.6);
    p
      ..style = PaintingStyle.fill
      ..strokeWidth = 3;
    if (heavy) {
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-2, -9, 4, 11), const Radius.circular(2)), p);
      canvas.drawCircle(const Offset(0, 6), 2.4, p);
    } else {
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawLine(const Offset(-6, 6), const Offset(6, -6), p);
      canvas.drawLine(const Offset(-6, -6), const Offset(6, 6), p);
    }
    canvas.restore();
  }
}

class _Slash extends PositionComponent {
  _Slash(Vector2 at, this.color, this.scaleBy) : super(position: at);

  final Color color;
  final double scaleBy;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt / 0.22;
    if (_t >= 1) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: (1 - _t).clamp(0.0, 1.0));
    canvas.save();
    canvas.scale(scaleBy, scaleBy);
    for (var i = 0; i < 2; i++) {
      p.strokeWidth = (5 - i * 2) * (1 - _t * 0.5);
      final r = 26.0 - i * 6;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(-8, 4), radius: r),
        -1.9 + _t * 0.5,
        1.8 + _t * 0.8,
        false,
        p,
      );
    }
    canvas.restore();
  }
}

class _Prop extends PositionComponent {
  _Prop(this.kind);

  final EventKind kind;
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.scale(1.7, 1.7);
    switch (kind) {
      case EventKind.rest:
        paintCampfire(canvas, _t);
      case EventKind.restock:
        paintMerchantCart(canvas, _t);
      case EventKind.treasure:
        paintChest(canvas, 0.0, 0);
    }
    canvas.restore();
  }
}

class _Chest extends PositionComponent {
  double pop = 0;
  double open = 0;
  double glow = 0;
  EquipmentItem? item;
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final s = 1.8 * pop;
    canvas.save();
    canvas.scale(s, s);
    paintChest(canvas, open, glow * (0.8 + math.sin(_t * 5) * 0.2));
    final it = item;
    if (it != null) {
      canvas.translate(0, -34 - 12 * open);
      paintItemIcon(canvas, it.slot, _t);
    }
    canvas.restore();
  }
}

/// Little icon for a piece of equipment, bobbing above an opened chest.
void paintItemIcon(Canvas c, EquipmentSlot slot, double t) {
  c.save();
  c.translate(0, math.sin(t * 3) * 2);
  switch (slot) {
    case EquipmentSlot.weapon:
      c.rotate(0.6);
      line(c, 0, 8, 0, -12, 4, const Color(0xFFECEFF1));
      line(c, -5, 6, 5, 6, 3, const Color(0xFFF2C94C));
    case EquipmentSlot.head:
      fillPath(c, Path()..moveTo(-9, 4)..quadraticBezierTo(-9, -10, 0, -10)..quadraticBezierTo(9, -10, 9, 4)..close(), const Color(0xFF66BB6A));
      rrect(c, -3, 1, 14, 3, 1.5, const Color(0xFF2E7D32));
    case EquipmentSlot.body:
      fillPath(c, poly([-10, -8, -5, -10, 5, -10, 10, -8, 7, 0, 5, 0, 5, 9, -5, 9, -5, 0, -7, 0]), const Color(0xFF8D6E63));
    case EquipmentSlot.trinket:
      fillPath(c, poly([0, -10, 8, -2, 0, 9, -8, -2]), const Color(0xFF4FC3F7));
      fillPath(c, poly([0, -10, 8, -2, 0, -2]), const Color(0xFFB3E5FC));
  }
  c.restore();
}

/// Screen-space HP bars, names and focus pips.
class _Hud extends PositionComponent {
  _Hud(this.heroBar, this.enemyBar, this.heroLabel, this.enemyLabel, this.pips) {
    addAll([heroBar, enemyBar, heroLabel, enemyLabel, pips]);
    priority = 1000;
  }

  final WorldBar heroBar;
  final WorldBar enemyBar;
  final _Label heroLabel;
  final _Label enemyLabel;
  final _Pips pips;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final w = math.min(150.0, size.x * 0.38);
    heroBar
      ..position = Vector2(14, 12)
      ..size.x = w;
    enemyBar
      ..position = Vector2(size.x - 14 - w, 12)
      ..size.x = w;
    heroLabel.position = Vector2(14, 27);
    enemyLabel.position = Vector2(size.x - 14, 27);
    pips.position = Vector2(19, 56);
  }
}
