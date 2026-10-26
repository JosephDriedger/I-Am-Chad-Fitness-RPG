import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../domain/activity.dart';
import '../../domain/exercise_history.dart';
import '../../domain/workout.dart';
import '../workout/log_workout_screen.dart';
import 'mark_progress.dart';

/// Everything the journal knows about one exercise, in one place: how often it
/// was done over the last weeks, the player's own marks, and the latest entries.
/// Only for looking back on. It sets no target and never changes a reward.
class ExercisePage extends ConsumerWidget {
  const ExercisePage({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched, so editing or deleting an entry from here shows straight away.
    final entries = ref.watch(workoutsProvider).value ?? const <WorkoutEntry>[];
    final now = ref.watch(clockProvider)();
    final metric = ref.watch(prefsProvider).useMetric;
    final activity = ActivityCatalog.byId(activityId);
    final h = ExerciseHistory.of(entries, activityId, now: now);
    final date = DateFormat('MMM d, y');
    return GameScaffold(
      title: activity?.name ?? 'Exercise',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          GamePanel(
            title: 'The Story So Far',
            child: h.hasHistory
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      GameChip(text: '${h.days} ${h.days == 1 ? 'Day' : 'Days'}', icon: Icons.calendar_today),
                      GameChip(text: 'Since ${date.format(h.first!)}', icon: Icons.history_rounded, color: GameColors.cream),
                      GameChip(text: 'Last ${date.format(h.last!)}', icon: Icons.event_available_rounded, color: GameColors.teal),
                    ],
                  )
                : const Text('Nothing logged for this yet. When you do it, its story starts here.', key: Key('exercise_empty')),
          ),
          if (h.hasHistory) ...[
            const SizedBox(height: 14),
            _WeeksPanel(history: h, metric: metric),
            if (h.bests.isNotEmpty) ...[
              const SizedBox(height: 14),
              _MarksPanel(history: h, entries: entries, metric: metric),
            ],
            const SizedBox(height: 14),
            GamePanel(
              title: 'Latest',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in h.recent)
                    ListTile(
                      key: Key('exercise_recent_${e.id}'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(DateFormat('EEE, MMM d').format(e.performedAt), style: gameTitle(17)),
                      subtitle: Text(
                        [
                          e.summary(metric: metric),
                          if (e.feel != null) 'Felt ${e.feel}',
                          if (e.notes != null) e.notes!,
                        ].join(' · '),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: GameColors.inkSoft),
                      onTap: activity == null
                          ? null
                          : () => Navigator.of(context).push(gameRoute(LogWorkoutScreen(activity: activity, editing: e))),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'This is only for looking back on. It sets no target, and it never changes what you earn. '
            'Quiet weeks are rest, and rest is part of getting stronger.',
            style: TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

/// Days per week over the latest weeks, with the number always printed.
class _WeeksPanel extends StatelessWidget {
  const _WeeksPanel({required this.history, required this.metric});

  final ExerciseHistory history;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    final weeks = history.weeks;
    final label = DateFormat('d');
    return GamePanel(
      title: 'Last ${ExerciseHistory.weeksShown} Weeks',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Days you did it each week for the last ${weeks.length} weeks: '
                '${[for (final w in weeks) w.days].join(', ')}.',
            child: ExcludeSemantics(
              child: SizedBox(
                key: const Key('exercise_weeks'),
                // Room for the bars plus the two text labels at whatever text size is chosen.
                height: 70 + MediaQuery.textScalerOf(context).scale(46),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < weeks.length; i++)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              weeks[i].rest ? '–' : '${weeks[i].days}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, box) => Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: (4 + (box.maxHeight - 4) * (weeks[i].days / 7)).clamp(0.0, box.maxHeight),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      gradient: weeks[i].rest
                                          ? null
                                          : const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [GameColors.gold, GameColors.goldDark],
                                            ),
                                      color: weeks[i].rest ? GameColors.parchmentDark : null,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: GameColors.wood, width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              i == weeks.length - 1 ? 'Now' : label.format(weeks[i].start),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: i == weeks.length - 1 ? GameColors.ink : GameColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Days each week you did it. Each number under a bar is the Monday that week began on.',
            style: TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
          if (history.hasLoad) ...[
            const SizedBox(height: 10),
            Text(
              key: const Key('exercise_lifted'),
              'Lifted in these weeks: ${ExerciseHistory.describeLifted(history.liftedKg, metric: metric)} in all '
              '(weight × reps × sets).',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

class _MarksPanel extends StatelessWidget {
  const _MarksPanel({required this.history, required this.entries, required this.metric});

  final ExerciseHistory history;
  final List<WorkoutEntry> entries;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d');
    return GamePanel(
      title: 'Your Marks',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final b in history.bests)
            Semantics(
              button: true,
              label: '${b.kind.label}, ${b.describe(metric: metric)}. Show your progress.',
              child: ExcludeSemantics(
                child: InkWell(
                  key: Key('exercise_mark_${b.kind.name}'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => showMarkProgress(context, entries: entries, best: b, metric: metric),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: GameColors.teal, size: 22),
                        const SizedBox(width: 8),
                        Expanded(flex: 3, child: Text(b.kind.label, style: const TextStyle(fontWeight: FontWeight.w800))),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${b.describe(metric: metric)} · ${date.format(b.achievedAt)}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded, color: GameColors.inkSoft),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
