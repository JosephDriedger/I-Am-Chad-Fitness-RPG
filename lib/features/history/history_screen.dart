import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../domain/player_state.dart';
import '../../domain/workout.dart';
import '../workout/log_workout_screen.dart';

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
          return Center(
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
          Expanded(child: Text(DateFormat('EEEE, MMM d').format(d), style: gameTitle(19))),
          if (grant != null) ...[
            GameChip(text: '+${grant!.xp} XP', icon: Icons.star_rounded),
            const SizedBox(width: 6),
            GameChip(text: '+${grant!.energy}', icon: Icons.bolt_rounded, color: GameColors.teal),
          ],
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
            '${entry.cameraCounted ? ' · Camera Counted' : ''}',
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
              height: 120,
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
                          Container(
                            height: 4 + 70 * (values[i] / maxV),
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
