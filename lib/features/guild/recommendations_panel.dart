import 'package:flutter/material.dart';

import '../../app/game_ui.dart';
import '../../domain/records.dart';
import '../../domain/recommendations.dart';
import '../../domain/workout.dart';
import '../history/past_marks.dart';
import '../workout/log_workout_screen.dart';

/// Ideas for today beside the quests: something that goes with a quest, things the
/// player has not tried before, and now and then an old favourite. Entirely
/// optional. For anything they have done before it shows their own marks, so they
/// can see where they are before they start.
class RecommendationsPanel extends StatelessWidget {
  const RecommendationsPanel({
    super.key,
    required this.recommendations,
    required this.journal,
    required this.today,
    required this.metric,
  });

  final List<Recommendation> recommendations;

  /// The whole journal, for the marks.
  final List<WorkoutEntry> journal;

  /// Entries logged today, so a suggestion already done shows as done.
  final List<WorkoutEntry> today;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();
    return GamePanel(
      title: 'Try Something Today',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ideas to go with the quests, and a few things you might like. Pick one, none, or something else entirely.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          for (final r in recommendations) ...[
            const Divider(height: 22),
            _Idea(
              key: Key('rec_${r.activity.id}'),
              rec: r,
              done: r.isDoneBy(today),
              recap: ExerciseRecap.of(journal, r.activity.id),
              journal: journal,
              metric: metric,
            ),
          ],
        ],
      ),
    );
  }
}

class _Idea extends StatelessWidget {
  const _Idea({super.key, required this.rec, required this.done, required this.recap, required this.journal, required this.metric});

  final Recommendation rec;
  final bool done;
  final ExerciseRecap recap;
  final List<WorkoutEntry> journal;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    final a = rec.activity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(a.name, style: gameTitle(19)),
            if (done) const GameChip(text: 'Done Today', icon: Icons.check_circle_rounded, color: GameColors.teal),
          ],
        ),
        const SizedBox(height: 2),
        Text(rec.reason, style: const TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Start with ${rec.plan.description}', style: const TextStyle(fontWeight: FontWeight.w600)),
        if (recap.hasHistory) ...[
          const SizedBox(height: 6),
          PastMarks(recap: recap, entries: journal, metric: metric, compact: true),
        ],
        const SizedBox(height: 8),
        GameButton(
          key: Key('rec_try_${a.id}'),
          label: done ? 'Do It Again' : 'Try It',
          icon: Icons.play_arrow_rounded,
          kind: GameButtonKind.secondary,
          small: true,
          expanded: false,
          onPressed: () => Navigator.of(context).push(gameRoute(LogWorkoutScreen(activity: a, quest: rec.plan))),
        ),
      ],
    );
  }
}
