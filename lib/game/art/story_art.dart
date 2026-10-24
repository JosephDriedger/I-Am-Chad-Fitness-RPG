/// Backdrops and the extra characters for the story scenes, drawn in code like
/// the rest of the game's art. Characters stand with their feet at the origin
/// of their own space, as in painters.dart.
library;

import 'dart:math' as math;
import 'dart:ui';

import '../../domain/story.dart';
import '../look.dart';
import 'enemy_art.dart';
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

/// Wren Halloway, keeper of the Gullhaven light: navy oilskin coat, a yellow
/// sou'wester, and a lantern that never quite goes out.
void paintWren(Canvas c, ActorState s) {
  final bob = math.sin(s.time * 1.7) * 0.8;
  final glow = 0.85 + math.sin(s.time * 5) * 0.1;
  const coat = Color(0xFF1F3A5F);
  const skin = Color(0xFFD9A77A);
  shadow(c, 16);
  c.save();
  c.translate(0, bob);
  // Boots and legs.
  rrect(c, -8, -10, 7, 10, 2, const Color(0xFF3E4A3A));
  rrect(c, 1, -10, 7, 10, 2, const Color(0xFF3E4A3A));
  rrect(c, -6.5, -22, 5, 14, 2, const Color(0xFF37474F));
  rrect(c, 1.5, -22, 5, 14, 2, const Color(0xFF37474F));
  // Long coat, with a seam and two brass buttons.
  rrect(c, -15, -62, 30, 46, 9, coat);
  rrect(c, -1.5, -62, 3, 46, 1, const Color(0xFF152A45));
  circle(c, 5, -50, 1.7, const Color(0xFFE6B83C));
  circle(c, 5, -40, 1.7, const Color(0xFFE6B83C));
  // Arms.
  rrect(c, -20, -58, 7, 26, 3.5, coat);
  rrect(c, 13, -58, 7, 26, 3.5, coat);
  circle(c, -16.5, -31, 4, skin);
  // The lantern, held out at the end of the right arm.
  circle(c, 17, -42, 4, skin);
  line(c, 17, -42, 17, -35, 1.3, const Color(0xFF5D4037));
  circle(c, 17, -28, 15 * glow, const Color(0x33FFD36B));
  rrect(c, 12.5, -36, 9, 12, 2.5, const Color(0xFF5D4037));
  rrect(c, 14, -34.5, 6, 9, 2, const Color(0xFFFFE9A8));
  circle(c, 17, -29.5, 2.8 * glow, const Color(0xFFFFB02E));
  // Head, a short braid and the yellow sou'wester.
  circle(c, 0, -74, 12.5, skin);
  line(c, -9, -70, -13, -58, 3.2, const Color(0xFF6D4326));
  oval(c, 0, -81, 16, 5.5, const Color(0xFFF2C94C));
  rrect(c, -10, -96, 20, 16, 7, const Color(0xFFF2C94C));
  rrect(c, -15, -82, 7, 12, 3, const Color(0xFFE0B23A));
  circle(c, -4.5, -73, 1.5, const Color(0xFF2B1D14));
  circle(c, 4.5, -73, 1.5, const Color(0xFF2B1D14));
  line(c, -3, -67.5, 3, -67.5, 1.2, const Color(0xFF9C4B3A));
  c.restore();
}

/// Sedge, who keeps the slowest ferry in the world: a very old tortoise in a
/// small red cap, facing right.
void paintSedge(Canvas c, ActorState s) {
  final nod = math.sin(s.time * 0.9) * 1.2;
  shadow(c, 26);
  // Legs and tail.
  rrect(c, -20, -9, 9, 9, 3.5, const Color(0xFF9DAA66));
  rrect(c, 10, -9, 9, 9, 3.5, const Color(0xFF9DAA66));
  oval(c, -25, -9, 5, 3, const Color(0xFF9DAA66));
  // Body under the shell.
  oval(c, 0, -10, 24, 7, const Color(0xFFB7C27A));
  // The shell: a dome with its plates.
  oval(c, 0, -23, 25, 17, const Color(0xFF5E7F43));
  oval(c, 0, -26, 20, 12, const Color(0xFF6B8E4E));
  for (final p in const [Offset(-12, -26), Offset(0, -29), Offset(12, -26), Offset(-6, -18), Offset(7, -18)]) {
    oval(c, p.dx, p.dy, 6.5, 4.5, const Color(0xFF7BA05A));
    oval(c, p.dx, p.dy, 6.5, 4.5, const Color(0x22000000));
  }
  // Neck, head, a patient eye, and the cap.
  oval(c, 24, -19 + nod * 0.4, 8, 6, const Color(0xFFB7C27A));
  circle(c, 31, -23 + nod, 7.5, const Color(0xFFB7C27A));
  circle(c, 33.5, -24.5 + nod, 1.5, const Color(0xFF2B1D14));
  line(c, 32, -19.5 + nod, 37, -20 + nod, 1.1, const Color(0xFF7C8A4A));
  rrect(c, 26, -32 + nod, 11, 5, 2, const Color(0xFFB23A3A));
  rrect(c, 31, -33.5 + nod, 8, 2.5, 1, const Color(0xFF8E2B2B));
}

/// Pip, a newcomer to the guild: drawn as a smaller hero with a look of their own.
void paintPip(Canvas c, ActorState s) =>
    paintHero(c, const HeroLook(style: 4, color: 2, skin: 3), s);

/// Fennel, the mountain courier: a teal jacket, a long red scarf that never
/// quite stops moving, a satchel with a letter sticking out, and a bounce in
/// the step even when standing still.
void paintFennel(Canvas c, ActorState s) {
  final bounce = math.sin(s.time * 5).abs() * 2.2;
  final flutter = math.sin(s.time * 3.2) * 4;
  const jacket = Color(0xFF2E8B83);
  const skin = Color(0xFFD9A074);
  shadow(c, 14);
  c.save();
  c.translate(0, -bounce);
  // Legs and boots.
  rrect(c, -7, -22, 5.5, 18, 2, const Color(0xFF4E5D78));
  rrect(c, 1.5, -22, 5.5, 18, 2, const Color(0xFF4E5D78));
  rrect(c, -9, -6, 9, 6, 2, const Color(0xFF3E2723));
  rrect(c, 0, -6, 9, 6, 2, const Color(0xFF3E2723));
  // Jacket, arms, and the satchel on its strap.
  rrect(c, -13, -60, 26, 40, 8, jacket);
  rrect(c, -18, -56, 6, 22, 3, jacket);
  rrect(c, 12, -56, 6, 22, 3, jacket);
  circle(c, -15, -32, 3.8, skin);
  circle(c, 15, -32, 3.8, skin);
  line(c, -11, -58, 10, -28, 3.2, const Color(0xFF6D4326));
  rrect(c, 6, -36, 15, 12, 3, const Color(0xFF8D5E3C));
  rrect(c, 6, -36, 15, 4, 2, const Color(0xFF6D4326));
  rrect(c, 9, -41, 9, 7, 1, const Color(0xFFFFF3D6));
  // The scarf, with its tail in the wind.
  rrect(c, -11, -66, 22, 8, 4, const Color(0xFFC62828));
  strokePath(c, Path()..moveTo(-8, -62)..quadraticBezierTo(-20, -58 + flutter, -30, -64 + flutter * 1.4), 5, const Color(0xFFC62828));
  // Head, short dark hair and a cap with a feather.
  circle(c, 0, -75, 12.5, skin);
  oval(c, 0, -82, 13, 7, const Color(0xFF2B1D14));
  rrect(c, -14, -86, 28, 7, 3.5, jacket);
  rrect(c, 4, -81, 13, 3.5, 1.7, shade(jacket, -0.12));
  strokePath(c, Path()..moveTo(-9, -86)..quadraticBezierTo(-12, -98, -4, -100), 2.2, const Color(0xFFF2C94C));
  circle(c, -4.5, -74, 1.5, const Color(0xFF2B1D14));
  circle(c, 4.5, -74, 1.5, const Color(0xFF2B1D14));
  strokePath(c, Path()..moveTo(-4, -68)..quadraticBezierTo(0, -64.5, 4, -68), 1.4, const Color(0xFF9C4B3A));
  c.restore();
}

/// Hush, who keeps the hut at the snow line: a big, soft yeti in a knitted
/// scarf, holding a steaming mug.
void paintHush(Canvas c, ActorState s) {
  paintYeti(c, s, fur: const Color(0xFFEFE6D8));
  final breathe = math.sin(s.time * 1.8) * 1.4;
  c.save();
  c.translate(0, breathe);
  // The scarf at the neck, striped.
  rrect(c, -15, -56, 30, 8, 4, const Color(0xFFB23A3A));
  for (var i = 0; i < 4; i++) {
    rrect(c, -12 + i * 7.5, -56, 3.2, 8, 1.5, const Color(0xFFF2C94C));
  }
  // The mug, held in the right hand, with a thread of steam.
  rrect(c, 29, -34, 11, 12, 2.5, const Color(0xFFFFF3D6));
  rrect(c, 37, -31, 5, 6, 2.5, const Color(0xFFFFF3D6));
  rrect(c, 31, -32, 7, 3, 1.5, const Color(0xFF6D4326));
  final sway = math.sin(s.time * 2.2) * 2;
  strokePath(c, Path()..moveTo(33, -38)..quadraticBezierTo(30 + sway, -46, 34, -52), 1.4, const Color(0x88FFFFFF));
  strokePath(c, Path()..moveTo(37, -38)..quadraticBezierTo(41 - sway, -45, 37, -51), 1.4, const Color(0x66FFFFFF));
  c.restore();
}

/// Tamsin Vale, the Weatherkeeper of Thunder Heights: a long storm-blue coat,
/// round brass goggles pushed up into silver hair, and a walking staff.
void paintTamsin(Canvas c, ActorState s) {
  final bob = math.sin(s.time * 1.5) * 0.7;
  const coat = Color(0xFF4F6285);
  const skin = Color(0xFFC98F67);
  shadow(c, 16);
  c.save();
  c.translate(0, bob);
  // The staff.
  line(c, 19, -4, 20, -86, 3.2, const Color(0xFF6D4326));
  circle(c, 20, -88, 4, const Color(0xFFB87D2E));
  // Boots and the long coat.
  rrect(c, -9, -6, 8, 6, 2, const Color(0xFF3E2723));
  rrect(c, 1, -6, 8, 6, 2, const Color(0xFF3E2723));
  rrect(c, -15, -62, 30, 56, 9, coat);
  rrect(c, -1.5, -62, 3, 56, 1, shade(coat, -0.1));
  for (final y in const [-52.0, -42.0, -32.0]) {
    circle(c, 6, y, 1.7, const Color(0xFFE6B83C));
  }
  // Arms, the near hand on the staff, a mustard scarf, and a thermos.
  rrect(c, -20, -58, 7, 26, 3.5, coat);
  rrect(c, 13, -58, 7, 26, 3.5, coat);
  circle(c, -16.5, -31, 4, skin);
  circle(c, 19, -40, 4, skin);
  rrect(c, -24, -38, 7, 14, 3, const Color(0xFF90A4AE));
  rrect(c, -24, -41, 7, 4, 2, const Color(0xFFB23A3A));
  rrect(c, -13, -66, 26, 7, 3.5, const Color(0xFFD9A441));
  // Head, silver hair in a braid, and the goggles up on the forehead.
  circle(c, 0, -76, 12.5, skin);
  oval(c, 0, -82, 13.5, 8, const Color(0xFFC9D0D8));
  line(c, -10, -76, -13, -58, 3.4, const Color(0xFFC9D0D8));
  rrect(c, -13, -88, 26, 4, 2, const Color(0xFF6D4326));
  circle(c, -6, -86, 5, const Color(0xFFB87D2E));
  circle(c, 6, -86, 5, const Color(0xFFB87D2E));
  circle(c, -6, -86, 3.2, const Color(0xCCCFE6F5));
  circle(c, 6, -86, 3.2, const Color(0xCCCFE6F5));
  circle(c, -4.5, -75, 1.5, const Color(0xFF2B1D14));
  circle(c, 4.5, -75, 1.5, const Color(0xFF2B1D14));
  strokePath(c, Path()..moveTo(-4, -69)..quadraticBezierTo(0, -66, 4, -69), 1.4, const Color(0xFF9C4B3A));
  c.restore();
}

/// Skarn, a very small wizard with a very large storm: a pointed hat that
/// droops, a robe of stars, and his own little thundercloud following him.
void paintSkarn(Canvas c, ActorState s) {
  final bob = math.sin(s.time * 2.1).abs() * 1.2;
  final flash = (math.sin(s.time * 2.3) + math.sin(s.time * 3.9)) > 1.55;
  shadow(c, 12);
  c.save();
  c.translate(0, -bob);
  const robe = Color(0xFF3F3F8F);
  // Boots, and the robe with a few stars on it.
  rrect(c, -8, -5, 7, 5, 2, const Color(0xFF2B1D14));
  rrect(c, 1, -5, 7, 5, 2, const Color(0xFF2B1D14));
  c.drawPath(
    Path()
      ..moveTo(-9, -36)
      ..quadraticBezierTo(-15, -8, -13, -4)
      ..lineTo(13, -4)
      ..quadraticBezierTo(15, -8, 9, -36)
      ..close(),
    Paint()..color = robe,
  );
  for (final p in const [Offset(-5, -18), Offset(4, -26), Offset(6, -12), Offset(-3, -30)]) {
    circle(c, p.dx, p.dy, 1.4, const Color(0xFFFFE082));
  }
  rrect(c, -14, -32, 5, 14, 2.5, robe);
  rrect(c, 9, -32, 5, 14, 2.5, robe);
  circle(c, -11.5, -17, 3, const Color(0xFFE8B98E));
  circle(c, 11.5, -17, 3, const Color(0xFFE8B98E));
  // Head, a grey beard, and the drooping hat.
  circle(c, 0, -43, 8.5, const Color(0xFFE8B98E));
  c.drawPath(
    Path()
      ..moveTo(-7, -40)
      ..quadraticBezierTo(0, -22, 7, -40)
      ..quadraticBezierTo(0, -35, -7, -40)
      ..close(),
    Paint()..color = const Color(0xFFD7DCE2),
  );
  circle(c, -3, -44, 1.2, const Color(0xFF2B1D14));
  circle(c, 3, -44, 1.2, const Color(0xFF2B1D14));
  oval(c, 0, -49, 12, 3, robe);
  c.drawPath(
    Path()
      ..moveTo(-7, -50)
      ..quadraticBezierTo(0, -68, 9, -62)
      ..quadraticBezierTo(2, -60, 7, -50)
      ..close(),
    Paint()..color = robe,
  );
  // His own small storm, hanging just over the hat.
  final cx = 2 + math.sin(s.time * 1.1) * 3;
  _cloud(c, cx, -72, 15, flash ? const Color(0xFF8D93B8) : const Color(0xFF4E5273));
  if (flash) {
    fillPath(c, poly([cx - 2, -68, cx + 4, -68, cx, -61, cx + 5, -61, cx - 3, -50, cx - 1, -58, cx - 5, -58]), const Color(0xFFFFEE58));
  } else {
    for (var i = 0; i < 3; i++) {
      final fall = (s.time * 18 + i * 9) % 18;
      line(c, cx - 7 + i * 7, -66 + fall, cx - 8 + i * 7, -62 + fall, 1.2, const Color(0x889FC3E8));
    }
  }
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
    case StorySpeaker.pip:
      paintPip(c, s);
    case StorySpeaker.wren:
      paintWren(c, s);
    case StorySpeaker.sedge:
      paintSedge(c, s);
    case StorySpeaker.fennel:
      paintFennel(c, s);
    case StorySpeaker.hush:
      paintHush(c, s);
    case StorySpeaker.tamsin:
      paintTamsin(c, s);
    case StorySpeaker.skarn:
      paintSkarn(c, s);
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
      StorySpeaker.pip => 0.82,
      StorySpeaker.wren => 1.0,
      StorySpeaker.sedge => 1.2,
      StorySpeaker.fennel => 1.0,
      StorySpeaker.hush => 0.95,
      StorySpeaker.tamsin => 1.0,
      StorySpeaker.skarn => 1.35,
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

/// A band of sea from [top] down to [bottom], with soft moving ripples.
void _sea(Canvas c, Size s, double top, double bottom, List<Color> colors, double time, {Color ripple = const Color(0x33FFFFFF)}) {
  _gradient(c, Rect.fromLTRB(0, top, s.width, bottom), colors);
  for (var i = 0; i < 9; i++) {
    final y = top + (bottom - top) * (0.1 + i * 0.1);
    final x = (s.width * (i * 0.23 + time * 0.012)) % (s.width + 60) - 30;
    line(c, x, y, x + 26 + i * 3, y, 1.6, ripple);
  }
}

void _gull(Canvas c, double x, double y, double size, double time) {
  final flap = math.sin(time * 4 + x) * size * 0.25;
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFF7F7F2);
  c.drawPath(
    Path()
      ..moveTo(x - size, y + flap)
      ..quadraticBezierTo(x - size * 0.4, y - size * 0.3, x, y)
      ..quadraticBezierTo(x + size * 0.4, y - size * 0.3, x + size, y + flap),
    p,
  );
}

void _boat(Canvas c, double x, double y, double size, double time, Color sail) {
  c.save();
  c.translate(x, y + math.sin(time * 1.3 + x) * 1.6);
  c.rotate(math.sin(time * 1.1 + x) * 0.03);
  c.drawPath(
    Path()
      ..moveTo(-size, 0)
      ..lineTo(size, 0)
      ..lineTo(size * 0.7, size * 0.42)
      ..lineTo(-size * 0.7, size * 0.42)
      ..close(),
    Paint()..color = const Color(0xFF5D4037),
  );
  line(c, 0, 0, 0, -size * 1.6, 2, const Color(0xFF4E342E));
  c.drawPath(
    Path()
      ..moveTo(1.5, -size * 1.5)
      ..lineTo(size * 0.95, -size * 0.15)
      ..lineTo(1.5, -size * 0.15)
      ..close(),
    Paint()..color = sail,
  );
  c.restore();
}

/// The Gullhaven lighthouse: a white tower with red bands, a gallery and a lamp
/// room. [lit] turns the lamp on and sweeps a beam across the sky.
void _lighthouse(Canvas c, double cx, double baseY, double height, double time, {required bool lit}) {
  final half = height * 0.1;
  final tower = Path()
    ..moveTo(cx - half, baseY)
    ..lineTo(cx + half, baseY)
    ..lineTo(cx + half * 0.62, baseY - height)
    ..lineTo(cx - half * 0.62, baseY - height)
    ..close();
  c.drawPath(tower, Paint()..color = const Color(0xFFF1EEE4));
  c.save();
  c.clipPath(tower);
  for (var i = 0; i < 4; i++) {
    if (i.isOdd) continue;
    _fill(c, Rect.fromLTWH(cx - half * 2, baseY - height * (0.28 + i * 0.22), half * 4, height * 0.12), const Color(0xFFB23A3A));
  }
  c.restore();
  rrect(c, cx - half * 0.3, baseY - height * 0.18, half * 0.6, height * 0.12, half * 0.2, const Color(0xFF5D4037));
  // The gallery and the lamp room.
  final top = baseY - height;
  rrect(c, cx - half * 1.05, top - 4, half * 2.1, 6, 2, const Color(0xFF4E342E));
  final lampRoom = Rect.fromLTWH(cx - half * 0.55, top - height * 0.2, half * 1.1, height * 0.2 - 4);
  c.drawRRect(
    RRect.fromRectAndRadius(lampRoom, Radius.circular(half * 0.2)),
    Paint()..color = lit ? const Color(0xFFFFE9A8) : const Color(0xFF3B4658),
  );
  if (!lit) {
    // A crack across the glass.
    line(c, lampRoom.left + 2, lampRoom.top + lampRoom.height * 0.2, lampRoom.right - 2, lampRoom.bottom - 2, 1.2, const Color(0xFF8FA0B8));
  }
  c.drawPath(
    Path()
      ..moveTo(cx - half * 0.8, top - height * 0.2)
      ..lineTo(cx, top - height * 0.32)
      ..lineTo(cx + half * 0.8, top - height * 0.2)
      ..close(),
    Paint()..color = const Color(0xFFB23A3A),
  );
  if (lit) {
    final lamp = Offset(cx, top - height * 0.1);
    circle(c, lamp.dx, lamp.dy, height * 0.2, const Color(0x33FFE9A8));
    circle(c, lamp.dx, lamp.dy, height * 0.09, const Color(0x66FFE9A8));
    // A slow beam, swinging a little to either side of the sea.
    final swing = math.sin(time * 0.5) * 0.18;
    for (final dir in const [1.0, -1.0]) {
      final reach = height * 5.5;
      final a = (dir > 0 ? 0.0 : math.pi) + swing * dir;
      c.drawPath(
        Path()
          ..moveTo(lamp.dx, lamp.dy)
          ..lineTo(lamp.dx + math.cos(a - 0.07) * reach, lamp.dy + math.sin(a - 0.07) * reach)
          ..lineTo(lamp.dx + math.cos(a + 0.07) * reach, lamp.dy + math.sin(a + 0.07) * reach)
          ..close(),
        Paint()..color = const Color(0x22FFF3C4),
      );
    }
  }
}

/// A mountain: a triangle from [baseY] up to [h], with a ragged snow cap.
void _peak(Canvas c, double cx, double baseY, double w, double h, Color rock, Color snow) {
  fillPath(c, poly([cx - w / 2, baseY, cx, baseY - h, cx + w / 2, baseY]), rock);
  final capY = baseY - h * 0.68;
  final half = w / 2 * (1 - 0.68);
  fillPath(
    c,
    poly([
      cx - half, capY,
      cx - half * 0.45, capY + h * 0.06,
      cx - half * 0.1, capY - h * 0.01,
      cx + half * 0.35, capY + h * 0.07,
      cx + half, capY,
      cx, baseY - h,
    ]),
    snow,
  );
}

/// A snowy pine: stacked boughs on a short trunk.
void _pine(Canvas c, double x, double groundY, double h, Color bough, Color snow) {
  rrect(c, x - h * 0.05, groundY - h * 0.2, h * 0.1, h * 0.2, 1, const Color(0xFF4E342E));
  for (var i = 0; i < 3; i++) {
    final w = h * (0.34 - i * 0.07);
    final y = groundY - h * (0.16 + i * 0.27);
    fillPath(c, poly([x - w, y, x, y - h * 0.4, x + w, y]), bough);
    fillPath(c, poly([x - w * 0.55, y - h * 0.14, x, y - h * 0.4, x + w * 0.55, y - h * 0.14]), snow);
  }
}

/// The Weather Chime: an iron arch hung with seven bells of falling size. With
/// [sway] at 0 they hang still, as they have for two winters.
void _chimeRing(Canvas c, double cx, double topY, double span, double time, {double sway = 0}) {
  final arch = Rect.fromCenter(center: Offset(cx, topY + span * 0.5), width: span * 2, height: span);
  c.drawArc(
    arch,
    math.pi,
    math.pi,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0xFF455A64),
  );
  line(c, cx - span, topY + span * 0.5, cx - span, topY + span * 1.7, 5, const Color(0xFF455A64));
  line(c, cx + span, topY + span * 0.5, cx + span, topY + span * 1.7, 5, const Color(0xFF455A64));
  for (var i = 0; i < 7; i++) {
    final a = math.pi + math.pi * (i + 0.5) / 7;
    final x = cx + math.cos(a) * span;
    final y = topY + span * 0.5 + math.sin(a) * span * 0.5;
    final r = span * (0.1 + 0.025 * (3 - (i - 3).abs()));
    _bell(c, x, y, r, sway: sway == 0 ? math.sin(time * 0.7 + i) * 0.015 : math.sin(time * 2.4 + i * 0.9) * sway);
  }
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
    case StoryBackdrop.coastRoad:
      // A bright afternoon on the cliff road, the sea beyond and a far light.
      _gradient(c, full, const [Color(0xFF8EC8EE), Color(0xFFEAF5FA)]);
      _cloud(c, w * 0.3, h * 0.16, w * 0.12, const Color(0xE6FFFFFF));
      _cloud(c, w * 0.7, h * 0.24, w * 0.09, const Color(0xCCFFFFFF));
      _sea(c, s, h * 0.42, h * 0.62, const [Color(0xFF6DB3D6), Color(0xFF3F8DB8)], time);
      _gull(c, w * 0.22 + math.sin(time * 0.4) * 8, h * 0.3, 8, time);
      _gull(c, w * 0.34 + math.sin(time * 0.35 + 1) * 8, h * 0.36, 6, time);
      _hill(c, s, h * 0.62, h * 0.03, 0.8, const Color(0xFF8DBB6A));
      _lighthouse(c, w * 0.8, h * 0.62, h * 0.2, time, lit: false);
      // A small, stubborn glow in the lamp room: the lantern in the west.
      circle(c, w * 0.8, h * 0.62 - h * 0.22, 3 + math.sin(time * 3) * 0.6, const Color(0xFFFFC857));
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFF6FA55A));
      c.drawPath(
        Path()
          ..moveTo(w * 0.4, h * 0.68)
          ..lineTo(w * 0.6, h * 0.68)
          ..lineTo(w * 1.1, h)
          ..lineTo(-w * 0.1, h)
          ..close(),
        Paint()..color = const Color(0xFFDCC9A0),
      );
    case StoryBackdrop.estuary:
      // A wide, calm river mouth in low gold light, with reeds and a jetty.
      _gradient(c, full, const [Color(0xFFF4C791), Color(0xFFFBE9CC), Color(0xFFDCEBF0)]);
      circle(c, w * 0.3, h * 0.38, w * 0.07, const Color(0xCCFFF3D0));
      _hill(c, s, h * 0.5, h * 0.025, 1.4, const Color(0xFF9DB78A));
      _sea(c, s, h * 0.52, ground, const [Color(0xFFB7D4E0), Color(0xFF7FA9BE)], time, ripple: const Color(0x55FFF3D0));
      for (var i = 0; i < 10; i++) {
        final x = (i < 5 ? w * 0.01 + i * 7.0 : w * 0.9 + (i - 5) * 9.0);
        final sway = math.sin(time * 1.1 + i) * 3;
        line(c, x, ground, x + sway, h * 0.62 - (i % 3) * 8, 2.2, const Color(0xFF7A8F4C));
        oval(c, x + sway, h * 0.62 - (i % 3) * 8, 2.4, 6, const Color(0xFF8B5E3C));
      }
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFF8D6E4A));
      for (var x = 0.0; x < w; x += 34) {
        line(c, x, ground, x, h, 1.4, const Color(0x33000000));
      }
    case StoryBackdrop.harbour:
      // Evening in the harbour, boats at rest and a fog bank rolling in.
      _gradient(c, full, const [Color(0xFF7C8FA6), Color(0xFFD4C9BB)]);
      _sea(c, s, h * 0.46, ground, const [Color(0xFF6C8499), Color(0xFF46627A)], time);
      _boat(c, w * 0.18, h * 0.58, w * 0.05, time, const Color(0xFFF1E3C6));
      _boat(c, w * 0.42, h * 0.5, w * 0.04, time, const Color(0xFFD9A441));
      _boat(c, w * 0.64, h * 0.6, w * 0.055, time, const Color(0xFFE8E2D6));
      _gull(c, w * 0.5 + math.sin(time * 0.5) * 10, h * 0.2, 7, time);
      // Lamp posts along the quay.
      for (final x in [w * 0.12, w * 0.5, w * 0.88]) {
        line(c, x, ground, x, h * 0.62, 3, const Color(0xFF3E2F26));
        circle(c, x, h * 0.62, 12 + math.sin(time * 4 + x) * 1, const Color(0x33FFC46B));
        circle(c, x, h * 0.62, 4.5, const Color(0xFFFFD36B));
      }
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFF6B5339));
      for (var x = 0.0; x < w; x += 40) {
        line(c, x, ground, x, h, 1.4, const Color(0x33000000));
      }
      for (var i = 0; i < 4; i++) {
        final y = h * (0.5 + i * 0.1) + math.sin(time * 0.5 + i) * 4;
        oval(c, w * (0.15 + i * 0.25) + math.sin(time * 0.3 + i) * 14, y, w * 0.34, h * 0.04, const Color(0x55EEF0F2));
      }
    case StoryBackdrop.tidePools:
      // Low tide on a sunny beach: rocks, bright pools, and sand underfoot.
      _gradient(c, full, const [Color(0xFF86C5EC), Color(0xFFE6F3F8)]);
      _sea(c, s, h * 0.4, h * 0.56, const [Color(0xFF62AFD3), Color(0xFF3D8FBA)], time);
      _cloud(c, w * 0.72, h * 0.18, w * 0.1, const Color(0xE6FFFFFF));
      _fill(c, Rect.fromLTWH(0, h * 0.56, w, h - h * 0.56), const Color(0xFFE6D3A8));
      for (final r in [(0.1, 0.62, 0.12, 0.07), (0.85, 0.6, 0.14, 0.08), (0.55, 0.58, 0.07, 0.04)]) {
        oval(c, w * r.$1, h * r.$2, w * r.$3, h * r.$4, const Color(0xFF6D6A66));
        oval(c, w * r.$1 - 4, h * r.$2 - 4, w * r.$3 * 0.8, h * r.$4 * 0.6, const Color(0xFF85817C));
      }
      for (final p in [(0.3, 0.7, 0.1), (0.62, 0.78, 0.13), (0.8, 0.72, 0.08)]) {
        oval(c, w * p.$1, h * p.$2, w * p.$3, h * 0.03, const Color(0xFF8FD0E0));
        oval(c, w * p.$1 - 6, h * p.$2 - 2, w * p.$3 * 0.5, h * 0.01, const Color(0x66FFFFFF));
        final tw = 0.5 + 0.5 * math.sin(time * 3 + p.$1 * 9);
        circle(c, w * p.$1 + 8, h * p.$2 - 1, 1.8, Color.fromRGBO(255, 255, 255, tw));
      }
      // A starfish and a shell.
      circle(c, w * 0.46, h * 0.82, 4.5, const Color(0xFFE2703A));
      for (var i = 0; i < 5; i++) {
        final a = i * math.pi * 2 / 5 - math.pi / 2;
        line(c, w * 0.46, h * 0.82, w * 0.46 + math.cos(a) * 9, h * 0.82 + math.sin(a) * 9, 3.4, const Color(0xFFE2703A));
      }
      oval(c, w * 0.22, h * 0.86, 7, 5, const Color(0xFFF2E1C7));
    case StoryBackdrop.lighthouse:
      // Dusk on the headland, the great lamp dark and its glass cracked.
      _gradient(c, full, const [Color(0xFF3B4A7A), Color(0xFFE59A68)]);
      _stars(c, s, time, count: 20);
      _sea(c, s, h * 0.6, ground, const [Color(0xFF3A4E73), Color(0xFF223250)], time, ripple: const Color(0x33F2B07A));
      _fill(c, Rect.fromLTWH(0, ground - h * 0.06, w, h), const Color(0xFF4A4036));
      _lighthouse(c, w * 0.12, ground - h * 0.06, h * 0.62, time, lit: false);
      // The small emergency lantern, glowing by the door.
      circle(c, w * 0.2, ground - h * 0.1, 7 + math.sin(time * 4) * 0.8, const Color(0x33FFC857));
      circle(c, w * 0.2, ground - h * 0.1, 3, const Color(0xFFFFC857));
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFF3F4F33));
    case StoryBackdrop.lighthouseNight:
      // The same headland at night, the great lamp lit and sweeping the sea.
      _gradient(c, full, const [Color(0xFF0E1330), Color(0xFF2A3B6E)]);
      _stars(c, s, time, count: 55);
      circle(c, w * 0.84, h * 0.14, w * 0.05, const Color(0xFFF7F0D5));
      _sea(c, s, h * 0.6, ground, const [Color(0xFF1B2A52), Color(0xFF111B38)], time, ripple: const Color(0x44F7F0D5));
      _fill(c, Rect.fromLTWH(0, ground - h * 0.06, w, h), const Color(0xFF2E2A28));
      _lighthouse(c, w * 0.12, ground - h * 0.06, h * 0.62, time, lit: true);
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFF26331F));
      // Far out, a little fleet coming home by the light.
      for (var i = 0; i < 3; i++) {
        _boat(c, w * (0.6 + i * 0.12), h * (0.66 + (i % 2) * 0.04), w * 0.025, time, const Color(0xFFE8E2D6));
      }
    case StoryBackdrop.snowRoad:
      // A bright, cold morning on the pass: far peaks, pines and a trodden road.
      _gradient(c, full, const [Color(0xFF8CC3EA), Color(0xFFEAF4FB)]);
      _cloud(c, w * 0.3, h * 0.15, w * 0.1, const Color(0xE6FFFFFF));
      _cloud(c, w * 0.8, h * 0.24, w * 0.08, const Color(0xCCFFFFFF));
      _peak(c, w * 0.18, h * 0.62, w * 0.5, h * 0.42, const Color(0xFF8C9DB5), const Color(0xFFF7FBFF));
      _peak(c, w * 0.62, h * 0.62, w * 0.62, h * 0.52, const Color(0xFF7A8BA6), const Color(0xFFF7FBFF));
      _peak(c, w * 0.95, h * 0.62, w * 0.4, h * 0.32, const Color(0xFF8C9DB5), const Color(0xFFF7FBFF));
      _hill(c, s, h * 0.66, h * 0.025, 0.7, const Color(0xFFDCE8F2));
      for (final p in const [(0.06, 0.72, 0.3), (0.2, 0.69, 0.22), (0.86, 0.7, 0.26), (0.96, 0.74, 0.34)]) {
        _pine(c, w * p.$1, h * p.$2, h * p.$3, const Color(0xFF2F5F4A), const Color(0xFFF7FBFF));
      }
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFFF2F7FB));
      c.drawPath(
        Path()
          ..moveTo(w * 0.44, h * 0.68)
          ..lineTo(w * 0.56, h * 0.68)
          ..lineTo(w * 1.05, h)
          ..lineTo(-w * 0.05, h)
          ..close(),
        Paint()..color = const Color(0xFFD3C8B4),
      );
      for (var i = 0; i < 3; i++) {
        // Drifting snow.
        final x = (w * (i * 0.37 + time * 0.015)) % w;
        oval(c, x, h * (0.78 + i * 0.05), w * 0.07, h * 0.012, const Color(0x66FFFFFF));
      }
    case StoryBackdrop.passHut:
      // Inside the hut at the snow line: planks, a glowing stove and a snowy window.
      _fill(c, full, const Color(0xFF7A5230));
      for (var x = 0.0; x < w; x += 34) {
        line(c, x, 0, x, ground, 1.2, const Color(0x22000000));
      }
      for (var y = 0.0; y < ground; y += 52) {
        line(c, 0, y, w, y, 1, const Color(0x14000000));
      }
      _window(c, w * 0.62, h * 0.14, w * 0.2, h * 0.34, const Color(0xFFCFE6F5));
      for (var i = 0; i < 14; i++) {
        final fall = (time * 14 + i * 23) % (h * 0.34);
        circle(c, w * 0.63 + (i * 17.0) % (w * 0.18), h * 0.14 + fall, 1.3, const Color(0xFFFFFFFF));
      }
      // A shelf of mugs.
      rrect(c, w * 0.08, h * 0.3, w * 0.34, 6, 2, const Color(0xFF4E342E));
      for (var i = 0; i < 5; i++) {
        rrect(c, w * (0.1 + i * 0.065), h * 0.3 - 16, 14, 16, 3, i.isEven ? const Color(0xFFFFF3D6) : const Color(0xFFE6B83C));
      }
      // The stove, with its door glowing.
      final glow = 1 + math.sin(time * 7) * 0.08;
      rrect(c, w * 0.08, h * 0.5, w * 0.2, h * 0.4, 8, const Color(0xFF37474F));
      rrect(c, w * 0.12, h * 0.6, w * 0.12, h * 0.14, 5, const Color(0xFFFF8F3A));
      circle(c, w * 0.18, h * 0.67, w * 0.1 * glow, const Color(0x33FFB347));
      line(c, w * 0.18, h * 0.5, w * 0.18, h * 0.12, 9, const Color(0xFF37474F));
      // A banner for the hut's one rule.
      rrect(c, w * 0.4, 0, w * 0.1, h * 0.28, 4, const Color(0xFFFFF3D6));
      circle(c, w * 0.45, h * 0.11, w * 0.03, const Color(0xFFB23A3A));
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFF4E342E));
      oval(c, w * 0.5, ground + 4, w * 0.34, h * 0.03, const Color(0xFF8E2B3B));
    case StoryBackdrop.iceCave:
      // A cave of blue ice, with a bright mouth and a voice that comes back.
      _gradient(c, full, const [Color(0xFF16345A), Color(0xFF4F86AE)]);
      oval(c, w * 0.5, h * 0.55, w * 0.34, h * 0.4, const Color(0xFF86BCDA));
      oval(c, w * 0.5, h * 0.58, w * 0.22, h * 0.28, const Color(0xFFD8EEF8));
      for (var i = 0; i < 13; i++) {
        final x = w * (i + 0.5) / 13;
        final len = h * (0.1 + 0.08 * ((i * 7) % 5) / 4);
        fillPath(c, poly([x - w * 0.025, 0, x, len, x + w * 0.025, 0]), const Color(0xFFBFE3F5));
      }
      for (final p in const [(0.08, 0.86, 0.1), (0.2, 0.9, 0.07), (0.82, 0.88, 0.09), (0.94, 0.84, 0.12)]) {
        final tw = 0.6 + 0.4 * math.sin(time * 2 + p.$1 * 20);
        fillPath(
          c,
          poly([w * p.$1 - w * 0.025, h * p.$2, w * p.$1, h * (p.$2 - p.$3), w * p.$1 + w * 0.025, h * p.$2]),
          Color.fromRGBO(154, 230, 255, tw),
        );
      }
      // Rings, a voice travelling out and fading.
      for (var k = 0; k < 3; k++) {
        final t = ((time * 0.45) + k / 3) % 1.0;
        c.drawCircle(
          Offset(w * 0.3, h * 0.42),
          t * w * 0.34,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Color.fromRGBO(255, 255, 255, (1 - t) * 0.5),
        );
      }
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFF9FC8E0));
      line(c, w * 0.1, ground + 8, w * 0.4, ground + 8, 1.6, const Color(0x55FFFFFF));
      line(c, w * 0.55, ground + 14, w * 0.9, ground + 14, 1.6, const Color(0x55FFFFFF));
    case StoryBackdrop.observatory:
      // Late light at the foot of the Weatherkeeper's tower and its long stair.
      _gradient(c, full, const [Color(0xFF6C7A99), Color(0xFFDCD0C2)]);
      _peak(c, w * 0.85, h * 0.7, w * 0.6, h * 0.5, const Color(0xFF8493AB), const Color(0xFFF1F5FA));
      _peak(c, w * 0.55, h * 0.7, w * 0.4, h * 0.34, const Color(0xFF93A1B8), const Color(0xFFF1F5FA));
      // The tower, with a lit slit-window at each landing and a dome on top.
      final tx = w * 0.26, tw = w * 0.2;
      rrect(c, tx - tw / 2, h * 0.14, tw, ground - h * 0.14, 4, const Color(0xFF7D8696));
      for (var y = h * 0.16; y < ground; y += 22) {
        line(c, tx - tw / 2, y, tx + tw / 2, y, 1, const Color(0x22000000));
      }
      oval(c, tx, h * 0.14, tw * 0.62, h * 0.07, const Color(0xFF55627A));
      for (var i = 0; i < 4; i++) {
        rrect(c, tx - 3, h * (0.3 + i * 0.15), 6, 16, 2, const Color(0xFFFFD36B));
      }
      // The stair, zigzagging up the tower.
      final stair = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF9A9FA8);
      final path = Path()..moveTo(w * 0.52, ground);
      for (var i = 0; i < 6; i++) {
        path.lineTo(i.isEven ? tx + tw * 0.4 : w * 0.52, ground - (i + 1) * (ground - h * 0.2) / 6);
      }
      c.drawPath(path, stair);
      for (var i = 0; i < 18; i++) {
        final fall = (time * 12 + i * 31) % h;
        circle(c, (i * 53.0) % w, fall, 1.4, const Color(0xCCFFFFFF));
      }
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFFE9EFF5));
    case StoryBackdrop.stormTop:
      // The top of the heights in a storm, with the Weather Chime hanging silent.
      _gradient(c, full, const [Color(0xFF1B1836), Color(0xFF4B3F73)]);
      for (final p in const [(0.2, 0.12, 0.18), (0.55, 0.2, 0.22), (0.85, 0.1, 0.16), (0.4, 0.34, 0.14)]) {
        _cloud(c, w * p.$1, h * p.$2, w * p.$3, const Color(0xCC2A2547));
      }
      final flash = (math.sin(time * 2.1) + math.sin(time * 3.7)) > 1.6;
      if (flash) {
        _fill(c, full, const Color(0x22FFF59D));
        fillPath(c, poly([w * 0.78, h * 0.2, w * 0.82, h * 0.2, w * 0.79, h * 0.4, w * 0.84, h * 0.4, w * 0.74, h * 0.66, w * 0.77, h * 0.46, w * 0.73, h * 0.46]), const Color(0xFFFFF59D));
      }
      _chimeRing(c, w * 0.5, h * 0.2, w * 0.2, time);
      for (var i = 0; i < 40; i++) {
        final x = (i * 41.0 + time * 40) % (w + 40) - 20;
        final y = (i * 67.0 + time * 220) % h;
        line(c, x, y, x - 4, y + 11, 1.1, const Color(0x669FC3E8));
      }
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFF3A3550));
      oval(c, w * 0.5, ground + 2, w * 0.3, h * 0.025, const Color(0xFF4A4568));
    case StoryBackdrop.highCamp:
      // Night above the clouds: a sea of cloud, a green aurora and a small fire.
      _gradient(c, full, const [Color(0xFF0B1030), Color(0xFF2D3B6B)]);
      _stars(c, s, time, count: 60);
      for (var band = 0; band < 2; band++) {
        final p = Path()..moveTo(0, h * (0.2 + band * 0.08));
        for (var x = 0.0; x <= w; x += 8) {
          p.lineTo(x, h * (0.2 + band * 0.08) + math.sin(x / w * 6 + time * 0.4 + band) * h * 0.04);
        }
        for (var x = w; x >= 0; x -= 8) {
          p.lineTo(x, h * (0.3 + band * 0.08) + math.sin(x / w * 5 + time * 0.3 + band) * h * 0.05);
        }
        p.close();
        c.drawPath(p, Paint()..color = band == 0 ? const Color(0x3369F0AE) : const Color(0x2640C4FF));
      }
      circle(c, w * 0.18, h * 0.16, w * 0.045, const Color(0xFFF7F0D5));
      _peak(c, w * 0.1, h * 0.72, w * 0.3, h * 0.26, const Color(0xFF3C4A6B), const Color(0xFFC9D6EC));
      _peak(c, w * 0.92, h * 0.72, w * 0.34, h * 0.3, const Color(0xFF3C4A6B), const Color(0xFFC9D6EC));
      for (var i = 0; i < 6; i++) {
        oval(c, w * (0.08 + i * 0.17) + math.sin(time * 0.2 + i) * 10, h * (0.72 + (i % 2) * 0.02), w * 0.2, h * 0.05, const Color(0xCC8E9CC4));
      }
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFF3A4458));
      c.save();
      c.translate(w * 0.5, ground - 2);
      c.scale(h / 260, h / 260);
      paintCampfire(c, time);
      c.restore();
    case StoryBackdrop.summit:
      // Sunrise over a sea of cloud, and the Weather Chime ringing in the wind.
      _gradient(c, full, const [Color(0xFFF3A66A), Color(0xFFFBE0A8), Color(0xFFBFE0F2)]);
      circle(c, w * 0.5, h * 0.62, w * 0.13, const Color(0xCCFFF1C2));
      _peak(c, w * 0.16, h * 0.7, w * 0.3, h * 0.2, const Color(0xFF9DB3D1), const Color(0xFFFFFFFF));
      _peak(c, w * 0.86, h * 0.7, w * 0.36, h * 0.26, const Color(0xFF9DB3D1), const Color(0xFFFFFFFF));
      for (var i = 0; i < 6; i++) {
        oval(c, w * (0.06 + i * 0.18) + math.sin(time * 0.25 + i) * 12, h * (0.7 + (i % 2) * 0.025), w * 0.22, h * 0.05, const Color(0xF2FFF4E2));
      }
      _chimeRing(c, w * 0.5, h * 0.06, w * 0.2, time, sway: 0.1);
      _fill(c, Rect.fromLTWH(0, ground, w, h - ground), const Color(0xFFCFD6E2));
      oval(c, w * 0.5, ground + 2, w * 0.3, h * 0.025, const Color(0xFFE4E9F1));
  }
}
