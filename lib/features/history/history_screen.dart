import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../domain/activity.dart';
import '../../domain/exercise_history.dart';
import '../../domain/player_state.dart';
import '../../domain/records.dart';
import '../../domain/workout.dart';
import '../workout/log_workout_screen.dart';
import 'exercise_page.dart';
import 'mark_progress.dart';
import 'month_panel.dart';

/// The journal: a chronicle of everything you have done.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutsProvider);
    final grantList = ref.watch(grantsProvider).value ?? const <DayGrant>[];
    final grants = {for (final g in grantList) g.day: g};
    final hero = ref.watch(heroProvider).value;
    final metric = ref.watch(prefsProvider).useMetric;
    final now = ref.watch(clockProvider)();

    return workoutsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load history: $e')),
      data: (workouts) {
        if (workouts.isEmpty) {
          // Centred when there is room, and scrolls on a short screen or at large text.
          return LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 64, color: GameColors.woodLight),
                        const SizedBox(height: 12),
                        Text('No Workouts Yet', style: gameTitle(26)),
                        const SizedBox(height: 6),
                        const Text(
                          'Your workouts will appear here. Every legend starts with a first entry.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final byDay = <String, List<WorkoutEntry>>{};
        for (final w in workouts) {
          byDay.putIfAbsent(dayKey(w.performedAt), () => []).add(w);
        }
        final days = byDay.keys.toList(); // already newest first
        final totalMinutes = grantList.fold<double>(0, (a, g) => a + g.effortMinutes);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            GamePanel(
              title: 'Chronicle',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GameChip(text: '${workouts.length} Workouts', icon: Icons.fitness_center),
                  GameChip(text: '${totalMinutes.round()} Effort Min', icon: Icons.timer_outlined, color: GameColors.teal),
                  GameChip(text: '${byDay.length} Active Days', icon: Icons.calendar_today, color: GameColors.cream),
                  if (hero != null)
                    GameChip(text: '${hero.victories} Expeditions Won', icon: Icons.emoji_events_rounded),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _WeekChart(now: now, grants: grants),
            const SizedBox(height: 14),
            MonthPanel(entries: workouts, now: now),
            const SizedBox(height: 14),
            _BestsPanel(bests: PersonalBests.of(workouts), entries: workouts, metric: metric),
            const SizedBox(height: 14),
            _ExercisesPanel(summaries: ExerciseHistory.summaries(workouts), now: now),
            const SizedBox(height: 14),
            for (final day in days) ...[
              _DayHeader(day: day, grant: grants[day]),
              for (final w in byDay[day]!) _WorkoutTile(entry: w, metric: metric),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

/// The player's own best marks, newest first. Collapsed to a few until asked.
class _BestsPanel extends StatefulWidget {
  const _BestsPanel({required this.bests, required this.entries, required this.metric});

  final List<PersonalBest> bests;
  final List<WorkoutEntry> entries;
  final bool metric;

  @override
  State<_BestsPanel> createState() => _BestsPanelState();
}

class _BestsPanelState extends State<_BestsPanel> {
  static const _shown = 5;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final bests = widget.bests;
    if (bests.isEmpty) return const SizedBox.shrink();
    final visible = _all ? bests : bests.take(_shown).toList();
    return GamePanel(
      title: 'Personal Bests',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final b in visible)
            Semantics(
              button: true,
              label: '${ActivityCatalog.byId(b.activityId)?.name ?? 'Unknown'}, ${b.kind.label}, '
                  '${b.describe(metric: widget.metric)}. Show your progress.',
              child: ExcludeSemantics(
                child: InkWell(
                  key: Key('best_${b.activityId}_${b.kind.name}'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => showMarkProgress(context, entries: widget.entries, best: b, metric: widget.metric),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: GameColors.teal, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${ActivityCatalog.byId(b.activityId)?.name ?? 'Unknown'}: ${b.kind.label}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // May wrap onto a second line when text is large, rather than run off the edge.
                        Expanded(
                          flex: 2,
                          child: Text(b.describe(metric: widget.metric), textAlign: TextAlign.end, style: gameTitle(17)),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded, color: GameColors.inkSoft),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          const Text(
            'Your own marks. Tap one to see how it has moved. They are only for looking back on, and never change what you earn.',
            style: TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
          if (bests.length > _shown)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _all = !_all),
                child: Text(_all ? 'Show Fewer' : 'Show All ${bests.length}'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Every exercise in the journal, most recent first. Tap one for its own page.
/// Collapsed to a few until asked.
class _ExercisesPanel extends StatefulWidget {
  const _ExercisesPanel({required this.summaries, required this.now});

  final List<ExerciseSummary> summaries;
  final DateTime now;

  @override
  State<_ExercisesPanel> createState() => _ExercisesPanelState();
}

class _ExercisesPanelState extends State<_ExercisesPanel> {
  static const _shown = 4;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final list = widget.summaries;
    if (list.isEmpty) return const SizedBox.shrink();
    final visible = _all ? list : list.take(_shown).toList();
    final date = DateFormat('MMM d');
    return GamePanel(
      title: 'Your Exercises',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in visible)
            Semantics(
              button: true,
              label: '${ActivityCatalog.byId(s.activityId)?.name ?? 'Unknown'}, ${s.days} ${s.days == 1 ? 'day' : 'days'}, '
                  'last ${date.format(s.last)}. Show its story.',
              child: ExcludeSemantics(
                child: InkWell(
                  key: Key('exercise_${s.activityId}'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(context).push(gameRoute(ExercisePage(activityId: s.activityId))),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: [
                        const Icon(Icons.fitness_center_rounded, color: GameColors.teal, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Text(
                            ActivityCatalog.byId(s.activityId)?.name ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${s.days} ${s.days == 1 ? 'day' : 'days'} · ${date.format(s.last)}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.w700),
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
          const SizedBox(height: 4),
          const Text(
            'Tap one to see how often you have done it and your own marks. Only for looking back on.',
            style: TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
          if (list.length > _shown)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('exercises_toggle'),
                onPressed: () => setState(() => _all = !_all),
                child: Text(_all ? 'Show Fewer' : 'Show All ${list.length}'),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.grant});

  final String day;
  final DayGrant? grant;

  @override
  Widget build(BuildContext context) {
    final d = DateTime.parse(day);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(DateFormat('EEEE, MMM d').format(d), style: gameTitle(19))),
          if (grant != null)
            // The chips drop onto a second line when text is large, instead of running off the edge.
            Flexible(
              flex: 2,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 6,
                runSpacing: 4,
                children: [
                  GameChip(text: '+${grant!.xp} XP', icon: Icons.star_rounded),
                  GameChip(text: '+${grant!.energy}', icon: Icons.bolt_rounded, color: GameColors.teal),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkoutTile extends ConsumerWidget {
  const _WorkoutTile({required this.entry, required this.metric});

  final WorkoutEntry entry;
  final bool metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = entry.activity;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          title: Text(a?.name ?? 'Unknown activity', style: gameTitle(18)),
          subtitle: Text(
            '${DateFormat('h:mm a').format(entry.performedAt)} · ${entry.summary(metric: metric)}'
            '${entry.cameraCounted ? ' · Camera Counted' : ''}'
            '${entry.countsForRewards ? '' : ' · Journal Only'}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: IconButton(
            tooltip: 'Delete workout',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
          onTap: a == null
              ? null
              : () => Navigator.of(context).push(gameRoute(LogWorkoutScreen(activity: a, editing: entry))),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showGameDialog<bool>(
      context: context,
      title: 'Delete This Workout?',
      content: const Text(
        'The entry is removed from your history and that day\'s rewards are recalculated.',
      ),
      actions: [
        Builder(
          builder: (ctx) => GameButton(label: 'Keep It', kind: GameButtonKind.positive, onPressed: () => Navigator.pop(ctx, false)),
        ),
        Builder(
          builder: (ctx) => GameButton(label: 'Delete', kind: GameButtonKind.danger, small: true, onPressed: () => Navigator.pop(ctx, true)),
        ),
      ],
    );
    if (ok == true && entry.id != null) {
      await ref.read(repositoryProvider).deleteWorkout(entry.id!);
    }
  }
}

/// Last seven days of effort minutes. Values are always printed, so colour
/// is never the only signal.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.now, required this.grants});

  final DateTime now;
  final Map<String, DayGrant> grants;

  @override
  Widget build(BuildContext context) {
    final today = startOfDay(now);
    final days = [for (var i = 6; i >= 0; i--) DateTime(today.year, today.month, today.day - i)];
    final values = [for (final d in days) grants[dayKey(d)]?.effortMinutes ?? 0.0];
    final maxV = values.fold<double>(20, (a, b) => b > a ? b : a);
    final total = values.fold<double>(0, (a, b) => a + b);

    return Semantics(
      label: 'Last 7 days: ${total.round()} effort minutes in total',
      child: GamePanel(
        title: 'Last 7 Days',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              // Room for the bars plus the two text labels at whatever text size the
              // player has chosen (about 128 at the normal size).
              height: 82 + MediaQuery.textScalerOf(context).scale(46),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            values[i] > 0 ? values[i].round().toString() : '–',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          // The bar takes whatever height the labels leave, so it never overflows.
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, box) => Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: (4 + (box.maxHeight - 4) * (values[i] / maxV)).clamp(0.0, box.maxHeight),
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    gradient: values[i] > 0
                                        ? const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [GameColors.gold, GameColors.goldDark],
                                          )
                                        : null,
                                    color: values[i] > 0 ? null : GameColors.parchmentDark,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: GameColors.wood, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('E').format(days[i]).substring(0, 1),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: i == 6 ? GameColors.ink : GameColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Effort minutes per day. Rest days are part of the plan.',
              style: TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}
