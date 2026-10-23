part of 'exercise_demo.dart';

// Resistance exercises: dumbbells, barbells, kettlebells, bands and machines.

/// Arms hanging, holding weights at the sides.
const _hang = Offset(3, 31);

final _bicepCurl = _rig([
  _K(0.0, hip: _stand, foot: _fl(124), footB: _fl(116), arm: _hang, armB: const Offset(-1, 31)),
  _K(0.4, hip: _stand, foot: _fl(124), footB: _fl(116), arm: const Offset(18, 4), armB: const Offset(14, 6)),
  _K(0.52, hip: _stand, foot: _fl(124), footB: _fl(116), arm: const Offset(18, 4), armB: const Offset(14, 6)),
  _K(0.92, hip: _stand, foot: _fl(124), footB: _fl(116), arm: _hang, armB: const Offset(-1, 31)),
]);

/// Seen face-on: the arms sweep out to the sides.
final _lateralRaise = _rig([
  _K(0.0, hip: _stand, foot: _fl(124), footB: _fl(116), arm: const Offset(4, 31), armB: const Offset(-4, 31)),
  _K(0.4, hip: _stand, foot: _fl(124), footB: _fl(116), arm: const Offset(31, 0), armB: const Offset(-31, 0)),
  _K(0.52, hip: _stand, foot: _fl(124), footB: _fl(116), arm: const Offset(31, 0), armB: const Offset(-31, 0)),
  _K(0.92, hip: _stand, foot: _fl(124), footB: _fl(116), arm: const Offset(4, 31), armB: const Offset(-4, 31)),
]);

final _overheadTricep = _rig([
  _K(0.0, hip: _stand, foot: _fl(124), footB: _fl(116), arm: const Offset(2, -32), armB: const Offset(0, -32)),
  _K(0.4, hip: _stand, foot: _fl(124), footB: _fl(116), arm: const Offset(-9, -6), armB: const Offset(-11, -5)),
  _K(0.52, hip: _stand, foot: _fl(124), footB: _fl(116), arm: const Offset(-9, -6), armB: const Offset(-11, -5)),
  _K(0.92, hip: _stand, foot: _fl(124), footB: _fl(116), arm: const Offset(2, -32), armB: const Offset(0, -32)),
]);

const _benchHip = Offset(128, 93);
const _benchLean = -math.pi / 2 + 0.05;

final _benchPress = _rig([
  _K(0.0, hip: _benchHip, lean: _benchLean, foot: const Offset(156, 114), footB: const Offset(150, 114), arm: const Offset(2, -31), armB: const Offset(0, -31)),
  _K(0.42, hip: _benchHip, lean: _benchLean, foot: const Offset(156, 114), footB: const Offset(150, 114), arm: const Offset(3, -8), armB: const Offset(1, -8)),
  _K(0.52, hip: _benchHip, lean: _benchLean, foot: const Offset(156, 114), footB: const Offset(150, 114), arm: const Offset(3, -8), armB: const Offset(1, -8)),
  _K(0.92, hip: _benchHip, lean: _benchLean, foot: const Offset(156, 114), footB: const Offset(150, 114), arm: const Offset(2, -31), armB: const Offset(0, -31)),
]);

final _deadlift = _rig([
  _K(0.0, hip: const Offset(88, 86), lean: 1.3, foot: _fl(112), footB: _fl(106), hand: const Offset(121, 106), handB: const Offset(117, 106)),
  _K(0.4, hip: const Offset(112, 72), lean: 0.05, foot: _fl(114), footB: _fl(108), arm: const Offset(3, 30), armB: const Offset(1, 30)),
  _K(0.54, hip: const Offset(112, 72), lean: 0.05, foot: _fl(114), footB: _fl(108), arm: const Offset(3, 30), armB: const Offset(1, 30)),
  _K(0.92, hip: const Offset(88, 86), lean: 1.3, foot: _fl(112), footB: _fl(106), hand: const Offset(121, 106), handB: const Offset(117, 106)),
]);

final _romanianDeadlift = _rig([
  _K(0.0, hip: const Offset(112, 72), lean: 0.05, foot: _fl(116), footB: _fl(110), arm: const Offset(3, 30), armB: const Offset(1, 30)),
  _K(0.45, hip: const Offset(94, 78), lean: 1.25, foot: _fl(114), footB: _fl(108), arm: const Offset(-2, 32), armB: const Offset(-4, 32)),
  _K(0.55, hip: const Offset(94, 78), lean: 1.25, foot: _fl(114), footB: _fl(108), arm: const Offset(-2, 32), armB: const Offset(-4, 32)),
  _K(0.92, hip: const Offset(112, 72), lean: 0.05, foot: _fl(116), footB: _fl(110), arm: const Offset(3, 30), armB: const Offset(1, 30)),
]);

final _barbellRow = _rig([
  _K(0.0, hip: const Offset(92, 80), lean: 1.15, foot: _fl(112), footB: _fl(106), arm: const Offset(3, 33), armB: const Offset(1, 33)),
  _K(0.42, hip: const Offset(92, 80), lean: 1.15, foot: _fl(112), footB: _fl(106), arm: const Offset(-10, 18), armB: const Offset(-12, 19)),
  _K(0.52, hip: const Offset(92, 80), lean: 1.15, foot: _fl(112), footB: _fl(106), arm: const Offset(-10, 18), armB: const Offset(-12, 19)),
  _K(0.92, hip: const Offset(92, 80), lean: 1.15, foot: _fl(112), footB: _fl(106), arm: const Offset(3, 33), armB: const Offset(1, 33)),
]);

final _hipThrust = _rig([
  _K(0.0, hip: const Offset(112, 104), lean: -1.18, foot: const Offset(140, 115), footB: const Offset(134, 115), hand: const Offset(112, 100), handB: const Offset(110, 101)),
  _K(0.4, hip: const Offset(114, 82), lean: -1.76, foot: const Offset(140, 115), footB: const Offset(134, 115), hand: const Offset(114, 79), handB: const Offset(112, 80)),
  _K(0.54, hip: const Offset(114, 82), lean: -1.76, foot: const Offset(140, 115), footB: const Offset(134, 115), hand: const Offset(114, 79), handB: const Offset(112, 80)),
  _K(0.92, hip: const Offset(112, 104), lean: -1.18, foot: const Offset(140, 115), footB: const Offset(134, 115), hand: const Offset(112, 100), handB: const Offset(110, 101)),
]);

final _latPulldown = _rig([
  _K(0.0, hip: const Offset(96, 97), lean: -0.08, foot: _fl(118), footB: _fl(112), arm: const Offset(8, -32), armB: const Offset(2, -32)),
  _K(0.42, hip: const Offset(96, 97), lean: -0.18, foot: _fl(118), footB: _fl(112), arm: const Offset(15, 4), armB: const Offset(11, 5)),
  _K(0.52, hip: const Offset(96, 97), lean: -0.18, foot: _fl(118), footB: _fl(112), arm: const Offset(15, 4), armB: const Offset(11, 5)),
  _K(0.92, hip: const Offset(96, 97), lean: -0.08, foot: _fl(118), footB: _fl(112), arm: const Offset(8, -32), armB: const Offset(2, -32)),
]);

final _legPress = _rig([
  _K(0.0, hip: const Offset(78, 100), lean: -0.8, foot: const Offset(106, 84), footB: const Offset(102, 87), hand: const Offset(86, 90), handB: const Offset(84, 92)),
  _K(0.45, hip: const Offset(78, 100), lean: -0.8, foot: const Offset(115, 76), footB: const Offset(111, 79), hand: const Offset(86, 90), handB: const Offset(84, 92)),
  _K(0.55, hip: const Offset(78, 100), lean: -0.8, foot: const Offset(115, 76), footB: const Offset(111, 79), hand: const Offset(86, 90), handB: const Offset(84, 92)),
  _K(0.95, hip: const Offset(78, 100), lean: -0.8, foot: const Offset(106, 84), footB: const Offset(102, 87), hand: const Offset(86, 90), handB: const Offset(84, 92)),
]);

final _kettlebellSwing = _rig([
  _K(0.0, hip: const Offset(92, 78), lean: 1.15, foot: _fl(112), footB: _fl(106), hand: const Offset(112, 94), handB: const Offset(110, 95)),
  _K(0.3, hip: const Offset(118, 72), lean: 0.05, foot: _fl(122), footB: _fl(114), arm: const Offset(30, 0), armB: const Offset(28, 1)),
  _K(0.5, hip: const Offset(116, 72), lean: 0.05, foot: _fl(122), footB: _fl(114), arm: const Offset(28, 8), armB: const Offset(26, 9)),
  _K(0.85, hip: const Offset(92, 78), lean: 1.15, foot: _fl(112), footB: _fl(106), hand: const Offset(112, 94), handB: const Offset(110, 95)),
]);

final _gobletSquat = _rig([
  _K(0.0, hip: _stand, foot: _fl(122), footB: _fl(114), arm: const Offset(14, 12), armB: const Offset(13, 13)),
  _K(0.42, hip: const Offset(98, 98), lean: 0.55, foot: _fl(122), footB: _fl(114), arm: const Offset(14, 12), armB: const Offset(13, 13)),
  _K(0.52, hip: const Offset(98, 98), lean: 0.55, foot: _fl(122), footB: _fl(114), arm: const Offset(14, 12), armB: const Offset(13, 13)),
  _K(0.92, hip: _stand, foot: _fl(122), footB: _fl(114), arm: const Offset(14, 12), armB: const Offset(13, 13)),
]);

final _bandRow = _rig([
  _K(0.0, hip: const Offset(96, 72), lean: -0.06, foot: _fl(104), footB: _fl(94), arm: const Offset(31, 4), armB: const Offset(29, 5)),
  _K(0.42, hip: const Offset(96, 72), lean: -0.12, foot: _fl(104), footB: _fl(94), arm: const Offset(6, 6), armB: const Offset(4, 7)),
  _K(0.52, hip: const Offset(96, 72), lean: -0.12, foot: _fl(104), footB: _fl(94), arm: const Offset(6, 6), armB: const Offset(4, 7)),
  _K(0.92, hip: const Offset(96, 72), lean: -0.06, foot: _fl(104), footB: _fl(94), arm: const Offset(31, 4), armB: const Offset(29, 5)),
]);

/// Walking tall with a weight in each hand: the arms stay down at the sides.
FigurePose _carry(double t) => _gait(t, swing: 0.4, kneeFlex: 0.6, armSwing: 0.03, elbowBend: 0.02, lean: 0.0);

// ---- Prop painters for the weights ---------------------------------------------

void _bothDumbbells(Canvas c, FigurePose p, double t, {double tilt = 0}) {
  _dumbbell(c, p.handB, tilt: tilt);
  _dumbbell(c, p.handF, tilt: tilt);
}

void _barAt(Canvas c, FigurePose p, double t) => _barbell(c, p.handF + const Offset(0, -1));

void _kettlebellAtHands(Canvas c, FigurePose p, double t) =>
    _kettlebell(c, Offset((p.handF.dx + p.handB.dx) / 2, (p.handF.dy + p.handB.dy) / 2 + 5));

void _benchProp(Canvas c, FigurePose p, double t) {
  _rect(c, 56, 99, 82, 7, const Color(0xFF8D6E63), 3);
  _rect(c, 64, 106, 5, 12, const Color(0xFF6D4C41), 1);
  _rect(c, 124, 106, 5, 12, const Color(0xFF6D4C41), 1);
}

void _hipThrustBench(Canvas c, FigurePose p, double t) {
  _rect(c, 44, 96, 50, 7, const Color(0xFF8D6E63), 3);
  _rect(c, 50, 103, 5, 15, const Color(0xFF6D4C41), 1);
  _rect(c, 82, 103, 5, 15, const Color(0xFF6D4C41), 1);
}

void _pulldownMachine(Canvas c, FigurePose p, double t) {
  _rect(c, 78, 100, 36, 6, const Color(0xFF546E7A), 2); // seat
  _rect(c, 74, 106, 5, 12, const Color(0xFF37474F), 1);
  _rect(c, 126, 18, 6, 100, const Color(0xFF546E7A), 2); // post
  _line(c, const Offset(129, 20), const Offset(108, 12), 5, const Color(0xFF546E7A)); // arm
  c.drawCircle(const Offset(108, 12), 4, _p..color = const Color(0xFF263238));
  _rect(c, 108, 82, 20, 6, const Color(0xFF37474F), 3); // thigh pad
}

void _pulldownCable(Canvas c, FigurePose p, double t) {
  final bar = Offset((p.handF.dx + p.handB.dx) / 2, math.min(p.handF.dy, p.handB.dy) - 3);
  _line(c, const Offset(108, 12), bar, 1.4, const Color(0xFF263238));
  _line(c, bar + const Offset(-12, 0), bar + const Offset(12, 0), 3, _steel);
}

void _legPressMachine(Canvas c, FigurePose p, double t) {
  // Back pad along the torso, seat, and the rails the platform slides on.
  _line(c, p.hip + const Offset(-4, 4), p.shoulder + const Offset(-6, 3), 8, const Color(0xFF455A64));
  _line(c, const Offset(60, 117), const Offset(60, 104), 4, const Color(0xFF37474F));
  _line(c, const Offset(96, 106), const Offset(138, 62), 3, const Color(0xFF78909C));
  _line(c, const Offset(100, 112), const Offset(146, 66), 3, const Color(0xFF78909C));
}

void _legPressPlate(Canvas c, FigurePose p, double t) {
  const dir = Offset(0.82, -0.57);
  const perp = Offset(0.57, 0.82);
  final centre = p.ankleF + dir * 7;
  _line(c, centre - perp * 16, centre + perp * 16, 6, const Color(0xFF37474F));
}

void _bandAnchor(Canvas c, FigurePose p, double t) {
  _wall(c, 190);
  c.drawCircle(const Offset(190, 54), 3, _p..color = _steel);
}

void _bandLine(Canvas c, FigurePose p, double t) {
  _band(c, const Offset(190, 54), (p.handF + p.handB) / 2);
}

/// Barbell press: the bar starts at the shoulders and locks out overhead. A
/// little lower in the frame than the dumbbell press so the plate stays in view.
final _overheadPress = _rig([
  _K(0.0, hip: const Offset(112, 78), foot: _fl(114), footB: _fl(106), arm: const Offset(8, -2), armB: const Offset(6, -1)),
  _K(0.4, hip: const Offset(112, 78), foot: _fl(114), footB: _fl(106), arm: const Offset(5, -29), armB: const Offset(3, -29)),
  _K(0.52, hip: const Offset(112, 78), foot: _fl(114), footB: _fl(106), arm: const Offset(5, -29), armB: const Offset(3, -29)),
  _K(0.92, hip: const Offset(112, 78), foot: _fl(114), footB: _fl(106), arm: const Offset(8, -2), armB: const Offset(6, -1)),
]);
