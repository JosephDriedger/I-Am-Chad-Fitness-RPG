part of 'exercise_demo.dart';

// Floor work: lying, all fours, seated and kneeling. These run along the floor
// with the head toward -x on your back and toward +x face down or on all fours.

/// On your back: hip on the floor, torso flat (head toward -x).
const _hipLying = Offset(128, 109);

/// Torso lean for lying on your back, raised by [a] radians.
double _supine(double a) => -math.pi / 2 + a;

const _lyingHand = Offset(120, 111);
const _lyingHandB = Offset(116, 112);

/// All fours: hips over knees, hands under shoulders.
const _quadHip = Offset(100, 90);
const _quadLean = 1.37;
const _quadHand = Offset(133, _handFloorY);
const _quadHandB = Offset(129, _handFloorY);
const _quadKnee = Offset(79, 113);
const _quadKneeB = Offset(75, 113);

final _gluteBridge = _rig([
  _K(0.0, hip: _hipLying, lean: _supine(0.1), foot: const Offset(156, 114), footB: const Offset(150, 114), hand: _lyingHand, handB: _lyingHandB),
  _K(0.4, hip: const Offset(127, 88), lean: -2.12, foot: const Offset(156, 114), footB: const Offset(150, 114), hand: _lyingHand, handB: _lyingHandB),
  _K(0.55, hip: const Offset(127, 88), lean: -2.12, foot: const Offset(156, 114), footB: const Offset(150, 114), hand: _lyingHand, handB: _lyingHandB),
  _K(0.92, hip: _hipLying, lean: _supine(0.1), foot: const Offset(156, 114), footB: const Offset(150, 114), hand: _lyingHand, handB: _lyingHandB),
]);

final _donkeyKick = _rig([
  _K(0.0, hip: _quadHip, lean: _quadLean, foot: _quadKnee, footB: _quadKneeB, hand: _quadHand, handB: _quadHandB),
  _K(0.35, hip: _quadHip, lean: _quadLean, foot: const Offset(80, 66), footB: _quadKneeB, hand: _quadHand, handB: _quadHandB),
  _K(0.5, hip: _quadHip, lean: _quadLean, foot: const Offset(80, 66), footB: _quadKneeB, hand: _quadHand, handB: _quadHandB),
  _K(0.88, hip: _quadHip, lean: _quadLean, foot: _quadKnee, footB: _quadKneeB, hand: _quadHand, handB: _quadHandB),
]);

final _fireHydrant = _rig([
  _K(0.0, hip: _quadHip, lean: _quadLean, foot: _quadKnee, footB: _quadKneeB, hand: _quadHand, handB: _quadHandB),
  _K(0.38, hip: _quadHip, lean: _quadLean, foot: const Offset(65, 100), footB: _quadKneeB, hand: _quadHand, handB: _quadHandB),
  _K(0.52, hip: _quadHip, lean: _quadLean, foot: const Offset(65, 100), footB: _quadKneeB, hand: _quadHand, handB: _quadHandB),
  _K(0.88, hip: _quadHip, lean: _quadLean, foot: _quadKnee, footB: _quadKneeB, hand: _quadHand, handB: _quadHandB),
]);

final _birdDog = _rig([
  _K(0.0, hip: _quadHip, lean: _quadLean, foot: _quadKnee, footB: _quadKneeB, hand: _quadHand, handB: _quadHandB),
  _K(0.32, hip: _quadHip, lean: _quadLean, foot: _quadKnee, footB: const Offset(58, 88), hand: const Offset(166, 84), handB: _quadHandB),
  _K(0.58, hip: _quadHip, lean: _quadLean, foot: _quadKnee, footB: const Offset(58, 88), hand: const Offset(166, 84), handB: _quadHandB),
  _K(0.9, hip: _quadHip, lean: _quadLean, foot: _quadKnee, footB: _quadKneeB, hand: _quadHand, handB: _quadHandB),
]);

final _catCow = _rig([
  _K(0.0, hip: _quadHip, lean: _quadLean, foot: _quadKnee, footB: _quadKneeB, hand: _quadHand, handB: _quadHandB),
  _K(0.25, hip: const Offset(100, 80), lean: 1.7, foot: _quadKnee, footB: _quadKneeB, hand: _quadHand, handB: _quadHandB),
  _K(0.5, hip: _quadHip, lean: _quadLean, foot: _quadKnee, footB: _quadKneeB, hand: _quadHand, handB: _quadHandB),
  _K(0.75, hip: const Offset(100, 98), lean: 1.1, foot: _quadKnee, footB: _quadKneeB, hand: _quadHand, handB: _quadHandB),
]);

final _bicycleCrunch = _rig([
  _K(0.0, hip: _hipLying, lean: _supine(0.5), foot: const Offset(160, 100), footB: const Offset(138, 90), hand: const Offset(86, 82), handB: const Offset(90, 84)),
  _K(0.25, hip: _hipLying, lean: _supine(0.55), foot: const Offset(146, 90), footB: const Offset(162, 100), hand: const Offset(90, 82), handB: const Offset(86, 84)),
  _K(0.5, hip: _hipLying, lean: _supine(0.5), foot: const Offset(138, 90), footB: const Offset(160, 100), hand: const Offset(86, 82), handB: const Offset(90, 84)),
  _K(0.75, hip: _hipLying, lean: _supine(0.55), foot: const Offset(162, 100), footB: const Offset(146, 90), hand: const Offset(90, 82), handB: const Offset(86, 84)),
]);

final _legRaise = _rig([
  _K(0.0, hip: _hipLying, lean: _supine(0.06), foot: const Offset(170, 107), footB: const Offset(166, 108), hand: _lyingHand, handB: _lyingHandB),
  _K(0.4, hip: _hipLying, lean: _supine(0.06), foot: const Offset(134, 70), footB: const Offset(130, 71), hand: _lyingHand, handB: _lyingHandB),
  _K(0.52, hip: _hipLying, lean: _supine(0.06), foot: const Offset(134, 70), footB: const Offset(130, 71), hand: _lyingHand, handB: _lyingHandB),
  _K(0.92, hip: _hipLying, lean: _supine(0.06), foot: const Offset(170, 107), footB: const Offset(166, 108), hand: _lyingHand, handB: _lyingHandB),
]);

final _russianTwist = _rig([
  _K(0.0, hip: const Offset(118, 109), lean: -0.5, foot: const Offset(150, 95), footB: const Offset(146, 98), arm: const Offset(26, 10), armB: const Offset(24, 11)),
  _K(0.25, hip: const Offset(118, 109), lean: -0.5, foot: const Offset(150, 95), footB: const Offset(146, 98), arm: const Offset(5, 20), armB: const Offset(3, 21)),
  _K(0.5, hip: const Offset(118, 109), lean: -0.5, foot: const Offset(150, 95), footB: const Offset(146, 98), arm: const Offset(26, 10), armB: const Offset(24, 11)),
  _K(0.75, hip: const Offset(118, 109), lean: -0.5, foot: const Offset(150, 95), footB: const Offset(146, 98), arm: const Offset(5, 20), armB: const Offset(3, 21)),
]);

final _deadBug = _rig([
  _K(0.0, hip: _hipLying, lean: _supine(0.06), foot: const Offset(149, 88), footB: const Offset(143, 90), hand: const Offset(96, 75), handB: const Offset(92, 76)),
  _K(0.25, hip: _hipLying, lean: _supine(0.06), foot: const Offset(149, 88), footB: const Offset(168, 108), hand: const Offset(62, 104), handB: const Offset(92, 76)),
  _K(0.45, hip: _hipLying, lean: _supine(0.06), foot: const Offset(149, 88), footB: const Offset(168, 108), hand: const Offset(62, 104), handB: const Offset(92, 76)),
  _K(0.55, hip: _hipLying, lean: _supine(0.06), foot: const Offset(149, 88), footB: const Offset(143, 90), hand: const Offset(96, 75), handB: const Offset(92, 76)),
  _K(0.75, hip: _hipLying, lean: _supine(0.06), foot: const Offset(168, 108), footB: const Offset(143, 90), hand: const Offset(96, 75), handB: const Offset(58, 104)),
  _K(0.92, hip: _hipLying, lean: _supine(0.06), foot: const Offset(149, 88), footB: const Offset(143, 90), hand: const Offset(96, 75), handB: const Offset(92, 76)),
]);

final _flutterKick = _rig([
  _K(0.0, hip: _hipLying, lean: _supine(0.05), foot: const Offset(165, 108), footB: const Offset(163, 109), hand: _lyingHand, handB: _lyingHandB),
  _K(0.14, hip: _hipLying, lean: _supine(0.28), foot: const Offset(160, 92), footB: const Offset(160, 104), hand: _lyingHand, handB: _lyingHandB),
  _K(0.3, hip: _hipLying, lean: _supine(0.28), foot: const Offset(160, 104), footB: const Offset(160, 92), hand: _lyingHand, handB: _lyingHandB),
  _K(0.46, hip: _hipLying, lean: _supine(0.28), foot: const Offset(160, 92), footB: const Offset(160, 104), hand: _lyingHand, handB: _lyingHandB),
  _K(0.62, hip: _hipLying, lean: _supine(0.28), foot: const Offset(160, 104), footB: const Offset(160, 92), hand: _lyingHand, handB: _lyingHandB),
  _K(0.78, hip: _hipLying, lean: _supine(0.28), foot: const Offset(160, 98), footB: const Offset(160, 98), hand: _lyingHand, handB: _lyingHandB),
]);

final _hollowHold = _rig([
  _K(0.0, hip: _hipLying, lean: _supine(0.05), foot: const Offset(170, 108), footB: const Offset(166, 109), hand: const Offset(62, 104), handB: const Offset(58, 105)),
  _K(0.3, hip: _hipLying, lean: _supine(0.45), foot: const Offset(165, 88), footB: const Offset(161, 89), hand: const Offset(68, 84), handB: const Offset(64, 85)),
  _K(0.75, hip: _hipLying, lean: _supine(0.47), foot: const Offset(165, 87), footB: const Offset(161, 88), hand: const Offset(68, 83), handB: const Offset(64, 84)),
  _K(0.95, hip: _hipLying, lean: _supine(0.05), foot: const Offset(170, 108), footB: const Offset(166, 109), hand: const Offset(62, 104), handB: const Offset(58, 105)),
]);

final _superman = _rig([
  _K(0.0, hip: const Offset(80, 108), lean: 1.45, foot: const Offset(38, 109), footB: const Offset(34, 110), hand: const Offset(146, 106), handB: const Offset(142, 107)),
  _K(0.35, hip: const Offset(80, 108), lean: 1.15, foot: const Offset(40, 94), footB: const Offset(36, 95), hand: const Offset(144, 92), handB: const Offset(140, 93)),
  _K(0.6, hip: const Offset(80, 108), lean: 1.15, foot: const Offset(40, 94), footB: const Offset(36, 95), hand: const Offset(144, 92), handB: const Offset(140, 93)),
  _K(0.92, hip: const Offset(80, 108), lean: 1.45, foot: const Offset(38, 109), footB: const Offset(34, 110), hand: const Offset(146, 106), handB: const Offset(142, 107)),
]);

final _sidePlank = _rig([
  _K(0.0, hip: const Offset(72, 106), lean: 1.30, foot: const Offset(36, 114), footB: const Offset(32, 114), hand: const Offset(106, _handFloorY), handB: const Offset(104, _handFloorY), armB: const Offset(4, -28)),
  _K(0.38, hip: const Offset(70, 95), lean: 1.22, foot: const Offset(36, 114), footB: const Offset(32, 114), hand: const Offset(106, _handFloorY), handB: const Offset(104, _handFloorY), armB: const Offset(4, -30)),
  _K(0.62, hip: const Offset(70, 95), lean: 1.22, foot: const Offset(36, 114), footB: const Offset(32, 114), hand: const Offset(106, _handFloorY), handB: const Offset(104, _handFloorY), armB: const Offset(4, -30)),
  _K(0.95, hip: const Offset(72, 106), lean: 1.30, foot: const Offset(36, 114), footB: const Offset(32, 114), hand: const Offset(106, _handFloorY), handB: const Offset(104, _handFloorY), armB: const Offset(4, -28)),
]);

// ---- Mobility on the floor ----------------------------------------------------

final _childPose = _rig([
  _K(0.0, hip: const Offset(62, 104), lean: 0.0, foot: const Offset(60, 113), footB: const Offset(56, 113), hand: const Offset(80, 98), handB: const Offset(78, 99)),
  _K(0.4, hip: const Offset(62, 104), lean: 1.42, foot: const Offset(60, 113), footB: const Offset(56, 113), hand: const Offset(128, 108), handB: const Offset(124, 109)),
  _K(0.78, hip: const Offset(62, 104), lean: 1.42, foot: const Offset(60, 113), footB: const Offset(56, 113), hand: const Offset(128, 108), handB: const Offset(124, 109)),
  _K(0.98, hip: const Offset(62, 104), lean: 0.0, foot: const Offset(60, 113), footB: const Offset(56, 113), hand: const Offset(80, 98), handB: const Offset(78, 99)),
]);

final _cobra = _rig([
  _K(0.0, hip: const Offset(60, 109), lean: 1.45, foot: const Offset(18, 112), footB: const Offset(14, 112), hand: const Offset(92, 116), handB: const Offset(88, 116)),
  _K(0.4, hip: const Offset(60, 109), lean: 0.85, foot: const Offset(18, 112), footB: const Offset(14, 112), hand: const Offset(92, 116), handB: const Offset(88, 116)),
  _K(0.72, hip: const Offset(60, 109), lean: 0.85, foot: const Offset(18, 112), footB: const Offset(14, 112), hand: const Offset(92, 116), handB: const Offset(88, 116)),
  _K(0.96, hip: const Offset(60, 109), lean: 1.45, foot: const Offset(18, 112), footB: const Offset(14, 112), hand: const Offset(92, 116), handB: const Offset(88, 116)),
]);

final _hamstringStretch = _rig([
  _K(0.0, hip: const Offset(74, 108), lean: 0.0, foot: const Offset(117, 112), footB: const Offset(96, 113), hand: const Offset(100, 100), handB: const Offset(96, 101)),
  _K(0.4, hip: const Offset(74, 108), lean: 1.0, foot: const Offset(117, 112), footB: const Offset(96, 113), hand: const Offset(114, 108), handB: const Offset(110, 109)),
  _K(0.75, hip: const Offset(74, 108), lean: 1.0, foot: const Offset(117, 112), footB: const Offset(96, 113), hand: const Offset(114, 108), handB: const Offset(110, 109)),
  _K(0.97, hip: const Offset(74, 108), lean: 0.0, foot: const Offset(117, 112), footB: const Offset(96, 113), hand: const Offset(100, 100), handB: const Offset(96, 101)),
]);

/// Seen from the front: the soles of the feet together, knees out.
final _butterflyStretch = _rig(
  [
    _K(0.0, hip: const Offset(120, 108), lean: 0.0, foot: const Offset(124, 113), footB: const Offset(116, 113), hand: const Offset(128, 108), handB: const Offset(112, 108)),
    _K(0.4, hip: const Offset(120, 108), lean: 0.5, foot: const Offset(124, 113), footB: const Offset(116, 113), hand: const Offset(134, 112), handB: const Offset(114, 112)),
    _K(0.75, hip: const Offset(120, 108), lean: 0.5, foot: const Offset(124, 113), footB: const Offset(116, 113), hand: const Offset(134, 112), handB: const Offset(114, 112)),
    _K(0.97, hip: const Offset(120, 108), lean: 0.0, foot: const Offset(124, 113), footB: const Offset(116, 113), hand: const Offset(128, 108), handB: const Offset(112, 108)),
  ],
  kneeSide: -1,
  kneeSideB: 1,
);

final _hipFlexorStretch = _rig([
  _K(0.0, hip: const Offset(100, 94), foot: const Offset(142, 115), footB: const Offset(78, 113), arm: const Offset(-2, 28), armB: const Offset(-4, 28)),
  _K(0.4, hip: const Offset(112, 96), foot: const Offset(142, 115), footB: const Offset(78, 113), arm: const Offset(-2, 28), armB: const Offset(-4, 28)),
  _K(0.76, hip: const Offset(112, 96), foot: const Offset(142, 115), footB: const Offset(78, 113), arm: const Offset(-2, 28), armB: const Offset(-4, 28)),
  _K(0.97, hip: const Offset(100, 94), foot: const Offset(142, 115), footB: const Offset(78, 113), arm: const Offset(-2, 28), armB: const Offset(-4, 28)),
]);

final _spinalTwist = _rig([
  _K(0.0, hip: const Offset(84, 94), foot: const Offset(106, 115), footB: const Offset(100, 115), hand: const Offset(102, 90), handB: const Offset(98, 91)),
  _K(0.4, hip: const Offset(84, 94), foot: const Offset(106, 115), footB: const Offset(100, 115), hand: const Offset(66, 72), handB: const Offset(100, 90)),
  _K(0.76, hip: const Offset(84, 94), foot: const Offset(106, 115), footB: const Offset(100, 115), hand: const Offset(66, 72), handB: const Offset(100, 90)),
  _K(0.97, hip: const Offset(84, 94), foot: const Offset(106, 115), footB: const Offset(100, 115), hand: const Offset(102, 90), handB: const Offset(98, 91)),
]);

// ---- Standing mobility --------------------------------------------------------

final _quadStretch = _rig([
  _K(0.0, hip: const Offset(116, 72), foot: const Offset(118, 115), footB: const Offset(110, 115), hand: const Offset(140, 62), handB: const Offset(140, 66)),
  _K(0.4, hip: const Offset(116, 72), foot: const Offset(104, 82), footB: const Offset(112, 115), hand: const Offset(112, 68), handB: const Offset(140, 66)),
  _K(0.76, hip: const Offset(116, 72), foot: const Offset(104, 82), footB: const Offset(112, 115), hand: const Offset(112, 68), handB: const Offset(140, 66)),
  _K(0.97, hip: const Offset(116, 72), foot: const Offset(118, 115), footB: const Offset(110, 115), hand: const Offset(140, 62), handB: const Offset(140, 66)),
]);

final _shoulderStretch = _rig([
  _K(0.0, hip: _stand, foot: _fl(124), footB: _fl(116), arm: const Offset(2, 30), armB: const Offset(0, 30)),
  _K(0.38, hip: _stand, foot: _fl(124), footB: _fl(116), arm: const Offset(26, 4), armB: const Offset(13, 8)),
  _K(0.76, hip: _stand, foot: _fl(124), footB: _fl(116), arm: const Offset(26, 4), armB: const Offset(13, 8)),
  _K(0.96, hip: _stand, foot: _fl(124), footB: _fl(116), arm: const Offset(2, 30), armB: const Offset(0, 30)),
]);

/// Seen face-on: a lean toward +x is a lean to the side.
final _sideBend = _rig([
  _K(0.0, hip: const Offset(116, 72), foot: _fl(124), footB: _fl(108), arm: const Offset(4, 30), armB: const Offset(-4, 30)),
  _K(0.38, hip: const Offset(110, 72), lean: 0.4, foot: _fl(124), footB: _fl(108), arm: const Offset(10, -30), armB: const Offset(-12, 16)),
  _K(0.76, hip: const Offset(110, 72), lean: 0.4, foot: _fl(124), footB: _fl(108), arm: const Offset(10, -30), armB: const Offset(-12, 16)),
  _K(0.96, hip: const Offset(116, 72), foot: _fl(124), footB: _fl(108), arm: const Offset(4, 30), armB: const Offset(-4, 30)),
]);

final _hipCircles = _rig([
  _K(0.0, hip: const Offset(127, 72), lean: -0.18, foot: _fl(124), footB: _fl(112), hand: const Offset(135, 66), handB: const Offset(125, 66)),
  _K(0.25, hip: const Offset(120, 70), lean: 0.0, foot: _fl(124), footB: _fl(112), hand: const Offset(128, 64), handB: const Offset(118, 64)),
  _K(0.5, hip: const Offset(113, 72), lean: 0.18, foot: _fl(124), footB: _fl(112), hand: const Offset(121, 66), handB: const Offset(111, 66)),
  _K(0.75, hip: const Offset(120, 70), lean: 0.0, foot: _fl(124), footB: _fl(112), hand: const Offset(128, 64), handB: const Offset(118, 64)),
]);

final _taiChi = _rig([
  _K(0.0, hip: _stand, foot: _fl(126), footB: _fl(112), arm: const Offset(2, 30), armB: const Offset(0, 30)),
  _K(0.3, hip: const Offset(120, 78), foot: _fl(130), footB: _fl(110), arm: const Offset(24, -6), armB: const Offset(22, -4)),
  _K(0.6, hip: const Offset(124, 78), lean: 0.05, foot: _fl(130), footB: _fl(110), arm: const Offset(30, -2), armB: const Offset(28, 0)),
  _K(0.85, hip: _stand, foot: _fl(126), footB: _fl(112), arm: const Offset(8, 22), armB: const Offset(6, 22)),
]);

final _sunSalutation = _rig([
  _K(0.0, hip: _stand, foot: _fl(124), footB: _fl(116), arm: const Offset(2, 30), armB: const Offset(0, 30)),
  _K(0.11, hip: _stand, lean: 0.0, foot: _fl(124), footB: _fl(116), arm: const Offset(28, 4), armB: const Offset(26, 6)),
  _K(0.22, hip: _stand, lean: -0.1, foot: _fl(124), footB: _fl(116), arm: const Offset(2, -32), armB: const Offset(0, -32)),
  _K(0.5, hip: const Offset(104, 72), lean: 2.3, foot: _fl(124), footB: _fl(116), hand: const Offset(140, _handFloorY), handB: const Offset(134, _handFloorY)),
  _K(0.66, hip: const Offset(104, 72), lean: 2.3, foot: _fl(124), footB: _fl(116), hand: const Offset(140, _handFloorY), handB: const Offset(134, _handFloorY)),
  _K(0.74, hip: const Offset(108, 72), lean: 1.1, foot: _fl(124), footB: _fl(116), arm: const Offset(28, 10), armB: const Offset(26, 12)),
  _K(0.86, hip: _stand, lean: -0.1, foot: _fl(124), footB: _fl(116), arm: const Offset(2, -32), armB: const Offset(0, -32)),
  _K(0.93, hip: _stand, lean: 0.0, foot: _fl(124), footB: _fl(116), arm: const Offset(28, 4), armB: const Offset(26, 6)),
]);
