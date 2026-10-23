part of 'exercise_demo.dart';

// Cardio kit and sports: ropes, bikes, rowers, stairs, water and balls.

// ---- Jump rope -------------------------------------------------------------------

final _jumpRope = _rig([
  _K(0.0, hip: _stand, foot: _fl(122), footB: _fl(114), arm: const Offset(14, 14), armB: const Offset(12, 16)),
  _K(0.25, hip: const Offset(120, 65), foot: const Offset(122, 106), footB: const Offset(114, 107), arm: const Offset(17, 22), armB: const Offset(15, 24)),
  _K(0.5, hip: _stand, foot: _fl(122), footB: _fl(114), arm: const Offset(14, 14), armB: const Offset(12, 16)),
  _K(0.75, hip: const Offset(120, 65), foot: const Offset(122, 106), footB: const Offset(114, 107), arm: const Offset(17, 22), armB: const Offset(15, 24)),
]);

// ---- Cycling ---------------------------------------------------------------------

const _pedalCentre = Offset(116, 70);

Offset _pedal(double a) => _pedalCentre + Offset(math.cos(a), math.sin(a)) * 11;

final _cycling = _rig([
  for (var k = 0; k < 8; k++)
    _K(
      k / 8,
      hip: const Offset(106, 46),
      lean: 1.0,
      foot: _pedal(k * math.pi / 4),
      footB: _pedal(k * math.pi / 4 + math.pi),
      hand: const Offset(140, 47),
      handB: const Offset(138, 47),
    ),
]);

// ---- Rowing ----------------------------------------------------------------------

const _footplate = Offset(150, 104);

final _rowing = _rig([
  _K(0.0, hip: const Offset(124, 98), lean: 0.55, foot: _footplate, footB: _footplate + const Offset(-3, 1), hand: const Offset(152, 96), handB: const Offset(150, 97)),
  _K(0.45, hip: const Offset(108, 98), lean: -0.35, foot: _footplate, footB: _footplate + const Offset(-3, 1), arm: const Offset(14, 10), armB: const Offset(12, 11)),
  _K(0.55, hip: const Offset(108, 98), lean: -0.35, foot: _footplate, footB: _footplate + const Offset(-3, 1), arm: const Offset(14, 10), armB: const Offset(12, 11)),
  _K(0.9, hip: const Offset(124, 98), lean: 0.55, foot: _footplate, footB: _footplate + const Offset(-3, 1), hand: const Offset(152, 96), handB: const Offset(150, 97)),
]);

void _rowerFrame(Canvas c, FigurePose p, double t) {
  _line(c, const Offset(50, 112), const Offset(196, 112), 4, const Color(0xFF546E7A)); // rail
  _rect(c, p.hip.dx - 9, p.hip.dy + 4, 18, 5, const Color(0xFF263238), 2); // seat
  _line(c, const Offset(150, 112), const Offset(164, 86), 4, const Color(0xFF37474F)); // footplate
  c.drawCircle(const Offset(184, 100), 13, _p..color = const Color(0xFF455A64));
  c.drawCircle(const Offset(184, 100), 8, _p..color = const Color(0xFF78909C));
  _line(c, const Offset(188, 108), const Offset(190, 112), 4, const Color(0xFF37474F));
}

void _rowerHandle(Canvas c, FigurePose p, double t) {
  final h = (p.handF + p.handB) / 2;
  _line(c, h, const Offset(184, 100), 1.4, const Color(0xFF263238));
  _line(c, h + const Offset(0, -5), h + const Offset(0, 5), 3, _steel);
}

// ---- Stairs ----------------------------------------------------------------------

final _stairClimb = _rig([
  _K(0.0, hip: const Offset(120, 66), lean: 0.1, foot: const Offset(132, 100), footB: const Offset(106, 115), arm: const Offset(-10, 14), armB: const Offset(16, 12)),
  _K(0.25, hip: const Offset(120, 70), lean: 0.1, foot: const Offset(120, 110), footB: const Offset(120, 104), arm: const Offset(4, 24), armB: const Offset(4, 24)),
  _K(0.5, hip: const Offset(120, 66), lean: 0.1, foot: const Offset(106, 115), footB: const Offset(132, 100), arm: const Offset(16, 12), armB: const Offset(-10, 14)),
  _K(0.75, hip: const Offset(120, 70), lean: 0.1, foot: const Offset(120, 104), footB: const Offset(120, 110), arm: const Offset(4, 24), armB: const Offset(4, 24)),
]);

void _stairs(Canvas c, FigurePose p, double t) {
  _rect(c, 122, 102, 30, 16, const Color(0xFF8D6E63), 2);
  _rect(c, 152, 86, 30, 32, const Color(0xFF8D6E63), 2);
  _line(c, const Offset(122, 102), const Offset(152, 102), 2, const Color(0xFFA1887F));
  _line(c, const Offset(152, 86), const Offset(182, 86), 2, const Color(0xFFA1887F));
}

// ---- Hiking ----------------------------------------------------------------------

FigurePose _hike(double t) =>
    _gait(t, swing: 0.42, kneeFlex: 0.7, armSwing: 0.35, elbowBend: 0.4, lean: 0.14);

void _backpack(Canvas c, FigurePose p, double t) {
  final mid = (p.shoulder + p.hip) / 2;
  c.save();
  c.translate(mid.dx - 11, mid.dy);
  c.rotate(-0.1);
  _rect(c, -7, -17, 14, 30, const Color(0xFFB5651D), 4);
  _rect(c, -5, -11, 10, 7, const Color(0xFF8B4513), 2);
  c.restore();
}

void _hikingPoles(Canvas c, FigurePose p, double t) {
  _line(c, p.handF, Offset(p.handF.dx + 12, demoGround - 1), 2, const Color(0xFF6D4C41));
}

// ---- Elliptical ------------------------------------------------------------------

final _elliptical = _rig([
  _K(0.0, hip: const Offset(121, 72), foot: const Offset(136, 110), footB: const Offset(106, 110), hand: const Offset(150, 52), handB: const Offset(134, 54)),
  _K(0.25, hip: const Offset(121, 72), foot: const Offset(122, 102), footB: const Offset(122, 114), hand: const Offset(142, 48), handB: const Offset(142, 58)),
  _K(0.5, hip: const Offset(121, 72), foot: const Offset(106, 110), footB: const Offset(136, 110), hand: const Offset(134, 54), handB: const Offset(150, 52)),
  _K(0.75, hip: const Offset(121, 72), foot: const Offset(122, 114), footB: const Offset(122, 102), hand: const Offset(142, 58), handB: const Offset(142, 48)),
]);

void _ellipticalFrame(Canvas c, FigurePose p, double t) {
  _rect(c, 92, 112, 98, 6, const Color(0xFF546E7A), 3);
  _line(c, const Offset(172, 112), const Offset(172, 30), 6, const Color(0xFF546E7A));
  _rect(c, 162, 22, 22, 12, const Color(0xFF37474F), 3);
  _line(c, const Offset(172, 40), p.handB, 3, const Color(0xFF78909C));
  _line(c, const Offset(172, 40), p.handF, 3, const Color(0xFF90A4AE));
  _line(c, p.ankleB, const Offset(176, 112), 3, const Color(0xFF455A64));
  _line(c, p.ankleF, const Offset(176, 112), 3, const Color(0xFF546E7A));
}

// ---- Boxing and martial arts -----------------------------------------------------

final _shadowBoxing = _rig([
  _K(0.0, hip: const Offset(116, 77), lean: 0.1, foot: _fl(138), footB: _fl(98), arm: const Offset(16, -2), armB: const Offset(13, 2)),
  _K(0.12, hip: const Offset(118, 77), lean: 0.2, foot: _fl(138), footB: _fl(98), arm: const Offset(32, -3), armB: const Offset(13, 2)),
  _K(0.26, hip: const Offset(116, 77), lean: 0.1, foot: _fl(138), footB: _fl(98), arm: const Offset(16, -2), armB: const Offset(13, 2)),
  _K(0.42, hip: const Offset(120, 77), lean: 0.22, foot: _fl(138), footB: _fl(98), arm: const Offset(16, -2), armB: const Offset(32, -2)),
  _K(0.58, hip: const Offset(116, 77), lean: 0.1, foot: _fl(138), footB: _fl(98), arm: const Offset(16, -2), armB: const Offset(13, 2)),
  _K(0.72, hip: const Offset(118, 77), lean: 0.2, foot: _fl(138), footB: _fl(98), arm: const Offset(32, -3), armB: const Offset(13, 2)),
  _K(0.84, hip: const Offset(116, 77), lean: 0.1, foot: _fl(138), footB: _fl(98), arm: const Offset(16, -2), armB: const Offset(13, 2)),
]);

void _gloves(Canvas c, FigurePose p, double t) {
  c.drawCircle(p.handB, 5.5, _p..color = const Color(0xFFB71C1C));
  c.drawCircle(p.handF, 5.5, _p..color = const Color(0xFFE53935));
}

final _martialArts = _rig([
  _K(0.0, hip: const Offset(116, 77), lean: 0.08, foot: _fl(136), footB: _fl(98), arm: const Offset(16, -2), armB: const Offset(13, 2)),
  _K(0.15, hip: const Offset(118, 77), lean: 0.2, foot: _fl(136), footB: _fl(98), arm: const Offset(32, -3), armB: const Offset(13, 2)),
  _K(0.3, hip: const Offset(116, 77), lean: 0.08, foot: _fl(136), footB: _fl(98), arm: const Offset(16, -2), armB: const Offset(13, 2)),
  _K(0.5, hip: const Offset(114, 74), lean: -0.05, foot: const Offset(136, 92), footB: _fl(98), arm: const Offset(16, 4), armB: const Offset(8, 8)),
  _K(0.62, hip: const Offset(110, 72), lean: -0.18, foot: const Offset(150, 78), footB: _fl(98), arm: const Offset(10, 8), armB: const Offset(0, 10)),
  _K(0.78, hip: const Offset(114, 74), lean: -0.05, foot: const Offset(136, 92), footB: _fl(98), arm: const Offset(16, 4), armB: const Offset(8, 8)),
  _K(0.92, hip: const Offset(116, 77), lean: 0.08, foot: _fl(136), footB: _fl(98), arm: const Offset(16, -2), armB: const Offset(13, 2)),
]);

// ---- Swimming --------------------------------------------------------------------

FigurePose _swim(double t) {
  final ph = t * 2 * math.pi;
  const hip = Offset(84, 80);
  final shoulder = hip + _upDir(1.5) * torsoLen;
  Offset hand(double a) => shoulder + Offset(math.cos(a), math.sin(a)) * 31;
  Offset foot(double a) => hip + Offset(-40, 4 * math.sin(a));
  return _build(
    hip: hip,
    shoulder: shoulder,
    ankleF: foot(ph * 3),
    ankleB: foot(ph * 3 + math.pi),
    handF: hand(ph - 1.0),
    handB: hand(ph - 1.0 + math.pi),
  );
}

/// Water over the lower half of the swimmer.
void _swimWater(Canvas c, FigurePose p, double t) {
  _rect(c, 0, 86, demoW, demoH - 86, const Color(0x5542A5F5), 0);
  for (var i = 0; i < 9; i++) {
    final x = (i * 30 + t * 60) % (demoW + 30) - 15;
    _line(c, Offset(x, 86), Offset(x + 14, 86), 1.4, const Color(0x99FFFFFF));
  }
}

// ---- Ball sports -----------------------------------------------------------------

final _dribble = _rig([
  _K(0.0, hip: const Offset(112, 86), lean: 0.32, foot: _fl(132), footB: _fl(96), hand: const Offset(140, 86), handB: const Offset(132, 62)),
  _K(0.25, hip: const Offset(119, 80), lean: 0.2, foot: _fl(136), footB: _fl(100), hand: const Offset(144, 76), handB: const Offset(134, 60)),
  _K(0.5, hip: const Offset(126, 86), lean: 0.32, foot: _fl(140), footB: _fl(104), hand: const Offset(150, 86), handB: const Offset(138, 62)),
  _K(0.75, hip: const Offset(119, 80), lean: 0.2, foot: _fl(136), footB: _fl(100), hand: const Offset(144, 76), handB: const Offset(134, 60)),
]);

void _dribbleBall(Canvas c, FigurePose p, double t) {
  final y = 108 - 22 * (0.5 + 0.5 * math.cos(t * 4 * math.pi));
  _ball(c, Offset(p.handF.dx + 1, y), r: 6);
}

final _soccerKick = _rig([
  _K(0.0, hip: const Offset(110, 72), lean: 0.05, foot: _fl(122), footB: _fl(104), arm: const Offset(14, 18), armB: const Offset(-14, 20)),
  _K(0.25, hip: const Offset(110, 72), lean: 0.0, foot: const Offset(86, 98), footB: _fl(106), arm: const Offset(18, 14), armB: const Offset(-16, 16)),
  _K(0.4, hip: const Offset(120, 74), lean: 0.15, foot: const Offset(144, 110), footB: _fl(112), arm: const Offset(16, 18), armB: const Offset(-18, 14)),
  _K(0.55, hip: const Offset(122, 72), lean: 0.12, foot: const Offset(152, 82), footB: _fl(114), arm: const Offset(14, 18), armB: const Offset(-16, 18)),
  _K(0.8, hip: const Offset(112, 72), lean: 0.05, foot: _fl(124), footB: _fl(106), arm: const Offset(14, 18), armB: const Offset(-14, 20)),
]);

void _soccerBall(Canvas c, FigurePose p, double t) {
  final x = t < 0.4 ? 150.0 : 150 + math.min((t - 0.4) / 0.4, 1.0) * 70;
  final y = t < 0.4 ? 112.0 : 112 - 14 * math.sin(math.min((t - 0.4) / 0.4, 1.0) * math.pi);
  _ball(c, Offset(x, y), r: 6, color: const Color(0xFFF5F5F5));
}

final _tennisSwing = _rig([
  _K(0.0, hip: const Offset(116, 78), lean: 0.08, foot: _fl(136), footB: _fl(100), arm: const Offset(20, 6), armB: const Offset(17, 8)),
  _K(0.25, hip: const Offset(112, 78), lean: -0.12, foot: _fl(136), footB: _fl(100), arm: const Offset(-22, 4), armB: const Offset(-17, 8)),
  _K(0.45, hip: const Offset(122, 78), lean: 0.2, foot: _fl(138), footB: _fl(102), arm: const Offset(28, 10), armB: const Offset(24, 12)),
  _K(0.62, hip: const Offset(122, 77), lean: 0.22, foot: _fl(138), footB: _fl(102), arm: const Offset(14, -24), armB: const Offset(12, -20)),
  _K(0.88, hip: const Offset(116, 78), lean: 0.08, foot: _fl(136), footB: _fl(100), arm: const Offset(20, 6), armB: const Offset(17, 8)),
]);

void _racket(Canvas c, FigurePose p, double t) {
  var d = p.handF - p.elbowF;
  d = d / d.distance;
  final grip = p.handF - d * 3;
  final head = p.handF + d * 22;
  _line(c, grip, p.handF + d * 12, 2.4, const Color(0xFF6D4C41));
  c.save();
  c.translate(head.dx, head.dy);
  c.rotate(math.atan2(d.dy, d.dx));
  c.drawOval(
    const Rect.fromLTWH(-11, -7, 22, 14),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF2E7D32),
  );
  c.restore();
}

final _dance = _rig([
  _K(0.0, hip: const Offset(116, 74), lean: 0.08, foot: _fl(128), footB: _fl(108), arm: const Offset(20, -24), armB: const Offset(-10, 22)),
  _K(0.25, hip: const Offset(122, 78), lean: -0.05, foot: const Offset(136, 108), footB: _fl(110), arm: const Offset(24, -4), armB: const Offset(-18, -8)),
  _K(0.5, hip: const Offset(124, 74), lean: 0.08, foot: _fl(130), footB: _fl(112), arm: const Offset(4, 26), armB: const Offset(-8, -26)),
  _K(0.75, hip: const Offset(118, 78), lean: 0.0, foot: _fl(126), footB: const Offset(104, 108), arm: const Offset(-14, -8), armB: const Offset(20, -4)),
]);
