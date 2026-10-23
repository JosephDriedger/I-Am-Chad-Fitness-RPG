import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/game/demo/exercise_demo.dart';
import 'package:i_am_chad/game/look.dart';

/// Every (activity, variant) the app can log.
List<(String, String?)> get _everything => [
      for (final a in ActivityCatalog.all) ...[
        (a.id, null),
        for (final v in a.variants) (a.id, v),
      ],
    ];

double _d(Offset a, Offset b) => (a - b).distance;

void main() {
  test('every activity and variant has a demonstration', () {
    for (final (id, variant) in _everything) {
      expect(demoFor(id, variant), isNotNull, reason: '$id / $variant');
    }
  });

  test('variants that are meant to look different do', () {
    for (final a in ActivityCatalog.all) {
      final base = demoFor(a.id)!;
      for (final v in a.variants) {
        if (const {'Standard', 'Bodyweight', 'Sit-Up'}.contains(v)) continue;
        expect(demoFor(a.id, v)!.title, isNot(base.title),
            reason: '${a.id} / $v should not reuse the default demo');
      }
    }
  });

  test('every demo has cues, a sane duration and valid key times', () {
    for (final (id, variant) in _everything) {
      final c = demoFor(id, variant)!;
      expect(c.cues.length, inInclusiveRange(2, 5), reason: c.title);
      expect(c.seconds, inInclusiveRange(0.8, 8), reason: c.title);
      for (final k in c.keyTimes) {
        expect(k, inInclusiveRange(0, 1));
      }
      for (var i = 0; i < 100; i++) {
        expect(c.cueAt(i / 99).isNotEmpty, isTrue);
      }
    }
  });

  group('figure stays physically plausible', () {
    for (final (id, variant) in _everything) {
      test('$id / ${variant ?? 'default'}', () {
        final c = demoFor(id, variant)!;
        FigurePose? prev;
        for (var i = 0; i <= 240; i++) {
          final t = (i % 240) / 240;
          final p = c.pose(t);

          for (final j in p.joints) {
            expect(j.dx.isFinite && j.dy.isFinite, isTrue, reason: 't=$t');
            expect(j.dx, inInclusiveRange(-10, demoW + 10), reason: 'x out of frame at t=$t');
            expect(j.dy, inInclusiveRange(-10, demoH + 10), reason: 'y out of frame at t=$t');
          }

          // Limbs never stretch or shrink.
          expect(_d(p.shoulder, p.elbowF), closeTo(armUpper, 0.8), reason: 'upper arm t=$t');
          expect(_d(p.elbowF, p.handF), closeTo(armLower, 0.8), reason: 'forearm t=$t');
          expect(_d(p.shoulder, p.elbowB), closeTo(armUpper, 0.8), reason: 'back upper arm t=$t');
          expect(_d(p.hip, p.kneeF), closeTo(legThigh, 0.8), reason: 'thigh t=$t');
          expect(_d(p.kneeF, p.ankleF), closeTo(legShin, 0.8), reason: 'shin t=$t');
          expect(_d(p.hip, p.kneeB), closeTo(legThigh, 0.8), reason: 'back thigh t=$t');

          // Nothing sinks through the floor.
          expect(p.ankleF.dy, lessThanOrEqualTo(demoGround + 1), reason: 'foot underground t=$t');
          expect(p.ankleB.dy, lessThanOrEqualTo(demoGround + 1), reason: 'foot underground t=$t');
          expect(p.handF.dy, lessThanOrEqualTo(demoGround + 1), reason: 'hand underground t=$t');

          // Smooth motion, including across the loop point.
          if (prev != null) {
            for (var k = 0; k < p.joints.length; k++) {
              final step = _d(p.joints[k], prev.joints[k]);
              expect(step, lessThan(5), reason: 'joint $k jumped $step at t=$t');
            }
          }
          prev = p;
        }
      });
    }
  });

  test('the loop is closed: the last frame leads into the first', () {
    for (final (id, variant) in _everything) {
      final c = demoFor(id, variant)!;
      final a = c.pose(0).joints, b = c.pose(0.9999).joints;
      for (var k = 0; k < a.length; k++) {
        expect(_d(a[k], b[k]), lessThan(0.6), reason: '${c.title} joint $k');
      }
    }
  });

  test('exercises actually move through a useful range', () {
    // The main body part should travel, otherwise the demo shows nothing.
    for (final (id, variant) in _everything) {
      final c = demoFor(id, variant)!;
      var maxMove = 0.0;
      final first = c.pose(0);
      for (var i = 1; i < 60; i++) {
        final p = c.pose(i / 60);
        maxMove = math.max(
          maxMove,
          math.max(_d(p.handF, first.handF), math.max(_d(p.head, first.head), _d(p.kneeF, first.kneeF))),
        );
      }
      // Planks are deliberately almost still; everything else moves a lot.
      final min = id == 'plank' ? 0.5 : 8.0;
      expect(maxMove, greaterThan(min), reason: '${c.title} barely moves');
    }
  });

  test('every demo paints without throwing', () {
    for (final (id, variant) in _everything) {
      final c = demoFor(id, variant)!;
      for (final t in [0.0, 0.25, 0.5, 0.75, 0.999]) {
        paintDemo(Canvas(PictureRecorder()), c, t, const HeroLook(style: 5, skin: 4));
      }
    }
  });
}
