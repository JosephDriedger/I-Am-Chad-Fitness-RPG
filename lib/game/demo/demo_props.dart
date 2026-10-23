part of 'exercise_demo.dart';

// Props for the larger catalog. All are drawn in code like the rest.

void _stepBox(Canvas c, double x, double w, double h) {
  _rect(c, x, demoGround - h, w, h, const Color(0xFF8D6E63), 2);
  _rect(c, x, demoGround - h, w, 4, const Color(0xFFA1887F), 2);
}

/// A pull-up frame: two posts and a bar at [barY], seen side-on.
void _pullUpBar(Canvas c, double x, double barY) {
  _line(c, Offset(x - 22, demoGround), Offset(x - 22, barY), 4, const Color(0xFF6D4C41));
  _line(c, Offset(x + 22, demoGround), Offset(x + 22, barY), 4, const Color(0xFF6D4C41));
  _line(c, Offset(x - 26, barY), Offset(x + 26, barY), 4, _steel);
}

void _kettlebell(Canvas c, Offset at, {double scale = 1}) {
  c.save();
  c.translate(at.dx, at.dy);
  c.scale(scale);
  _line(c, const Offset(-4, -6), const Offset(4, -6), 2.4, const Color(0xFF263238));
  c.drawCircle(const Offset(0, 1), 7.5, _p..color = const Color(0xFF37474F));
  c.drawCircle(const Offset(-2, -1), 2, _p..color = const Color(0x33FFFFFF));
  c.restore();
}

void _ball(Canvas c, Offset at, {double r = 5, Color color = const Color(0xFFE57C23)}) {
  c.drawCircle(at, r, _p..color = color);
  c.drawArc(Rect.fromCircle(center: at, radius: r * 0.8), 0.4, 2.2, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = const Color(0x66000000));
}

/// A band running between two points.
void _band(Canvas c, Offset a, Offset b) {
  _line(c, a, b, 2.2, const Color(0xFFEF5350));
}

/// A rope as a loop swinging from hand to hand around the figure.
void _rope(Canvas c, Offset handL, Offset handR, double phase) {
  final lift = math.sin(phase * 2 * math.pi);
  final mid = Offset((handL.dx + handR.dx) / 2, demoGround - 4 - 52 * (0.5 + 0.5 * lift));
  final path = Path()
    ..moveTo(handL.dx, handL.dy)
    ..quadraticBezierTo(handL.dx - 26, mid.dy, mid.dx, mid.dy)
    ..quadraticBezierTo(handR.dx + 26, mid.dy, handR.dx, handR.dy);
  c.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFF6D4C41),
  );
}

void _bikeFrame(Canvas c, double cx) {
  // Wheels and frame of a stationary bike, seen side-on.
  final wheel = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = const Color(0xFF455A64);
  c.drawCircle(Offset(cx - 34, 98), 17, wheel);
  c.drawCircle(Offset(cx + 34, 98), 17, wheel);
  _line(c, Offset(cx - 34, 98), Offset(cx - 4, 70), 3, const Color(0xFF546E7A));
  _line(c, Offset(cx - 4, 70), Offset(cx + 34, 98), 3, const Color(0xFF546E7A));
  _line(c, Offset(cx - 4, 70), Offset(cx + 20, 56), 3, const Color(0xFF546E7A));
  _line(c, Offset(cx - 34, 98), Offset(cx + 34, 98), 2, const Color(0xFF546E7A));
  _line(c, Offset(cx - 14, 66), Offset(cx - 14, 52), 3, const Color(0xFF37474F)); // seat post
  _rect(c, cx - 22, 49, 16, 5, const Color(0xFF263238), 2); // seat
  _line(c, Offset(cx + 20, 56), Offset(cx + 20, 48), 3, const Color(0xFF37474F)); // stem
  _line(c, Offset(cx + 14, 47), Offset(cx + 28, 47), 3, const Color(0xFF263238)); // bars
}

