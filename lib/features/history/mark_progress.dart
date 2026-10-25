import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/game_ui.dart';
import '../../domain/activity.dart';
import '../../domain/records.dart';
import '../../domain/workout.dart';

/// A look back at one personal best: how that mark has moved over the days it
/// was done. Only for looking back on; it never changes a reward, and it never
/// compares the player with a target or with anyone else.
Future<void> showMarkProgress(
  BuildContext context, {
  required List<WorkoutEntry> entries,
  required PersonalBest best,
  required bool metric,
}) {
  final history = MarkHistory.of(entries, activityId: best.activityId, kind: best.kind);
  final name = ActivityCatalog.byId(best.activityId)?.name ?? 'Unknown';
  return showGameDialog<void>(
    context: context,
    title: 'Your Progress',
    content: _Progress(name: name, kind: best.kind, history: history, metric: metric),
    actions: [
      Builder(
        builder: (ctx) => GameButton(
          key: const Key('progress_close'),
          label: 'Close',
          kind: GameButtonKind.secondary,
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ),
    ],
  );
}

class _Progress extends StatelessWidget {
  const _Progress({required this.name, required this.kind, required this.history, required this.metric});

  final String name;
  final RecordKind kind;
  final MarkHistory history;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d');
    String mark(PersonalBest p) => '${p.describe(metric: metric)} (${date.format(p.achievedAt)})';
    final p = history.points;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$name: ${kind.label}', style: gameTitle(20)),
        const SizedBox(height: 10),
        if (!history.hasLine)
          Text(
            p.isEmpty
                ? 'Nothing logged for this yet.'
                : 'Only one day so far, ${mark(p.first)}. Do it again and a line will start to appear here.',
            key: const Key('progress_empty'),
          )
        else ...[
          Semantics(
            label: '${p.length} days. From ${p.first.describe(metric: metric)} to ${p.last.describe(metric: metric)}, '
                'best ${history.best!.describe(metric: metric)}.',
            child: ExcludeSemantics(
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: CustomPaint(key: const Key('progress_chart'), painter: _LinePainter([for (final x in p) x.value])),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Each dot is a day you did it.',
            style: TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          _Row(label: 'First', text: mark(p.first)),
          _Row(label: 'Latest', text: mark(p.last)),
          _Row(label: 'Best', text: mark(history.best!)),
        ],
        const SizedBox(height: 10),
        const Text(
          'A line wobbles, and that is normal. Lighter days and rest weeks are part of getting stronger. '
          'This is only for looking back on, and it never changes what you earn.',
          style: TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12.5),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Wrap(
          spacing: 8,
          children: [
            Text('$label:', style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

/// A plain line with a dot for each day. The scale is only as wide as the marks
/// themselves, so a small change still shows, and the line never needs a unit.
class _LinePainter extends CustomPainter {
  const _LinePainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 14.0;
    final w = size.width - pad * 2, h = size.height - pad * 2;
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    double x(int i) => pad + (values.length == 1 ? w / 2 : w * i / (values.length - 1));
    // A flat run sits in the middle instead of on an edge.
    double y(double v) => hi == lo ? pad + h / 2 : pad + h * (1 - (v - lo) / (hi - lo));

    final frame = Paint()
      ..color = GameColors.parchmentDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)), frame);

    final path = Path()..moveTo(x(0), y(values.first));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = GameColors.wood
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < values.length; i++) {
      final latest = i == values.length - 1;
      final c = Offset(x(i), y(values[i]));
      canvas.drawCircle(c, latest ? 7 : 5, Paint()..color = GameColors.gold);
      canvas.drawCircle(
        c,
        latest ? 7 : 5,
        Paint()
          ..color = GameColors.wood
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.values.length != values.length || !_same(old.values, values);

  static bool _same(List<double> a, List<double> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
