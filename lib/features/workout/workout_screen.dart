import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/feedback.dart';
import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/activity.dart';
import '../../game/core.dart' show Haptic, Sfx;
import '../../game/demo/exercise_demo.dart';
import '../../game/look.dart';
import 'log_workout_screen.dart';

/// The training yard: pick an exercise card. Every card shows the exercise
/// itself, and free-form logging is always available (quests from the hall
/// just pre-fill the same form).
class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = ref.watch(heroProvider).value;
    final look = hero == null
        ? const HeroLook()
        : HeroLook(style: hero.appearanceStyle, color: hero.appearanceColor, skin: hero.appearanceSkin);

    return LayoutBuilder(
      builder: (context, box) {
        final cardW = (box.maxWidth - 32 - 12) / 2;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const ChadBubble(
              text: 'Pick what you did. Any version counts, and you can edit or delete it later.',
            ),
            for (final c in ActivityCategory.values) ...[
              const SizedBox(height: 8),
              GameHeading(c.label),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final a in ActivityCatalog.inCategory(c))
                    SizedBox(width: cardW, child: _ExerciseCard(activity: a, look: look)),
                ],
              ),
            ],
            const SafetyNote(),
          ],
        );
      },
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({required this.activity, required this.look});

  final ActivityType activity;
  final HeroLook look;

  static String _metrics(ActivityType a) {
    final names = <String>[
      if (a.metrics.contains(Metric.sets)) 'sets',
      if (a.metrics.contains(Metric.reps)) 'reps',
      if (a.metrics.contains(Metric.duration)) 'time',
      if (a.metrics.contains(Metric.distance)) 'distance',
      if (a.metrics.contains(Metric.load)) 'weight',
    ];
    return names.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = demoFor(activity.id);
    return Semantics(
      button: true,
      label: '${activity.name}. Record ${_metrics(activity)}.',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: () {
            final fx = ref.read(feedbackProvider);
            fx.sfx(Sfx.tap);
            fx.haptic(Haptic.light);
            Navigator.of(context).push(gameRoute(LogWorkoutScreen(activity: activity)));
          },
          child: GamePanel(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (demo != null)
                  AspectRatio(
                    aspectRatio: demoW / demoH,
                    child: CustomPaint(painter: _ThumbPainter(demo, look)),
                  ),
                Container(height: 3, color: GameColors.wood),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.name, style: gameTitle(17), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(_metrics(activity),
                          style: const TextStyle(color: GameColors.inkSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A still frame of the exercise, mid-movement.
class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.config, this.look);

  final DemoConfig config;
  final HeroLook look;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / demoW, size.height / demoH);
    canvas.clipRect(const Rect.fromLTWH(0, 0, demoW, demoH));
    paintDemo(canvas, config, config.keyTimes.last, look);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ThumbPainter old) =>
      old.config != config || old.look.style != look.style || old.look.color != look.color || old.look.skin != look.skin;
}
