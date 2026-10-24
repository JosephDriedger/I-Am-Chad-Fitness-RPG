/// The enemies of the later regions, and the camp props that go with them, drawn
/// in code like the rest of the game's art. Characters stand with their feet at
/// the origin and face +x. See painters.dart for the conventions.
library;

import 'dart:math' as math;
import 'dart:ui';

import '../look.dart';
import 'painters.dart';

const _ink = Color(0xFF2B1D14);

/// Recolours another painter: a translucent [tint] laid over everything it
/// draws, so one body can be a whole family (an icy golem, a stormy imp).
ActorPainter tinted(ActorPainter base, Color tint) => (Canvas c, ActorState s) {
      c.saveLayer(null, Paint());
      base(c, s);
      // srcATop paints only where something was already drawn.
      c.drawRect(
        const Rect.fromLTWH(-200, -300, 400, 400),
        Paint()
          ..color = tint
          ..blendMode = BlendMode.srcATop,
      );
      c.restore();
    };

// ---------------------------------------------------------------------------
// The Gullhaven Coast
// ---------------------------------------------------------------------------

/// A crab. [hat] puts a captain's hat on a big one.
void paintCrab(Canvas c, ActorState s, {bool hat = false}) {
  final snap = s.windUp * 0.7 + s.attack * 0.9 + math.sin(s.time * 3).abs() * 0.15;
  shadow(c, 26);
  const shell = Color(0xFFE2703A);
  const shellDark = Color(0xFFB8501F);
  // Legs.
  for (var i = 0; i < 3; i++) {
    final y = -10 - i * 3.0;
    final wiggle = math.sin(s.time * 6 + i) * 2;
    line(c, -14, y, -26, y + 8 + wiggle, 2.6, shellDark);
    line(c, 14, y, 26, y + 8 - wiggle, 2.6, shellDark);
  }
  // Claws, raised and snapping.
  for (final side in [-1.0, 1.0]) {
    c.save();
    c.translate(side * 20, -26);
    c.rotate(side * (-0.5 - snap * 0.5));
    line(c, 0, 0, side * 6, -14, 4, shell);
    c.save();
    c.translate(side * 6, -16);
    final gap = 0.25 + snap * 0.6;
    c.rotate(side * -0.2);
    fillPath(c, poly([0, 0, side * 14, -6 - gap * 8, side * 12, -2]), shell);
    fillPath(c, poly([0, 0, side * 14, 4 + gap * 8, side * 12, 0]), shellDark);
    c.restore();
    c.restore();
  }
  // Shell and face.
  oval(c, 0, -18, 24, 15, shell);
  oval(c, 0, -22, 19, 9, const Color(0xFFF08A52));
  for (final e in [-8.0, 8.0]) {
    line(c, e, -30, e, -38, 2, shellDark);
    circle(c, e, -40, 4.2, const Color(0xFFFFFFFF));
    circle(c, e + 0.8, -40, 1.8, _ink);
  }
  strokePath(c, Path()..moveTo(-6, -15)..quadraticBezierTo(0, -11, 6, -15), 1.6, _ink);
  if (hat) {
    // A very large captain's hat.
    fillPath(c, poly([-26, -44, 26, -44, 18, -58, 0, -66, -18, -58]), const Color(0xFF1F2F4F));
    rrect(c, -18, -49, 36, 4, 1, const Color(0xFFF2C94C));
    circle(c, 0, -56, 3.4, const Color(0xFFF2C94C));
  }
}

/// A jelly: a glowing bell, trailing tentacles.
void paintJelly(Canvas c, ActorState s) {
  final bob = -6 + math.sin(s.time * 2) * 4;
  final pulse = 1 + math.sin(s.time * 3) * 0.05 - s.windUp * 0.1;
  oval(c, 0, 0, 16, 3.5, const Color(0x24000000));
  c.save();
  c.translate(0, bob);
  // Tentacles.
  for (var i = 0; i < 5; i++) {
    final x = -12.0 + i * 6;
    final sway = math.sin(s.time * 3 + i * 1.3) * 4;
    strokePath(
      c,
      Path()
        ..moveTo(x, -22)
        ..quadraticBezierTo(x + sway, -10, x - sway * 0.5, 0),
      2.6,
      const Color(0xAAE1BEE7),
    );
  }
  c.save();
  c.scale(1 / pulse, pulse);
  final bell = Path()
    ..moveTo(-22, -22)
    ..quadraticBezierTo(-24, -52, 0, -52)
    ..quadraticBezierTo(24, -52, 22, -22)
    ..quadraticBezierTo(0, -16, -22, -22)
    ..close();
  fillPath(c, bell, const Color(0xCCCE93D8));
  strokePath(c, bell, 1.4, const Color(0xFFAB47BC));
  oval(c, -8, -42, 6, 3, const Color(0x80FFFFFF));
  circle(c, 0, -34, 8, const Color(0x44FFFFFF));
  c.restore();
  circle(c, -6, -30, 2.4, _ink);
  circle(c, 6, -30, 2.4, _ink);
  strokePath(c, Path()..moveTo(-3, -25)..quadraticBezierTo(0, -22.5, 3, -25), 1.4, _ink);
  c.restore();
}

/// A seabird. [king] gives it a crown and a stormier colour.
void paintBird(Canvas c, ActorState s, {Color body = const Color(0xFFF7F7F2), Color wing = const Color(0xFF90A4AE), bool crown = false}) {
  final flap = math.sin(s.time * (s.windUp > 0.1 ? 14 : 7));
  final hover = -4 + math.sin(s.time * 2) * 2 - s.windUp * 4;
  shadow(c, 16);
  c.save();
  c.translate(0, hover);
  // Legs and tail.
  line(c, -3, -12, -3, -2, 1.8, const Color(0xFFFFA726));
  line(c, 4, -12, 5, -2, 1.8, const Color(0xFFFFA726));
  fillPath(c, poly([-14, -22, -28, -26, -26, -16]), wing);
  // Body and head.
  oval(c, 0, -22, 16, 11, body);
  oval(c, 2, -18, 11, 6, shade(body, -0.06));
  circle(c, 12, -33, 8, body);
  fillPath(c, poly([18, -34, 30, -31, 18, -29]), const Color(0xFFFFA726));
  circle(c, 14, -35, 1.8, _ink);
  // Wing, beating.
  c.save();
  c.translate(-2, -26);
  c.rotate(-0.6 - flap * 0.7);
  fillPath(
    c,
    Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-14, -22, -30, -14)
      ..quadraticBezierTo(-16, -10, 0, 4)
      ..close(),
    wing,
  );
  c.restore();
  if (crown) {
    fillPath(c, poly([6, -40, 8, -48, 11, -42, 14, -50, 17, -42, 20, -48, 21, -40]), const Color(0xFFF2C94C));
  }
  c.restore();
}

void paintGull(Canvas c, ActorState s) => paintBird(c, s);

void paintGullKing(Canvas c, ActorState s) =>
    paintBird(c, s, body: const Color(0xFFFFF8E1), wing: const Color(0xFF546E7A), crown: true);

void paintGaleHawk(Canvas c, ActorState s) =>
    paintBird(c, s, body: const Color(0xFF8D6E63), wing: const Color(0xFF4E342E));

// ---------------------------------------------------------------------------
// The Glimmer Caverns
// ---------------------------------------------------------------------------

void paintBeetle(Canvas c, ActorState s) {
  final scuttle = math.sin(s.time * 5) * 1.5;
  shadow(c, 26);
  const shell = Color(0xFF3E5C76);
  for (var i = 0; i < 3; i++) {
    final x = -14.0 + i * 12;
    line(c, x, -8, x - 5, 0 + scuttle * (i.isEven ? 1 : -1), 2.4, const Color(0xFF263B4F));
    line(c, x + 4, -8, x + 9, 0 - scuttle * (i.isEven ? 1 : -1), 2.4, const Color(0xFF263B4F));
  }
  oval(c, -2, -18, 24, 16, shell);
  oval(c, -2, -22, 19, 9, const Color(0xFF5D7F9E));
  line(c, -2, -33, -2, -4, 1.4, const Color(0xFF263B4F));
  // Glowing crystals on its back.
  final glow = 0.7 + math.sin(s.time * 3) * 0.3 + s.windUp * 0.3;
  for (final p in const [[-12.0, -30.0, 9.0], [-2.0, -34.0, 12.0], [8.0, -30.0, 9.0]]) {
    fillPath(c, poly([p[0] - 3.5, p[1], p[0], p[1] - p[2], p[0] + 3.5, p[1]]), Color.fromRGBO(186, 140, 255, glow.clamp(0.0, 1.0)));
  }
  // Head with a crystal horn.
  circle(c, 22, -17, 8.5, const Color(0xFF2E4A62));
  fillPath(c, poly([24, -23, 36, -33, 29, -20]), const Color(0xFFD1A8FF));
  circle(c, 25, -19, 2.4, const Color(0xFFFFFFFF));
  circle(c, 25.6, -19, 1.1, _ink);
}

/// A mushroom. [cap] and [spots] make the big one a different colour.
void paintShroom(Canvas c, ActorState s, {Color cap = const Color(0xFF26A69A), Color spots = const Color(0xFFB2FF59)}) {
  final bounce = math.sin(s.time * 2.4) * 1.2 - s.windUp * 3;
  shadow(c, 20);
  final glow = 0.25 + math.sin(s.time * 2) * 0.1;
  circle(c, 0, -34, 40, Color.fromRGBO(178, 255, 89, glow));
  c.save();
  c.translate(0, bounce);
  // Stem and arms.
  rrect(c, -10, -34, 20, 34, 8, const Color(0xFFF3E9D2));
  rrect(c, -10, -12, 20, 5, 0, const Color(0x22000000));
  final wave = s.attack * 10 + math.sin(s.time * 3) * 2;
  line(c, -10, -22, -20, -14 - wave, 4, const Color(0xFFF3E9D2));
  line(c, 10, -22, 20, -14 - wave, 4, const Color(0xFFF3E9D2));
  // Cap.
  final top = Path()
    ..moveTo(-28, -32)
    ..quadraticBezierTo(-30, -62, 0, -62)
    ..quadraticBezierTo(30, -62, 28, -32)
    ..quadraticBezierTo(0, -28, -28, -32)
    ..close();
  fillPath(c, top, cap);
  circle(c, -12, -48, 4.6, spots);
  circle(c, 6, -54, 3.6, spots);
  circle(c, 15, -44, 4, spots);
  circle(c, -2, -40, 2.6, spots);
  // Face.
  circle(c, -4, -24, 1.8, _ink);
  circle(c, 4, -24, 1.8, _ink);
  strokePath(c, Path()..moveTo(-3, -19)..quadraticBezierTo(0, -16.5, 3, -19), 1.4, _ink);
  c.restore();
}

void paintMotherGlowcap(Canvas c, ActorState s) =>
    paintShroom(c, s, cap: const Color(0xFFAB47BC), spots: const Color(0xFFFFEB3B));

void paintBat(Canvas c, ActorState s) {
  final flap = math.sin(s.time * (s.windUp > 0.1 ? 16 : 9));
  final hover = -22 + math.sin(s.time * 2.2) * 5;
  oval(c, 0, 0, 14, 3.5, const Color(0x24000000));
  c.save();
  c.translate(0, hover);
  for (final side in [-1.0, 1.0]) {
    c.save();
    c.scale(side, 1);
    final lift = flap * 14;
    fillPath(
      c,
      Path()
        ..moveTo(6, -4)
        ..quadraticBezierTo(24, -30 - lift, 40, -14 - lift * 0.4)
        ..quadraticBezierTo(32, -12, 30, -4)
        ..quadraticBezierTo(22, -8, 16, 0)
        ..quadraticBezierTo(12, -6, 6, 2)
        ..close(),
      const Color(0xFF5E35B1),
    );
    c.restore();
  }
  oval(c, 0, -6, 9, 12, const Color(0xFF7E57C2));
  circle(c, 0, -22, 8.5, const Color(0xFF7E57C2));
  fillPath(c, poly([-7, -26, -9, -38, -2, -28]), const Color(0xFF7E57C2));
  fillPath(c, poly([7, -26, 9, -38, 2, -28]), const Color(0xFF7E57C2));
  circle(c, -3.4, -23, 2.2, const Color(0xFFFFEE58));
  circle(c, 3.4, -23, 2.2, const Color(0xFFFFEE58));
  circle(c, -3.4, -23, 0.9, _ink);
  circle(c, 3.4, -23, 0.9, _ink);
  fillPath(c, poly([-2, -17, -1, -13, 0, -17]), const Color(0xFFFFFFFF));
  fillPath(c, poly([2, -17, 1, -13, 0, -17]), const Color(0xFFFFFFFF));
  c.restore();
  // An echo, rippling out.
  final t = (s.time * 0.8) % 1;
  strokePath(c, Path()..addArc(Rect.fromCircle(center: Offset(0, hover - 20), radius: 20 + t * 22), -0.5, 1), 1.6, Color.fromRGBO(206, 147, 216, 1 - t));
}

// ---------------------------------------------------------------------------
// Frostpeak Pass
// ---------------------------------------------------------------------------

void paintFrostSprite(Canvas c, ActorState s) {
  final hover = -22 + math.sin(s.time * 2.8) * 4;
  final buzz = math.sin(s.time * 20);
  oval(c, 0, 0, 12, 3, const Color(0x24000000));
  c.save();
  c.translate(0, hover);
  for (final side in [-1.0, 1.0]) {
    c.save();
    c.scale(side, 1);
    c.rotate(buzz * 0.08);
    fillPath(c, Path()..moveTo(4, -18)..quadraticBezierTo(24, -38, 20, -10)..quadraticBezierTo(10, -12, 4, -14)..close(), const Color(0x88B3E5FC));
    c.restore();
  }
  oval(c, 0, -14, 7, 10, const Color(0xFFE1F5FE));
  circle(c, 0, -30, 8, const Color(0xFFE1F5FE));
  fillPath(c, poly([-7, -36, -9, -48, -3, -38, 0, -50, 3, -38, 9, -48, 7, -36]), const Color(0xFF81D4FA));
  circle(c, -3, -30, 1.8, const Color(0xFF1565C0));
  circle(c, 3, -30, 1.8, const Color(0xFF1565C0));
  strokePath(c, Path()..moveTo(-2, -25)..quadraticBezierTo(0, -23, 2, -25), 1.2, const Color(0xFF1565C0));
  // A snowflake wand.
  final raise = s.windUp * 8 + s.attack * -6;
  line(c, 8, -14, 18, -26 - raise, 2, const Color(0xFF90CAF9));
  for (var i = 0; i < 3; i++) {
    c.save();
    c.translate(18, -29 - raise);
    c.rotate(i * math.pi / 3 + s.time * 2);
    line(c, -5, 0, 5, 0, 1.6, const Color(0xFFFFFFFF));
    c.restore();
  }
  c.restore();
}

/// A big, fluffy yeti. [fur] and [beard] make the bosses their own.
void paintYeti(Canvas c, ActorState s, {Color fur = const Color(0xFFF5F5F5), bool beard = false, bool horns = false}) {
  final breathe = math.sin(s.time * 1.8) * 1.4;
  final raise = s.windUp * 16 + s.attack * -14;
  shadow(c, 30);
  final shade1 = shade(fur, -0.08);
  rrect(c, -18, -16, 14, 16, 5, shade1);
  rrect(c, 4, -16, 14, 16, 5, shade1);
  c.save();
  c.translate(0, breathe);
  // Arms.
  line(c, -22, -50, -34, -24 - raise, 11, fur);
  line(c, 22, -50, 34, -24 - raise, 11, fur);
  circle(c, -34, -22 - raise, 8, shade1);
  circle(c, 34, -22 - raise, 8, shade1);
  // Body and fluff.
  oval(c, 0, -36, 24, 26, fur);
  oval(c, 0, -30, 14, 16, shade(fur, -0.04));
  for (final p in const [[-20.0, -48.0], [20.0, -48.0], [-12.0, -20.0], [12.0, -20.0]]) {
    fillPath(c, poly([p[0] - 5, p[1], p[0], p[1] - 9, p[0] + 5, p[1]]), fur);
  }
  // Head.
  circle(c, 0, -66, 15, fur);
  oval(c, 0, -63, 10, 9, const Color(0xFF90A4AE));
  circle(c, -4, -66, 2, const Color(0xFFFFFFFF));
  circle(c, 4, -66, 2, const Color(0xFFFFFFFF));
  circle(c, -4, -66, 0.9, _ink);
  circle(c, 4, -66, 0.9, _ink);
  strokePath(c, Path()..moveTo(-5, -58)..quadraticBezierTo(0, -55, 5, -58), 1.6, _ink);
  fillPath(c, poly([-4, -58, -3, -53, -2, -58]), const Color(0xFFFFFFFF));
  fillPath(c, poly([4, -58, 3, -53, 2, -58]), const Color(0xFFFFFFFF));
  if (beard) {
    fillPath(c, Path()..moveTo(-12, -58)..quadraticBezierTo(0, -36, 12, -58)..quadraticBezierTo(0, -50, -12, -58)..close(), const Color(0xFFE3F2FD));
  }
  if (horns) {
    fillPath(c, poly([-10, -78, -18, -94, -4, -80]), const Color(0xFFB0BEC5));
    fillPath(c, poly([10, -78, 18, -94, 4, -80]), const Color(0xFFB0BEC5));
  }
  c.restore();
}

void paintAvalancheMatron(Canvas c, ActorState s) =>
    paintYeti(c, s, fur: const Color(0xFFE3F2FD), horns: true);

void paintOldManWinter(Canvas c, ActorState s) =>
    paintYeti(c, s, fur: const Color(0xFFCFD8DC), beard: true);

// ---------------------------------------------------------------------------
// Thunder Heights
// ---------------------------------------------------------------------------

/// A thundercloud. [dark] is the big one.
void paintCloud(Canvas c, ActorState s, {bool dark = false}) {
  final hover = -26 + math.sin(s.time * 1.6) * 4;
  final base = dark ? const Color(0xFF455A64) : const Color(0xFF78909C);
  final light = dark ? const Color(0xFF607D8B) : const Color(0xFF90A4AE);
  oval(c, 0, 0, 18, 3.5, const Color(0x24000000));
  c.save();
  c.translate(0, hover);
  // Rain.
  for (var i = 0; i < 5; i++) {
    final t = (s.time * 1.4 + i * 0.37) % 1;
    final x = -16.0 + i * 8;
    line(c, x, -10 + t * 22, x - 1.5, -4 + t * 22, 1.4, const Color(0xAA90CAF9));
  }
  for (final p in const [
    [-16.0, -22.0, 13.0],
    [16.0, -22.0, 13.0],
    [0.0, -32.0, 17.0],
    [-26.0, -18.0, 9.0],
    [26.0, -18.0, 9.0],
  ]) {
    circle(c, p[0], p[1], p[2], base);
  }
  circle(c, 0, -26, 15, light);
  // A bolt that flickers, and grows when it is about to strike.
  final flick = (math.sin(s.time * 9) > 0.2 || s.windUp > 0.1) ? 1.0 : 0.25;
  final bolt = poly([-3, -14, 5, -14, 1, -6, 7, -6, -4, 8, -1, -2, -6, -2]);
  fillPath(c, bolt, Color.fromRGBO(255, 241, 118, flick));
  // Face.
  strokePath(c, Path()..moveTo(-10, -34)..lineTo(-3, -31)..moveTo(10, -34)..lineTo(3, -31), 2, _ink);
  circle(c, -6, -29, 2.4, const Color(0xFFFFFF8D));
  circle(c, 6, -29, 2.4, const Color(0xFFFFFF8D));
  c.restore();
}

void paintThunderhead(Canvas c, ActorState s) => paintCloud(c, s, dark: true);

// ---------------------------------------------------------------------------
// Camp props for the new events
// ---------------------------------------------------------------------------

/// A wandering bard's stool and lute, with notes drifting up.
void paintBard(Canvas c, double t) {
  oval(c, 0, 0, 24, 5, const Color(0x2E000000));
  rrect(c, -8, -16, 16, 5, 2, const Color(0xFF8D6E63));
  line(c, -6, -11, -8, 0, 3, const Color(0xFF6D4C2F));
  line(c, 6, -11, 8, 0, 3, const Color(0xFF6D4C2F));
  // The lute.
  c.save();
  c.translate(4, -30);
  c.rotate(-0.5);
  oval(c, 0, 0, 9, 11, const Color(0xFFD7A86E));
  circle(c, 0, 1, 3, const Color(0xFF5D4037));
  rrect(c, -1.5, -26, 3, 18, 1, const Color(0xFF6D4C2F));
  fillPath(c, poly([-3, -29, 3, -29, 2, -24, -2, -24]), const Color(0xFF6D4C2F));
  c.restore();
  // Notes.
  for (var i = 0; i < 3; i++) {
    final p = (t * 0.6 + i / 3) % 1;
    final x = -12.0 + i * 14 + math.sin(p * 6 + i) * 4;
    final y = -40 - p * 34;
    final a = (1 - p).clamp(0.0, 1.0);
    final col = Color.fromRGBO(255, 224, 130, a);
    circle(c, x, y, 3, col);
    line(c, x + 2.6, y, x + 2.6, y - 10, 1.6, col);
  }
}

/// A small spring in a ring of stones, rippling.
void paintSpring(Canvas c, double t) {
  oval(c, 0, 0, 30, 6, const Color(0x2E000000));
  oval(c, 0, -6, 26, 9, const Color(0xFF8D8D99));
  oval(c, 0, -7, 21, 6.5, const Color(0xFF4FC3F7));
  oval(c, -6, -8, 7, 2, const Color(0x99FFFFFF));
  for (var i = 0; i < 2; i++) {
    final p = (t * 0.7 + i * 0.5) % 1;
    final a = (1 - p).clamp(0.0, 1.0);
    strokePath(c, Path()..addOval(Rect.fromCenter(center: const Offset(0, -7), width: 10 + p * 26, height: 3 + p * 8)), 1.2, Color.fromRGBO(255, 255, 255, a * 0.8));
  }
  for (final x in const [-22.0, -12.0, 6.0, 18.0]) {
    oval(c, x, -9, 6, 4.5, const Color(0xFF9E9EAA));
  }
  // A little fern.
  for (var i = 0; i < 3; i++) {
    strokePath(c, Path()..moveTo(26, -10)..quadraticBezierTo(30 + i * 3, -22 - i * 4, 36 + i * 4, -22 - i * 6), 2, const Color(0xFF66BB6A));
  }
}

// ---------------------------------------------------------------------------
// The Sunstone Dunes
// ---------------------------------------------------------------------------

/// A small whirlwind of sand with a face, and somebody's hat going round on top.
void paintDustDevil(Canvas c, ActorState s) {
  final spin = s.time * 6 + s.windUp * 8 + s.attack * 10;
  shadow(c, 18);
  const sand = Color(0xFFE0B26B);
  const pale = Color(0xFFF5D9A0);
  for (var i = 0; i < 6; i++) {
    final w = 8 + i * 3.6 + s.windUp * i * 0.7;
    final dx = math.sin(spin + i * 0.9) * (3 + i * 0.8);
    oval(c, dx, -6 - i * 10.0, w, 6, Color.lerp(sand, pale, i / 5)!);
  }
  // Grit going round.
  for (var i = 0; i < 7; i++) {
    final a = spin * 1.3 + i * 0.9;
    circle(c, math.cos(a) * (14 + i * 2), -10 - i * 8 + math.sin(a) * 3, 1.5, const Color(0xFFB8864B));
  }
  // The face rides the second band from the top.
  final fx = math.sin(spin + 4.5) * 6;
  circle(c, fx - 5, -50, 2.6, const Color(0xFFFFFFFF));
  circle(c, fx + 5, -50, 2.6, const Color(0xFFFFFFFF));
  circle(c, fx - 4.5, -50, 1.1, _ink);
  circle(c, fx + 5.5, -50, 1.1, _ink);
  strokePath(c, Path()..moveTo(fx - 5, -43)..quadraticBezierTo(fx, -38, fx + 5, -43), 1.6, _ink);
  // The stolen hat.
  c.save();
  c.translate(math.sin(spin + 5.4) * 9, -68);
  c.rotate(math.sin(spin) * 0.3);
  rrect(c, -9, -3, 18, 3, 1.5, const Color(0xFF6D4326));
  rrect(c, -5, -9, 10, 7, 2, const Color(0xFF8D5E3C));
  c.restore();
}

/// A cactus in a flowerpot helmet, with a very small sword.
void paintCactusKnight(Canvas c, ActorState s) {
  final sway = math.sin(s.time * 2) * 1.2;
  final raise = s.windUp * 14 - s.attack * 10;
  shadow(c, 18);
  const green = Color(0xFF4F9A4A);
  const dark = Color(0xFF2F6E33);
  c.save();
  c.translate(sway * 0.4, 0);
  // Arms, one holding the sword.
  rrect(c, -26, -42, 14, 8, 4, green);
  rrect(c, -26, -58, 8, 24, 4, green);
  rrect(c, 12, -42, 14, 8, 4, green);
  rrect(c, 19, -54, 8, 20, 4, green);
  line(c, 23, -56 - raise * 0.3, 38, -78 - raise, 2.8, const Color(0xFFCFD8DC));
  rrect(c, 19, -58 - raise * 0.3, 9, 3, 1.5, const Color(0xFFB87D2E));
  // Body, with ridges and prickles.
  rrect(c, -13, -60, 26, 58, 12, green);
  for (final x in const [-6.0, 0.0, 6.0]) {
    line(c, x, -56, x, -6, 1.2, dark);
  }
  for (final p in const [[-14.0, -30.0], [14.0, -22.0], [-14.0, -14.0], [14.0, -40.0]]) {
    line(c, p[0], p[1], p[0] + (p[0] < 0 ? -4 : 4), p[1] - 2, 1.4, const Color(0xFFF1F8E9));
  }
  // The pot helmet and its single flower.
  fillPath(c, poly([-14, -60, 14, -60, 11, -78, -11, -78]), const Color(0xFFC0643A));
  rrect(c, -16, -63, 32, 5, 2, const Color(0xFFD9784A));
  circle(c, 0, -82, 4, const Color(0xFFF48FB1));
  circle(c, 0, -82, 1.6, const Color(0xFFFFEE58));
  // A kind, serious face.
  circle(c, -5, -46, 2.2, const Color(0xFFFFFFFF));
  circle(c, 5, -46, 2.2, const Color(0xFFFFFFFF));
  circle(c, -4.6, -46, 1, _ink);
  circle(c, 5.4, -46, 1, _ink);
  strokePath(c, Path()..moveTo(-4, -38)..quadraticBezierTo(0, -35, 4, -38), 1.5, _ink);
  c.restore();
}

/// A dung beetle in blue, rolling a golden ball that it will not explain.
void paintScarab(Canvas c, ActorState s) {
  final roll = s.time * 3 + s.attack * 4;
  final shove = s.attack * 8 - s.windUp * 6;
  shadow(c, 28);
  // The ball, out in front.
  c.save();
  c.translate(24 + shove, -15);
  c.rotate(roll);
  circle(c, 0, 0, 15, const Color(0xFFD9A441));
  circle(c, 0, 0, 15, const Color(0x22000000));
  circle(c, -2, -2, 12, const Color(0xFFF2C94C));
  line(c, -9, 0, 9, 0, 1.6, const Color(0xFFB8864B));
  line(c, 0, -9, 0, 9, 1.6, const Color(0xFFB8864B));
  c.restore();
  // Legs.
  for (var i = 0; i < 3; i++) {
    final wig = math.sin(s.time * 8 + i * 1.7) * 2;
    line(c, -14 + i * 8, -10, -18 + i * 8 + wig, 0, 2.2, const Color(0xFF1F3F5F));
  }
  line(c, 6, -16, 14, -6, 2.6, const Color(0xFF1F3F5F));
  // Shell, wing line and a gleam.
  oval(c, -8, -20, 22, 13, const Color(0xFF2E6AA3));
  line(c, -8, -32, -8, -8, 1.4, const Color(0xFF1F3F5F));
  oval(c, -16, -25, 6, 3, const Color(0x66FFFFFF));
  // Head with horns.
  circle(c, 14, -22, 8, const Color(0xFF1F3F5F));
  fillPath(c, poly([12, -29, 16, -29, 14, -39]), const Color(0xFF90A4AE));
  circle(c, 17, -24, 2.2, const Color(0xFFFFFFFF));
  circle(c, 17.6, -24, 1, _ink);
  strokePath(c, Path()..moveTo(14, -17)..quadraticBezierTo(18, -15, 20, -18), 1.4, const Color(0xFFFFB74D));
}

/// A great sand-coloured worm coming up out of a dune to say hello.
void paintDuneWorm(Canvas c, ActorState s) {
  final sway = math.sin(s.time * 1.4) * 6;
  final lunge = s.attack * 14 - s.windUp * 10;
  const skin = Color(0xFFB07A55);
  const belly = Color(0xFFE3B98C);
  oval(c, 0, -2, 38, 9, const Color(0xFFD9B070));
  for (var i = 0; i < 7; i++) {
    final t = i / 6;
    final x = sway * t + t * t * (20 + lunge);
    final y = -10 - t * 68;
    final r = 21 - t * 4;
    circle(c, x, y, r, i.isEven ? skin : shade(skin, 0.05));
    oval(c, x + 4, y + 2, r * 0.5, r * 0.8, belly);
    line(c, x - r * 0.9, y, x - r * 0.5, y + 2, 1.3, shade(skin, -0.12));
  }
  // The head, at the top, with a mouth open towards the hero.
  const t = 1.0;
  final hx = sway * t + t * t * (20 + lunge) + 6;
  const hy = -78.0;
  circle(c, hx, hy, 19, shade(skin, 0.04));
  final gape = 6 + s.windUp * 6 + s.attack * 5;
  oval(c, hx + 12, hy + 4, 8, gape, const Color(0xFF5A2A2A));
  for (var i = 0; i < 4; i++) {
    final ty = hy + 4 - gape + 3 + i * (gape * 2 - 6) / 3;
    fillPath(c, poly([hx + 8, ty - 2, hx + 14, ty, hx + 8, ty + 2]), const Color(0xFFFFF3D6));
  }
  circle(c, hx - 2, hy - 8, 3, const Color(0xFFFFFFFF));
  circle(c, hx - 1.4, hy - 8, 1.3, _ink);
  strokePath(c, Path()..moveTo(hx - 7, hy - 13)..quadraticBezierTo(hx - 2, hy - 16, hx + 3, hy - 12), 1.6, shade(skin, -0.2));
}

/// A sphinx lying in the sun, in a striped headcloth, with a riddle in the air.
void paintSphinx(Canvas c, ActorState s) {
  final breathe = math.sin(s.time * 1.6) * 1;
  final lift = s.windUp * 8 - s.attack * 6;
  const fur = Color(0xFFE0B26B);
  const dark = Color(0xFFC08F4B);
  shadow(c, 38);
  // The tail, curling up behind.
  strokePath(c, Path()..moveTo(-32, -10)..quadraticBezierTo(-50, -12, -44, -30 + math.sin(s.time * 2) * 3), 4, dark);
  // Body and the two front paws, out in front.
  oval(c, -6, -20 + breathe, 32, 16, fur);
  rrect(c, 6, -11, 34, 9, 4, fur);
  rrect(c, 8, -5, 32, 6, 3, dark);
  // The striped headcloth and the face.
  fillPath(c, poly([12, -62 - lift, 38, -62 - lift, 44, -26, 6, -26]), const Color(0xFFF2C94C));
  for (var i = 0; i < 4; i++) {
    final y = -58 - lift + i * 8.0;
    line(c, 13 + i * 0.7, y, 37 - i * 0.7, y, 2.4, const Color(0xFF2E6AA3));
  }
  circle(c, 25, -46 - lift, 9.5, const Color(0xFFD9A074));
  circle(c, 21.5, -47 - lift, 1.8, _ink);
  circle(c, 28.5, -47 - lift, 1.8, _ink);
  strokePath(c, Path()..moveTo(20, -43 - lift)..quadraticBezierTo(25, -39 - lift, 30, -43 - lift), 1.5, const Color(0xFF8E4B3A));
  // The riddle: a question mark that bobs.
  final bob = math.sin(s.time * 2.2) * 3;
  final q = Path()
    ..moveTo(18, -80 - lift + bob)
    ..quadraticBezierTo(18, -88 - lift + bob, 25, -88 - lift + bob)
    ..quadraticBezierTo(32, -88 - lift + bob, 32, -81 - lift + bob)
    ..quadraticBezierTo(32, -76 - lift + bob, 25, -73 - lift + bob)
    ..lineTo(25, -70 - lift + bob);
  strokePath(c, q, 2.6, const Color(0xFFFFF3D6));
  circle(c, 25, -65 - lift + bob, 1.8, const Color(0xFFFFF3D6));
}

/// A signpost where the path splits, with an arrow each way and a lantern.
void paintSignpost(Canvas c, double t) {
  oval(c, 0, 0, 22, 5, const Color(0x2E000000));
  rrect(c, -3, -62, 6, 62, 2, const Color(0xFF6D4C2F));
  // Two arrows, pointing apart.
  c.save();
  c.translate(0, -52);
  fillPath(c, poly([-3, -6, -26, -6, -32, 0, -26, 6, -3, 6]), const Color(0xFFD7A86E));
  fillPath(c, poly([3, 12, 26, 12, 32, 18, 26, 24, 3, 24]), const Color(0xFFC9955A));
  for (var i = 0; i < 3; i++) {
    line(c, -24 + i * 6.0, -3, -24 + i * 6.0, 3, 1.2, const Color(0xFF8D6E63));
    line(c, 8 + i * 6.0, 15, 8 + i * 6.0, 21, 1.2, const Color(0xFF8D6E63));
  }
  c.restore();
  // A small lantern hanging from the top, swaying and glowing.
  final sway = math.sin(t * 1.6) * 2;
  line(c, 3, -60, 12 + sway * 0.4, -52, 1.2, const Color(0xFF5D4037));
  circle(c, 12 + sway, -48, 8 + math.sin(t * 4) * 0.8, const Color(0x33FFC857));
  rrect(c, 9.5 + sway, -52, 5, 7, 1.5, const Color(0xFFFFE9A8));
}

// ---------------------------------------------------------------------------
// The Starlit Isles
// ---------------------------------------------------------------------------

/// A large soft moth with a glowing belly, flapping.
void paintLanternMoth(Canvas c, ActorState s) {
  final flap = math.sin(s.time * 9 + s.windUp * 6) * 0.35;
  final hover = -26 + math.sin(s.time * 2) * 4;
  oval(c, 0, 0, 16, 3, const Color(0x24000000));
  c.save();
  c.translate(0, hover);
  // Wings, a pair each side, beating.
  for (final side in [-1.0, 1.0]) {
    c.save();
    c.rotate(side * (0.2 + flap));
    oval(c, side * 22, -8, 21, 13, const Color(0xFFD7C8F0));
    oval(c, side * 20, 8, 15, 9, const Color(0xFFBFA8E6));
    circle(c, side * 24, -9, 4.5, const Color(0xFF8E6FD0));
    c.restore();
  }
  // Fuzzy body and the lantern in its belly.
  oval(c, 0, 0, 9, 15, const Color(0xFF8D6E63));
  circle(c, 0, 4, 7, const Color(0x44FFE082));
  circle(c, 0, 4, 4, const Color(0xFFFFE082));
  // Head with feathery antennae.
  circle(c, 0, -17, 7, const Color(0xFF8D6E63));
  strokePath(c, Path()..moveTo(-3, -22)..quadraticBezierTo(-10, -32, -14, -28), 1.6, const Color(0xFF5D4037));
  strokePath(c, Path()..moveTo(3, -22)..quadraticBezierTo(10, -32, 14, -28), 1.6, const Color(0xFF5D4037));
  circle(c, -3, -17, 2.2, const Color(0xFFFFFFFF));
  circle(c, 3, -17, 2.2, const Color(0xFFFFFFFF));
  circle(c, -3, -17, 1, _ink);
  circle(c, 3, -17, 1, _ink);
  c.restore();
}

/// A cat trailing sparkles, mid-bound.
void paintCometCat(Canvas c, ActorState s) {
  final bound = math.sin(s.time * 5).abs() * 5;
  shadow(c, 20);
  c.save();
  c.translate(0, -bound);
  // The sparkle trail, behind.
  for (var i = 0; i < 6; i++) {
    final p = (s.time * 1.2 + i / 6) % 1;
    final a = (1 - p).clamp(0.0, 1.0);
    final x = -16 - p * 40;
    final y = -22 + math.sin(p * 6 + i) * 5;
    circle(c, x, y, 3.4 * (1 - p * 0.6), Color.fromRGBO(255, 241, 118, a));
    circle(c, x + 4, y - 5, 1.6, Color.fromRGBO(255, 255, 255, a));
  }
  // Tail, body, legs.
  strokePath(c, Path()..moveTo(-14, -22)..quadraticBezierTo(-30, -34, -26, -48), 5, const Color(0xFF5C6BC0));
  oval(c, 0, -22, 18, 11, const Color(0xFF7986CB));
  rrect(c, -10, -14, 5, 14, 2, const Color(0xFF5C6BC0));
  rrect(c, 7, -14, 5, 14, 2, const Color(0xFF5C6BC0));
  // Head with ears and a star on the forehead.
  circle(c, 18, -30, 9.5, const Color(0xFF7986CB));
  fillPath(c, poly([11, -36, 13, -48, 19, -38]), const Color(0xFF7986CB));
  fillPath(c, poly([21, -38, 27, -48, 27, -35]), const Color(0xFF7986CB));
  circle(c, 15, -31, 2.2, const Color(0xFFFFEB3B));
  circle(c, 22, -31, 2.2, const Color(0xFFFFEB3B));
  circle(c, 15.6, -31, 1, _ink);
  circle(c, 22.6, -31, 1, _ink);
  circle(c, 18.5, -38, 2, const Color(0xFFFFF59D));
  c.restore();
}

/// A turtle carrying a night sky on its shell.
void paintStarTurtle(Canvas c, ActorState s) {
  final plod = math.sin(s.time * 1.6) * 1.2;
  shadow(c, 30);
  // Legs and tail.
  rrect(c, -22, -10, 10, 10, 3, const Color(0xFF9DAA66));
  rrect(c, 12, -10, 10, 10, 3, const Color(0xFF9DAA66));
  oval(c, -30, -8, 6, 3, const Color(0xFF9DAA66));
  c.save();
  c.translate(0, plod);
  // The shell: a dark dome with stars and a few joined lines.
  oval(c, 0, -24, 28, 20, const Color(0xFF1F2A5C));
  oval(c, 0, -28, 22, 13, const Color(0xFF2E3C7E));
  const stars = [Offset(-14, -28), Offset(-4, -36), Offset(8, -30), Offset(16, -24), Offset(0, -22)];
  for (var i = 0; i < stars.length - 1; i++) {
    line(c, stars[i].dx, stars[i].dy, stars[i + 1].dx, stars[i + 1].dy, 0.9, const Color(0x66FFF59D));
  }
  for (var i = 0; i < stars.length; i++) {
    final tw = 0.6 + 0.4 * math.sin(s.time * 3 + i);
    circle(c, stars[i].dx, stars[i].dy, 2 + tw, Color.fromRGBO(255, 245, 157, tw));
  }
  // The head, patient and kind.
  oval(c, 28, -20, 9, 7, const Color(0xFFB7C27A));
  circle(c, 35, -24, 7, const Color(0xFFB7C27A));
  circle(c, 37.5, -25.5, 1.5, _ink);
  strokePath(c, Path()..moveTo(34, -20)..quadraticBezierTo(37, -18, 40, -20), 1.2, const Color(0xFF7C8A4A));
  c.restore();
}

/// A comet with a crown and a long tail, very sure of itself.
void paintCometKing(Canvas c, ActorState s) {
  final hover = -46 + math.sin(s.time * 1.5) * 5 - s.windUp * 8 + s.attack * 10;
  oval(c, 0, 0, 22, 4, const Color(0x24000000));
  c.save();
  c.translate(0, hover);
  // The tail, streaming up and back.
  for (var i = 0; i < 9; i++) {
    final t = i / 8;
    final w = 17 * (1 - t * 0.85);
    circle(c, -t * 46, -t * 34, w, Color.fromRGBO(129, 212, 250, 0.55 * (1 - t)));
  }
  // The head: a glowing orb with a face.
  circle(c, 0, 0, 25, const Color(0x44B3E5FC));
  circle(c, 0, 0, 19, const Color(0xFFE1F5FE));
  circle(c, 0, 0, 14, const Color(0xFFB3E5FC));
  circle(c, -5, -3, 3, const Color(0xFFFFFFFF));
  circle(c, 5, -3, 3, const Color(0xFFFFFFFF));
  circle(c, -4.4, -3, 1.3, _ink);
  circle(c, 5.6, -3, 1.3, _ink);
  strokePath(c, Path()..moveTo(-6, 5)..quadraticBezierTo(0, 9, 6, 5), 1.7, _ink);
  // A crown, slightly crooked.
  fillPath(c, poly([-12, -17, -12, -29, -6, -22, 0, -32, 6, -22, 12, -29, 12, -17]), const Color(0xFFF2C94C));
  rrect(c, -12, -19, 24, 4, 1.5, const Color(0xFFB8860B));
  circle(c, 0, -24, 2, const Color(0xFFE53935));
  c.restore();
}

/// A burst of light in sunglasses, because it cannot be looked at directly.
void paintNova(Canvas c, ActorState s) {
  final pulse = 1 + math.sin(s.time * 3) * 0.06 + s.windUp * 0.14;
  final hover = -44 + math.sin(s.time * 1.8) * 4;
  oval(c, 0, 0, 22, 4, const Color(0x24000000));
  c.save();
  c.translate(0, hover);
  c.rotate(s.time * 0.25);
  c.scale(pulse, pulse);
  // The rays.
  final pts = <double>[];
  for (var i = 0; i < 24; i++) {
    final a = i * math.pi / 12;
    final r = i.isEven ? 34.0 : 19.0;
    pts
      ..add(math.cos(a) * r)
      ..add(math.sin(a) * r);
  }
  fillPath(c, poly(pts), const Color(0xFFFFE082));
  c.restore();
  circle(c, 0, hover, 24 * pulse, const Color(0x55FFF59D));
  circle(c, 0, hover, 17 * pulse, const Color(0xFFFFFDE7));
  // Sunglasses and a pleased smile.
  rrect(c, -13, hover - 7, 11, 7, 2.5, const Color(0xFF263238));
  rrect(c, 2, hover - 7, 11, 7, 2.5, const Color(0xFF263238));
  line(c, -2, hover - 4, 2, hover - 4, 1.6, const Color(0xFF263238));
  strokePath(c, Path()..moveTo(-6, hover + 5)..quadraticBezierTo(0, hover + 10, 6, hover + 5), 1.7, const Color(0xFFB8860B));
}
