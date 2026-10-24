/// Procedural character art. Every character is drawn from canvas shapes, so
/// the game ships with no borrowed assets and every look can be animated.
///
/// Origin is the character's feet; negative y is up; the character faces +x.
/// Units are roughly "pixels at design resolution" (a hero is ~60 tall).
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show HSLColor;

import '../../domain/cosmetics.dart' show Cape;
import '../look.dart';

final Paint _p = Paint();
final Paint _stroke = Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

void circle(Canvas c, double x, double y, double r, Color col) {
  _p
    ..style = PaintingStyle.fill
    ..color = col;
  c.drawCircle(Offset(x, y), r, _p);
}

void oval(Canvas c, double cx, double cy, double rx, double ry, Color col) {
  _p
    ..style = PaintingStyle.fill
    ..color = col;
  c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2), _p);
}

void rrect(Canvas c, double x, double y, double w, double h, double r, Color col) {
  _p
    ..style = PaintingStyle.fill
    ..color = col;
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)), _p);
}

void line(Canvas c, double x1, double y1, double x2, double y2, double w, Color col) {
  _stroke
    ..strokeWidth = w
    ..color = col;
  c.drawLine(Offset(x1, y1), Offset(x2, y2), _stroke);
}

void fillPath(Canvas c, Path path, Color col) {
  _p
    ..style = PaintingStyle.fill
    ..color = col;
  c.drawPath(path, _p);
}

void strokePath(Canvas c, Path path, double w, Color col) {
  _stroke
    ..strokeWidth = w
    ..color = col;
  c.drawPath(path, _stroke);
}

Path poly(List<double> pts) {
  final p = Path()..moveTo(pts[0], pts[1]);
  for (var i = 2; i < pts.length; i += 2) {
    p.lineTo(pts[i], pts[i + 1]);
  }
  return p..close();
}

void shadow(Canvas c, double rx) => oval(c, 0, 0, rx, 4, const Color(0x2E000000));

Color shade(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

const _ink = Color(0xFF2B1D14);

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

/// Draws the adventurer. [s] supplies idle motion, walking, swing and guard.
void paintHero(Canvas c, HeroLook look, ActorState s) {
  final bob = s.walking ? -(math.sin(s.walkPhase * 2)).abs() * 2.2 : math.sin(s.time * 2.6) * 1.1;
  final swing = s.walking ? math.sin(s.walkPhase) * 6 : 0.0;
  final tunic = look.tunic;

  shadow(c, 15);

  // Cape, behind everything, swaying a little.
  final sway = math.sin(s.time * 3) * 2 + (s.walking ? -4 : 0) - s.attack * 3;
  final cape = look.cape;
  if (cape != null && cape.color != null) {
    _paintMantle(c, cape, bob, sway);
  } else {
    fillPath(
      c,
      Path()
        ..moveTo(-9, -36 + bob)
        ..lineTo(-17 + sway, -8)
        ..lineTo(-3, -10)
        ..close(),
      shade(tunic, -0.14),
    );
  }

  // Legs.
  rrect(c, -7 + swing, -14, 6, 14, 2, const Color(0xFF5D4037));
  rrect(c, 1 - swing, -14, 6, 14, 2, const Color(0xFF5D4037));
  rrect(c, -8 + swing, -3, 8, 3, 1.5, const Color(0xFF3E2723));
  rrect(c, 0 - swing, -3, 8, 3, 1.5, const Color(0xFF3E2723));

  // Torso.
  c.save();
  c.translate(0, bob);
  rrect(c, -10, -40, 20, 28, 6, tunic);
  rrect(c, -10, -24, 20, 3.5, 0, const Color(0xFF6D4C41));
  rrect(c, -2, -25, 4, 5, 1, const Color(0xFFF2C94C));
  if (look.equipped.contains('guild_tunic')) {
    circle(c, 0, -33, 4.5, const Color(0xFFF2C94C));
    circle(c, 0, -33, 2.4, tunic);
  }
  if (look.equipped.contains('trail_vest')) {
    rrect(c, -10, -40, 6, 28, 3, const Color(0xFF8D6E63));
    rrect(c, 4, -40, 6, 28, 3, const Color(0xFF8D6E63));
    rrect(c, -9, -30, 4, 5, 1, const Color(0xFF6D4C41));
  }
  if (look.equipped.contains('stopwatch_charm')) {
    circle(c, -8, -20, 2.6, const Color(0xFFCFD8DC));
    circle(c, -8, -20, 1.2, const Color(0xFF455A64));
  }
  if (look.equipped.contains('lucky_pebble')) {
    oval(c, 8, -20, 2.6, 2, const Color(0xFF90A4AE));
  }

  // Head.
  _paintHead(c, look, s);
  c.restore();

  // Weapon arm. Base pose angled up and forward; attack swings it down.
  c.save();
  c.translate(11, -28 + bob);
  final base = 0.32 + (s.windUp > 0 ? -0.2 * s.windUp : 0);
  c.rotate(base + s.attack * 2.0 - s.guard * 0.4);
  _paintWeapon(c, look);
  circle(c, 0, 0, 3.6, look.skinColor);
  c.restore();

  // Off hand + guard shield.
  if (s.guard > 0.01) {
    c.save();
    c.translate(17, -30 + bob);
    c.scale(s.guard, s.guard);
    oval(c, 0, 0, 9, 12, const Color(0xFF90A4AE));
    oval(c, 0, 0, 6, 9, const Color(0xFFB0BEC5));
    circle(c, 0, 0, 2.6, const Color(0xFFF2C94C));
    c.restore();
  }
}

/// A full-length mantle from the Patron Pack or earned in play. It hangs behind
/// the torso and sways with the hero, so only its edges and hem show.
void _paintMantle(Canvas c, Cape cape, double bob, double sway) {
  final base = Color(cape.color!);
  final trim = Color(cape.trim ?? cape.color!);
  final body = Path()
    ..moveTo(-9, -38 + bob)
    ..lineTo(9, -38 + bob)
    ..quadraticBezierTo(15, -22, 13 + sway * 0.2, -5)
    ..lineTo(-21 + sway, -3)
    ..quadraticBezierTo(-14, -22, -9, -38 + bob)
    ..close();
  fillPath(c, body, base);
  fillPath(
    c,
    Path()
      ..moveTo(-3, -38 + bob)
      ..lineTo(3, -38 + bob)
      ..lineTo(2 + sway * 0.1, -4)
      ..lineTo(-8 + sway * 0.5, -3.5)
      ..close(),
    shade(base, -0.1),
  );
  line(c, 13 + sway * 0.2, -5, -21 + sway, -3, 2.6, trim);
  if (cape.stars) {
    for (final p in [
      (-12.0 + sway * 0.45, -20.0),
      (-3.0 + sway * 0.1, -11.0),
      (9.0, -17.0),
      (-17.0 + sway * 0.7, -8.0),
      (6.0, -8.0),
    ]) {
      circle(c, p.$1, p.$2, 1.1, trim);
    }
  }
}

void _paintWeapon(Canvas c, HeroLook look) {
  if (look.equipped.contains('iron_blade')) {
    rrect(c, -2.2, -36, 4.4, 34, 2, const Color(0xFFCFD8DC));
    rrect(c, -0.6, -35, 1.2, 30, 0.6, const Color(0xFFFFFFFF));
    rrect(c, -6, -4, 12, 3, 1, const Color(0xFFF2C94C));
  } else if (look.equipped.contains('wooden_sword')) {
    rrect(c, -2.2, -30, 4.4, 28, 2, const Color(0xFFA1887F));
    rrect(c, -5, -4, 10, 3, 1, const Color(0xFF6D4C41));
  } else {
    rrect(c, -1.8, -26, 3.6, 24, 1.8, const Color(0xFF8D6E63));
  }
}

void _paintHead(Canvas c, HeroLook look, ActorState s) {
  final skin = look.skinColor;
  final hair = look.hairColor;
  const cy = -49.0;
  final blink = (s.time % 4.2) > 4.05;

  // Hair or hood that sits behind the face.
  switch (look.style % 6) {
    case 1:
      rrect(c, -11.5, cy - 4, 5, 20, 2.5, hair);
      rrect(c, 6.5, cy - 4, 5, 20, 2.5, hair);
    case 5:
      circle(c, 0, cy, 12.5, shade(look.tunic, -0.08));
    default:
      break;
  }

  circle(c, 0, cy, look.style % 6 == 5 ? 8.6 : 10, skin);

  final cap = Path()
    ..moveTo(-10.5, cy + 1)
    ..quadraticBezierTo(-11, cy - 11, 0, cy - 11)
    ..quadraticBezierTo(11, cy - 11, 10.5, cy + 1)
    ..quadraticBezierTo(5, cy - 5, -2, cy - 4)
    ..quadraticBezierTo(-7, cy - 3, -10.5, cy + 1)
    ..close();
  switch (look.style % 6) {
    case 0:
    case 1:
      fillPath(c, cap, hair);
    case 2:
      fillPath(c, cap, hair);
      fillPath(
        c,
        poly([-9, cy - 7, -8, cy - 17, -4, cy - 9, 0, cy - 19, 4, cy - 9, 8, cy - 17, 9, cy - 7]),
        hair,
      );
    case 3:
      fillPath(c, cap, hair);
      circle(c, 0, cy - 14, 5, hair);
    case 4:
      fillPath(c, cap, hair);
      rrect(c, -10.5, cy - 6, 21, 3.2, 1, const Color(0xFFE53935));
    default:
      break;
  }

  // Equipment on the head.
  if (look.equipped.contains('sweatband') && look.style % 6 != 4) {
    rrect(c, -10.5, cy - 6, 21, 3.2, 1, const Color(0xFFE53935));
  }
  if (look.equipped.contains('wayfarer_cap')) {
    fillPath(
      c,
      Path()
        ..moveTo(-11, cy - 4)
        ..quadraticBezierTo(-10, cy - 15, 0, cy - 15)
        ..quadraticBezierTo(10, cy - 15, 11, cy - 4)
        ..close(),
      const Color(0xFF558B2F),
    );
    rrect(c, -2, cy - 7, 15, 3, 1.5, const Color(0xFF33691E));
  }

  // Face.
  if (blink) {
    line(c, -5, cy + 1, -2, cy + 1, 1.2, _ink);
    line(c, 2, cy + 1, 5, cy + 1, 1.2, _ink);
  } else {
    circle(c, -3.5, cy + 1, 1.3, _ink);
    circle(c, 3.5, cy + 1, 1.3, _ink);
  }
  strokePath(
    c,
    Path()
      ..moveTo(-3, cy + 5)
      ..quadraticBezierTo(0, cy + 7.5, 3, cy + 5),
    1,
    _ink,
  );
}

/// Round portrait (head and shoulders) for HUDs, menus and onboarding.
void paintHeroPortrait(Canvas c, double size, HeroLook look, double time) {
  final r = size / 2;
  circle(c, r, r, r, const Color(0xFFE8D8B8));
  c.save();
  c.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(r, r), radius: r)));
  final scale = size / 40;
  c.translate(r, size * 0.98);
  c.scale(scale, scale);
  // Shoulders sit below the head.
  rrect(c, -17, -4, 34, 28, 12, look.tunic);
  rrect(c, -17, 6, 34, 3.5, 0, const Color(0xFF6D4C41));
  // Head, scaled up from the full-body proportions and centred in the circle.
  c.save();
  c.translate(0, -16);
  c.scale(1.2, 1.2);
  c.translate(0, 49);
  final s = ActorState()..time = time;
  _paintHead(c, look, s);
  c.restore();
  c.restore();
}

// ---------------------------------------------------------------------------
// Chad and Brad (the muscle)
// ---------------------------------------------------------------------------

class _MuscleStyle {
  const _MuscleStyle({
    required this.skin,
    required this.hair,
    required this.top,
    required this.shorts,
    required this.band,
    this.sunglasses = false,
    this.emblem = true,
  });

  final Color skin;
  final Color hair;
  final Color top;
  final Color shorts;
  final Color band;
  final bool sunglasses;
  final bool emblem;
}

const _chadStyle = _MuscleStyle(
  skin: Color(0xFFD9A066),
  hair: Color(0xFFF2C94C),
  top: Color(0xFFFAFAFA),
  shorts: Color(0xFF3F51B5),
  band: Color(0xFFE53935),
);

const _bradStyle = _MuscleStyle(
  skin: Color(0xFFE8B98E),
  hair: Color(0xFF3B2A20),
  top: Color(0xFFC62828),
  shorts: Color(0xFF263238),
  band: Color(0xFF263238),
  sunglasses: true,
  emblem: false,
);

void paintChad(Canvas c, ActorState s) => _muscle(c, s, _chadStyle);

/// Brad, Chad's old rival.
void paintBrad(Canvas c, ActorState s) => _muscle(c, s, _bradStyle);

void _muscle(Canvas c, ActorState s, _MuscleStyle m) {
  final flex = s.attack > 0 ? s.attack : (math.sin(s.time * 1.8) * 0.5 + 0.5) * 0.35;
  final bob = math.sin(s.time * 2.2) * 1.2;
  shadow(c, 19);

  rrect(c, -8, -14, 7, 14, 2, m.skin);
  rrect(c, 1, -14, 7, 14, 2, m.skin);
  rrect(c, -10, -22, 20, 10, 2, m.shorts);

  c.save();
  c.translate(0, bob);
  fillPath(c, poly([-17, -44, 17, -44, 11, -20, -11, -20]), m.top);
  if (m.emblem) {
    circle(c, 0, -34, 5, const Color(0xFFF2C94C));
    strokePath(
      c,
      Path()..addArc(Rect.fromCircle(center: const Offset(0, -34), radius: 3.2), 0.6, 4.9),
      1.5,
      const Color(0xFFB8860B),
    );
  }
  rrect(c, -11, -22, 22, 3, 0, const Color(0xFFF2C94C));

  // Arms flexing: upper arm out, fist raised higher with [flex].
  final lift = 14 + flex * 8;
  for (final side in [-1.0, 1.0]) {
    line(c, side * 21, -38, side * (23 + flex * 3), -38 - lift, 7, m.skin);
    circle(c, side * 21, -38, 7, m.skin);
    circle(c, side * (23 + flex * 3), -38 - lift - 1, 5, m.skin);
  }

  // Head.
  circle(c, 0, -54, 11, m.skin);
  fillPath(
    c,
    Path()
      ..moveTo(-11, -55)
      ..quadraticBezierTo(-12, -70, 2, -68)
      ..quadraticBezierTo(14, -66, 11, -55)
      ..quadraticBezierTo(6, -60, -2, -59)
      ..quadraticBezierTo(-8, -58, -11, -55)
      ..close(),
    m.hair,
  );
  rrect(c, -11.5, -57, 23, 3.5, 1, m.band);
  if (m.sunglasses) {
    rrect(c, -9, -54, 8, 4.5, 2, const Color(0xFF111111));
    rrect(c, 1, -54, 8, 4.5, 2, const Color(0xFF111111));
    line(c, -1, -52, 1, -52, 1.2, const Color(0xFF111111));
    strokePath(
      c,
      Path()
        ..moveTo(-4, -47)
        ..quadraticBezierTo(0, -44, 5, -48),
      1.4,
      _ink,
    );
  } else {
    circle(c, -4, -52, 1.4, _ink);
    circle(c, 4, -52, 1.4, _ink);
    fillPath(
      c,
      Path()
        ..moveTo(-5, -48)
        ..quadraticBezierTo(0, -42, 5, -48)
        ..close(),
      const Color(0xFFFFFFFF),
    );
  }
  c.restore();
}

// ---------------------------------------------------------------------------
// Enemies
// ---------------------------------------------------------------------------

typedef ActorPainter = void Function(Canvas c, ActorState s);

/// Painter for each enemy by name, with a friendly blob as the fallback.
ActorPainter enemyPainter(String name) => switch (name) {
      'Snooze Slime' => paintSlime,
      'Fog Imp' => paintImp,
      'Rusty Gear Golem' => paintGolem,
      'Cobweb Wisp' => paintCobwebWisp,
      'Pebble Gremlin' => paintGremlin,
      'Mist Wisp' => paintMistWisp,
      'Grumbling Treant' => paintTreant,
      'Chad\'s Old Rival, Brad' => paintBrad,
      _ => paintSlime,
    };

void paintSlime(Canvas c, ActorState s) {
  final squash = 1 + math.sin(s.time * 3) * 0.045 - s.windUp * 0.12;
  shadow(c, 26);
  c.save();
  c.scale(1 / squash, squash);
  final body = Path()
    ..moveTo(-24, 0)
    ..quadraticBezierTo(-28, -26, -8, -34)
    ..quadraticBezierTo(0, -40, 10, -34)
    ..quadraticBezierTo(28, -26, 24, 0)
    ..close();
  fillPath(c, body, const Color(0xFF7EC8E3));
  strokePath(c, body, 1.2, const Color(0xFF3F8FB0));
  oval(c, -9, -26, 5, 3, const Color(0x80FFFFFF));
  final awake = s.attack > 0.05 || s.windUp > 0.05;
  if (awake) {
    circle(c, -7, -16, 2.6, _ink);
    circle(c, 7, -16, 2.6, _ink);
  } else {
    strokePath(c, Path()..moveTo(-12, -16)..quadraticBezierTo(-8, -13, -4, -16), 1.8, const Color(0xFF1F3B4D));
    strokePath(c, Path()..moveTo(4, -16)..quadraticBezierTo(8, -13, 12, -16), 1.8, const Color(0xFF1F3B4D));
  }
  c.restore();
  if (!awake) {
    // Drifting "z" bubbles.
    for (var i = 0; i < 2; i++) {
      final t = (s.time * 0.5 + i * 0.5) % 1;
      final a = (1 - t).clamp(0.0, 1.0);
      final x = 20 + i * 8 + t * 6;
      final y = -40 - t * 22;
      strokePath(
        c,
        Path()
          ..moveTo(x, y)
          ..lineTo(x + 5, y)
          ..lineTo(x, y + 6)
          ..lineTo(x + 5, y + 6),
        1.6,
        Color.fromRGBO(63, 143, 176, a),
      );
    }
  }
}

void paintImp(Canvas c, ActorState s) {
  final hover = -4 + math.sin(s.time * 2.4) * 3;
  final flap = math.sin(s.time * 11);
  shadow(c, 14);
  c.save();
  c.translate(0, hover);
  for (final side in [-1.0, 1.0]) {
    c.save();
    c.scale(side, 1);
    final w = 1 + flap * 0.18;
    fillPath(
      c,
      Path()
        ..moveTo(12, -30)
        ..quadraticBezierTo(36, -44 * w, 32, -20)
        ..quadraticBezierTo(22, -26, 12, -22)
        ..close(),
      const Color(0xFF6A3D8F),
    );
    c.restore();
  }
  strokePath(
    c,
    Path()
      ..moveTo(10, -12)
      ..quadraticBezierTo(30, -6, 26, -26),
    3,
    const Color(0xFF8E5BB5),
  );
  fillPath(c, poly([24, -27, 30, -27, 27, -34]), const Color(0xFFE0D36A));
  oval(c, 0, -22, 12, 15, const Color(0xFF8E5BB5));
  circle(c, 0, -44, 11, const Color(0xFF8E5BB5));
  fillPath(c, poly([-8, -52, -13, -66, -3, -55]), const Color(0xFFE0D36A));
  fillPath(c, poly([8, -52, 13, -66, 3, -55]), const Color(0xFFE0D36A));
  circle(c, -4, -45, 3, const Color(0xFFFFE066));
  circle(c, 4, -45, 3, const Color(0xFFFFE066));
  circle(c, -4, -45, 1.2, _ink);
  circle(c, 4, -45, 1.2, _ink);
  strokePath(c, Path()..moveTo(-4, -39)..quadraticBezierTo(0, -36, 4, -39), 1.3, _ink);
  c.restore();
}

void paintGolem(Canvas c, ActorState s) {
  final stomp = math.sin(s.time * 1.6).abs() * 1.2;
  shadow(c, 24);
  rrect(c, -12, -14, 10, 14, 2, const Color(0xFF6D4C41));
  rrect(c, 2, -14, 10, 14, 2, const Color(0xFF6D4C41));
  c.save();
  c.translate(0, -stomp);
  rrect(c, -26, -46, 9, 28, 3, const Color(0xFF795548));
  rrect(c, 17, -46, 9, 28, 3, const Color(0xFF795548));
  rrect(c, -16, -48, 32, 34, 4, const Color(0xFF8D6E63));
  rrect(c, -10, -64, 20, 16, 3, const Color(0xFFA1887F));
  final glow = 0.7 + math.sin(s.time * 4) * 0.3 + s.windUp * 0.5;
  final eye = Color.fromRGBO(255, 213, 79, glow.clamp(0.0, 1.0));
  rrect(c, -6, -58, 4, 4, 1, eye);
  rrect(c, 2, -58, 4, 4, 1, eye);
  // Spinning gear.
  c.save();
  c.translate(0, -31);
  c.rotate(s.time * 1.2);
  circle(c, 0, 0, 8, const Color(0xFFB0907A));
  for (var i = 0; i < 8; i++) {
    c.save();
    c.rotate(i * math.pi / 4);
    rrect(c, -2, -12, 4, 5, 1, const Color(0xFF5D4037));
    c.restore();
  }
  circle(c, 0, 0, 3.2, const Color(0xFF5D4037));
  c.restore();
  circle(c, -10, -22, 2.5, const Color(0x99B4531A));
  circle(c, 9, -42, 2, const Color(0x99B4531A));
  c.restore();
}

void paintCobwebWisp(Canvas c, ActorState s) {
  final hover = -16 + math.sin(s.time * 2.0) * 5;
  oval(c, 0, 0, 14, 3.5, const Color(0x24000000));
  c.save();
  c.translate(0, hover);
  final flame = Path()
    ..moveTo(0, -48)
    ..quadraticBezierTo(18, -26, 14, -8)
    ..quadraticBezierTo(8, 4 + math.sin(s.time * 6) * 2, 0, -2)
    ..quadraticBezierTo(-8, 4 + math.cos(s.time * 6) * 2, -14, -8)
    ..quadraticBezierTo(-18, -26, 0, -48)
    ..close();
  fillPath(c, flame, const Color(0xFFE3F2FD));
  strokePath(c, flame, 1.2, const Color(0xFF90CAF9));
  // Web lines.
  strokePath(c, Path()..moveTo(-10, -24)..lineTo(10, -24)..moveTo(0, -42)..lineTo(0, -6)..moveTo(-8, -34)..lineTo(8, -14)..moveTo(8, -34)..lineTo(-8, -14), 0.7, const Color(0x80607D8B));
  oval(c, -5, -24, 2.6, 3.4, const Color(0xFF37474F));
  oval(c, 5, -24, 2.6, 3.4, const Color(0xFF37474F));
  oval(c, 0, -15, 2.4, 1.6, const Color(0xFF37474F));
  c.restore();
}

void paintGremlin(Canvas c, ActorState s) {
  final hop = math.sin(s.time * 4).abs() * 4;
  shadow(c, 14);
  c.save();
  c.translate(0, -hop);
  rrect(c, -7, -12, 5, 12, 2, const Color(0xFF558B2F));
  rrect(c, 2, -12, 5, 12, 2, const Color(0xFF558B2F));
  oval(c, 0, -24, 12, 14, const Color(0xFF7CB342));
  oval(c, 0, -22, 8, 9, const Color(0xFFAED581));
  fillPath(c, poly([-10, -42, -26, -48, -12, -34]), const Color(0xFF7CB342));
  fillPath(c, poly([10, -42, 26, -48, 12, -34]), const Color(0xFF7CB342));
  circle(c, 0, -40, 11, const Color(0xFF7CB342));
  circle(c, -4, -41, 3, const Color(0xFFFFFFFF));
  circle(c, 4, -41, 3, const Color(0xFFFFFFFF));
  circle(c, -4, -41, 1.3, _ink);
  circle(c, 4, -41, 1.3, _ink);
  strokePath(c, Path()..moveTo(-4, -34)..quadraticBezierTo(0, -31, 4, -34), 1.3, _ink);
  // Pebble held overhead.
  final raise = -8 - s.windUp * 10 - s.attack * 6;
  line(c, 9, -26, 14, -58 + raise, 4, const Color(0xFF7CB342));
  oval(c, 15, -64 + raise, 7, 5.5, const Color(0xFF90A4AE));
  oval(c, 13, -66 + raise, 3, 2, const Color(0x80FFFFFF));
  c.restore();
}

void paintMistWisp(Canvas c, ActorState s) {
  final hover = -14 + math.sin(s.time * 1.8 + 1) * 5;
  oval(c, 0, 0, 16, 3.5, const Color(0x24000000));
  c.save();
  c.translate(0, hover);
  const puff = Color(0xFFB39DDB);
  for (final p in const [
    [-10.0, -16.0, 11.0],
    [10.0, -16.0, 11.0],
    [0.0, -26.0, 14.0],
    [-14.0, -28.0, 8.0],
    [14.0, -28.0, 8.0],
  ]) {
    circle(c, p[0], p[1], p[2], puff);
  }
  circle(c, 0, -20, 12, const Color(0xFFD1C4E9));
  for (var i = 0; i < 3; i++) {
    final a = s.time * 1.6 + i * 2.1;
    circle(c, math.cos(a) * 20, -22 + math.sin(a) * 10, 2.4, const Color(0xCCEDE7F6));
  }
  circle(c, -4, -22, 2.4, _ink);
  circle(c, 4, -22, 2.4, _ink);
  strokePath(c, Path()..moveTo(-3, -16)..quadraticBezierTo(0, -14, 3, -16), 1.3, _ink);
  c.restore();
}

void paintTreant(Canvas c, ActorState s) {
  final sway = math.sin(s.time * 1.3) * 3;
  shadow(c, 30);
  // Roots and trunk.
  fillPath(c, poly([-22, 0, -12, -56, 12, -56, 22, 0]), const Color(0xFF6D4C2F));
  fillPath(c, poly([-22, 0, -30, 0, -20, -10]), const Color(0xFF6D4C2F));
  fillPath(c, poly([22, 0, 30, 0, 20, -10]), const Color(0xFF6D4C2F));
  // Branch arms.
  final raise = s.windUp * 12 + s.attack * -10;
  strokePath(c, Path()..moveTo(-12, -40)..quadraticBezierTo(-36 + sway, -46, -38 + sway, -70 - raise), 7, const Color(0xFF6D4C2F));
  strokePath(c, Path()..moveTo(12, -40)..quadraticBezierTo(36 - sway, -46, 38 - sway, -70 - raise), 7, const Color(0xFF6D4C2F));
  // Canopy.
  circle(c, 0, -80, 28, const Color(0xFF3F8F3F));
  circle(c, -24, -68, 17, const Color(0xFF4AA14A));
  circle(c, 24, -68, 17, const Color(0xFF4AA14A));
  circle(c, -10, -90, 12, const Color(0xFF5BB45B));
  // Face.
  strokePath(c, Path()..moveTo(-10, -46)..lineTo(-3, -43)..moveTo(10, -46)..lineTo(3, -43), 2.2, _ink);
  final glow = Color.fromRGBO(255, 213, 79, 0.8 + s.windUp * 0.2);
  circle(c, -6, -39, 2.8, glow);
  circle(c, 6, -39, 2.8, glow);
  strokePath(c, Path()..moveTo(-7, -26)..quadraticBezierTo(0, -32, 7, -26), 2.2, _ink);
}

// ---------------------------------------------------------------------------
// Props for expedition events
// ---------------------------------------------------------------------------

void paintCampfire(Canvas c, double t) {
  oval(c, 0, 0, 22, 5, const Color(0x2E000000));
  line(c, -16, -2, 14, -10, 6, const Color(0xFF6D4C2F));
  line(c, 16, -2, -14, -10, 6, const Color(0xFF5A3D24));
  for (var i = 0; i < 3; i++) {
    final h = 30 + math.sin(t * 9 + i * 2) * 5 - i * 7;
    final w = 14 - i * 3.0;
    fillPath(
      c,
      Path()
        ..moveTo(-w, -8)
        ..quadraticBezierTo(-w * 0.4, -h * 0.6, 0, -h)
        ..quadraticBezierTo(w * 0.4, -h * 0.6, w, -8)
        ..close(),
      [const Color(0xFFFF7043), const Color(0xFFFFB300), const Color(0xFFFFF59D)][i],
    );
  }
}

void paintMerchantCart(Canvas c, double t) {
  oval(c, 0, 0, 34, 5, const Color(0x2E000000));
  rrect(c, -30, -34, 60, 22, 4, const Color(0xFF8D6E63));
  rrect(c, -30, -38, 60, 6, 3, const Color(0xFF6D4C2F));
  circle(c, -18, -8, 9, const Color(0xFF4E342E));
  circle(c, 18, -8, 9, const Color(0xFF4E342E));
  circle(c, -18, -8, 3, const Color(0xFFBCAAA4));
  circle(c, 18, -8, 3, const Color(0xFFBCAAA4));
  // Potion bottles.
  for (var i = 0; i < 4; i++) {
    final x = -20.0 + i * 13;
    rrect(c, x - 3, -52, 6, 14, 3, [const Color(0xFFE57373), const Color(0xFF64B5F6), const Color(0xFF81C784), const Color(0xFFBA68C8)][i]);
    rrect(c, x - 1.5, -56, 3, 5, 1, const Color(0xFFBCAAA4));
  }
  fillPath(c, poly([-34, -58, 34, -58, 28, -72, -28, -72]), const Color(0xFFC62828));
  fillPath(c, poly([-14, -58, 0, -58, -4, -72, -18, -72]), const Color(0xFFFAFAFA));
  fillPath(c, poly([14, -58, 28, -58, 26, -72, 12, -72]), const Color(0xFFFAFAFA));
}

/// A treasure chest; [open] is 0 (closed) to 1 (lid fully up).
void paintChest(Canvas c, double open, double glow) {
  oval(c, 0, 0, 26, 5, const Color(0x2E000000));
  if (glow > 0) {
    _p
      ..style = PaintingStyle.fill
      ..color = Color.fromRGBO(255, 235, 130, 0.35 * glow);
    c.drawCircle(const Offset(0, -26), 46 * glow, _p);
  }
  rrect(c, -22, -26, 44, 26, 3, const Color(0xFF8D5A2B));
  rrect(c, -22, -16, 44, 4, 0, const Color(0xFFF2C94C));
  c.save();
  c.translate(-22, -26);
  c.rotate(-open * 1.25);
  rrect(c, 0, -14, 44, 14, 6, const Color(0xFFA0692F));
  rrect(c, 0, -5, 44, 4, 0, const Color(0xFFF2C94C));
  c.restore();
  rrect(c, -4, -24, 8, 9, 2, const Color(0xFFF2C94C));
  if (open > 0.4) {
    final a = ((open - 0.4) / 0.6).clamp(0.0, 1.0);
    _p
      ..style = PaintingStyle.fill
      ..color = Color.fromRGBO(255, 244, 180, 0.8 * a);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-18, -29, 36, 5), const Radius.circular(2)), _p);
  }
}
