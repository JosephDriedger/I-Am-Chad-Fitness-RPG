/// The Adventurer's Guild hall: the game's home screen. Tap an object and the
/// hero walks over to use it, then the matching screen opens.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart'
    show TextPainter, TextSpan, TextStyle, FontWeight, TextDirection, TextAlign;

import '../domain/cosmetics.dart' show KeepsakeShape, PatronDecor, TrophyShape;
import 'art/painters.dart';
import 'core.dart';
import 'look.dart';

enum HubTarget { train, quests, adventure, hero, journal }

/// Everything the scene needs to know about the player, kept as plain data so
/// the scene never touches providers or the database.
class HubState {
  const HubState({
    required this.look,
    required this.chadLine,
    this.questPending = false,
    this.canAdventure = false,
    this.weeklyDone = 0,
    this.weeklyGoal = 1,
    this.hour = 12,
    this.itemsOwned = 0,
    this.pennants = const [],
    this.trophies = const [],
    this.keepsakes = const [],
    this.patronDecor = const {},
    this.highlight,
  });

  final HeroLook look;
  final String chadLine;
  final bool questPending;
  final bool canAdventure;
  final int weeklyDone;
  final int weeklyGoal;

  /// Local hour of day, for the light through the windows.
  final int hour;
  final int itemsOwned;

  /// Colours (ARGB) of the pennants the player has earned, in hanging order.
  /// The bunting starts bare and fills in as milestones are reached.
  final List<int> pennants;

  /// The trophies set out on the Journal shelf, in order. The shelf has room
  /// for six; it shows books on that row until the first one is earned.
  final List<TrophyShape> trophies;

  /// The keepsakes standing on the hall floor, in order, one for each later season finished.
  final List<KeepsakeShape> keepsakes;

  /// Ids from `PatronDecor` for the optional Patron Pack. Looks only.
  final Set<String> patronDecor;

  /// An object to glow softly as a first-steps hint, or null. It is only set
  /// until the first workout is logged, and it never blocks or times out.
  final HubTarget? highlight;
}

class HubScene extends GameScene {
  HubScene({
    required HubState initial,
    super.reducedMotion,
    super.onSfx,
    super.onHaptic,
    this.onSelect,
    this.onChadTap,
  })  : _state = initial,
        super(designWidth: 360, designHeight: 640);

  /// Called once the hero has walked to the object and finished interacting.
  void Function(HubTarget target)? onSelect;
  void Function()? onChadTap;

  HubState _state;
  final _ready = Completer<void>();
  Future<void> get sceneReady => _ready.future;

  late final HallBackdrop _hall;
  late final ActorComponent hero;
  late final ActorComponent chad;
  late final _Bubble _bubble;
  final Map<HubTarget, _Hotspot> _spots = {};

  static const floorTop = 372.0;
  static const walkMinY = 430.0;
  static const walkMaxY = 600.0;

  Completer<bool>? _arrive;
  Vector2? _goal;
  bool _busy = false;
  bool _heroGone = false;
  bool _loaded = false;

  @override
  Vector2 get focus => Vector2(180, 322);

  @override
  Future<void> onLoad() async {
    _hall = HallBackdrop(_state)..priority = -100;
    world.add(_hall);

    // Tapping the floor sends the hero walking there.
    world.add(_FloorTap(this)..priority = -50);

    final spots = <_Hotspot>[
      _Hotspot(HubTarget.quests, 'Quests', Rect.fromLTWH(14, 170, 100, 130), Vector2(64, 480), _paintBoard),
      _Hotspot(HubTarget.journal, 'Journal', Rect.fromLTWH(128, 150, 104, 222), Vector2(180, 520), _paintShelf),
      _Hotspot(HubTarget.adventure, 'Adventure', Rect.fromLTWH(244, 130, 102, 242), Vector2(290, 525), _paintGate),
      _Hotspot(HubTarget.train, 'Train', Rect.fromLTWH(26, 420, 80, 96), Vector2(124, 530), _paintDummy),
      _Hotspot(HubTarget.hero, 'Hero', Rect.fromLTWH(264, 424, 72, 92), Vector2(232, 530), _paintStand),
    ];
    for (final s in spots) {
      s
        ..scene = this
        ..priority = s.target == HubTarget.train || s.target == HubTarget.hero ? 20 : 5;
      _spots[s.target] = s;
      world.add(s);
    }

    chad = ActorComponent(
      painter: (c, s) => paintChad(c, s),
      position: Vector2(168, 542),
      scaleFactor: 1.45,
    );
    world.add(chad);
    world.add(_ChadTap(this)
      ..position = Vector2(132, 440)
      ..size = Vector2(72, 104)
      ..priority = 400);

    hero = ActorComponent(
      painter: (c, s) => paintHero(c, _state.look, s),
      position: Vector2(238, 592),
      scaleFactor: 1.5,
    );
    world.add(hero);

    _bubble = _Bubble(_state.chadLine)
      ..position = Vector2(58, 432)
      ..priority = 500;
    world.add(_bubble);
    _loaded = true;
  }

  @override
  void onMount() {
    super.onMount();
    if (!_ready.isCompleted) _ready.complete();
  }

  // -- State ---------------------------------------------------------------

  /// Pushes the latest player data into the scene.
  void apply(HubState s) {
    final lineChanged = s.chadLine != _state.chadLine;
    _state = s;
    if (!_loaded) return; // onLoad builds from the latest state
    _hall.state = s;
    if (lineChanged) _bubble.setText(s.chadLine);
  }

  void setChadLine(String line) {
    if (_loaded) _bubble.setText(line);
  }

  // -- Walking -------------------------------------------------------------

  Future<bool> walkTo(Vector2 goal) {
    _arrive?.complete(false);
    final clamped = Vector2(goal.x.clamp(30.0, 330.0), goal.y.clamp(walkMinY, walkMaxY));
    if (reducedMotion) {
      hero.position.setFrom(clamped);
      _goal = null;
      hero.state.walking = false;
      return Future.value(true);
    }
    _goal = clamped;
    hero.state.walking = true;
    final c = Completer<bool>();
    _arrive = c;
    return c.future;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final g = _goal;
    if (g != null && !_heroGone) {
      final to = g - hero.position;
      final dist = to.length;
      final step = 130 * dt;
      if (to.x.abs() > 0.5) hero.faceLeft = to.x < 0;
      if (dist <= step) {
        hero.position.setFrom(g);
        _goal = null;
        hero.state.walking = false;
        _arrive?.complete(true);
        _arrive = null;
      } else {
        hero.position.add(to / dist * step);
      }
    }
    hero.priority = hero.position.y.toInt();
    chad.priority = chad.position.y.toInt();
  }

  // -- Interaction -----------------------------------------------------------

  Future<void> activate(HubTarget t) async {
    if (_busy) return;
    _busy = true;
    sfx(Sfx.tap);
    haptic(Haptic.light);
    final spot = _spots[t]!;
    final ok = await walkTo(spot.stand);
    if (!ok) {
      _busy = false;
      return;
    }
    hero.faceLeft = spot.stand.x > spot.rect.center.dx && t != HubTarget.hero
        ? true
        : spot.stand.x < spot.rect.center.dx
            ? false
            : hero.faceLeft;
    await _interact(t, spot);
    _busy = false;
    onSelect?.call(t);
  }

  Future<void> _interact(HubTarget t, _Hotspot spot) async {
    switch (t) {
      case HubTarget.train:
        for (var i = 0; i < 2; i++) {
          await tween(0.14, (v) => hero.state.attack = v);
          sfx(Sfx.hit);
          haptic(Haptic.medium);
          burst(Burst.hit(Vector2(spot.rect.center.dx, 460)));
          spot.wobble = 1;
          await tween(0.16, (v) => hero.state.attack = 1 - v);
        }
        hero.state.attack = 0;
      case HubTarget.quests:
        sfx(Sfx.tap);
        spot.wobble = 1;
        await tween(0.3, (v) => hero.hop = 6 * math.sin(v * math.pi));
        hero.hop = 0;
      case HubTarget.journal:
        sfx(Sfx.tap);
        spot.wobble = 1;
        await tween(0.3, (v) => hero.hop = 4 * math.sin(v * math.pi));
        hero.hop = 0;
      case HubTarget.hero:
        burst(Burst.stars(Vector2(spot.rect.center.dx, 440), count: 8));
        await tween(0.35, (v) => hero.hop = 8 * math.sin(v * math.pi));
        hero.hop = 0;
      case HubTarget.adventure:
        if (_state.canAdventure) {
          sfx(Sfx.whoosh);
          final from = hero.position.clone();
          final into = Vector2(spot.rect.center.dx, spot.rect.bottom - 8);
          hero.state.walking = true;
          await tween(0.5, (v) {
            hero.position.setValues(
              from.x + (into.x - from.x) * v,
              from.y + (into.y - from.y) * v,
            );
            hero.alpha = 1 - v * v;
            hero.scaleFactor = 1.5 - 0.3 * v;
          });
          hero.state.walking = false;
          _heroGone = true;
        } else {
          sfx(Sfx.guard);
          await tween(0.3, (v) => hero.hop = 5 * math.sin(v * math.pi));
          hero.hop = 0;
        }
    }
  }

  /// Brings the hero back after returning from the gate.
  Future<void> resume() async {
    if (!_heroGone) return;
    final spot = _spots[HubTarget.adventure]!;
    hero.position.setValues(spot.stand.x, spot.stand.y);
    _heroGone = false;
    hero.scaleFactor = 1.5;
    await tween(0.4, (v) => hero.alpha = v);
    hero.alpha = 1;
  }

  // -- Celebrations ----------------------------------------------------------

  Future<void> showGain({int xp = 0, int energy = 0, int coins = 0}) async {
    _bubble.hidden = true; // keep the popups readable
    final at = Vector2(hero.position.x.clamp(100.0, 260.0), hero.position.y - 125);
    final lines = <(String, Color, Sfx?)>[
      if (xp > 0) ('+$xp XP', const Color(0xFFFFE082), null),
      if (energy > 0) ('+$energy Energy', const Color(0xFF80DEEA), null),
      if (coins > 0) ('+$coins Coins', const Color(0xFFFFD54F), Sfx.coin),
    ];
    for (var i = 0; i < lines.length; i++) {
      final (text, color, snd) = lines[i];
      floatText(text, at + Vector2(0, -i * 38.0), color: color, size: 24, life: 1.7, rise: 14);
      burst(Burst.stars(at + Vector2(0, 40), count: 8));
      sfx(snd ?? Sfx.coin);
      await pause(0.4);
    }
    await pause(1.2);
    _bubble.hidden = false;
  }

  Future<void> celebrateLevelUp(int level) async {
    _bubble.hidden = true;
    sfx(Sfx.levelUp);
    haptic(Haptic.heavy);
    final top = Vector2(180, 250);
    burst(Burst.confetti(top, count: 90));
    burst(Burst.stars(hero.position + Vector2(0, -60), count: 24));
    floatText('LEVEL UP!', top, color: const Color(0xFFFFEB3B), size: 38, life: 2.2, rise: 40);
    floatText('Level $level', top + Vector2(0, 34), color: const Color(0xFFFFFFFF), size: 22, life: 2.2, rise: 30);
    for (var i = 0; i < 3; i++) {
      await tween(0.26, (v) => hero.hop = 18 * math.sin(v * math.pi));
    }
    hero.hop = 0;
    await pause(1.6);
    _bubble.hidden = false;
  }

  // -- Hotspot art -------------------------------------------------------------

  void _paintBoard(Canvas c, _Hotspot s) {
    final w = math.sin(s.wobble * math.pi * 6) * 2 * s.wobble;
    c.save();
    c.translate(s.rect.center.dx, s.rect.top);
    c.rotate(w * 0.02);
    rrect(c, -50, 0, 100, 112, 6, const Color(0xFF6F4727));
    rrect(c, -44, 6, 88, 100, 3, const Color(0xFFC9A56A));
    final notes = [
      (-34.0, 12.0, -0.06, const Color(0xFFF6EED8)),
      (2.0, 14.0, 0.05, const Color(0xFFF1E4BE)),
      (-30.0, 56.0, 0.04, const Color(0xFFF6EED8)),
      (6.0, 58.0, -0.05, const Color(0xFFFFF6D5)),
    ];
    for (final n in notes) {
      c.save();
      c.translate(n.$1 + 14, n.$2 + 17);
      c.rotate(n.$3);
      rrect(c, -14, -17, 28, 34, 2, n.$4);
      line(c, -8, -8, 8, -8, 1.4, const Color(0xFF8D6E63));
      line(c, -8, -2, 8, -2, 1.4, const Color(0xFF8D6E63));
      line(c, -8, 4, 3, 4, 1.4, const Color(0xFF8D6E63));
      circle(c, 0, -17, 2.2, const Color(0xFFD32F2F));
      c.restore();
    }
    c.restore();
    if (_state.patronDecor.contains(PatronDecor.lights)) {
      _stringLights(
        c,
        Path()
          ..moveTo(s.rect.left - 2, s.rect.bottom - 8)
          ..lineTo(s.rect.left - 2, s.rect.top - 2)
          ..lineTo(s.rect.right + 2, s.rect.top - 2)
          ..lineTo(s.rect.right + 2, s.rect.bottom - 8),
      );
    }
    if (_state.questPending) {
      final bob = math.sin(clock * 5) * 3;
      circle(c, s.rect.right - 6, s.rect.top + 2 + bob, 11, const Color(0xFFF5A623));
      rrect(c, s.rect.right - 7.5, s.rect.top - 5 + bob, 3, 8, 1.5, const Color(0xFF4A2B00));
      circle(c, s.rect.right - 6, s.rect.top + 7 + bob, 1.8, const Color(0xFF4A2B00));
    }
  }

  void _paintShelf(Canvas c, _Hotspot s) {
    final r = s.rect;
    rrect(c, r.left, r.top, r.width, r.height, 4, const Color(0xFF6F4727));
    rrect(c, r.left + 6, r.top + 6, r.width - 12, r.height - 12, 2, const Color(0xFF4A2F1A));
    final colors = [
      const Color(0xFFB23A3A), const Color(0xFF3F6BB2), const Color(0xFF3A8F5A), const Color(0xFFD9A441),
      const Color(0xFF7B4FB2), const Color(0xFFB2603A), const Color(0xFF2F8F8F),
    ];
    final trophies = _state.trophies;
    for (var row = 0; row < 4; row++) {
      final y = r.top + 10 + row * 50;
      rrect(c, r.left + 6, y + 40, r.width - 12, 5, 0, const Color(0xFF6F4727));
      // The top shelf holds the first six trophies instead of books, and the second the next six.
      final firstOnRow = row * 6;
      if (row < 2 && trophies.length > firstOnRow) {
        for (var t = firstOnRow; t < trophies.length && t < firstOnRow + 6; t++) {
          _trophy(c, trophies[t], r.left + 20 + (t - firstOnRow) * 14.5, y + 40);
        }
        continue;
      }
      var x = r.left + 10.0;
      var i = row * 3;
      while (x < r.right - 18) {
        final w = 7.0 + (i * 5 % 4);
        final h = 28.0 + (i * 7 % 10);
        rrect(c, x, y + 40 - h, w, h, 1.5, colors[i % colors.length]);
        x += w + 1.5;
        i++;
      }
    }
    // Open ledger on the third shelf, so the trophies' two rows stay clear. It glows a little when
    // there is history.
    rrect(c, r.center.dx - 18, r.top + 120, 36, 10, 2, const Color(0xFFF6EED8));
    line(c, r.center.dx, r.top + 120, r.center.dx, r.top + 130, 1.2, const Color(0xFF8D6E63));
    if (s.wobble > 0) {
      final w = math.sin(s.wobble * math.pi * 5) * 1.5 * s.wobble;
      oval(c, r.center.dx + w, r.top + 116, 3, 2, const Color(0xFFFFF59D));
    }
  }

  /// One small trophy standing on a shelf, [x] the middle of its plinth and
  /// [baseY] the shelf board. Each is about 14 wide and 28 tall.
  void _trophy(Canvas c, TrophyShape shape, double x, double baseY) {
    const gold = Color(0xFFE6B83C);
    const goldDark = Color(0xFFB8860B);
    rrect(c, x - 6, baseY - 3, 12, 3, 1, const Color(0xFF8D6E63));
    final b = baseY - 3;
    switch (shape) {
      case TrophyShape.cup:
        rrect(c, x - 1.5, b - 8, 3, 8, 0, goldDark);
        c.drawPath(
          Path()
            ..moveTo(x - 6, b - 26)
            ..lineTo(x + 6, b - 26)
            ..quadraticBezierTo(x + 6, b - 10, x, b - 9)
            ..quadraticBezierTo(x - 6, b - 10, x - 6, b - 26)
            ..close(),
          Paint()..color = gold,
        );
        strokePath(c, Path()..moveTo(x - 6, b - 23)..quadraticBezierTo(x - 10, b - 22, x - 6, b - 16), 1.4, goldDark);
        strokePath(c, Path()..moveTo(x + 6, b - 23)..quadraticBezierTo(x + 10, b - 22, x + 6, b - 16), 1.4, goldDark);
        rrect(c, x - 3.5, b - 24, 2, 8, 1, const Color(0x66FFFFFF));
      case TrophyShape.star:
        rrect(c, x - 1.5, b - 8, 3, 8, 0, goldDark);
        final pts = <double>[];
        for (var i = 0; i < 10; i++) {
          final a = -math.pi / 2 + i * math.pi / 5;
          final rad = i.isEven ? 8.5 : 3.6;
          pts
            ..add(x + math.cos(a) * rad)
            ..add(b - 18 + math.sin(a) * rad);
        }
        fillPath(c, poly(pts), gold);
        circle(c, x, b - 18, 1.8, const Color(0xFFFFF3D6));
      case TrophyShape.shield:
        c.drawPath(
          Path()
            ..moveTo(x - 6, b - 26)
            ..lineTo(x + 6, b - 26)
            ..lineTo(x + 6, b - 14)
            ..quadraticBezierTo(x + 6, b - 5, x, b - 3)
            ..quadraticBezierTo(x - 6, b - 5, x - 6, b - 14)
            ..close(),
          Paint()..color = const Color(0xFF3F6BB2),
        );
        line(c, x, b - 26, x, b - 4, 1.6, gold);
        line(c, x - 6, b - 17, x + 6, b - 17, 1.6, gold);
        circle(c, x, b - 17, 2.2, gold);
      case TrophyShape.sun:
        final glow = 0.7 + 0.3 * math.sin(clock * 2);
        rrect(c, x - 1.5, b - 8, 3, 8, 0, goldDark);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          line(c, x + math.cos(a) * 6, b - 17 + math.sin(a) * 6, x + math.cos(a) * 9.5, b - 17 + math.sin(a) * 9.5, 1.6, const Color(0xFFF2994A));
        }
        circle(c, x, b - 17, 5.4, Color.lerp(const Color(0xFFF2994A), const Color(0xFFFFD36B), glow)!);
      case TrophyShape.lantern:
        final glow = 0.6 + 0.4 * math.sin(clock * 3);
        strokePath(c, Path()..moveTo(x - 4, b - 22)..quadraticBezierTo(x, b - 30, x + 4, b - 22), 1.3, const Color(0xFFC49A4A));
        rrect(c, x - 5.5, b - 22, 11, 3, 1, const Color(0xFFC49A4A));
        rrect(c, x - 5, b - 19, 10, 13, 2, Color.lerp(const Color(0xFFFFE9A8), const Color(0xFFFFC857), glow)!);
        circle(c, x, b - 13, 2.4, const Color(0xFFFFB02E));
        rrect(c, x - 5.5, b - 6, 11, 3, 1, const Color(0xFFC49A4A));
        line(c, x, b - 19, x, b - 6, 1, const Color(0xFFC49A4A));
      case TrophyShape.chime:
        strokePath(c, Path()..moveTo(x - 6, b - 8)..lineTo(x - 6, b - 22)..quadraticBezierTo(x, b - 29, x + 6, b - 22)..lineTo(x + 6, b - 8), 1.6, const Color(0xFFCFD8DC));
        for (var i = 0; i < 3; i++) {
          final bx = x - 3.6 + i * 3.6;
          final sway = math.sin(clock * 1.8 + i * 1.3) * 0.6;
          line(c, bx, b - 23 + (i == 1 ? -2 : 0), bx + sway, b - 17, 0.9, const Color(0xFFCFD8DC));
          c.drawPath(
            Path()
              ..moveTo(bx + sway - 1.2, b - 17)
              ..lineTo(bx + sway + 1.2, b - 17)
              ..lineTo(bx + sway + 2.4, b - 11)
              ..lineTo(bx + sway - 2.4, b - 11)
              ..close(),
            Paint()..color = const Color(0xFFD9A441),
          );
        }
      case TrophyShape.table:
        // A long table with a cloth, two plates and a candle.
        rrect(c, x - 7, b - 12, 14, 3, 1, const Color(0xFFF6EED8));
        rrect(c, x - 6, b - 9, 2, 8, 0, const Color(0xFF8D5E3C));
        rrect(c, x + 4, b - 9, 2, 8, 0, const Color(0xFF8D5E3C));
        circle(c, x - 3.5, b - 13.5, 1.8, const Color(0xFFFFFFFF));
        circle(c, x + 3.5, b - 13.5, 1.8, const Color(0xFFFFFFFF));
        rrect(c, x - 0.8, b - 19, 1.6, 6, 0, const Color(0xFFFFF3D6));
        final f = 1 + math.sin(clock * 6) * 0.15;
        oval(c, x, b - 20.5, 1.5 * f, 2.4 * f, const Color(0xFFFFB300));
      case TrophyShape.crown:
        rrect(c, x - 1.5, b - 7, 3, 7, 0, goldDark);
        c.drawPath(
          Path()
            ..moveTo(x - 8, b - 10)
            ..lineTo(x - 8, b - 24)
            ..lineTo(x - 4, b - 18)
            ..lineTo(x, b - 26)
            ..lineTo(x + 4, b - 18)
            ..lineTo(x + 8, b - 24)
            ..lineTo(x + 8, b - 10)
            ..close(),
          Paint()..color = gold,
        );
        rrect(c, x - 8, b - 12, 16, 3, 1, goldDark);
        circle(c, x, b - 17, 1.6, const Color(0xFFE53935));
      case TrophyShape.flame:
        // A small banked fire in a stone cradle: a low red glow with one steady flame.
        final glow = 0.7 + 0.3 * math.sin(clock * 2.4);
        oval(c, x, b - 5, 7, 4, const Color(0xFF6D5A4A));
        oval(c, x, b - 7, 5, 2.4, Color.lerp(const Color(0xFFBF360C), const Color(0xFFFF7043), glow)!);
        final flick = math.sin(clock * 7) * 0.8;
        c.drawPath(
          Path()
            ..moveTo(x, b - 25 + flick)
            ..quadraticBezierTo(x + 6, b - 15, x + 4, b - 9)
            ..quadraticBezierTo(x, b - 6, x - 4, b - 9)
            ..quadraticBezierTo(x - 6, b - 15, x, b - 25 + flick)
            ..close(),
          Paint()..color = const Color(0xFFFF7043),
        );
        oval(c, x, b - 12, 2.2, 4, const Color(0xFFFFCA28));
    }
  }

  void _paintGate(Canvas c, _Hotspot s) {
    final r = s.rect;
    final open = _state.canAdventure;
    final pulse = open ? 0.75 + math.sin(clock * 3) * 0.25 : 0.0;
    final arch = Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + 60)
      ..quadraticBezierTo(r.left, r.top, r.center.dx, r.top)
      ..quadraticBezierTo(r.right, r.top, r.right, r.top + 60)
      ..lineTo(r.right, r.bottom)
      ..close();
    fillPath(c, arch, const Color(0xFF7A6A5A));
    final inner = Path()
      ..moveTo(r.left + 10, r.bottom)
      ..lineTo(r.left + 10, r.top + 62)
      ..quadraticBezierTo(r.left + 10, r.top + 12, r.center.dx, r.top + 12)
      ..quadraticBezierTo(r.right - 10, r.top + 12, r.right - 10, r.top + 62)
      ..lineTo(r.right - 10, r.bottom)
      ..close();
    fillPath(c, inner, open ? const Color(0xFF2B1E3A) : const Color(0xFF3A3028));
    if (open) {
      fillPath(c, inner, Color.fromRGBO(90, 209, 196, 0.55 * pulse));
      for (var i = 0; i < 5; i++) {
        final a = clock * 1.4 + i * 1.3;
        circle(c, r.center.dx + math.cos(a) * 18, r.center.dy + 20 + math.sin(a * 1.3) * 40, 2.4, const Color(0xCCB2EBF2));
      }
    } else {
      // Locked: a padlock until there is energy to spend.
      rrect(c, r.center.dx - 11, r.center.dy + 10, 22, 18, 3, const Color(0xFF9E9E9E));
      strokePath(c, Path()..addArc(Rect.fromCircle(center: Offset(r.center.dx, r.center.dy + 10), radius: 7), math.pi, math.pi), 3, const Color(0xFFBDBDBD));
      circle(c, r.center.dx, r.center.dy + 19, 2.2, const Color(0xFF424242));
    }
    // Stone blocks.
    for (var i = 0; i < 6; i++) {
      line(c, r.left, r.top + 70 + i * 28, r.left + 10, r.top + 70 + i * 28, 1.2, const Color(0xFF5E5145));
      line(c, r.right - 10, r.top + 70 + i * 28, r.right, r.top + 70 + i * 28, 1.2, const Color(0xFF5E5145));
    }
    if (_state.patronDecor.contains(PatronDecor.lights)) {
      _stringLights(
        c,
        Path()
          ..moveTo(r.left - 4, r.bottom - 6)
          ..lineTo(r.left - 4, r.top + 60)
          ..quadraticBezierTo(r.left - 4, r.top - 4, r.center.dx, r.top - 4)
          ..quadraticBezierTo(r.right + 4, r.top - 4, r.right + 4, r.top + 60)
          ..lineTo(r.right + 4, r.bottom - 6),
      );
    }
  }

  /// Warm bulbs along [wire], twinkling gently. Part of the Patron Pack.
  void _stringLights(Canvas c, Path wire) {
    strokePath(c, wire, 1.2, const Color(0xFF4A2F1A));
    const colors = [Color(0xFFFFE08A), Color(0xFFFFB3A7), Color(0xFFA7E3FF), Color(0xFFC8F0A8)];
    var i = 0;
    for (final m in wire.computeMetrics()) {
      for (var d = 10.0; d < m.length; d += 20) {
        final p = m.getTangentForOffset(d)!.position;
        final tw = 0.55 + 0.45 * math.sin(clock * 2.6 + i * 1.7);
        final col = colors[i % colors.length];
        circle(c, p.dx, p.dy, 5.5, col.withValues(alpha: 0.22 * tw));
        circle(c, p.dx, p.dy, 2.4, Color.lerp(const Color(0xFF8A7A5A), col, 0.5 + 0.5 * tw)!);
        i++;
      }
    }
  }

  void _paintDummy(Canvas c, _Hotspot s) {
    final r = s.rect;
    final w = math.sin(s.wobble * math.pi * 5) * 6 * s.wobble;
    c.save();
    c.translate(r.center.dx, r.bottom - 6);
    c.rotate(w * 0.04);
    oval(c, 0, 4, 26, 5, const Color(0x2E000000));
    rrect(c, -4, -70, 8, 70, 2, const Color(0xFF8D6E63));
    rrect(c, -26, -56, 52, 8, 3, const Color(0xFF8D6E63));
    circle(c, 0, -78, 12, const Color(0xFFD7B98E));
    circle(c, 0, -78, 8, const Color(0xFFFFFFFF));
    circle(c, 0, -78, 5, const Color(0xFFE53935));
    circle(c, 0, -78, 2, const Color(0xFFFFFFFF));
    rrect(c, -12, -62, 24, 30, 5, const Color(0xFFC9A56A));
    c.restore();
  }

  void _paintStand(Canvas c, _Hotspot s) {
    final r = s.rect;
    final x = r.center.dx;
    final look = _state.look;
    oval(c, x, r.bottom - 2, 22, 5, const Color(0x2E000000));
    rrect(c, x - 3, r.bottom - 36, 6, 34, 2, const Color(0xFF8D6E63));
    rrect(c, x - 16, r.bottom - 6, 32, 6, 2, const Color(0xFF6F4727));
    rrect(c, x - 16, r.bottom - 74, 32, 42, 8, look.tunic);
    rrect(c, x - 16, r.bottom - 52, 32, 4, 0, const Color(0xFF6D4C41));
    circle(c, x, r.bottom - 84, 11, const Color(0xFFD7B98E));
    if (look.equipped.contains('wayfarer_cap')) {
      fillPath(c, Path()..moveTo(x - 12, r.bottom - 86)..quadraticBezierTo(x - 11, r.bottom - 100, x, r.bottom - 100)..quadraticBezierTo(x + 11, r.bottom - 100, x + 12, r.bottom - 86)..close(), const Color(0xFF558B2F));
    }
    if (look.equipped.contains('iron_blade') || look.equipped.contains('wooden_sword')) {
      line(c, x + 22, r.bottom - 20, x + 22, r.bottom - 66, 3.4, look.equipped.contains('iron_blade') ? const Color(0xFFCFD8DC) : const Color(0xFFA1887F));
      line(c, x + 17, r.bottom - 26, x + 27, r.bottom - 26, 3, const Color(0xFFF2C94C));
    }
    if (_state.itemsOwned > 0) {
      final tw = 0.5 + 0.5 * math.sin(clock * 4);
      circle(c, x + 16, r.bottom - 100, 2 + tw * 1.4, Color.fromRGBO(255, 245, 157, 0.6 + tw * 0.4));
    }
  }
}

// ---------------------------------------------------------------------------
// Components
// ---------------------------------------------------------------------------

class _Hotspot extends PositionComponent with TapCallbacks {
  _Hotspot(this.target, this.label, this.rect, this.stand, this.painter)
      : super(position: Vector2(rect.left, rect.top), size: Vector2(rect.width, rect.height)) {
    _text = _label(label);
  }

  final HubTarget target;
  final String label;

  /// World-space bounds of the object.
  final Rect rect;

  /// Where the hero stands to use it.
  final Vector2 stand;

  final void Function(Canvas, _Hotspot) painter;
  late final HubScene scene;
  late final TextPainter _text;
  double wobble = 0;
  bool _pressed = false;

  @override
  void update(double dt) {
    if (wobble > 0) wobble = math.max(0, wobble - dt * 1.6);
  }

  @override
  void onTapDown(TapDownEvent event) => _pressed = true;

  @override
  void onTapCancel(TapCancelEvent event) => _pressed = false;

  @override
  void onTapUp(TapUpEvent event) {
    _pressed = false;
    scene.activate(target);
  }

  @override
  void render(Canvas canvas) {
    // The painters work in world coordinates, so undo this component's offset.
    canvas.save();
    canvas.translate(-position.x, -position.y);
    if (_pressed) {
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.scale(1.03, 1.03);
      canvas.translate(-rect.center.dx, -rect.center.dy);
    }
    if (scene._state.highlight == target) _drawHint(canvas);
    painter(canvas, this);
    _drawSign(canvas);
    canvas.restore();
  }

  /// A soft golden glow behind the object, for a brand-new player. It breathes
  /// slowly, or just stays lit when motion is reduced.
  void _drawHint(Canvas canvas) {
    final pulse = scene.reducedMotion ? 0.6 : 0.5 + 0.5 * math.sin(scene.clock * 2.6);
    final r = rect.inflate(8 + pulse * 5);
    final shape = RRect.fromRectAndRadius(r, const Radius.circular(20));
    canvas.drawRRect(shape, Paint()..color = Color.fromRGBO(255, 224, 130, 0.14 + 0.16 * pulse));
    canvas.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Color.fromRGBO(255, 214, 90, 0.45 + 0.4 * pulse),
    );
  }

  void _drawSign(Canvas canvas) {
    final w = _text.width + 18;
    final x = rect.center.dx - w / 2;
    final y = target == HubTarget.journal
        ? rect.bottom - 86
        : rect.bottom + (target == HubTarget.train || target == HubTarget.hero ? 4 : 8);
    rrect(canvas, x, y, w, 20, 6, const Color(0xFF5A3A22));
    rrect(canvas, x + 1.5, y + 1.5, w - 3, 17, 5, const Color(0xFF7A5230));
    _text.paint(canvas, Offset(x + 9, y + 2.5));
  }
}

TextPainter _label(String text, {double size = 12, Color color = const Color(0xFFFFF3D6)}) {
  return TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color)),
    textDirection: TextDirection.ltr,
  )..layout();
}

class _FloorTap extends PositionComponent with TapCallbacks {
  _FloorTap(this.scene)
      : super(position: Vector2(-900, HubScene.floorTop), size: Vector2(2160, 700));

  final HubScene scene;

  @override
  void onTapUp(TapUpEvent event) {
    final p = event.localPosition + position;
    scene.walkTo(Vector2(p.x, p.y));
  }
}

class _ChadTap extends PositionComponent with TapCallbacks {
  _ChadTap(this.scene);

  final HubScene scene;

  @override
  void onTapUp(TapUpEvent event) {
    scene.sfx(Sfx.tap);
    scene.chad.state.attack = 1;
    scene.tween(0.4, (t) => scene.chad.state.attack = 1 - t);
    scene.onChadTap?.call();
  }
}

/// Chad's speech bubble, with a small pop whenever the text changes.
class _Bubble extends PositionComponent {
  _Bubble(String text) {
    setText(text);
  }

  TextPainter? _tp;
  double _age = 0;
  bool hidden = false;

  void setText(String text) {
    _tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3A2A1C), height: 1.25),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      maxLines: 6,
      ellipsis: '…',
    )..layout(maxWidth: 160);
    _age = 0;
  }

  @override
  void update(double dt) => _age += dt;

  @override
  void render(Canvas canvas) {
    final tp = _tp;
    if (tp == null || hidden) return;
    final pop = _age < 0.25 ? Curves.easeOutBack.transform(_age / 0.25) : 1.0;
    final w = tp.width + 24, h = tp.height + 18;
    canvas.save();
    // Anchor the bubble's bottom-left (where its tail points at Chad).
    canvas.translate(0, 0);
    canvas.scale(pop, pop);
    canvas.translate(0, -h);
    rrect(canvas, 2, 3, w, h, 12, const Color(0x40000000));
    rrect(canvas, 0, 0, w, h, 12, const Color(0xFFFFFFFF));
    fillPath(canvas, poly([w * 0.62, h - 1, w * 0.62 + 14, h - 1, w * 0.62 + 20, h + 12]), const Color(0xFFFFFFFF));
    tp.paint(canvas, const Offset(12, 9));
    canvas.restore();
  }
}

/// The hall: walls, floor, windows with day/night light, banner and torches.
class HallBackdrop extends Component {
  HallBackdrop(this.state) {
    final r = math.Random(3);
    for (var i = 0; i < 16; i++) {
      _motes.add([r.nextDouble(), r.nextDouble(), 0.4 + r.nextDouble()]);
    }
    for (var i = 0; i < 24; i++) {
      _stars.add(Offset(r.nextDouble(), r.nextDouble()));
    }
  }

  HubState state;
  final List<List<double>> _motes = [];
  final List<Offset> _stars = [];
  double _t = 0;
  final Paint _p = Paint();

  @override
  void update(double dt) => _t += dt;

  /// 0 = full day, 1 = deep night, easing through dusk and dawn.
  double get _night {
    final h = state.hour;
    if (h >= 21 || h < 5) return 1;
    if (h >= 18) return (h - 17) / 4;
    if (h < 8) return (8 - h) / 3;
    return 0;
  }

  @override
  void render(Canvas canvas) {
    const left = -700.0, width = 1760.0;
    final night = _night;

    // Wall.
    _p.color = const Color(0xFFD8BB8C);
    canvas.drawRect(Rect.fromLTWH(left, -300, width, 300 + HubScene.floorTop), _p);
    _p.color = const Color(0x14000000);
    for (var y = -280.0; y < 300; y += 32) {
      canvas.drawRect(Rect.fromLTWH(left, y, width, 1.4), _p);
      final off = ((y / 32).floor() % 2) * 28.0;
      for (var x = left + off; x < left + width; x += 56) {
        canvas.drawRect(Rect.fromLTWH(x, y, 1.4, 32), _p);
      }
    }
    // Wainscot.
    _p.color = const Color(0xFFB8935F);
    canvas.drawRect(Rect.fromLTWH(left, 300, width, HubScene.floorTop - 300), _p);
    _p.color = const Color(0xFF9C7A48);
    canvas.drawRect(Rect.fromLTWH(left, 300, width, 5), _p);

    _windows(canvas, night);
    _bunting(canvas);

    // Banner.
    fillPath(canvas, poly([160, 40, 200, 40, 200, 130, 180, 148, 160, 130]), const Color(0xFFB23A3A));
    fillPath(canvas, poly([164, 44, 196, 44, 196, 128, 180, 143, 164, 128]), const Color(0xFFC54A4A));
    circle(canvas, 180, 82, 13, const Color(0xFFF2C94C));
    strokePath(canvas, Path()..addArc(Rect.fromCircle(center: const Offset(180, 82), radius: 7), 0.6, 4.9), 3, const Color(0xFFB8860B));
    if (state.patronDecor.contains(PatronDecor.rosette)) _rosette(canvas);

    // Torches.
    for (final x in [136.0, 224.0]) {
      rrect(canvas, x - 2.5, 112, 5, 22, 1, const Color(0xFF5A3A22));
      final f = 1 + math.sin(_t * 11 + x) * 0.12;
      _p.shader = Gradient.radial(Offset(x, 106), 60 * f, [Color.fromRGBO(255, 190, 80, 0.30 + night * 0.15), const Color(0x00FFBE50)]);
      canvas.drawCircle(Offset(x, 106), 60 * f, _p);
      _p.shader = null;
      oval(canvas, x, 104, 6 * f, 10 * f, const Color(0xFFFFB300));
      oval(canvas, x, 106, 3 * f, 6 * f, const Color(0xFFFF7043));
    }

    // Floor.
    _p.color = const Color(0xFF8C5E35);
    canvas.drawRect(Rect.fromLTWH(left, HubScene.floorTop, width, 500), _p);
    _p.color = const Color(0xFF6F4727);
    for (var i = 0; i < 9; i++) {
      final y = HubScene.floorTop + 14 + i * 30.0 + i * i * 1.2;
      canvas.drawRect(Rect.fromLTWH(left, y, width, 1.6), _p);
      final off = (i % 2) * 40.0;
      for (var x = left + off; x < left + width; x += 80 + i * 2.0) {
        canvas.drawRect(Rect.fromLTWH(x, y, 1.4, 30 + i * 1.2), _p);
      }
    }
    _p.color = const Color(0x22000000);
    canvas.drawRect(Rect.fromLTWH(left, HubScene.floorTop, width, 8), _p);
    // Rug.
    _p.color = const Color(0xFF7A2E2E);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(70, 468, 220, 120), const Radius.circular(10)), _p);
    _p.color = const Color(0xFFB8903A);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(78, 476, 204, 104), const Radius.circular(8)), _p..style = PaintingStyle.stroke..strokeWidth = 3);
    _p.style = PaintingStyle.fill;

    _keepsakes(canvas, night);
    if (state.patronDecor.contains(PatronDecor.lantern)) _lanternTree(canvas, night);

    // Night tint over everything so far; torches stay warm on top.
    if (night > 0) {
      _p.color = Color.fromRGBO(10, 14, 48, 0.34 * night);
      canvas.drawRect(Rect.fromLTWH(left, -300, width, 1400), _p);
      for (final x in [136.0, 224.0]) {
        _p.shader = Gradient.radial(Offset(x, 112), 80, [Color.fromRGBO(255, 190, 80, 0.30 * night), const Color(0x00FFBE50)]);
        canvas.drawCircle(Offset(x, 112), 80, _p);
        _p.shader = null;
      }
    }
  }

  /// Where each earned pennant hangs, so earlier ones never shift as more are
  /// added. They fill outward from the banner.
  static const _pennantSlots = <double>[148, 212, 116, 244, 84, 276, 52, 308, 20, 340];

  double _ropeY(double x) {
    final k = (x - 180) / 190;
    return 30 + 22 * (1 - k * k);
  }

  /// Bunting across the top of the wall: one pennant for each milestone the
  /// player has earned. Nothing here is sold, and nothing is ever taken down.
  void _bunting(Canvas canvas) {
    final pennants = state.pennants;
    if (pennants.isEmpty) return;
    final rope = Path()..moveTo(-10, _ropeY(-10));
    for (var x = 0.0; x <= 370; x += 10) {
      rope.lineTo(x, _ropeY(x));
    }
    strokePath(canvas, rope, 1.6, const Color(0xFF6F4727));
    for (var i = 0; i < pennants.length && i < _pennantSlots.length; i++) {
      final x = _pennantSlots[i];
      final sway = math.sin(_t * 1.6 + i * 1.7) * 1.4;
      final top = _ropeY(x);
      fillPath(
        canvas,
        poly([x - 10, top - 0.5, x + 10, top - 0.5, x + sway, top + 26]),
        Color(pennants[i]),
      );
      fillPath(
        canvas,
        poly([x - 10, top - 0.5, x + 10, top - 0.5, x + 8, top + 3, x - 8, top + 3]),
        const Color(0x26FFFFFF),
      );
    }
  }


  /// Where each keepsake stands on the floor by the left wall, so earlier ones never
  /// shift as more are earned.
  static const _keepsakeSlots = <double>[54, 76, 98, 120];

  /// Small things that stand on the hall floor for each story season finished.
  /// Earned, never sold, and never taken away.
  void _keepsakes(Canvas canvas, double night) {
    const base = 408.0;
    for (var i = 0; i < state.keepsakes.length && i < _keepsakeSlots.length; i++) {
      final x = _keepsakeSlots[i];
      oval(canvas, x, base + 1, 10, 2.6, const Color(0x2E000000));
      switch (state.keepsakes[i]) {
        case KeepsakeShape.lamp:
          // A small harbour lamp on a post, glowing a little more at night.
          final glow = 0.7 + 0.3 * math.sin(_t * 2.2 + 1) + night * 0.3;
          rrect(canvas, x - 1.5, base - 20, 3, 20, 1, const Color(0xFF5D4037));
          circle(canvas, x, base - 24, 10, Color.fromRGBO(255, 200, 87, 0.22 * glow.clamp(0.0, 1.5)));
          rrect(canvas, x - 5, base - 30, 10, 12, 2, const Color(0xFFFFE9A8));
          circle(canvas, x, base - 24, 2.6, const Color(0xFFFFB02E));
          rrect(canvas, x - 6, base - 31, 12, 3, 1, const Color(0xFFC49A4A));
        case KeepsakeShape.chime:
          // A short stand with three small bells, swaying.
          line(canvas, x - 6, base, x - 6, base - 22, 1.6, const Color(0xFFCFD8DC));
          line(canvas, x + 6, base, x + 6, base - 22, 1.6, const Color(0xFFCFD8DC));
          line(canvas, x - 6, base - 22, x + 6, base - 22, 1.6, const Color(0xFFCFD8DC));
          for (var b = 0; b < 3; b++) {
            final bx = x - 4 + b * 4.0 + math.sin(_t * 1.8 + b * 1.3) * 0.7;
            line(canvas, bx, base - 22, bx, base - 17, 0.9, const Color(0xFFCFD8DC));
            fillPath(canvas, poly([bx - 1.4, base - 17, bx + 1.4, base - 17, bx + 2.8, base - 10, bx - 2.8, base - 10]), const Color(0xFFD9A441));
          }
        case KeepsakeShape.table:
          // A small laid table with a candle.
          rrect(canvas, x - 10, base - 12, 20, 3, 1, const Color(0xFFF6EED8));
          rrect(canvas, x - 8, base - 9, 2.4, 9, 0, const Color(0xFF8D5E3C));
          rrect(canvas, x + 5.6, base - 9, 2.4, 9, 0, const Color(0xFF8D5E3C));
          circle(canvas, x - 5, base - 13.5, 2, const Color(0xFFFFFFFF));
          circle(canvas, x + 5, base - 13.5, 2, const Color(0xFFFFFFFF));
          rrect(canvas, x - 1, base - 20, 2, 7, 0, const Color(0xFFFFF3D6));
          final f = 1 + math.sin(_t * 7) * 0.15;
          oval(canvas, x, base - 22, 1.8 * f, 2.8 * f, const Color(0xFFFFB300));
        case KeepsakeShape.hearth:
          // A small stone hearth with one low, steady flame.
          oval(canvas, x, base - 5, 10, 5, const Color(0xFF6D5A4A));
          oval(canvas, x, base - 7, 7, 3, Color.lerp(const Color(0xFFBF360C), const Color(0xFFFF7043), 0.6 + 0.4 * math.sin(_t * 2.4))!);
          final flick = math.sin(_t * 6) * 0.8;
          canvas.drawPath(
            Path()
              ..moveTo(x, base - 24 + flick)
              ..quadraticBezierTo(x + 6, base - 15, x + 4, base - 9)
              ..quadraticBezierTo(x, base - 6, x - 4, base - 9)
              ..quadraticBezierTo(x - 6, base - 15, x, base - 24 + flick)
              ..close(),
            Paint()..color = const Color(0xFFFF7043),
          );
          oval(canvas, x, base - 12, 2.2, 4, const Color(0xFFFFCA28));
      }
    }
  }

  /// A patron rosette pinned to the banner.
  void _rosette(Canvas canvas) {
    fillPath(canvas, poly([172, 118, 178, 118, 174, 134, 170, 130]), const Color(0xFFF2C94C));
    fillPath(canvas, poly([182, 118, 188, 118, 190, 130, 186, 134]), const Color(0xFFF2C94C));
    circle(canvas, 180, 114, 9, const Color(0xFFF2C94C));
    circle(canvas, 180, 114, 6.6, const Color(0xFFB23A3A));
    final heart = Path()
      ..moveTo(180, 118.4)
      ..cubicTo(175, 114.8, 176.4, 110.6, 180, 112.6)
      ..cubicTo(183.6, 110.6, 185, 114.8, 180, 118.4)
      ..close();
    fillPath(canvas, heart, const Color(0xFFFFE9B0));
  }

  /// A potted lantern tree on the floor by the wall, glowing a little more at
  /// night.
  void _lanternTree(Canvas canvas, double night) {
    const x = 24.0, base = 414.0;
    oval(canvas, x, base + 2, 18, 4, const Color(0x2E000000));
    rrect(canvas, x - 9, base - 14, 18, 16, 3, const Color(0xFF8A5A38));
    rrect(canvas, x - 10, base - 16, 20, 4, 2, const Color(0xFF6F4727));
    rrect(canvas, x - 1.6, base - 48, 3.2, 34, 1.6, const Color(0xFF5A3A22));
    circle(canvas, x, base - 56, 15, const Color(0xFF3F8F5A));
    circle(canvas, x - 9, base - 46, 10, const Color(0xFF4FA56A));
    circle(canvas, x + 10, base - 48, 9, const Color(0xFF357F4D));
    for (var i = 0; i < 4; i++) {
      final lx = x + (i - 1.5) * 9;
      final ly = base - 60 + (i % 2) * 14;
      final glow = 0.55 + 0.45 * math.sin(_t * 2.2 + i * 1.3);
      _p.shader = Gradient.radial(Offset(lx, ly), 11, [Color.fromRGBO(255, 214, 120, 0.30 + night * 0.25 * glow), const Color(0x00FFD678)]);
      canvas.drawCircle(Offset(lx, ly), 11, _p);
      _p.shader = null;
      rrect(canvas, lx - 2.4, ly - 3.4, 4.8, 6.8, 2, Color.lerp(const Color(0xFFFFE08A), const Color(0xFFFFB347), glow)!);
    }
  }

  void _windows(Canvas canvas, double night) {
    for (final x in [34.0, 270.0]) {
      final skyDay = const Color(0xFFA8D8F0);
      final skyNight = const Color(0xFF1B2A56);
      final sky = Color.lerp(skyDay, skyNight, night)!;
      rrect(canvas, x - 5, 56, 66, 94, 6, const Color(0xFF7A5230));
      rrect(canvas, x, 62, 56, 82, 3, sky);
      if (night > 0.4) {
        for (var i = 0; i < _stars.length; i++) {
          final s = _stars[i];
          final tw = 0.5 + 0.5 * math.sin(_t * 2 + i);
          _p.color = Color.fromRGBO(255, 255, 255, 0.35 + 0.5 * tw);
          canvas.drawCircle(Offset(x + 4 + s.dx * 48, 66 + s.dy * 70), 0.9, _p);
        }
        circle(canvas, x + 38, 84, 8, const Color(0xFFF1F4C9));
      } else if (night < 0.3) {
        circle(canvas, x + 40, 84, 9, const Color(0xFFFFF2A8));
      } else {
        circle(canvas, x + 40, 112, 10, const Color(0xFFFFB067));
      }
      line(canvas, x + 28, 62, x + 28, 144, 3, const Color(0xFF7A5230));
      line(canvas, x, 103, x + 56, 103, 3, const Color(0xFF7A5230));

      // Light beam onto the floor.
      final beam = Path()
        ..moveTo(x, 144)
        ..lineTo(x + 56, 144)
        ..lineTo(x + 130, 372)
        ..lineTo(x + 20, 372)
        ..close();
      final k = (1 - night) * (0.2 + math.sin(_t * 0.8 + x) * 0.03);
      final moon = night * 0.10;
      _p.color = night > 0.5
          ? Color.fromRGBO(170, 190, 255, moon)
          : Color.fromRGBO(255, 246, 200, k);
      canvas.drawPath(beam, _p);
    }
    // Dust motes drifting through the light.
    if (_night < 0.6) {
      _p.color = Color.fromRGBO(255, 250, 220, 0.5);
      for (final m in _motes) {
        final prog = (m[1] + _t * 0.012 * m[2]) % 1;
        final x = 40 + m[0] * 90 + prog * 70 + math.sin(_t * m[2] + m[0] * 9) * 4;
        final y = 150 + prog * 220;
        canvas.drawCircle(Offset(x, y), 1.1 * m[2], _p);
      }
    }
  }
}
