import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/game_ui.dart';
import '../../game/art/painters.dart';
import '../../game/look.dart';

/// The game's logo art: a slowly turning sunburst behind Chad, with the title
/// in the game font. Used on the title screen and the first onboarding step.
class TitleLockup extends StatefulWidget {
  const TitleLockup({super.key, this.height = 300});

  final double height;

  @override
  State<TitleLockup> createState() => _TitleLockupState();
}

class _TitleLockupState extends State<TitleLockup> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 600))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return Semantics(
      header: true,
      label: 'I Am Chad: Fitness RPG',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              border: Border.all(color: GameColors.gold, width: 4),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => CustomPaint(
                    painter: _LockupPainter(still ? 0 : _c.value * 600),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, -0.78),
                  // A logo keeps its designed size whatever the text-size setting, and shrinks to
                  // fit if the space is tight, instead of breaking "CHAD" over four lines.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('I AM', textScaler: TextScaler.noScaling, style: gameTitle(26, color: GameColors.gold, letterSpacing: 6).copyWith(shadows: _outline)),
                        Text('CHAD', textScaler: TextScaler.noScaling, style: gameTitle(72, color: GameColors.cream, letterSpacing: 3).copyWith(shadows: _outline, height: 0.95)),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
                    decoration: BoxDecoration(
                      color: GameColors.red,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: GameColors.redDark, width: 2.5),
                      boxShadow: const [BoxShadow(color: Color(0x88000000), offset: Offset(0, 3))],
                    ),
                    child: Text('FITNESS RPG', textScaler: TextScaler.noScaling, style: gameTitle(20, color: Colors.white, letterSpacing: 2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _outline = [
    Shadow(color: GameColors.woodDark, offset: Offset(0, 4), blurRadius: 0),
    Shadow(color: GameColors.woodDark, offset: Offset(3, 0), blurRadius: 0),
    Shadow(color: GameColors.woodDark, offset: Offset(-3, 0), blurRadius: 0),
    Shadow(color: GameColors.woodDark, offset: Offset(0, -3), blurRadius: 0),
  ];
}

class _LockupPainter extends CustomPainter {
  _LockupPainter(this.time);

  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, 0.35),
          radius: 1.0,
          colors: [Color(0xFF9A6A3E), Color(0xFF4A2F1A), Color(0xFF2B1A0E)],
        ).createShader(rect),
    );

    // Sunburst rays.
    final center = Offset(size.width / 2, size.height * 0.62);
    final rays = Paint()..color = const Color(0x22F2C94C);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(time * 0.15);
    const n = 14;
    final r = size.longestSide;
    for (var i = 0; i < n; i++) {
      final a0 = i * 2 * math.pi / n;
      final a1 = a0 + math.pi / n;
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(math.cos(a0) * r, math.sin(a0) * r)
          ..lineTo(math.cos(a1) * r, math.sin(a1) * r)
          ..close(),
        rays,
      );
    }
    canvas.restore();

    // Chad, flexing.
    canvas.save();
    canvas.translate(size.width / 2, size.height - 52);
    final s = size.height / 150;
    canvas.scale(s, s);
    paintChad(canvas, ActorState()..time = time);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LockupPainter old) => old.time != time;
}
