/// Animated "how to do it" demonstrations, drawn in code like the rest of the
/// game art. A jointed figure (limb lengths are fixed, hands and feet stay
/// planted using two-bone IK) loops through each exercise with cues that
/// follow the movement.
library;

import 'dart:math' as math;
import 'dart:ui';

import '../art/painters.dart' show shade;
import '../look.dart';

/// Drawing space for every demo.
const double demoW = 240;
const double demoH = 140;
const double demoGround = 118;

// Limb lengths shared by every pose, so the figure never stretches.
const double armUpper = 17;
const double armLower = 16;
const double legThigh = 22;
const double legShin = 21;
const double torsoLen = 34;
const double headGap = 15;

/// Direction with 0 = straight down, positive = toward +x (forward).
Offset _dir(double a) => Offset(math.sin(a), math.cos(a));

/// Direction of the torso from hip to shoulder; [lean] is radians forward.
Offset _upDir(double lean) => Offset(math.sin(lean), -math.cos(lean));

double _lerp(double a, double b, double t) => a + (b - a) * t;
Offset _lerpO(Offset a, Offset b, double t) => Offset(_lerp(a.dx, b.dx, t), _lerp(a.dy, b.dy, t));
double _smooth(double t) {
  final x = t.clamp(0.0, 1.0);
  return x * x * (3 - 2 * x);
}

/// 0 -> 1 -> 0 over one loop: rise, brief hold at the top, fall.
double _cycle(double t, {double rise = 0.4, double hold = 0.1}) {
  final fall = 1 - rise - hold;
  if (t < rise) return _smooth(t / rise);
  if (t < rise + hold) return 1;
  return 1 - _smooth((t - rise - hold) / fall);
}

class _Limb {
  const _Limb(this.mid, this.end);
  final Offset mid;
  final Offset end;
}

/// Two-bone IK. [side] is +1 or -1 and picks which way the joint bends.
_Limb _ik(Offset root, Offset target, double l1, double l2, double side) {
  final d = target - root;
  final reach = d.distance.clamp((l1 - l2).abs() + 0.5, l1 + l2 - 0.01).toDouble();
  final base = math.atan2(d.dy, d.dx);
  final cosA = ((l1 * l1 + reach * reach - l2 * l2) / (2 * l1 * reach)).clamp(-1.0, 1.0);
  final a = math.acos(cosA);
  final mid = root + Offset.fromDirection(base + side * a, l1);
  final end = root + Offset.fromDirection(base, reach);
  return _Limb(mid, end);
}

/// All joints of the figure in drawing space.
class FigurePose {
  const FigurePose({
    required this.head,
    required this.shoulder,
    required this.hip,
    required this.elbowF,
    required this.handF,
    required this.elbowB,
    required this.handB,
    required this.kneeF,
    required this.ankleF,
    required this.kneeB,
    required this.ankleB,
  });

  final Offset head, shoulder, hip;
  final Offset elbowF, handF, elbowB, handB;
  final Offset kneeF, ankleF, kneeB, ankleB;

  List<Offset> get joints => [
        head, shoulder, hip, elbowF, handF, elbowB, handB, kneeF, ankleF, kneeB, ankleB,
      ];
}

/// Builds a pose from the torso and where the hands and feet should be.
FigurePose _build({
  required Offset hip,
  required Offset shoulder,
  required Offset ankleF,
  Offset? ankleB,
  required Offset handF,
  Offset? handB,
  double kneeSide = -1,
  double elbowSide = 1,
}) {
  final axis = (shoulder - hip);
  final head = shoulder + (axis / axis.distance) * headGap;
  final legF = _ik(hip, ankleF, legThigh, legShin, kneeSide);
  final legB = _ik(hip, ankleB ?? ankleF + const Offset(-7, 0), legThigh, legShin, kneeSide);
  final armF = _ik(shoulder, handF, armUpper, armLower, elbowSide);
  final armB = _ik(shoulder, handB ?? handF + const Offset(-3, 2), armUpper, armLower, elbowSide);
  return FigurePose(
    head: head,
    shoulder: shoulder,
    hip: hip,
    elbowF: armF.mid,
    handF: armF.end,
    elbowB: armB.mid,
    handB: armB.end,
    kneeF: legF.mid,
    ankleF: legF.end,
    kneeB: legB.mid,
    ankleB: legB.end,
  );
}

typedef PropPainter = void Function(Canvas canvas, FigurePose pose, double t);

class DemoConfig {
  const DemoConfig({
    required this.title,
    required this.cues,
    required this.pose,
    this.seconds = 3.6,
    this.back,
    this.front,
    this.note,
    this.keyTimes = const [0.0, 0.5],
  });

  /// Shown above the animation, e.g. "Push-Ups (Wall)".
  final String title;

  /// Phase captions, shown in order across one loop.
  final List<String> cues;
  final FigurePose Function(double t) pose;
  final double seconds;
  final PropPainter? back;
  final PropPainter? front;
  final String? note;

  /// Loop positions to show when animation is off (reduced motion).
  final List<double> keyTimes;

  String cueAt(double t) => cues[(t.clamp(0.0, 0.9999) * cues.length).floor()];
}

// ---------------------------------------------------------------------------
// Props
// ---------------------------------------------------------------------------

const _wood = Color(0xFF8D6E63);
const _steel = Color(0xFF90A4AE);
final Paint _p = Paint();

void _line(Canvas c, Offset a, Offset b, double w, Color col) {
  c.drawLine(
    a,
    b,
    Paint()
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..color = col,
  );
}

void _rect(Canvas c, double x, double y, double w, double h, Color col, [double r = 2]) {
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)), _p..color = col);
}

void _wall(Canvas c, double x) {
  _rect(c, x, 8, 12, demoGround - 8, const Color(0xFFBCAAA4), 1);
  for (var y = 14.0; y < demoGround; y += 12) {
    _line(c, Offset(x + 2, y), Offset(x + 10, y), 1, const Color(0x33000000));
  }
}

void _bench(Canvas c, double x, double w, double topY) {
  _rect(c, x, topY, w, 6, _wood, 2);
  _rect(c, x + 4, topY + 6, 5, demoGround - topY - 6, const Color(0xFF6D4C41), 1);
  _rect(c, x + w - 9, topY + 6, 5, demoGround - topY - 6, const Color(0xFF6D4C41), 1);
}

void _dumbbell(Canvas c, Offset at, {double tilt = 0}) {
  c.save();
  c.translate(at.dx, at.dy);
  c.rotate(tilt);
  _rect(c, -6, -1.6, 12, 3.2, _steel, 1);
  _rect(c, -9, -5, 4, 10, const Color(0xFF455A64), 1.5);
  _rect(c, 5, -5, 4, 10, const Color(0xFF455A64), 1.5);
  c.restore();
}

void _barbell(Canvas c, Offset at) {
  _line(c, at + const Offset(-4, 0), at + const Offset(4, 0), 3, _steel);
  c.drawCircle(at + const Offset(0, 0), 11, _p..color = const Color(0xFF37474F));
  c.drawCircle(at + const Offset(0, 0), 7, _p..color = const Color(0xFF546E7A));
  c.drawCircle(at + const Offset(0, 0), 2.2, _p..color = _steel);
}

void _chair(Canvas c, double x, double seatY) {
  _rect(c, x, seatY, 34, 5, _wood, 2);
  _rect(c, x, seatY - 34, 5, 34, _wood, 2);
  _rect(c, x + 2, seatY + 5, 4, demoGround - seatY - 5, const Color(0xFF6D4C41), 1);
  _rect(c, x + 28, seatY + 5, 4, demoGround - seatY - 5, const Color(0xFF6D4C41), 1);
}

void _mat(Canvas c, double x, double w) {
  _rect(c, x, demoGround - 3, w, 5, const Color(0xFF26A69A), 2);
}

/// Dashes that slide past so a figure moving in place reads as travelling.
void _treadmill(Canvas c, double t, double speed) {
  for (var i = 0; i < 12; i++) {
    final x = ((i * 24.0) - (t * speed * 24 * 12)) % (demoW + 24) - 12;
    _rect(c, x, demoGround + 5, 12, 2.5, const Color(0x44000000), 1);
  }
}

// ---------------------------------------------------------------------------
// Poses
// ---------------------------------------------------------------------------

/// Hands planted, feet (or knees) planted, body a rigid plank that tips.
FigurePose _plankFamily({
  required Offset pivot,
  required double angle,
  required Offset hand,
  bool kneeling = false,
}) {
  final along = Offset(math.cos(angle), -math.sin(angle));
  if (kneeling) {
    final hip = pivot + along * legThigh;
    final shoulder = hip + along * torsoLen;
    final ankle = pivot + const Offset(-20.3, -5.4);
    return _build(
      hip: hip,
      shoulder: shoulder,
      ankleF: ankle,
      ankleB: ankle + const Offset(-2, 1),
      handF: hand,
      handB: hand + const Offset(-4, 0),
    ).withLegs(kneeF: pivot, kneeB: pivot, ankleF: ankle, ankleB: ankle);
  }
  final hip = pivot + along * (legThigh + legShin);
  final shoulder = hip + along * torsoLen;
  return _build(
    hip: hip,
    shoulder: shoulder,
    ankleF: pivot,
    ankleB: pivot + const Offset(-4, 0),
    handF: hand,
    handB: hand + const Offset(-4, 0),
  );
}

extension on FigurePose {
  FigurePose withLegs({
    required Offset kneeF,
    required Offset kneeB,
    required Offset ankleF,
    required Offset ankleB,
  }) =>
      FigurePose(
        head: head,
        shoulder: shoulder,
        hip: hip,
        elbowF: elbowF,
        handF: handF,
        elbowB: elbowB,
        handB: handB,
        kneeF: kneeF,
        ankleF: ankleF,
        kneeB: kneeB,
        ankleB: ankleB,
      );
}

FigurePose _pushUp(double t) {
  final u = _cycle(t);
  const hand = Offset(101, 116);
  final angle = _lerp(23, 7, u) * math.pi / 180;
  return _plankFamily(pivot: const Offset(30, 115), angle: angle, hand: hand);
}

FigurePose _kneePushUp(double t) {
  final u = _cycle(t);
  const hand = Offset(118, 116);
  final angle = _lerp(31, 10, u) * math.pi / 180;
  return _plankFamily(pivot: const Offset(70, 115), angle: angle, hand: hand, kneeling: true);
}

FigurePose _inclinePushUp(double t) {
  final u = _cycle(t);
  const hand = Offset(87, 96);
  final angle = _lerp(42.5, 24, u) * math.pi / 180;
  return _plankFamily(pivot: const Offset(30, 115), angle: angle, hand: hand);
}

FigurePose _wallPushUp(double t) {
  final u = _cycle(t);
  final phi = _lerp(22, 40, u) * math.pi / 180; // lean toward the wall
  const feet = Offset(112, 115);
  final along = Offset(math.sin(phi), -math.cos(phi));
  final hip = feet + along * (legThigh + legShin);
  final shoulder = hip + along * torsoLen;
  return _build(
    hip: hip,
    shoulder: shoulder,
    ankleF: feet,
    ankleB: feet + const Offset(-4, 0),
    handF: const Offset(168, 52),
    handB: const Offset(168, 56),
  );
}

FigurePose _plank(double t, {required bool knees, required bool forearms}) {
  final breathe = math.sin(t * 2 * math.pi) * 0.012;
  final hand = forearms ? const Offset(122, 115) : const Offset(104, 116);
  if (knees) {
    return _plankFamily(
      pivot: const Offset(66, 115),
      angle: (forearms ? 0.30 : 0.50) + breathe,
      hand: forearms ? const Offset(112, 115) : const Offset(106, 116),
      kneeling: true,
    );
  }
  return _plankFamily(
    pivot: const Offset(30, 115),
    angle: (forearms ? 0.25 : 0.40) + breathe,
    hand: hand,
  );
}

FigurePose _wallPlank(double t) {
  final breathe = math.sin(t * 2 * math.pi) * 0.012;
  final phi = 0.5 + breathe;
  const feet = Offset(106, 115);
  final along = Offset(math.sin(phi), -math.cos(phi));
  final hip = feet + along * (legThigh + legShin);
  final shoulder = hip + along * torsoLen;
  return _build(
    hip: hip,
    shoulder: shoulder,
    ankleF: feet,
    ankleB: feet + const Offset(-4, 0),
    handF: const Offset(168, 56),
    handB: const Offset(168, 60),
  );
}

FigurePose _squat(double t, {bool chair = false, bool bar = false}) {
  final u = _cycle(t, rise: 0.42, hold: 0.08);
  final hip = chair
      ? _lerpO(const Offset(120, 71), const Offset(88, 97), u)
      : _lerpO(const Offset(120, 71), const Offset(94, 99), u);
  final lean = _lerp(0.02, chair ? 0.55 : 0.68, u);
  final shoulder = hip + _upDir(lean) * torsoLen;
  const ankleF = Offset(122, 115);
  const ankleB = Offset(114, 115);
  final Offset hand;
  if (bar) {
    hand = shoulder + const Offset(3, -6);
  } else if (chair) {
    hand = shoulder + Offset(_lerp(8, 14, u), _lerp(12, 8, u));
  } else {
    hand = shoulder + Offset(_lerp(10, 31, u), _lerp(14, 2, u));
  }
  return _build(
    hip: hip,
    shoulder: shoulder,
    ankleF: ankleF,
    ankleB: ankleB,
    handF: hand,
    handB: hand + const Offset(-2, 1),
    elbowSide: bar ? -1 : 1,
  );
}

FigurePose _sitUp(double t, {required double maxDeg}) {
  final u = _cycle(t, rise: 0.42, hold: 0.06);
  final a = _lerp(6, maxDeg, u) * math.pi / 180;
  const hip = Offset(128, 109);
  final shoulder = hip + Offset(-math.cos(a), -math.sin(a)) * torsoLen;
  final axis = Offset(-math.cos(a), -math.sin(a));
  final head = shoulder + axis * headGap;
  final hands = head + const Offset(-3, 5);
  final legF = _ik(hip, const Offset(158, 114), legThigh, legShin, -1);
  final legB = _ik(hip, const Offset(150, 114), legThigh, legShin, -1);
  final armF = _ik(shoulder, hands, armUpper, armLower, -1);
  final armB = _ik(shoulder, hands + const Offset(3, 2), armUpper, armLower, -1);
  return FigurePose(
    head: head,
    shoulder: shoulder,
    hip: hip,
    elbowF: armF.mid,
    handF: armF.end,
    elbowB: armB.mid,
    handB: armB.end,
    kneeF: legF.mid,
    ankleF: legF.end,
    kneeB: legB.mid,
    ankleB: legB.end,
  );
}

/// Walking and running cycle: leg swing, knee bend and arm swing, with the hip
/// height solved each frame so the lowest foot is always on the ground.
FigurePose _gait(
  double t, {
  required double swing,
  required double kneeFlex,
  required double armSwing,
  required double elbowBend,
  required double lean,
  double flight = 0,
}) {
  final ph = t * 2 * math.pi;
  ({Offset knee, Offset ankle, double drop}) leg(double phase, Offset hip) {
    final a = swing * math.sin(ph + phase);
    final swingingForward = math.cos(ph + phase) > 0;
    final flex = 0.12 + (swingingForward ? kneeFlex * math.cos(ph + phase) : 0.0);
    final b = a - flex;
    final knee = hip + _dir(a) * legThigh;
    final ankle = knee + _dir(b) * legShin;
    return (knee: knee, ankle: ankle, drop: legThigh * math.cos(a) + legShin * math.cos(b));
  }

  var hip = const Offset(120, 0);
  final lf = leg(0, hip);
  final lb = leg(math.pi, hip);
  final lowest = math.max(lf.drop, lb.drop);
  final bounce = flight * math.sin(ph * 2).abs();
  hip = Offset(120, demoGround - 3 - lowest - bounce);
  final f = leg(0, hip);
  final b = leg(math.pi, hip);

  final shoulder = hip + _upDir(lean) * torsoLen;
  final head = shoulder + _upDir(lean) * headGap;
  Offset arm(double phase, bool elbowOnly) {
    final upper = -armSwing * math.sin(ph + phase);
    final elbow = shoulder + _dir(upper) * armUpper;
    if (elbowOnly) return elbow;
    final fore = upper + elbowBend;
    return elbow + _dir(fore) * armLower;
  }

  return FigurePose(
    head: head,
    shoulder: shoulder,
    hip: hip,
    elbowF: arm(0, true),
    handF: arm(0, false),
    elbowB: arm(math.pi, true),
    handB: arm(math.pi, false),
    kneeF: f.knee,
    ankleF: f.ankle,
    kneeB: b.knee,
    ankleB: b.ankle,
  );
}

FigurePose _dumbbellRow(double t) {
  final u = _cycle(t, rise: 0.4, hold: 0.1);
  const hip = Offset(98, 76);
  final shoulder = hip + _upDir(1.0) * torsoLen;
  final handF = _lerpO(shoulder + const Offset(2, 31), Offset(hip.dx + 8, hip.dy - 12), u);
  return _build(
    hip: hip,
    shoulder: shoulder,
    ankleF: const Offset(94, 115),
    ankleB: const Offset(106, 115),
    handF: handF,
    handB: const Offset(142, 88),
    elbowSide: 1,
  );
}

FigurePose _shoulderPress(double t) {
  final u = _cycle(t, rise: 0.4, hold: 0.1);
  const hip = Offset(112, 71);
  final shoulder = hip + _upDir(0.0) * torsoLen;
  final hand = _lerpO(shoulder + const Offset(6, -3), shoulder + const Offset(3, -33), u);
  return _build(
    hip: hip,
    shoulder: shoulder,
    ankleF: const Offset(114, 115),
    ankleB: const Offset(106, 115),
    handF: hand,
    handB: hand + const Offset(-2, 1),
    elbowSide: 1,
  );
}

FigurePose _forwardFold(double t) {
  // Reach up tall, fold forward, hang, roll back up.
  double lean;
  if (t < 0.18) {
    lean = 0;
  } else if (t < 0.5) {
    lean = _smooth((t - 0.18) / 0.32);
  } else if (t < 0.68) {
    lean = 1;
  } else if (t < 0.95) {
    lean = 1 - _smooth((t - 0.68) / 0.27);
  } else {
    lean = 0;
  }
  final hip = Offset(_lerp(120, 106, lean), 71);
  final shoulder = hip + _upDir(lean * 1.4) * torsoLen;
  // Sweep the arms from overhead, forward, to hanging so the elbow never flips.
  final sweep = math.pi * (1 - _smooth(lean));
  final hand = shoulder + _dir(sweep) * (armUpper + armLower - 1);
  return _build(
    hip: hip,
    shoulder: shoulder,
    ankleF: const Offset(120, 115),
    ankleB: const Offset(112, 115),
    handF: hand,
    handB: hand + const Offset(-2, 1),
    elbowSide: 1,
  );
}

FigurePose _armCircles(double t) {
  const hip = Offset(120, 71);
  final shoulder = hip + _upDir(0) * torsoLen;
  final sway = math.sin(t * 2 * math.pi * 2) * 1.2;
  FigurePose base = _build(
    hip: hip + Offset(0, sway.abs()),
    shoulder: shoulder + Offset(0, sway.abs()),
    ankleF: const Offset(122, 115),
    ankleB: const Offset(114, 115),
    handF: shoulder,
  );
  final s = base.shoulder;
  final a = t * 2 * math.pi * 2;
  Offset elbowAt(double ang) => s + _dir(ang) * armUpper;
  Offset handAt(double ang) => s + _dir(ang) * (armUpper + armLower);
  return FigurePose(
    head: base.head,
    shoulder: s,
    hip: base.hip,
    elbowF: elbowAt(a),
    handF: handAt(a),
    elbowB: elbowAt(a + 0.35),
    handB: handAt(a + 0.35),
    kneeF: base.kneeF,
    ankleF: base.ankleF,
    kneeB: base.kneeB,
    ankleB: base.ankleB,
  );
}

// ---------------------------------------------------------------------------
// Catalogue
// ---------------------------------------------------------------------------

/// The demonstration for an activity and variant, or null if there isn't one.
DemoConfig? demoFor(String activityId, [String? variant]) {
  switch (activityId) {
    case 'push_up':
      switch (variant) {
        case 'Wall':
          return DemoConfig(
            title: 'Push-Ups (Wall)',
            cues: const [
              'Stand an arm\'s length from the wall, hands at shoulder height.',
              'Bend your elbows and lean in, keeping your body in one line.',
              'Push back to the start. Breathe out as you push.',
            ],
            note: 'The gentlest version. Step closer or further away to change the effort.',
            pose: _wallPushUp,
            back: (c, p, t) => _wall(c, 168),
          );
        case 'Incline':
          return DemoConfig(
            title: 'Push-Ups (Incline)',
            cues: const [
              'Hands on a sturdy bench or counter, body in one straight line.',
              'Lower your chest toward the edge, elbows about 45° from your body.',
              'Press back up. Breathe out as you push.',
            ],
            note: 'A higher surface makes it easier. Lower it as you get stronger.',
            pose: _inclinePushUp,
            back: (c, p, t) => _bench(c, 80, 70, 96),
          );
        case 'Knee':
          return DemoConfig(
            title: 'Push-Ups (Knees)',
            cues: const [
              'Hands under your shoulders, knees on the floor, body in one line.',
              'Lower your chest slowly, elbows about 45° from your body.',
              'Press back up. Breathe out as you push.',
            ],
            note: 'Pad your knees with a folded towel if the floor is hard.',
            pose: _kneePushUp,
            back: (c, p, t) => _mat(c, 30, 130),
          );
        default:
          return DemoConfig(
            title: 'Push-Ups',
            cues: const [
              'Hands under your shoulders, body in one straight line.',
              'Lower your chest slowly, elbows about 45° from your body.',
              'Press back up. Breathe out as you push.',
            ],
            note: 'Too hard? Try the Wall, Incline or Knee version. They earn the same.',
            pose: _pushUp,
            back: (c, p, t) => _mat(c, 20, 150),
          );
      }
    case 'squat':
      if (variant == 'Sit-to-Stand (Chair)') {
        return DemoConfig(
          title: 'Squats (Sit-to-Stand)',
          cues: const [
            'Stand in front of a sturdy chair, feet about shoulder-width apart.',
            'Push your hips back and sit down slowly with control.',
            'Press through your feet and stand tall. Breathe out as you rise.',
          ],
          note: 'A great starting point. Use the chair arms or your hands for help if needed.',
          pose: (t) => _squat(t, chair: true),
          back: (c, p, t) => _chair(c, 64, 98),
        );
      }
      return DemoConfig(
        title: 'Squats',
        cues: const [
          'Feet about shoulder-width apart, chest up, arms forward.',
          'Push your hips back and bend your knees, tracking over your toes.',
          'Press through your feet and stand tall. Breathe out as you rise.',
        ],
        note: 'Only go as low as feels comfortable.',
        pose: _squat,
      );
    case 'sit_up':
      final small = variant == 'Small Crunch';
      return DemoConfig(
        title: small ? 'Crunches (Small)' : 'Sit-Ups',
        cues: [
          'Lie on your back, knees bent, hands lightly behind your head.',
          small
              ? 'Curl your shoulders up a little. Keep your neck relaxed.'
              : 'Curl up slowly, leading with your chest, not your neck.',
          'Lower back down with control. Breathe out as you come up.',
        ],
        note: 'Small movements count. Don\'t pull on your head.',
        pose: (t) => _sitUp(t, maxDeg: small ? 30 : 72),
        back: (c, p, t) => _mat(c, 40, 150),
      );
    case 'plank':
      final forearm = variant == 'Forearm';
      final knee = variant == 'Knee';
      final wall = variant == 'Wall';
      return DemoConfig(
        title: 'Plank (${variant ?? 'Standard'})'.replaceAll(' (Standard)', ''),
        cues: [
          wall
              ? 'Stand a step from the wall and lean in, hands at shoulder height.'
              : forearm
                  ? 'Elbows under your shoulders, body in one straight line.'
                  : 'Hands under your shoulders, body in one straight line.',
          'Gently tighten your belly. Keep your hips from sagging or lifting.',
          'Hold steady and breathe normally. Stop if your back aches.',
        ],
        note: 'Hold for as long as feels good, then rest. Shorter holds count too.',
        seconds: 4.4,
        pose: wall ? _wallPlank : (t) => _plank(t, knees: knee, forearms: forearm || knee),
        back: wall ? (c, p, t) => _wall(c, 168) : (c, p, t) => _mat(c, 16, 150),
        keyTimes: const [0.0, 0.25],
      );
    case 'walking':
      return DemoConfig(
        title: 'Walking',
        cues: const [
          'Stand tall and look ahead, shoulders relaxed.',
          'Take easy steps, rolling heel to toe, arms swinging gently.',
          'Pick a pace where you could still hold a conversation.',
        ],
        seconds: 1.8,
        pose: (t) => _gait(t, swing: 0.45, kneeFlex: 0.7, armSwing: 0.4, elbowBend: 0.35, lean: 0.03),
        back: (c, p, t) => _treadmill(c, t, 1.0),
        keyTimes: const [0.0, 0.25],
      );
    case 'running':
      return DemoConfig(
        title: 'Running / Jogging',
        cues: const [
          'Lean slightly forward from your ankles, shoulders relaxed.',
          'Quick, light steps with elbows bent and arms swinging.',
          'Slow down or walk whenever you need to. Walk/jog intervals count.',
        ],
        seconds: 1.1,
        pose: (t) => _gait(t, swing: 0.7, kneeFlex: 1.35, armSwing: 0.6, elbowBend: 1.2, lean: 0.16, flight: 5),
        back: (c, p, t) => _treadmill(c, t, 2.4),
        keyTimes: const [0.0, 0.25],
      );
    case 'dumbbell_row':
      return DemoConfig(
        title: 'Dumbbell Row',
        cues: const [
          'Hinge forward with a flat back, one hand braced on a bench.',
          'Pull the weight toward your hip, elbow close to your body.',
          'Lower slowly. Start with a light weight.',
        ],
        note: 'Use a bottle of water if you don\'t have a dumbbell yet.',
        pose: _dumbbellRow,
        back: (c, p, t) => _bench(c, 128, 44, 88),
        front: (c, p, t) => _dumbbell(c, p.handF),
      );
    case 'dumbbell_press':
      return DemoConfig(
        title: 'Dumbbell Shoulder Press',
        cues: const [
          'Stand tall, weights at shoulder height, belly gently tight.',
          'Press up until your arms are straight overhead. Breathe out.',
          'Lower slowly back to your shoulders. Start light.',
        ],
        pose: _shoulderPress,
        front: (c, p, t) {
          _dumbbell(c, p.handB, tilt: math.pi / 2);
          _dumbbell(c, p.handF, tilt: math.pi / 2);
        },
      );
    case 'barbell_squat':
      return DemoConfig(
        title: 'Barbell Squat',
        cues: const [
          'Bar across your upper back, feet shoulder-width apart, chest up.',
          'Push your hips back and bend your knees to a comfortable depth.',
          'Stand tall. Use a safety rack or spotter, and learn the move unloaded first.',
        ],
        pose: (t) => _squat(t, bar: true),
        front: (c, p, t) => _barbell(c, p.shoulder + const Offset(-3, -5)),
      );
    case 'stretching':
      return DemoConfig(
        title: 'Stretching',
        cues: const [
          'Reach up tall and take a slow breath in.',
          'Fold forward gently with soft knees. A mild pull is enough.',
          'Let your arms hang, then roll up slowly, one bone at a time.',
        ],
        note: 'Never bounce or push into pain.',
        seconds: 6,
        pose: _forwardFold,
        keyTimes: const [0.0, 0.58],
      );
    case 'light_mobility':
      return DemoConfig(
        title: 'Light Mobility',
        cues: const [
          'Stand relaxed with a soft bend in your knees.',
          'Make slow, easy arm circles, forwards then backwards.',
          'Keep it gentle. Stop if anything hurts.',
        ],
        seconds: 4,
        pose: _armCircles,
        keyTimes: const [0.0, 0.25],
      );
  }
  return null;
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

/// Draws [config] at loop position [t] in the 240 x 140 demo space.
void paintDemo(Canvas canvas, DemoConfig config, double t, HeroLook look) {
  final pose = config.pose(t);

  // Backdrop and floor.
  _rect(canvas, 0, 0, demoW, demoH, const Color(0xFFF4EBDD), 0);
  _rect(canvas, 0, demoGround, demoW, demoH - demoGround, const Color(0xFFD7C3A5), 0);
  _line(canvas, const Offset(0, demoGround), const Offset(demoW, demoGround), 2, const Color(0xFFB59C78));
  config.back?.call(canvas, pose, t);

  final trousers = const Color(0xFF5D4037);
  final boots = const Color(0xFF3E2723);
  final skin = look.skinColor;
  final tunic = look.tunic;

  void leg(Offset hip, Offset knee, Offset ankle, Color c, Color bootC) {
    _line(canvas, hip, knee, 8, c);
    _line(canvas, knee, ankle, 7, c);
    _line(canvas, ankle, ankle + const Offset(8, 1.5), 5, bootC);
  }

  void arm(Offset shoulder, Offset elbow, Offset hand, Color sleeve, Color skinC) {
    _line(canvas, shoulder, elbow, 6.5, sleeve);
    _line(canvas, elbow, hand, 5.5, skinC);
    canvas.drawCircle(hand, 3.2, _p..color = skinC);
  }

  // Back limbs first.
  leg(pose.hip, pose.kneeB, pose.ankleB, shade(trousers, -0.08), shade(boots, -0.04));
  arm(pose.shoulder, pose.elbowB, pose.handB, shade(tunic, -0.12), shade(skin, -0.08));

  // Torso with a belt.
  _line(canvas, pose.hip, pose.shoulder, 15, tunic);
  final belt = _lerpO(pose.hip, pose.shoulder, 0.12);
  canvas.drawCircle(belt, 3.4, _p..color = const Color(0xFFF2C94C));

  // Front limbs.
  leg(pose.hip, pose.kneeF, pose.ankleF, trousers, boots);
  arm(pose.shoulder, pose.elbowF, pose.handF, tunic, skin);

  // Head: hair behind, face in front.
  canvas.drawCircle(pose.head + const Offset(-1.5, -1.5), 9.8, _p..color = look.hairColor);
  canvas.drawCircle(pose.head + const Offset(1.2, 0.8), 8.2, _p..color = skin);
  canvas.drawCircle(pose.head + const Offset(4.2, -0.4), 1.2, _p..color = const Color(0xFF2B1D14));

  config.front?.call(canvas, pose, t);
}
