import 'package:flutter/material.dart';

import '../../app/game_ui.dart';
import '../../domain/activity.dart';
import '../../game/demo/exercise_demo.dart';
import '../../game/look.dart';

/// How to set the phone up so the camera can count reps: a drawn diagram and
/// numbered steps for this exercise. Shown before the camera starts and again
/// from the "How to Set Up" button while counting.
class CameraSetupGuide extends StatelessWidget {
  const CameraSetupGuide({
    super.key,
    required this.activity,
    required this.look,
    required this.metric,
    this.variant,
    this.showDiagram = true,
  });

  final ActivityType activity;
  final String? variant;
  final HeroLook look;
  final bool metric;
  final bool showDiagram;

  bool get _lowPhone => activity.id == 'push_up';

  @override
  Widget build(BuildContext context) {
    final distance = metric ? '2 m' : '6 ft';
    final steps = <(String, String)>[
      (
        'Put Your Phone in Its Stand',
        _lowPhone
            ? 'Set the stand on the floor with the phone upright, low down near the floor, and leave it there.'
            : 'Set the stand on the floor, or raise a tripod so the phone sits at about hip height, and leave it there.',
      ),
      (
        'Stand Back About Two Big Steps',
        'That is roughly $distance. You need to be far enough away that your whole body fits on the screen, '
            'from head to toe, even at full stretch.',
      ),
      (
        'Turn Side-On',
        _lowPhone
            ? 'Face sideways to the phone, so the camera sees your bending elbows in profile.'
            : 'Face sideways to the phone (a slight angle is fine), so the camera sees your knees bend in profile.',
      ),
      (
        'Give It Good Light',
        'Face a window or a lamp if you can, with a clear floor and nothing in the way of your arms and legs. '
            'Snug clothes help it see your joints.',
      ),
      (
        'Check the Screen',
        'Once the camera starts you will see a skeleton drawn over you. When both ticks in the set-up check turn green, '
            'you are ready to go.',
      ),
    ];

    final config = demoFor(activity.id, variant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.smartphone_rounded, color: GameColors.goldDark),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'You will need a phone stand or tripod. Any kind that holds the phone upright will do.',
                style: TextStyle(color: GameColors.ink, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (showDiagram && config != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: _SetupPainter.w / _SetupPainter.h,
              child: Semantics(
                label: 'Diagram: the phone sits in a ${_lowPhone ? 'low stand on the floor' : 'tripod at hip height'}, '
                    'about $distance from you, with you side-on and your whole body in view.',
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: _SetupPainter(
                      config: config,
                      look: look,
                      lowPhone: _lowPhone,
                      distanceLabel: 'About 2 big steps ($distance)',
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: GameColors.woodDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: GameColors.gold, width: 2),
                  ),
                  child: Text('${i + 1}', style: gameTitle(15, color: GameColors.cream)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(steps[i].$1, style: gameTitle(17)),
                      const SizedBox(height: 2),
                      Text(
                        steps[i].$2,
                        style: const TextStyle(color: GameColors.ink, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const Text(
          'Trouble? Step back a little, add more light, or try snugger clothes. '
          'The front camera is used first so you can see the screen; tap the camera-switch button to use the back one.',
          style: TextStyle(color: GameColors.inkSoft),
        ),
      ],
    );
  }
}

/// A side view of the room: the phone on its stand, the view cone, and the
/// exercise figure side-on at the right distance.
class _SetupPainter extends CustomPainter {
  _SetupPainter({
    required this.config,
    required this.look,
    required this.lowPhone,
    required this.distanceLabel,
  });

  static const double w = 370;
  static const double h = demoH;

  final DemoConfig config;
  final HeroLook look;
  final bool lowPhone;
  final String distanceLabel;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / w, size.height / h);
    canvas.clipRect(const Rect.fromLTWH(0, 0, w, h));

    // Room, matching the demo backdrop so the two halves join up.
    canvas.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFF4EBDD));
    canvas.drawRect(
      const Rect.fromLTWH(0, demoGround, w, h - demoGround),
      Paint()..color = const Color(0xFFD7C3A5),
    );
    canvas.drawLine(
      const Offset(0, demoGround),
      const Offset(w, demoGround),
      Paint()
        ..color = const Color(0xFFB59C78)
        ..strokeWidth = 2,
    );

    // The figure, in the right-hand part.
    canvas.save();
    canvas.translate(w - demoW, 0);
    canvas.clipRect(const Rect.fromLTWH(0, 0, demoW, demoH));
    paintDemo(canvas, config, config.keyTimes.last, look);
    canvas.restore();

    // Stand and phone.
    const phoneX = 34.0;
    final standTop = lowPhone ? demoGround - 7 : demoGround - 46;
    final metal = Paint()
      ..color = const Color(0xFF55555F)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    if (lowPhone) {
      // A small desk stand: flat base and a rest for the phone's back.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(phoneX - 10, demoGround - 3, 26, 3),
          const Radius.circular(1.5),
        ),
        Paint()..color = metal.color,
      );
      canvas.drawLine(Offset(phoneX - 2, demoGround - 3), Offset(phoneX + 2, standTop), metal);
    } else {
      // A tripod: a centre column and three legs.
      final head = Offset(phoneX + 3, standTop);
      canvas.drawLine(head, Offset(phoneX + 3, demoGround), metal);
      canvas.drawLine(head, Offset(phoneX - 13, demoGround), metal);
      canvas.drawLine(head, Offset(phoneX + 19, demoGround), metal);
    }
    final phoneTop = standTop - 26;
    final phone = RRect.fromRectAndRadius(
      Rect.fromLTWH(phoneX, phoneTop, 7, 26),
      const Radius.circular(2),
    );
    canvas.drawRRect(phone, Paint()..color = const Color(0xFF2B2B33));
    final lens = Offset(phoneX + 7, phoneTop + 6);
    canvas.drawCircle(lens, 2.2, Paint()..color = const Color(0xFF9AD4FF));

    // What the camera sees.
    final cone = Path()
      ..moveTo(lens.dx, lens.dy)
      ..lineTo(w - 4, 4)
      ..lineTo(w - 4, demoGround + 4)
      ..close();
    canvas.drawPath(cone, Paint()..color = const Color(0xFFF2C94C).withValues(alpha: 0.2));
    final edge = Paint()
      ..color = const Color(0xFFD9A93A).withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(lens, Offset(w - 4, 4), edge);
    canvas.drawLine(lens, Offset(w - 4, demoGround + 4), edge);

    // Distance.
    const y = 132.0;
    final figureX = w - demoW / 2;
    final arrow = Paint()
      ..color = const Color(0xFF3A2A1C)
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(phoneX + 4, y), Offset(figureX, y), arrow);
    for (final (x, dir) in [(phoneX + 4, 1.0), (figureX, -1.0)]) {
      canvas.drawLine(Offset(x, y), Offset(x + 5 * dir, y - 3), arrow);
      canvas.drawLine(Offset(x, y), Offset(x + 5 * dir, y + 3), arrow);
    }
    final tp = TextPainter(
      text: TextSpan(
        text: distanceLabel,
        style: const TextStyle(color: Color(0xFF3A2A1C), fontSize: 9, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((phoneX + figureX) / 2 - tp.width / 2, y - 13));

    final cam = TextPainter(
      text: const TextSpan(
        text: 'Phone',
        style: TextStyle(color: Color(0xFF3A2A1C), fontSize: 8, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    cam.paint(canvas, Offset(phoneX - 2 - cam.width / 2 + 3, 6));

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SetupPainter old) =>
      old.config != config ||
      old.lowPhone != lowPhone ||
      old.distanceLabel != distanceLabel ||
      old.look.style != look.style ||
      old.look.color != look.color ||
      old.look.skin != look.skin;
}
