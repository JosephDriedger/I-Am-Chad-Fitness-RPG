/// Body pose types and geometry, independent of any camera or ML library.
///
/// The camera layer turns whatever the pose detector returns into a
/// [BodyPose]; everything after that (angles, rep counting) is pure Dart and
/// unit tested with synthetic poses.
library;

import 'dart:math' as math;

/// The joints the rep counter cares about.
enum Joint {
  nose,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

/// Three joints in a row, such as shoulder-elbow-wrist; the angle is measured
/// at [mid].
typedef JointTriple = ({Joint a, Joint mid, Joint c});

/// A detected joint. Coordinates are pixels in the upright camera frame;
/// [confidence] is 0 to 1.
class JointPoint {
  const JointPoint(this.x, this.y, {this.confidence = 1});

  final double x;
  final double y;
  final double confidence;
}

/// One frame's pose. [width] and [height] are the size of the upright frame
/// the points are measured in, so angles are never distorted by aspect ratio.
class BodyPose {
  const BodyPose({required this.width, required this.height, required this.joints});

  final double width;
  final double height;
  final Map<Joint, JointPoint> joints;

  JointPoint? operator [](Joint j) => joints[j];

  /// How many of the main body joints (shoulders, elbows, wrists, hips,
  /// knees and ankles) are visible with at least [minConfidence].
  int visibleMainJoints({double minConfidence = 0.5}) {
    var n = 0;
    for (final j in Joint.values) {
      if (j == Joint.nose) continue;
      final p = joints[j];
      if (p != null && p.confidence >= minConfidence) n++;
    }
    return n;
  }

  /// The angle in degrees (0 to 180) at [b] between the lines to [a] and [c].
  static double angleAt(JointPoint a, JointPoint b, JointPoint c) {
    final v1x = a.x - b.x, v1y = a.y - b.y;
    final v2x = c.x - b.x, v2y = c.y - b.y;
    final len = math.sqrt(v1x * v1x + v1y * v1y) * math.sqrt(v2x * v2x + v2y * v2y);
    if (len == 0) return 180;
    final cos = ((v1x * v2x + v1y * v2y) / len).clamp(-1.0, 1.0);
    return math.acos(cos) * 180 / math.pi;
  }

  /// The angle at [mid] on the better-seen side of the body (left or right),
  /// or null if neither side has all three joints at [minConfidence]. A phone
  /// set up side-on sees one side clearly, so this picks that one.
  double? limbAngle(
    JointTriple left,
    JointTriple right, {
    double minConfidence = 0.5,
  }) {
    double? best;
    double bestConf = minConfidence;
    for (final side in [left, right]) {
      final a = joints[side.a], m = joints[side.mid], c = joints[side.c];
      if (a == null || m == null || c == null) continue;
      final conf = math.min(a.confidence, math.min(m.confidence, c.confidence));
      if (conf >= bestConf) {
        bestConf = conf;
        best = angleAt(a, m, c);
      }
    }
    return best;
  }
}
