import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/pose.dart';
import 'package:i_am_chad/domain/rep_counter.dart';

/// A pose whose left-side limb has exactly [degrees] at its middle joint.
BodyPose _limbPose(
  RepProfile p,
  double degrees, {
  double confidence = 1,
}) {
  final rad = degrees * math.pi / 180;
  final mid = JointPoint(300, 300, confidence: confidence);
  final a = JointPoint(400, 300, confidence: confidence);
  final c = JointPoint(300 + 100 * math.cos(rad), 300 + 100 * math.sin(rad), confidence: confidence);
  return BodyPose(
    width: 720,
    height: 1280,
    joints: {p.left.a: a, p.left.mid: mid, p.left.c: c},
  );
}

/// Drives a counter with a made-up exercise, 100 ms per frame.
class _Sim {
  _Sim(this.profile) : counter = RepCounter(profile);

  final RepProfile profile;
  final RepCounter counter;
  int now = 0;
  RepUpdate? last;
  final cues = <RepCue>[];

  void frame(double? degrees, {double confidence = 1}) {
    now += 100;
    last = counter.update(
      degrees == null ? null : _limbPose(profile, degrees, confidence: confidence),
      now,
    );
    cues.add(last!.cue);
  }

  void hold(double? degrees, int frames) {
    for (var i = 0; i < frames; i++) {
      frame(degrees);
    }
  }

  /// A smooth move from [from] to [to] over [frames] frames.
  void move(double from, double to, int frames) {
    for (var i = 1; i <= frames; i++) {
      frame(from + (to - from) * i / frames);
    }
  }

  /// Start at the top, go down to [bottom], come back: one rep, about 3 s.
  void rep({required double top, required double bottom}) {
    move(top, bottom, 12);
    hold(bottom, 3);
    move(bottom, top, 12);
    hold(top, 3);
  }
}

_Sim _push(RepLeniency l, {String? variant}) =>
    _Sim(RepProfile.forActivity('push_up', variant: variant, leniency: l)!);

void main() {
  test('only push-ups and squats can be counted', () {
    expect(RepProfile.supports('push_up'), isTrue);
    expect(RepProfile.supports('squat'), isTrue);
    expect(RepProfile.supports('walking'), isFalse);
    expect(RepProfile.forActivity('plank'), isNull);
    expect(RepProfile.forActivity('from_a_newer_app'), isNull);
  });

  test('beginners get the most forgiving range of motion', () {
    for (final id in ['push_up', 'squat']) {
      final b = RepProfile.forActivity(id, leniency: RepLeniency.beginner)!;
      final g = RepProfile.forActivity(id, leniency: RepLeniency.gentle)!;
      final s = RepProfile.forActivity(id, leniency: RepLeniency.standard)!;
      // Depth needed shrinks as leniency grows; the start position never gets
      // stricter than for someone who trains.
      expect(b.bottomAngle, greaterThan(g.bottomAngle), reason: id);
      expect(g.bottomAngle, greaterThan(s.bottomAngle), reason: id);
      expect(b.topAngle, lessThanOrEqualTo(s.topAngle), reason: id);
      expect(g.topAngle, lessThanOrEqualTo(s.topAngle), reason: id);
    }
  });

  test('every profile keeps a usable gap between down and up', () {
    for (final id in ['push_up', 'squat']) {
      for (final l in RepLeniency.values) {
        for (final v in [null, 'Wall', 'Incline', 'Knee', 'Standard']) {
          final p = RepProfile.forActivity(id, variant: v, leniency: l)!;
          expect(p.topAngle - p.bottomAngle, greaterThanOrEqualTo(25), reason: '$id $v $l');
          expect(p.topAngle, lessThanOrEqualTo(172));
        }
      }
    }
  });

  test('experience picks the leniency', () {
    expect(RepLeniency.forExperience(ExperienceLevel.starting), RepLeniency.beginner);
    expect(RepLeniency.forExperience(ExperienceLevel.returning), RepLeniency.gentle);
    expect(RepLeniency.forExperience(ExperienceLevel.regular), RepLeniency.standard);
  });

  test('the angle maths is right', () {
    const o = JointPoint(0, 0);
    expect(BodyPose.angleAt(const JointPoint(1, 0), o, const JointPoint(0, 1)), closeTo(90, 1e-9));
    expect(BodyPose.angleAt(const JointPoint(1, 0), o, const JointPoint(-1, 0)), closeTo(180, 1e-9));
    expect(BodyPose.angleAt(const JointPoint(1, 0), o, const JointPoint(1, 0)), closeTo(0, 1e-9));
    // A zero-length limb is treated as straight rather than dividing by zero.
    expect(BodyPose.angleAt(o, o, const JointPoint(1, 1)), 180);
  });

  test('a clean full rep counts at every leniency', () {
    for (final l in RepLeniency.values) {
      final s = _push(l);
      s.hold(170, 5);
      s.rep(top: 170, bottom: 80);
      expect(s.counter.count, 1, reason: '$l');
    }
  });

  test('five reps count five', () {
    final s = _push(RepLeniency.gentle);
    s.hold(170, 5);
    for (var i = 0; i < 5; i++) {
      s.rep(top: 170, bottom: 85);
    }
    expect(s.counter.count, 5);
  });

  test('the count lands on the frame the player gets back up', () {
    final s = _push(RepLeniency.gentle);
    s.hold(170, 5);
    s.move(170, 80, 10);
    s.hold(80, 3);
    expect(s.counter.count, 0);
    var counted = 0;
    for (var i = 1; i <= 12; i++) {
      s.frame(80 + (170 - 80) * i / 12);
      if (s.last!.counted) counted++;
    }
    expect(counted, 1);
    expect(s.counter.count, 1);
  });

  test('a shallow rep counts for a beginner but not for someone strict', () {
    // Elbows bent only to 120 degrees.
    final beginner = _push(RepLeniency.beginner)..hold(170, 5);
    beginner.rep(top: 170, bottom: 120);
    expect(beginner.counter.count, 1);

    final standard = _push(RepLeniency.standard)..hold(170, 5);
    standard.rep(top: 170, bottom: 120);
    expect(standard.counter.count, 0);
  });

  test('a near miss gets a gentle "a little lower" hint, once', () {
    final s = _push(RepLeniency.standard)..hold(170, 5);
    s.rep(top: 170, bottom: 120);
    expect(s.counter.count, 0);
    expect(s.cues, contains(RepCue.goLower));

    // Two quick near misses in a row, then a long quiet stretch. The hint is
    // shown once (about 2 s); the second near miss is inside the cool-down.
    final t = _push(RepLeniency.standard)..hold(170, 5);
    for (var i = 0; i < 2; i++) {
      t.move(170, 120, 5);
      t.frame(120);
      t.move(120, 170, 5);
      t.frame(170);
    }
    t.hold(170, 40);
    expect(t.cues.where((c) => c == RepCue.goLower).length, lessThanOrEqualTo(23));
  });

  test('barely moving gives no hint and no count', () {
    final s = _push(RepLeniency.gentle)..hold(170, 5);
    s.rep(top: 170, bottom: 160);
    expect(s.counter.count, 0);
    expect(s.cues, isNot(contains(RepCue.goLower)));
  });

  test('easier variants need less depth', () {
    // Wall push-ups bend the elbow only to about 125 degrees.
    final wall = _push(RepLeniency.gentle, variant: 'Wall')..hold(170, 5);
    wall.rep(top: 170, bottom: 125);
    expect(wall.counter.count, 1);

    final standard = _push(RepLeniency.gentle, variant: 'Standard')..hold(170, 5);
    standard.rep(top: 170, bottom: 125);
    expect(standard.counter.count, 0);
  });

  test('a single glitchy frame does not count as a rep', () {
    for (final l in RepLeniency.values) {
      final s = _push(l)..hold(170, 5);
      s.frame(60);
      s.hold(170, 5);
      expect(s.counter.count, 0, reason: '$l');
    }
  });

  test('wobble that does not return to the top is not a second rep', () {
    final s = _push(RepLeniency.gentle)..hold(170, 5);
    s.move(170, 80, 10);
    s.hold(80, 3);
    // Come up part-way, dip again, then finish: still only one rep.
    s.move(80, 130, 4);
    s.move(130, 85, 4);
    s.move(85, 170, 10);
    s.hold(170, 3);
    expect(s.counter.count, 1);
  });

  test('reps too close together to tell apart are not double counted', () {
    final s = _push(RepLeniency.gentle)..hold(170, 5);
    s.rep(top: 170, bottom: 85);
    expect(s.counter.count, 1);
    // A burst of fast flicker straight after: well under the minimum gap.
    for (var i = 0; i < 4; i++) {
      s.frame(60);
      s.frame(60);
      s.frame(170);
      s.frame(170);
    }
    expect(s.counter.count, lessThanOrEqualTo(2));
  });

  test('you have to reach the start position before anything counts', () {
    final s = _push(RepLeniency.gentle);
    // Starts already low and wiggles about without ever extending.
    s.hold(100, 5);
    s.move(100, 130, 5);
    s.move(130, 90, 5);
    expect(s.counter.count, 0);
    expect(s.last!.phase, RepPhase.getReady);
    expect(s.last!.cue, RepCue.getInPosition);
    // Extending arms the counter.
    s.move(90, 170, 6);
    expect(s.last!.phase, RepPhase.ready);
  });

  test('losing the body asks for the whole body and never counts', () {
    final s = _push(RepLeniency.gentle)..hold(170, 5);
    s.hold(null, 15);
    expect(s.last!.phase, RepPhase.searching);
    expect(s.last!.cue, RepCue.showWholeBody);
    expect(s.counter.count, 0);

    // Low-confidence joints are the same as not seeing them.
    final t = _push(RepLeniency.gentle);
    for (var i = 0; i < 15; i++) {
      t.frame(170, confidence: 0.1);
    }
    expect(t.last!.phase, RepPhase.searching);
  });

  test('a short dropout in the middle of a rep is forgiven', () {
    final s = _push(RepLeniency.gentle)..hold(170, 5);
    s.move(170, 80, 10);
    s.hold(null, 4); // 0.4 s lost at the bottom
    s.move(80, 170, 10);
    s.hold(170, 3);
    expect(s.counter.count, 1);
  });

  test('a long dropout forgets the rep in progress', () {
    final s = _push(RepLeniency.gentle)..hold(170, 5);
    s.move(170, 80, 10);
    s.hold(null, 40); // 4 s lost
    // Reappears half way up: it must get back to the top before counting.
    s.move(130, 170, 5);
    s.hold(170, 3);
    expect(s.counter.count, 0);
    s.rep(top: 170, bottom: 80);
    expect(s.counter.count, 1);
  });

  test('depth runs from 0 at the top to 1 at counting depth', () {
    final s = _push(RepLeniency.gentle)..hold(170, 10);
    expect(s.last!.depth, 0);
    s.hold(80, 15);
    expect(s.last!.depth, 1);
    s.hold(132, 15);
    expect(s.last!.depth, inExclusiveRange(0.3, 0.7));
  });

  test('squats use the hip, knee and ankle', () {
    final profile = RepProfile.forActivity('squat', leniency: RepLeniency.gentle)!;
    final s = _Sim(profile)..hold(170, 5);
    s.rep(top: 170, bottom: 95);
    s.rep(top: 170, bottom: 95);
    expect(s.counter.count, 2);
    // A quarter squat (knee bent to 140) is not enough for "gentle".
    s.rep(top: 170, bottom: 140);
    expect(s.counter.count, 2);
  });

  test('the better-seen side of the body is used', () {
    final profile = RepProfile.forActivity('push_up', leniency: RepLeniency.gentle)!;
    // Left side hidden (low confidence, wrong angle), right side clear and bent.
    final pose = BodyPose(width: 720, height: 1280, joints: {
      profile.left.a: const JointPoint(0, 0, confidence: 0.1),
      profile.left.mid: const JointPoint(1, 0, confidence: 0.1),
      profile.left.c: const JointPoint(2, 0, confidence: 0.1),
      profile.right.a: const JointPoint(400, 300),
      profile.right.mid: const JointPoint(300, 300),
      profile.right.c: const JointPoint(300, 400),
    });
    final angle = pose.limbAngle(profile.left, profile.right);
    expect(angle, closeTo(90, 1e-6));
    expect(pose.visibleMainJoints(), 3);
  });

  test('reset starts again from nothing', () {
    final s = _push(RepLeniency.gentle)..hold(170, 5);
    s.rep(top: 170, bottom: 80);
    s.counter.reset();
    expect(s.counter.count, 0);
  });
}
