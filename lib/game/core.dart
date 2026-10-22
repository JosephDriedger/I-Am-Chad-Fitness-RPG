// ignore_for_file: prefer_initializing_formals

/// Shared building blocks for the game scenes: a base scene with a fixed
/// design resolution, tweens, floating text, particles and actors.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart' show Curve, Curves;
import 'package:flutter/painting.dart'
    show TextPainter, TextSpan, TextStyle, FontWeight, TextDirection;

import 'look.dart';

/// Haptic feedback strengths the scenes can ask for.
enum Haptic { light, medium, heavy }

/// Sound effects the scenes can ask for. See `lib/app/sound.dart`.
enum Sfx { tap, hit, skill, guard, heal, coin, levelUp, victory, defeat, whoosh, chest }

/// A [FlameGame] that lays out a fixed design area and scales it to fit.
///
/// Anything drawn outside the design area (backdrops do this) shows on
/// screens with a different aspect ratio, so there are never bars.
abstract class GameScene extends FlameGame {
  GameScene({
    required this.designWidth,
    required this.designHeight,
    this.reducedMotion = false,
    this.onSfx,
    this.onHaptic,
  });

  final double designWidth;
  final double designHeight;

  /// When true, tweens finish immediately and decorative effects are skipped.
  bool reducedMotion;

  void Function(Sfx sfx)? onSfx;
  void Function(Haptic h)? onHaptic;

  final Vector2 _shake = Vector2.zero();

  /// Elapsed scene time in seconds.
  double clock = 0;

  /// Where the camera looks, in design coordinates. Defaults to the centre.
  Vector2 get focus => Vector2(designWidth / 2, designHeight / 2);

  @override
  Color backgroundColor() => const Color(0xFF1B1410);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _fit();
  }

  void _fit() {
    if (size.x <= 0 || size.y <= 0) return;
    camera.viewfinder
      ..anchor = Anchor.center
      ..zoom = math.min(size.x / designWidth, size.y / designHeight)
      ..position = focus + _shake;
  }

  @override
  void update(double dt) {
    super.update(dt);
    clock += dt;
    _fit();
  }

  void sfx(Sfx s) => onSfx?.call(s);
  void haptic(Haptic h) => onHaptic?.call(h);

  /// Shakes the camera for [seconds]. Skipped when motion is reduced.
  Future<void> shakeCamera({double amount = 6, double seconds = 0.25}) async {
    if (reducedMotion) return;
    final rng = math.Random();
    await tween(seconds, (t) {
      final fade = 1 - t;
      _shake.setValues(
        (rng.nextDouble() * 2 - 1) * amount * fade,
        (rng.nextDouble() * 2 - 1) * amount * fade,
      );
    });
    _shake.setZero();
  }

  /// Runs [onTick] with 0..1 progress over [seconds]. Completes after the
  /// final tick; with reduced motion it completes on the next frame.
  Future<void> tween(
    double seconds,
    void Function(double t) onTick, {
    Curve curve = Curves.linear,
  }) {
    final tw = _Tween(reducedMotion ? 0 : seconds, onTick, curve);
    world.add(tw);
    return tw.done;
  }

  Future<void> pause(double seconds) => tween(seconds, (_) {});

  /// Floating number or word that rises and fades.
  void floatText(
    String text,
    Vector2 at, {
    Color color = const Color(0xFFFFFFFF),
    Color outline = const Color(0xFF3A1F12),
    double size = 20,
    double rise = 34,
    double life = 0.9,
  }) {
    world.add(FloatingText(
      text,
      color: color,
      outline: outline,
      size: size,
      rise: reducedMotion ? 0 : rise,
      life: reducedMotion ? life * 1.4 : life,
    )..position = at.clone());
  }

  /// Adds a particle burst. Skipped when motion is reduced.
  void burst(Burst b) {
    if (reducedMotion) return;
    world.add(b);
  }
}

class _Tween extends Component {
  _Tween(this.duration, this.onTick, this.curve);

  final double duration;
  final void Function(double) onTick;
  final Curve curve;
  double _elapsed = 0;
  final _completer = Completer<void>();

  Future<void> get done => _completer.future;

  @override
  void update(double dt) {
    _elapsed += dt;
    final raw = duration <= 0 ? 1.0 : (_elapsed / duration).clamp(0.0, 1.0);
    onTick(curve.transform(raw));
    if (raw >= 1) {
      if (!_completer.isCompleted) _completer.complete();
      removeFromParent();
    }
  }
}

/// Text that rises, pops in, and fades out.
class FloatingText extends PositionComponent {
  FloatingText(
    String text, {
    required Color color,
    required Color outline,
    required double size,
    required this.rise,
    required this.life,
  }) {
    TextPainter make(Paint? stroke, Color fill) => TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w800,
              foreground: stroke,
              color: stroke == null ? fill : null,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
    _fill = make(null, color);
    _outline = make(
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.28
        ..strokeJoin = StrokeJoin.round
        ..color = outline,
      outline,
    );
    priority = 100;
  }

  final double rise;
  final double life;
  late final TextPainter _fill;
  late final TextPainter _outline;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / life).clamp(0.0, 1.0);
    final pop = p < 0.15 ? 0.6 + (p / 0.15) * 0.5 : 1.1 - (p - 0.15) * 0.12;
    final alpha = p < 0.6 ? 1.0 : 1 - (p - 0.6) / 0.4;
    canvas.save();
    canvas.translate(0, -rise * Curves.easeOut.transform(p));
    canvas.scale(pop, pop);
    canvas.saveLayer(
      Rect.fromLTWH(-200, -100, 400, 200),
      Paint()..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0)),
    );
    canvas.translate(-_fill.width / 2, -_fill.height / 2);
    _outline.paint(canvas, Offset.zero);
    _fill.paint(canvas, Offset.zero);
    canvas.restore();
    canvas.restore();
  }
}

enum ParticleShape { dot, spark, confetti, plus, star }

class _Particle {
  _Particle(this.x, this.y, this.vx, this.vy, this.life, this.size, this.color,
      this.rot, this.vr);
  double x, y, vx, vy, life, size, rot, vr;
  Color color;
  double age = 0;
}

/// A one-shot burst of simple particles.
class Burst extends Component {
  Burst({
    required Vector2 at,
    required int count,
    required List<Color> colors,
    ParticleShape shape = ParticleShape.dot,
    double speed = 120,
    double spread = math.pi * 2,
    double direction = -math.pi / 2,
    double gravity = 260,
    double life = 0.8,
    double size = 3,
    double drag = 0.9,
    math.Random? random,
  })  : _shape = shape,
        _gravity = gravity,
        _drag = drag,
        _origin = at.clone() {
    final r = random ?? math.Random();
    for (var i = 0; i < count; i++) {
      final a = direction + (r.nextDouble() - 0.5) * spread;
      final v = speed * (0.4 + r.nextDouble() * 0.8);
      _ps.add(_Particle(
        0,
        0,
        math.cos(a) * v,
        math.sin(a) * v,
        life * (0.6 + r.nextDouble() * 0.6),
        size * (0.6 + r.nextDouble() * 0.9),
        colors[r.nextInt(colors.length)],
        r.nextDouble() * math.pi * 2,
        (r.nextDouble() - 0.5) * 12,
      ));
    }
    priority = 90;
  }

  factory Burst.hit(Vector2 at) => Burst(
        at: at,
        count: 14,
        colors: const [Color(0xFFFFFFFF), Color(0xFFFFE082), Color(0xFFFFB74D)],
        shape: ParticleShape.spark,
        speed: 160,
        gravity: 200,
        life: 0.45,
        size: 3,
      );

  factory Burst.heal(Vector2 at) => Burst(
        at: at,
        count: 10,
        colors: const [Color(0xFF81C784), Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
        shape: ParticleShape.plus,
        speed: 40,
        spread: math.pi * 0.9,
        gravity: -50,
        life: 1.0,
        size: 3.2,
      );

  factory Burst.confetti(Vector2 at, {int count = 60}) => Burst(
        at: at,
        count: count,
        colors: const [
          Color(0xFFF2C94C),
          Color(0xFFE53935),
          Color(0xFF42A5F5),
          Color(0xFF66BB6A),
          Color(0xFFAB47BC),
        ],
        shape: ParticleShape.confetti,
        speed: 260,
        spread: math.pi * 0.9,
        gravity: 340,
        life: 1.6,
        size: 3.4,
      );

  factory Burst.stars(Vector2 at, {int count = 16}) => Burst(
        at: at,
        count: count,
        colors: const [Color(0xFFFFF59D), Color(0xFFFFE082), Color(0xFFFFFFFF)],
        shape: ParticleShape.star,
        speed: 110,
        gravity: 30,
        life: 1.0,
        size: 4,
      );

  factory Burst.puff(Vector2 at) => Burst(
        at: at,
        count: 12,
        colors: const [Color(0xFFEFEBE9), Color(0xFFD7CCC8)],
        speed: 60,
        gravity: -20,
        life: 0.7,
        size: 5,
      );

  final List<_Particle> _ps = [];
  final ParticleShape _shape;
  final double _gravity;
  final double _drag;
  final Vector2 _origin;
  final Paint _paint = Paint();

  @override
  void update(double dt) {
    var alive = false;
    for (final p in _ps) {
      p.age += dt;
      if (p.age >= p.life) continue;
      alive = true;
      p.vx *= math.pow(_drag, dt * 10).toDouble();
      p.vy = p.vy * math.pow(_drag, dt * 10).toDouble() + _gravity * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rot += p.vr * dt;
    }
    if (!alive) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    for (final p in _ps) {
      if (p.age >= p.life) continue;
      final k = 1 - p.age / p.life;
      _paint.color = p.color.withValues(alpha: k.clamp(0.0, 1.0));
      final pos = Offset(_origin.x + p.x, _origin.y + p.y);
      switch (_shape) {
        case ParticleShape.dot:
          canvas.drawCircle(pos, p.size * (0.5 + k * 0.5), _paint);
        case ParticleShape.spark:
          canvas.save();
          canvas.translate(pos.dx, pos.dy);
          canvas.rotate(math.atan2(p.vy, p.vx));
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: p.size * 3.2 * k + 2, height: p.size * 0.7),
              const Radius.circular(2),
            ),
            _paint,
          );
          canvas.restore();
        case ParticleShape.confetti:
          canvas.save();
          canvas.translate(pos.dx, pos.dy);
          canvas.rotate(p.rot);
          canvas.scale(1, math.cos(p.rot * 1.7).abs() * 0.8 + 0.2);
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size * 2, height: p.size), _paint);
          canvas.restore();
        case ParticleShape.plus:
          final s = p.size;
          canvas.drawRect(Rect.fromCenter(center: pos, width: s * 2.6, height: s * 0.9), _paint);
          canvas.drawRect(Rect.fromCenter(center: pos, width: s * 0.9, height: s * 2.6), _paint);
        case ParticleShape.star:
          canvas.save();
          canvas.translate(pos.dx, pos.dy);
          canvas.rotate(p.rot);
          final s = p.size * (0.6 + k * 0.6);
          final path = Path();
          for (var i = 0; i < 8; i++) {
            final r = i.isEven ? s * 1.8 : s * 0.6;
            final a = i * math.pi / 4;
            final pt = Offset(math.cos(a) * r, math.sin(a) * r);
            i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
          }
          path.close();
          canvas.drawPath(path, _paint);
          canvas.restore();
      }
    }
  }
}

/// A character in a scene. Feet sit at [position]; the painter draws in
/// character space (see `art/painters.dart`).
class ActorComponent extends PositionComponent {
  ActorComponent({
    required this.painter,
    Vector2? position,
    this.scaleFactor = 1,
    this.faceLeft = false,
  }) : super(position: position ?? Vector2.zero(), anchor: Anchor.topLeft);

  void Function(Canvas canvas, ActorState state) painter;
  final ActorState state = ActorState();

  double scaleFactor;
  bool faceLeft;

  /// 0..1 white hit flash.
  double flash = 0;

  /// 0..1 opacity.
  double alpha = 1;

  /// Pose offsets applied around the feet.
  double lean = 0;
  double hop = 0;
  Vector2 nudge = Vector2.zero();

  /// 0..1 aura drawn behind the actor (heavy-blow telegraph).
  double aura = 0;
  Color auraColor = const Color(0xFFFF5252);

  static const _bounds = Rect.fromLTWH(-90, -170, 180, 190);

  @override
  void update(double dt) {
    state.time += dt;
    if (state.walking) state.walkPhase += dt * 11;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(nudge.x, nudge.y - hop);
    canvas.scale(faceLeft ? -scaleFactor : scaleFactor, scaleFactor);
    canvas.rotate(lean);

    if (state.down > 0) {
      canvas.rotate((faceLeft ? -1 : 1) * -state.down * 1.45);
      canvas.translate(0, state.down * 6);
    }

    if (aura > 0.01) {
      final pulse = 0.75 + math.sin(state.time * 14) * 0.25;
      final paint = Paint()..color = auraColor.withValues(alpha: 0.35 * aura * pulse);
      canvas.drawOval(Rect.fromCenter(center: const Offset(0, -34), width: 90 + 20 * aura, height: 100 + 20 * aura), paint);
    }

    final needsLayer = flash > 0.01 || alpha < 0.99;
    if (needsLayer) {
      canvas.saveLayer(_bounds, Paint()..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0)));
    }
    painter(canvas, state);
    if (flash > 0.01) {
      canvas.drawRect(
        _bounds,
        Paint()
          ..blendMode = BlendMode.srcATop
          ..color = Color.fromRGBO(255, 255, 255, flash.clamp(0.0, 1.0)),
      );
    }
    if (needsLayer) canvas.restore();
    canvas.restore();
  }
}

/// Small HP bar that eases toward its target value.
class WorldBar extends PositionComponent {
  WorldBar({
    required Vector2 position,
    required this.max,
    required this.fill,
    double width = 96,
  }) : super(position: position, size: Vector2(width, 9)) {
    value = max.toDouble();
    shown = value;
    priority = 50;
  }

  int max;
  Color fill;
  late double value;
  late double shown;
  bool instant = false;
  bool hidden = false;

  void setValue(int v) => value = v.clamp(0, max).toDouble();

  /// Jumps straight to [v] of [newMax] with no easing.
  void snapTo(int v, int newMax) {
    max = newMax;
    value = v.clamp(0, newMax).toDouble();
    shown = value;
  }

  @override
  void update(double dt) {
    if (instant) {
      shown = value;
    } else {
      shown += (value - shown) * math.min(1, dt * 8);
      if ((value - shown).abs() < 0.05) shown = value;
    }
  }

  @override
  void render(Canvas canvas) {
    if (hidden) return;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(4.5));
    canvas.drawRRect(r, Paint()..color = const Color(0xCC1D1D1D));
    final frac = max <= 0 ? 0.0 : (shown / max).clamp(0.0, 1.0);
    if (frac > 0) {
      canvas.save();
      canvas.clipRRect(r);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x * frac, size.y), Paint()..color = fill);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x * frac, size.y * 0.4), Paint()..color = const Color(0x40FFFFFF));
      canvas.restore();
    }
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7),
    );
  }
}
