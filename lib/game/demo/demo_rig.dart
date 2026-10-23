part of 'exercise_demo.dart';

// A small keyframe rig for the bigger exercise catalog.
//
// Each keyframe says where the torso, hands and feet should be at one moment of
// the loop. Between keyframes the targets are blended, then solved with the
// same two-bone IK as every other demo, so limb lengths never change and
// every demo passes the same physical checks.

/// Ankle height when a foot is flat on the floor.
const double _floorY = 115;

/// Hand height when a palm is flat on the floor.
const double _handFloorY = 116;

class _K {
  const _K(
    this.t, {
    required this.hip,
    this.lean = 0,
    required this.foot,
    this.footB,
    this.hand,
    this.handB,
    this.arm,
    this.armB,
  });

  /// Where in the loop (0 to 1) this key applies.
  final double t;

  /// Hip position.
  final Offset hip;

  /// Torso angle from vertical in radians, positive leaning toward +x.
  final double lean;

  /// Front and back foot (ankle) targets. The back foot defaults to just
  /// behind the front one.
  final Offset foot;
  final Offset? footB;

  /// Hand targets in the drawing, or [arm] and [armB] relative to the
  /// shoulder (handy for arms that move with the body).
  final Offset? hand;
  final Offset? handB;
  final Offset? arm;
  final Offset? armB;
}

/// A key resolved to absolute positions.
class _Resolved {
  const _Resolved(this.hip, this.lean, this.footF, this.footB, this.handF, this.handB);

  final Offset hip;
  final double lean;
  final Offset footF, footB, handF, handB;
}

_Resolved _resolve(_K k) {
  final shoulder = k.hip + _upDir(k.lean) * torsoLen;
  final handF = k.hand ?? shoulder + (k.arm ?? const Offset(2, 30));
  final handB = k.handB ?? (k.armB != null ? shoulder + k.armB! : handF + const Offset(-2, 1));
  return _Resolved(k.hip, k.lean, k.foot, k.footB ?? k.foot + const Offset(-7, 0), handF, handB);
}

/// Builds a pose function from keyframes. The loop closes itself: the first
/// key repeats at t = 1.
///
/// [kneeSide] -1 bends knees toward +x (the way the figure faces); +1 bends
/// them the other way. [elbowSide] +1 points elbows back, -1 forward.
FigurePose Function(double) _rig(
  List<_K> keys, {
  double kneeSide = -1,
  double? kneeSideB,
  double elbowSide = 1,
  double? elbowSideB,
}) {
  final sorted = [...keys]..sort((a, b) => a.t.compareTo(b.t));
  final times = [for (final k in sorted) k.t, 1.0];
  final all = [for (final k in sorted) _resolve(k), _resolve(sorted.first)];
  return (double t) {
    final x = t.clamp(0.0, 1.0);
    var i = 0;
    while (i < times.length - 2 && x >= times[i + 1]) {
      i++;
    }
    final span = times[i + 1] - times[i];
    final u = span <= 0 ? 0.0 : _smooth((x - times[i]) / span);
    final a = all[i], b = all[i + 1];
    final hip = _lerpO(a.hip, b.hip, u);
    final shoulder = hip + _upDir(_lerp(a.lean, b.lean, u)) * torsoLen;
    return _build(
      hip: hip,
      shoulder: shoulder,
      ankleF: _lerpO(a.footF, b.footF, u),
      ankleB: _lerpO(a.footB, b.footB, u),
      handF: _lerpO(a.handF, b.handF, u),
      handB: _lerpO(a.handB, b.handB, u),
      kneeSide: kneeSide,
      kneeSideB: kneeSideB,
      elbowSide: elbowSide,
      elbowSideB: elbowSideB,
    );
  };
}
