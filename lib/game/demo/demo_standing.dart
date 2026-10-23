part of 'exercise_demo.dart';

// Standing, jumping and bar exercises.

const _stand = Offset(120, 72);
Offset _fl(double x) => Offset(x, _floorY);


final _lunge = _rig([
  _K(0.0, hip: _stand, foot: _fl(124), footB: _fl(116)),
  _K(0.4, hip: const Offset(122, 93), lean: 0.04, foot: _fl(152), footB: const Offset(92, 109)),
  _K(0.52, hip: const Offset(122, 93), lean: 0.04, foot: _fl(152), footB: const Offset(92, 109)),
  _K(0.92, hip: _stand, foot: _fl(124), footB: _fl(116)),
]);

final _sideLunge = _rig([
  _K(0.0, hip: const Offset(112, 72), foot: _fl(114), footB: _fl(106), arm: const Offset(16, 20), armB: const Offset(14, 22)),
  _K(0.4, hip: const Offset(130, 91), lean: 0.2, foot: _fl(160), footB: _fl(95), arm: const Offset(24, 8), armB: const Offset(22, 10)),
  _K(0.52, hip: const Offset(130, 91), lean: 0.2, foot: _fl(160), footB: _fl(95), arm: const Offset(24, 8), armB: const Offset(22, 10)),
  _K(0.92, hip: const Offset(112, 72), foot: _fl(114), footB: _fl(106), arm: const Offset(16, 20), armB: const Offset(14, 22)),
]);

final _calfRaise = _rig([
  _K(0.0, hip: const Offset(116, 72), foot: _fl(118), footB: _fl(110), hand: const Offset(140, 60), handB: const Offset(140, 64)),
  _K(0.38, hip: const Offset(116, 62), foot: const Offset(118, _floorY - 10), footB: const Offset(110, _floorY - 10), hand: const Offset(140, 60), handB: const Offset(140, 64)),
  _K(0.52, hip: const Offset(116, 62), foot: const Offset(118, _floorY - 10), footB: const Offset(110, _floorY - 10), hand: const Offset(140, 60), handB: const Offset(140, 64)),
  _K(0.9, hip: const Offset(116, 72), foot: _fl(118), footB: _fl(110), hand: const Offset(140, 60), handB: const Offset(140, 64)),
]);

/// Little toes that stay on the floor while the heel lifts.
void _toesDown(Canvas c, FigurePose p, double t) {
  for (final a in [p.ankleB, p.ankleF]) {
    final top = a.dy + 1.5;
    if (117 - top > 1.5) _rect(c, a.dx + 4, top, 4.5, 117 - top, const Color(0xFF3E2723), 2);
  }
}

final _stepUp = _rig([
  _K(0.0, hip: const Offset(92, 72), foot: _fl(96), footB: _fl(88)),
  _K(0.22, hip: const Offset(108, 66), lean: 0.1, foot: const Offset(136, 100.5), footB: _fl(90)),
  _K(0.44, hip: const Offset(138, 58), foot: const Offset(142, 100.5), footB: const Offset(132, 100.5)),
  _K(0.56, hip: const Offset(138, 58), foot: const Offset(142, 100.5), footB: const Offset(132, 100.5)),
  _K(0.76, hip: const Offset(108, 66), lean: 0.1, foot: const Offset(136, 100.5), footB: _fl(92)),
  _K(0.92, hip: const Offset(92, 72), foot: _fl(96), footB: _fl(88)),
]);

final _jumpSquat = _rig([
  _K(0.0, hip: _stand, foot: _fl(122), footB: _fl(114)),
  _K(0.2, hip: const Offset(96, 99), lean: 0.68, foot: _fl(122), footB: _fl(114), arm: const Offset(-16, 20), armB: const Offset(-18, 20)),
  _K(0.4, hip: const Offset(118, 60), lean: 0.0, foot: const Offset(122, 100), footB: const Offset(114, 102), arm: const Offset(5, -26), armB: const Offset(3, -26)),
  _K(0.54, hip: const Offset(100, 94), lean: 0.5, foot: _fl(122), footB: _fl(114), arm: const Offset(24, 8), armB: const Offset(22, 9)),
  _K(0.72, hip: _stand, foot: _fl(122), footB: _fl(114)),
]);

final _jumpingJacks = _rig(
  [
    _K(0.0, hip: _stand, foot: _fl(124), footB: _fl(116), arm: const Offset(4, 30), armB: const Offset(-4, 30)),
    _K(0.2, hip: const Offset(120, 66), foot: const Offset(136, 103), footB: const Offset(104, 103), arm: const Offset(14, -8), armB: const Offset(-14, -8)),
    _K(0.38, hip: const Offset(120, 80), foot: _fl(144), footB: _fl(96), arm: const Offset(22, -26), armB: const Offset(-22, -26)),
    _K(0.58, hip: const Offset(120, 66), foot: const Offset(132, 103), footB: const Offset(108, 103), arm: const Offset(14, 8), armB: const Offset(-14, 8)),
    _K(0.76, hip: _stand, foot: _fl(124), footB: _fl(116), arm: const Offset(4, 30), armB: const Offset(-4, 30)),
  ],
  elbowSide: 1,
);

final _highKnees = _rig([
  _K(0.0, hip: const Offset(120, 71), lean: 0.05, foot: const Offset(146, 94), footB: _fl(112), arm: const Offset(-10, 14), armB: const Offset(20, 8)),
  _K(0.25, hip: const Offset(120, 73), lean: 0.05, foot: _fl(124), footB: _fl(114), arm: const Offset(6, 24), armB: const Offset(8, 24)),
  _K(0.5, hip: const Offset(120, 71), lean: 0.05, foot: _fl(112), footB: const Offset(146, 94), arm: const Offset(20, 8), armB: const Offset(-10, 14)),
  _K(0.75, hip: const Offset(120, 73), lean: 0.05, foot: _fl(124), footB: _fl(114), arm: const Offset(6, 24), armB: const Offset(8, 24)),
]);

final _buttKicks = _rig([
  _K(0.0, hip: const Offset(120, 72), lean: 0.05, foot: const Offset(98, 85), footB: _fl(116), arm: const Offset(-8, 16), armB: const Offset(14, 10)),
  _K(0.25, hip: const Offset(120, 73), lean: 0.05, foot: _fl(120), footB: _fl(116), arm: const Offset(6, 24), armB: const Offset(8, 24)),
  _K(0.5, hip: const Offset(120, 72), lean: 0.05, foot: _fl(116), footB: const Offset(98, 85), arm: const Offset(14, 10), armB: const Offset(-8, 16)),
  _K(0.75, hip: const Offset(120, 73), lean: 0.05, foot: _fl(120), footB: _fl(116), arm: const Offset(6, 24), armB: const Offset(8, 24)),
]);

final _burpee = _rig([
  _K(0.0, hip: const Offset(120, 72), foot: _fl(124), footB: _fl(116)),
  _K(0.13, hip: const Offset(96, 98), lean: 1.25, foot: _fl(112), footB: _fl(104), hand: const Offset(140, _handFloorY), handB: const Offset(134, _handFloorY)),
  _K(0.28, hip: const Offset(74, 99), lean: 1.17, foot: _fl(35), footB: _fl(31), hand: const Offset(106, _handFloorY), handB: const Offset(101, _handFloorY)),
  _K(0.38, hip: const Offset(74, 99), lean: 1.17, foot: _fl(35), footB: _fl(31), hand: const Offset(106, _handFloorY), handB: const Offset(101, _handFloorY)),
  _K(0.5, hip: const Offset(96, 98), lean: 1.25, foot: _fl(112), footB: _fl(104), hand: const Offset(140, _handFloorY), handB: const Offset(134, _handFloorY)),
  _K(0.62, hip: const Offset(108, 78), lean: 0.4, foot: _fl(122), footB: _fl(114), arm: const Offset(24, -8), armB: const Offset(22, -6)),
  _K(0.73, hip: const Offset(118, 60), foot: const Offset(124, 100), footB: const Offset(116, 102), arm: const Offset(5, -26), armB: const Offset(3, -26)),
  _K(0.8, hip: const Offset(119, 66), foot: const Offset(124, 106), footB: const Offset(116, 108), arm: const Offset(24, 0), armB: const Offset(22, 2)),
  _K(0.9, hip: const Offset(120, 74), foot: _fl(124), footB: _fl(116)),
]);

final _wallSit = _rig([
  _K(0.0, hip: const Offset(84, 72), foot: _fl(96), footB: _fl(90), arm: const Offset(2, 30)),
  _K(0.3, hip: const Offset(86, 94), foot: _fl(108), footB: _fl(102), hand: const Offset(104, 90), handB: const Offset(100, 91)),
  _K(0.76, hip: const Offset(86, 95), foot: _fl(108), footB: _fl(102), hand: const Offset(104, 91), handB: const Offset(100, 92)),
  _K(0.98, hip: const Offset(84, 72), foot: _fl(96), footB: _fl(90), arm: const Offset(2, 30)),
]);

final _mountainClimber = _rig([
  _K(0.0, hip: const Offset(70, 98), lean: 1.17, foot: _fl(35), footB: const Offset(88, 101), hand: const Offset(106, _handFloorY), handB: const Offset(101, _handFloorY)),
  _K(0.25, hip: const Offset(70, 98), lean: 1.17, foot: _fl(35), footB: _fl(32), hand: const Offset(106, _handFloorY), handB: const Offset(101, _handFloorY)),
  _K(0.5, hip: const Offset(70, 98), lean: 1.17, foot: const Offset(88, 101), footB: _fl(32), hand: const Offset(106, _handFloorY), handB: const Offset(101, _handFloorY)),
  _K(0.75, hip: const Offset(70, 98), lean: 1.17, foot: _fl(35), footB: _fl(32), hand: const Offset(106, _handFloorY), handB: const Offset(101, _handFloorY)),
]);

final _pikePushUp = _rig([
  _K(0.0, hip: const Offset(80, 78), lean: 1.94, foot: _fl(60), footB: _fl(56), hand: const Offset(118, _handFloorY), handB: const Offset(114, _handFloorY)),
  _K(0.45, hip: const Offset(88, 86), lean: 1.98, foot: _fl(60), footB: _fl(56), hand: const Offset(118, _handFloorY), handB: const Offset(114, _handFloorY)),
  _K(0.55, hip: const Offset(88, 86), lean: 1.98, foot: _fl(60), footB: _fl(56), hand: const Offset(118, _handFloorY), handB: const Offset(114, _handFloorY)),
  _K(0.92, hip: const Offset(80, 78), lean: 1.94, foot: _fl(60), footB: _fl(56), hand: const Offset(118, _handFloorY), handB: const Offset(114, _handFloorY)),
]);

final _downwardDog = _rig([
  _K(0.0, hip: const Offset(100, 90), lean: 1.37, foot: const Offset(79, 113), footB: const Offset(75, 113), hand: const Offset(118, _handFloorY), handB: const Offset(114, _handFloorY)),
  _K(0.28, hip: const Offset(80, 78), lean: 1.94, foot: _fl(60), footB: _fl(56), hand: const Offset(118, _handFloorY), handB: const Offset(114, _handFloorY)),
  _K(0.44, hip: const Offset(80, 78), lean: 1.94, foot: _fl(60), footB: const Offset(56, 109), hand: const Offset(118, _handFloorY), handB: const Offset(114, _handFloorY)),
  _K(0.6, hip: const Offset(80, 77), lean: 1.94, foot: const Offset(60, 109), footB: _fl(56), hand: const Offset(118, _handFloorY), handB: const Offset(114, _handFloorY)),
  _K(0.76, hip: const Offset(80, 78), lean: 1.94, foot: _fl(60), footB: _fl(56), hand: const Offset(118, _handFloorY), handB: const Offset(114, _handFloorY)),
  _K(0.92, hip: const Offset(100, 90), lean: 1.37, foot: const Offset(79, 113), footB: const Offset(75, 113), hand: const Offset(118, _handFloorY), handB: const Offset(114, _handFloorY)),
]);

final _tricepDip = _rig([
  _K(0.0, hip: const Offset(106, 96), lean: -0.5, foot: _fl(142), footB: _fl(138), hand: const Offset(88, 94), handB: const Offset(84, 94)),
  _K(0.42, hip: const Offset(106, 108), lean: -0.35, foot: _fl(142), footB: _fl(138), hand: const Offset(88, 94), handB: const Offset(84, 94)),
  _K(0.52, hip: const Offset(106, 108), lean: -0.35, foot: _fl(142), footB: _fl(138), hand: const Offset(88, 94), handB: const Offset(84, 94)),
  _K(0.92, hip: const Offset(106, 96), lean: -0.5, foot: _fl(142), footB: _fl(138), hand: const Offset(88, 94), handB: const Offset(84, 94)),
]);

final _pullUp = _rig([
  _K(0.0, hip: const Offset(122, 87), foot: const Offset(106, 108), footB: const Offset(100, 106), hand: const Offset(124, 20), handB: const Offset(120, 20)),
  _K(0.45, hip: const Offset(122, 72), foot: const Offset(106, 94), footB: const Offset(100, 92), hand: const Offset(124, 20), handB: const Offset(120, 20)),
  _K(0.55, hip: const Offset(122, 72), foot: const Offset(106, 94), footB: const Offset(100, 92), hand: const Offset(124, 20), handB: const Offset(120, 20)),
  _K(0.95, hip: const Offset(122, 87), foot: const Offset(106, 108), footB: const Offset(100, 106), hand: const Offset(124, 20), handB: const Offset(120, 20)),
]);
