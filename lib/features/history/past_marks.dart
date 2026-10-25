import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/game_ui.dart';
import '../../domain/records.dart';
import '../../domain/workout.dart';
import 'mark_progress.dart';

/// What the journal says about an exercise the player has done before: the last
/// time, on how many days, and their own marks. Shown when they are about to do
/// it again, and beside a suggestion for something familiar. Nothing here is a
/// target: it is only a look back, and it never changes a reward. Shows nothing
/// for an exercise that has never been logged.
class PastMarks extends StatelessWidget {
  const PastMarks({
    super.key,
    required this.recap,
    required this.entries,
    required this.metric,
    this.compact = false,
    this.onUseLast,
  });

  final ExerciseRecap recap;

  /// The whole journal, so a mark can open its progress line.
  final List<WorkoutEntry> entries;
  final bool metric;

  /// Fewer words, for a card in a list.
  final bool compact;

  /// If set, a button fills in last time's numbers (on the log screen).
  final VoidCallback? onUseLast;

  @override
  Widget build(BuildContext context) {
    final last = recap.last;
    if (last == null) return const SizedBox.shrink();
    final bests = compact ? recap.bests.take(2).toList() : recap.bests;
    final summary = last.summary(metric: metric);
    final lastLine = 'Last time: $summary, ${DateFormat('MMM d').format(last.performedAt)}';
    final daysLine = recap.days == 1 ? 'Done on 1 day.' : 'Done on ${recap.days} days.';

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact) ...[
          Text('Your Marks', style: gameTitle(18)),
          const SizedBox(height: 4),
        ],
        Text(lastLine, key: const Key('past_last'), style: const TextStyle(fontWeight: FontWeight.w700)),
        if (!compact) Text(daysLine, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (bests.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 0,
            children: [
              for (final b in bests)
                ActionChip(
                  key: Key('past_${b.kind.name}'),
                  avatar: const Icon(Icons.workspace_premium_rounded, size: 18, color: GameColors.teal),
                  label: Text('${b.kind.label}: ${b.describe(metric: metric)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  onPressed: () => showMarkProgress(context, entries: entries, best: b, metric: metric),
                ),
            ],
          ),
        ],
        if (!compact && onUseLast != null) ...[
          const SizedBox(height: 6),
          GameButton(
            key: const Key('past_use_last'),
            label: "Fill In Last Time's Numbers",
            icon: Icons.history_rounded,
            kind: GameButtonKind.secondary,
            small: true,
            expanded: false,
            onPressed: onUseLast,
          ),
        ],
        if (!compact) ...[
          const SizedBox(height: 4),
          const Text(
            'Tap a mark to see how it has moved. These are only for looking back on, and never change what you earn.',
            style: TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
        ],
      ],
    );
    return compact ? body : GamePanel(child: body);
  }
}
