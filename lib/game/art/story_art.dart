/// Backdrops and the extra characters for the story scenes, drawn in code like
/// the rest of the game's art. Characters stand with their feet at the origin
/// of their own space, as in painters.dart.
library;

import 'dart:math' as math;
import 'dart:ui';

import '../../domain/story.dart';
import '../look.dart';
import 'painters.dart';

// ---------------------------------------------------------------------------
// Characters that only appear in the story
// ---------------------------------------------------------------------------

/// Maple Thistlewick, quartermaster and apothecary: auburn bun, cream apron
/// over a teal dress, and an apple.
void paintMaple(Canvas c, ActorState s) {
  final bob = math.sin(s.time * 1.9) * 0.8;
  shadow(c, 16);
  c.save();
  c.translate(0, bob);
  // Legs and boots.
  rrect(c, -7, -16, 5.5, 16, 2, const Color(0xFF5D4037));
  rrect(c, 1.5, -16, 5.5, 16, 2, const Color(0xFF5D4037));
  rrect(c, -9, -4, 9, 4, 2, const Color(0xFF3E2723));
  rrect(c, 0, -4, 9, 4, 2, const Color(0xFF3E2723));
  // Dress and apron.
  rrect(c, -14, -58, 28, 44, 8, const Color(0xFF26837A));
  rrect(c, -9, -50, 18, 34, 5, const Color(0xFFFFF3D6));
  rrect(c, -9, -50, 18, 5, 2, const Color(0xFFEEDDB5));
  // Arms: one holds an apple.
  rrect(c, -19, -54, 6, 24, 3, const Color(0xFF26837A));
  rrect(c, 13, -54, 6, 24, 3, const Color(0xFF26837A));
  circle(c, 16, -29, 4, const Color(0xFFE8B98E));
  circle(c, 16, -35, 4.6, const Color(0xFFD64541));
  line(c, 16, -39.5, 17.5, -42, 1.2, const Color(0xFF5D4037));
  circle(c, -16, -29, 4, const Color(0xFFE8B98E));
  // Head, hair, bun.
  circle(c, 0, -72, 13, const Color(0xFFE8B98E));
  circle(c, 0, -84, 11, const Color(0xFFA9532C));
  circle(c, -1, -91, 6, const Color(0xFFA9532C));
  oval(c, 0, -77, 12.5, 7, const Color(0xFFA9532C));
  circle(c, -4.5, -71, 1.5, const Color(0xFF2B1D14));
  circle(c, 4.5, -71, 1.5, const Color(0xFF2B1D14));
  line(c, -3, -65.5, 3, -65.5, 1.2, const Color(0xFF9C4B3A));
  c.restore();
}

/// Biscuit, the guild dog: small, brown, enthusiastic.
void paintBiscuit(Canvas c, ActorState s) {
  final wag = math.sin(s.time * 9) * 0.5;
  final bob = math.sin(s.time * 2.4).abs() * 1.5;
  shadow(c, 15);
  c.save();
  c.translate(0, -bob);
  // Tail.
  c.save();
  c.translate(-15, -17);
  c.rotate(-0.7 + wag);
  rrect(c, -2, -13, 4.5, 14, 2.2, const Color(0xFF8D5A34));
  c.restore();
  // Body and legs.
  oval(c, 0, -15, 16, 9.5, const Color(0xFFA6683A));
  rrect(c, -11, -10, 5, 10, 2, const Color(0xFF8D5A34));
  rrect(c, 6, -10, 5, 10, 2, const Color(0xFF8D5A34));
  oval(c, 0, -12, 9, 5, const Color(0xFFE8CFA6));
  // Head with one floppy ear.
  circle(c, 14, -27, 9.5, const Color(0xFFA6683A));
  oval(c, 21, -24, 5.5, 4, const Color(0xFFE8CFA6));
  circle(c, 25, -25, 1.8, const Color(0xFF2B1D14));
  c.save();
  c.translate(10, -33);
  c.rotate(0.4 + wag * 0.3);
  oval(c, 0, 4, 3.6, 7, const Color(0xFF6D4326));
  c.restore();
  circle(c, 15.5, -29, 1.7, const Color(0xFF2B1D14));
  c.restore();
}

// ---------------------------------------------------------------------------
// Cast
// ---------------------------------------------------------------------------

/// Draws [speaker] standing at the origin, [height] units tall in actor space
/// roughly 100. Returns false for those with no figure (the narrator).
bool _paintSpeaker(Canvas c, StorySpeaker who, ActorState s, HeroLook look) {
  switch (who) {
    case StorySpeaker.chad:
      paintChad(c, s);
    case StorySpeaker.brad:
      paintBrad(c, s);
    case StorySpeaker.maple:
      paintMaple(c, s);
    case StorySpeaker.biscuit:
      paintBiscuit(c, s);
    case StorySpeaker.oakhelm:
      paintTreant(c, s);
    case StorySpeaker.grit:
      paintGremlin(c, s);
    case StorySpeaker.murmur:
      paintImp(c, s);
    case StorySpeaker.hero:
      paintHero(c, look, s);
    case StorySpeaker.narrator:
      return false;
  }
  return true;
}

/// Natural size of each figure relative to Chad, so small characters look small.
double _scaleOf(StorySpeaker who) => switch (who) {
      StorySpeaker.oakhelm => 1.15,
      StorySpeaker.grit => 1.25,
      StorySpeaker.murmur => 1.3,
      StorySpeaker.biscuit => 1.1,
      StorySpeaker.maple => 1.0,
      StorySpeaker.brad => 1.05,
      _ => 1.0,
    };

/// Paints the cast across the stage. The hero stands at the right, facing the
/// others, who face the hero; whoever is [speaking] steps a little forward.
void paintStoryCast(
  Canvas c,
  Size size, {
  required List<StorySpeaker> cast,
  required StorySpeaker? speaking,
  required HeroLook look,
  required double time,
}) {
  final ground = size.height * 0.9;
  final crowd = cast.length >= 4;
  final base = size.height / 150 * (crowd ? 0.78 : 0.95);

  void actor(StorySpeaker who, double x, {required bool forward, double flip = 1}) {
    final s = ActorState()..time = time + who.index * 0.7;
    final scale = base * _scaleOf(who) * (forward ? 1.08 : 1.0);
    c.save();
    c.translate(x, ground + (forward ? size.height * 0.015 : 0));
    c.scale(scale * flip, scale);
    _paintSpeaker(c, who, s, look);
    c.restore();
  }

  final n = cast.length;
  for (var i = 0; i < n; i++) {
    final x = size.width * (0.27 + 0.39 * (n == 1 ? 0.5 : i / (n - 1)));
    actor(cast[i], x, forward: cast[i] == speaking);
  }
  // Painted facing right, so mirror the hero to face the others.
  actor(StorySpeaker.hero, size.width * 0.86, forward: speaking == StorySpeaker.hero, flip: -1);
}

// ---------------------------------------------------------------------------
// Backdrops
// ---------------------------------------------------------------------------

void _fill(Canvas c, Rect r, Color col) => c.drawRect(r, Paint()..color = col);

void _gradient(Canvas c, Rect r, List<Color> colors) =>
    c.drawRect(
      r,
      Paint()
        ..shader = Gradient.linear(
          r.topCenter,
          r.bottomCenter,
          colors,
          [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)],
        ),
    );

void _hill(Canvas c, Size s, double baseY, double amp, double phase, Color col) {
  final path = Path()..moveTo(0, s.height);
  for (var x = 0.0; x <= s.width + 4; x += 4) {
    final y = baseY + math.sin(x / s.width * math.pi * 2 + phase) * amp + math.sin(x / s.width * math.pi * 5 + phase) * amp * 0.3;
    path.lineTo(x, y);
  }
  path
    ..lineTo(s.width, s.height)
    ..close();
  c.drawPath(path, Paint()..color = col);
}

void _stars(Canvas c, Size s, double time, {int count = 40}) {
  final rng = math.Random(7);
  for (var i = 0; i < count; i++) {
    final x = rng.nextDouble() * s.width;
    final y = rng.nextDouble() * s.height * 0.5;
    final twinkle = 0.55 + 0.45 * math.sin(time * 2 + i);
    circle(c, x, y, 0.8 + rng.nextDouble() * 1.1, Color.fromRGBO(255, 244, 214, twinkle));
  }
}

void _cloud(Canvas c, double x, double y, double w, Color col) {
  oval(c, x, y, w, w * 0.32, col);
  oval(c, x - w * 0.45, y + w * 0.08, w * 0.55, w * 0.25, col);
  oval(c, x + w * 0.5, y + w * 0.06, w * 0.6, w * 0.26, col);
}

/// A tall arched window with light coming through.
void _window(Canvas c, double x, double y, double w, double h, Color glass) {
  rrect(c, x - 3, y - 3, w + 6, h + 6, w / 2, const Color(0xFF5D4037));
  rrect(c, x, y, w, h, w / 2, glass);
  line(c, x + w / 2, y, x + w / 2, y + h, 2, const Color(0xFF5D4037));
  line(c, x, y + h * 0.5, x + w, y + h * 0.5, 2, const Color(0xFF5D4037));
}

void _bell(Canvas c, double cx, double top, double r, {double sway = 0}) {
  c.save();
  c.translate(cx, top);
  c.rotate(sway);
  line(c, 0, 0, 0, 14, 5, const Color(0xFF6D4C41));
  final path = Path()
    ..moveTo(-r * 0.35, 12)
    ..quadraticBezierTo(-r * 0.4, 0.5 * r + 12, -r, r * 1.35 + 12)
    ..lineTo(r, r * 1.35 + 12)
    ..quadraticBezierTo(r * 0.4, 0.5 * r + 12, r * 0.35, 12)
    ..close();
  c.drawPath(path, Paint()..color = const Color(0xFFB87D2E));
  c.drawPath(
    Path()
      ..moveTo(-r * 0.2, 16)
      ..quadraticBezierTo(-r * 0.25, 0.5 * r, -r * 0.7, r * 1.25 + 12)
      ..lineTo(-r * 0.5, r * 1.25 + 12)
      ..quadraticBezierTo(-r * 0.06, 0.5 * r, -r * 0.08, 16)
      ..close(),
    Paint()..color = const Color(0x55FFFFFF),
  );
  rrect(c, -r * 1.05, r * 1.3 + 10, r * 2.1, 6, 3, const Color(0xFF8D5E1E));
  c.restore();
}

void _tree(Canvas c, double x, double groundY, double trunkW, double h, Color trunk, Color leaf) {
  rrect(c, x - trunkW / 2, groundY - h, trunkW, h, trunkW * 0.3, trunk);
  circle(c, x, groundY - h, trunkW * 2.4, leaf);
  circle(c, x - trunkW * 1.5, groundY - h + trunkW, trunkW * 1.7, leaf);
  circle(c, x + trunkW * 1.5, groundY - h + trunkW, trunkW * 1.7, leaf);
}

void paintStoryBackdrop(Canvas c, Size s, StoryBackdrop which, double time) {
  final w = s.width, h = s.height;
  final full = Offset.zero & s;
  final ground = h * 0.9;
  switch (which) {
    case StoryBackdrop.hall:
      _fill(c, full, const Color(0xFFB59A78));
      for (var y = 0.0; y < ground; y += 26) {
        line(c, 0, y, w, y, 1, const Color(0x1A000000));
      }
      _window(c, w * 0.16, h * 0.12, w * 0.17, h * 0.32, const Color(0xFFFFE9A8));
      _window(c, w * 0.67, h * 0.12, w * 0.17, h * 0.32, const Color(0xFFFFE9A8));
      // A banner with a gold emblem.
      rrect(c, w * 0.44, 0, w * 0.12, h * 0.34, 4, const Color(0xFF8E2B3B));
      circle(c, w * 0.5, h * 0.17, w * 0.04, const Color(0xFFE6B83C));
      // Torches glow.
      for (final x in [w * 0.38, w * 0.62]) {
        rrect(c, x - 3, h * 0.2, 6, h * 0.12, 2, const Color(0xFF5D4037));
        final flicker = 1 + math.sin(time * 9 + x) * 0.08;
        circle(c, x, h * 0.19, 7 * flicker, const Color(0xFFFF9F43));
        circle(c, x, h * 0.19, 11 * flicker, const Color(0x33FFC46B));
      }
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFF6B4528));
      rrect(c, w * 0.25, ground - 2, w * 0.5, 7, 3, const Color(0xFF8E2B3B));
    case StoryBackdrop.bellTower:
      _gradient(c, full, const [Color(0xFFBFD9F2), Color(0xFFEAF2FA)]);
      _cloud(c, w * 0.78, h * 0.22, w * 0.12, const Color(0xCCFFFFFF));
      // Stone arch frame.
      final stone = const Color(0xFF9A8F80);
      _fill(c, Rect.fromLTWH(0, 0, w * 0.12, h), stone);
      _fill(c, Rect.fromLTWH(w * 0.88, 0, w * 0.12, h), stone);
      _fill(c, Rect.fromLTWH(0, 0, w, h * 0.09), stone);
      c.drawArc(Rect.fromLTWH(w * 0.12, h * 0.02, w * 0.76, h * 0.5), math.pi, math.pi, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14
            ..color = stone);
      for (var y = 0.0; y < h; y += 28) {
        line(c, 0, y, w * 0.12, y, 1, const Color(0x22000000));
        line(c, w * 0.88, y, w, y, 1, const Color(0x22000000));
      }
      _bell(c, w * 0.5, h * 0.1, w * 0.13, sway: math.sin(time * 1.2) * 0.02);
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFF7C705F));
    case StoryBackdrop.meadowRoad:
      _gradient(c, full, const [Color(0xFF9CCBEF), Color(0xFFE5F2F9)]);
      _cloud(c, w * 0.25, h * 0.18, w * 0.12, const Color(0xE6FFFFFF));
      _cloud(c, w * 0.75, h * 0.28, w * 0.1, const Color(0xCCFFFFFF));
      _hill(c, s, h * 0.55, h * 0.04, 0.5, const Color(0xFF8FC27A));
      _hill(c, s, h * 0.66, h * 0.05, 2.2, const Color(0xFF6FAE5E));
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFF5E9B50));
      // The road.
      final road = Path()
        ..moveTo(w * 0.42, h * 0.62)
        ..lineTo(w * 0.58, h * 0.62)
        ..lineTo(w * 1.1, h)
        ..lineTo(-w * 0.1, h)
        ..close();
      c.drawPath(road, Paint()..color = const Color(0xFFD9C398));
    case StoryBackdrop.pebbleHollow:
      _gradient(c, full, const [Color(0xFF6B5A47), Color(0xFF8C7660)]);
      // A rounded hollow, with light coming in from above.
      oval(c, w * 0.5, h * 0.55, w * 0.62, h * 0.52, const Color(0xFF9B8468));
      c.drawPath(
        Path()
          ..moveTo(w * 0.42, 0)
          ..lineTo(w * 0.58, 0)
          ..lineTo(w * 0.75, ground)
          ..lineTo(w * 0.25, ground)
          ..close(),
        Paint()..color = const Color(0x22FFF1B8),
      );
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFF54442F));
      final rng = math.Random(3);
      for (var i = 0; i < 60; i++) {
        final x = rng.nextDouble() * w;
        final y = ground - rng.nextDouble() * h * 0.18;
        final col = i % 5 == 0 ? const Color(0xFFE6B83C) : (i % 7 == 0 ? const Color(0xFF9AD4FF) : const Color(0xFFBDB2A2));
        circle(c, x, y, 3 + rng.nextDouble() * 4, col);
        if (i % 5 == 0 || i % 7 == 0) {
          final tw = 0.5 + 0.5 * math.sin(time * 3 + i);
          circle(c, x - 1, y - 1, 1.6, Color.fromRGBO(255, 255, 255, tw));
        }
      }
    case StoryBackdrop.oldWood:
      _gradient(c, full, const [Color(0xFF3F6B45), Color(0xFF8DB36D)]);
      for (var i = 0; i < 7; i++) {
        final x = w * (0.04 + i * 0.16);
        _tree(c, x, ground, w * 0.06 + (i % 3) * 4, h * (0.55 + (i % 3) * 0.12), const Color(0xFF5B4128), const Color(0xFF2F5A3A));
      }
      // Shafts of light.
      for (final x in [w * 0.3, w * 0.55, w * 0.8]) {
        c.drawPath(
          Path()
            ..moveTo(x, 0)
            ..lineTo(x + w * 0.05, 0)
            ..lineTo(x + w * 0.16, ground)
            ..lineTo(x + w * 0.06, ground)
            ..close(),
          Paint()..color = const Color(0x1FFFF6C2),
        );
      }
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFF4A6B3B));
    case StoryBackdrop.mistHollow:
      _gradient(c, full, const [Color(0xFF8C97A6), Color(0xFFD7DDE4)]);
      _hill(c, s, h * 0.62, h * 0.03, 1.1, const Color(0xFF7D8A8A));
      // A weathervane on a post, a little crooked.
      line(c, w * 0.76, ground, w * 0.76, h * 0.34, 5, const Color(0xFF5D4037));
      c.save();
      c.translate(w * 0.76, h * 0.34);
      c.rotate(-0.12 + math.sin(time * 0.8) * 0.04);
      line(c, -20, 0, 22, 0, 3, const Color(0xFFB87D2E));
      c.drawPath(
        Path()
          ..moveTo(22, 0)
          ..lineTo(12, -6)
          ..lineTo(12, 6)
          ..close(),
        Paint()..color = const Color(0xFFB87D2E),
      );
      c.restore();
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFF6E7B73));
      // Layers of soft fog.
      for (var i = 0; i < 5; i++) {
        final y = h * (0.45 + i * 0.1) + math.sin(time * 0.5 + i) * 4;
        oval(c, w * (0.2 + i * 0.2) + math.sin(time * 0.3 + i) * 12, y, w * 0.4, h * 0.05, const Color(0x66F2F4F6));
      }
    case StoryBackdrop.hillCamp:
      _gradient(c, full, const [Color(0xFF151B3D), Color(0xFF3D4F86)]);
      _stars(c, s, time);
      circle(c, w * 0.82, h * 0.16, w * 0.06, const Color(0xFFFFF4D6));
      _hill(c, s, h * 0.7, h * 0.04, 0.9, const Color(0xFF1F2E3D));
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFF28402F));
      // The tower on the hill, far off.
      rrect(c, w * 0.08, h * 0.34, w * 0.07, h * 0.4, 3, const Color(0xFF232C45));
      c.save();
      c.translate(w * 0.5, ground - 2);
      c.scale(h / 260, h / 260);
      paintCampfire(c, time);
      c.restore();
    case StoryBackdrop.dawn:
      _gradient(c, full, const [Color(0xFFF6B76E), Color(0xFFFCE3B2), Color(0xFFCFE6F5)]);
      circle(c, w * 0.5, h * 0.55, w * 0.14, const Color(0xCCFFF1C2));
      _hill(c, s, h * 0.6, h * 0.035, 0.3, const Color(0xFFA6C77E));
      _hill(c, s, h * 0.7, h * 0.04, 2.5, const Color(0xFF7DAF63));
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFF6C9E54));
      // The hall with its bell tower, lamps on.
      rrect(c, w * 0.62, h * 0.4, w * 0.3, h * 0.3, 4, const Color(0xFF8D6E63));
      rrect(c, w * 0.72, h * 0.22, w * 0.1, h * 0.2, 3, const Color(0xFF9A8F80));
      _bell(c, w * 0.77, h * 0.24, w * 0.025, sway: math.sin(time * 3) * 0.12);
      for (var i = 0; i < 3; i++) {
        circle(c, w * (0.68 + i * 0.09), h * 0.52, 4, const Color(0xFFFFD36B));
      }
  }
}
