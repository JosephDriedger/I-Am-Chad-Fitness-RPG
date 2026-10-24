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
