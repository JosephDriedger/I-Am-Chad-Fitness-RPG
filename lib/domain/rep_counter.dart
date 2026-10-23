/// Counts reps from a stream of body poses. Pure Dart, no camera or ML.
///
/// A rep is one full trip: reach the top position, go down far enough, and
/// come back up. "Far enough" is deliberately forgiving, and more so for
/// people who are just starting out: the aim is to confirm the player really
/// did the movement, not to grade it. It counts and gives generic cues only;
/// it never judges form. See docs/ROADMAP.md ("Camera rep checking").
library;

import 'hero.dart';
import 'pose.dart';

/// How forgiving the counting is.
enum RepLeniency {
  /// Very forgiving: small range of motion counts, and extra slack on slow or
  /// wobbly reps. For people who are just starting.
  beginner,

  /// Forgiving. The default for people easing back in.
  gentle,

  /// Closer to a full range of motion, for people who already train.
  standard;

  static RepLeniency forExperience(ExperienceLevel level) => switch (level) {
        ExperienceLevel.starting => RepLeniency.beginner,
        ExperienceLevel.returning => RepLeniency.gentle,
        ExperienceLevel.regular => RepLeniency.standard,
      };
}


/// What to watch for one exercise: which joint angle, and how far it has to
/// travel to count.
class RepProfile {
  const RepProfile({
    required this.activityId,
    required this.left,
    required this.right,
    required this.bottomAngle,
    required this.topAngle,
    required this.minRepMillis,
  });

  /// Exercises the camera can count.
  static const supported = {'push_up', 'squat'};

  static bool supports(String activityId) => supported.contains(activityId);

  final String activityId;

  /// The joint triples (shoulder-elbow-wrist, or hip-knee-ankle) per side.
  final JointTriple left;
  final JointTriple right;

  /// The angle must get at or below this to count as "down".
  final double bottomAngle;

  /// The angle must get at or above this to count as "up" again.
  final double topAngle;

  /// Reps closer together than this are treated as tracking jitter.
  final int minRepMillis;

  /// Minimum gap kept between [bottomAngle] and [topAngle].
  static const _minRange = 25.0;

  /// Null for exercises the camera cannot count.
  static RepProfile? forActivity(
    String activityId, {
    String? variant,
    RepLeniency leniency = RepLeniency.gentle,
  }) {
    switch (activityId) {
      case 'push_up':
        // Easier versions bend the elbow less, so they need less depth.
        final extra = switch (variant) { 'Wall' => 12.0, 'Incline' => 6.0, _ => 0.0 };
        final (bottom, top) = switch (leniency) {
          RepLeniency.standard => (100.0, 155.0),
          RepLeniency.gentle => (115.0, 148.0),
          RepLeniency.beginner => (125.0, 150.0),
        };
        return _build(
          activityId,
          left: (a: Joint.leftShoulder, mid: Joint.leftElbow, c: Joint.leftWrist),
          right: (a: Joint.rightShoulder, mid: Joint.rightElbow, c: Joint.rightWrist),
          bottom: bottom + extra,
          top: top,
          minRepMillis: 600,
        );
      case 'squat':
        final (bottom, top) = switch (leniency) {
          RepLeniency.standard => (100.0, 160.0),
          RepLeniency.gentle => (120.0, 152.0),
          RepLeniency.beginner => (130.0, 155.0),
        };
        return _build(
          activityId,
          left: (a: Joint.leftHip, mid: Joint.leftKnee, c: Joint.leftAnkle),
          right: (a: Joint.rightHip, mid: Joint.rightKnee, c: Joint.rightAnkle),
          bottom: bottom,
          top: top,
          minRepMillis: 800,
        );
    }
    return null;
  }

  static RepProfile _build(
    String id, {
    required JointTriple left,
    required JointTriple right,
    required double bottom,
    required double top,
    required int minRepMillis,
  }) {
    final fixedTop = (top < bottom + _minRange ? bottom + _minRange : top).clamp(0.0, 172.0);
    return RepProfile(
      activityId: id,
      left: left,
      right: right,
      bottomAngle: bottom,
      topAngle: fixedTop,
      minRepMillis: minRepMillis,
    );
  }

  /// 0 at the top position, 1 once the angle reaches the counting depth.
  double depthFor(double angle) =>
      ((topAngle - angle) / (topAngle - bottomAngle)).clamp(0.0, 1.0);
}

enum RepPhase {
  /// Not seeing enough of the body.
  searching,

  /// Seen, waiting for the player to reach the start position.
  getReady,

  /// At the top, ready for the next rep.
  ready,

  /// Down at or past the counting depth.
  down,
}

/// A generic hint to show the player. Never a form judgement.
enum RepCue {
  none,
  showWholeBody,
  getInPosition,

  /// They turned back about halfway: a little further would count.
  goLower,

  /// Two reps came too close together to be told apart.
  steady,
}

class RepUpdate {
  const RepUpdate({
    required this.count,
    required this.phase,
    required this.cue,
    required this.depth,
    required this.counted,
    this.angle,
  });

  final int count;
  final RepPhase phase;
  final RepCue cue;

  /// 0 to 1, how close to counting depth (1 means deep enough).
  final double depth;

  /// True only on the frame a rep was added.
  final bool counted;

  /// The smoothed joint angle in degrees, if the body is tracked.
  final double? angle;
}

class RepCounter {
  RepCounter(this.profile);

  final RepProfile profile;

  /// How long the body can disappear before the phase says "searching".
  static const lostAfterMillis = 900;

  /// How long before an interrupted rep is forgotten and the player must
  /// get back to the start position.
  static const forgetAfterMillis = 3000;

  static const _cueHoldMillis = 2200;
  static const _cueCooldownMillis = 3000;

  /// How far (0 to 1) toward the counting depth a turn-around has to get
  /// before the "a little lower" hint appears.
  static const _nearMissDepth = 0.5;

  /// Weight of the newest angle in the smoothing average.
  static const _smoothing = 0.4;

  int _count = 0;
  double? _angle;
  bool _armed = false;
  bool _down = false;
  int? _lastSeenAt;
  int _lastRepAt = -1000000;
  int _lastNearMissCueAt = -1000000;
  double _deepest = 180;
  RepCue _eventCue = RepCue.none;
  int _eventCueUntil = 0;

  int get count => _count;

  void reset() {
    _count = 0;
    _angle = null;
    _armed = false;
    _down = false;
    _lastSeenAt = null;
    _lastRepAt = -1000000;
    _deepest = 180;
    _eventCue = RepCue.none;
  }

  /// Feeds one frame. [pose] is null when nothing was detected.
  RepUpdate update(BodyPose? pose, int nowMillis) {
    final raw = pose?.limbAngle(profile.left, profile.right, minConfidence: 0.45);

    if (raw == null) {
      final seen = _lastSeenAt;
      final gap = seen == null ? 1 << 30 : nowMillis - seen;
      if (gap > forgetAfterMillis) {
        _armed = false;
        _down = false;
        _angle = null;
        _deepest = 180;
      }
      return _snapshot(
        nowMillis,
        counted: false,
        searching: gap > lostAfterMillis,
      );
    }

    _lastSeenAt = nowMillis;
    final a = _angle == null ? raw : _angle! * (1 - _smoothing) + raw * _smoothing;
    _angle = a;

    var counted = false;
    if (!_armed) {
      if (a >= profile.topAngle) {
        _armed = true;
        _deepest = a;
      }
    } else if (!_down) {
      if (a < _deepest) _deepest = a;
      if (a <= profile.bottomAngle) {
        _down = true;
      } else if (a >= profile.topAngle) {
        // Back at the top without having gone deep enough: a near miss if it
        // got most of the way.
        if (profile.depthFor(_deepest) >= _nearMissDepth &&
            nowMillis - _lastNearMissCueAt >= _cueCooldownMillis) {
          _setCue(RepCue.goLower, nowMillis);
          _lastNearMissCueAt = nowMillis;
        }
        _deepest = a;
      }
    } else if (a >= profile.topAngle) {
      _down = false;
      _deepest = a;
      if (nowMillis - _lastRepAt >= profile.minRepMillis) {
        _count++;
        _lastRepAt = nowMillis;
        counted = true;
      } else {
        _setCue(RepCue.steady, nowMillis);
      }
    }
    return _snapshot(nowMillis, counted: counted, searching: false);
  }

  void _setCue(RepCue cue, int now) {
    _eventCue = cue;
    _eventCueUntil = now + _cueHoldMillis;
  }

  RepUpdate _snapshot(int now, {required bool counted, required bool searching}) {
    final RepPhase phase;
    RepCue cue;
    if (searching) {
      phase = RepPhase.searching;
      cue = RepCue.showWholeBody;
    } else if (!_armed) {
      phase = RepPhase.getReady;
      cue = RepCue.getInPosition;
    } else {
      phase = _down ? RepPhase.down : RepPhase.ready;
      cue = now < _eventCueUntil ? _eventCue : RepCue.none;
    }
    final a = _angle;
    return RepUpdate(
      count: _count,
      phase: phase,
      cue: cue,
      depth: a == null ? 0 : profile.depthFor(a),
      counted: counted,
      angle: a,
    );
  }
}
