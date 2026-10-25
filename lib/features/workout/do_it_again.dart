import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/game_ui.dart';
import '../../domain/records.dart';
import '../../domain/workout.dart';
import 'log_workout_screen.dart';

/// The last few exercises someone did, one tap from logging them again with the
/// same numbers filled in. Shown only once there is something to repeat.
class DoItAgainShelf extends StatelessWidget {
  const DoItAgainShelf({super.key, required this.journal, required this.metric});

  final List<WorkoutEntry> journal;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    final recent = RecentExercises.of(journal);
    if (recent.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GamePanel(
        title: 'Do It Again',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your last few. Tap one and the same numbers are filled in, so you can change anything or just save.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            for (final e in recent)
              Semantics(
                button: true,
                label: '${e.activity!.name}. Last time ${e.summary(metric: metric)}. Do it again.',
                child: ExcludeSemantics(
                  child: InkWell(
                    key: Key('again_${e.activityId}'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.of(context).push(gameRoute(LogWorkoutScreen(activity: e.activity!, repeatOf: e))),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Row(
                        children: [
                          const Icon(Icons.replay_rounded, color: GameColors.teal),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(e.activity!.name, style: gameTitle(17)),
                                Text(
                                  '${e.summary(metric: metric)} · ${DateFormat('MMM d').format(e.performedAt)}',
                                  style: const TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: GameColors.inkSoft),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
