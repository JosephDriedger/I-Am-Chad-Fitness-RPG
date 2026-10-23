import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../domain/player_state.dart';
import '../../domain/workout.dart';
import '../workout/log_workout_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutsProvider);
    final grants = {
      for (final g in ref.watch(grantsProvider).value ?? const <DayGrant>[])
        g.day: g,
    };
    final metric = ref.watch(prefsProvider).useMetric;
    final now = ref.watch(clockProvider)();
    final t = Theme.of(context).textTheme;

    return workoutsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load history: $e')),
      data: (workouts) {
        if (workouts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history,
                      size: 48, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('No Workouts Yet', style: t.titleMedium),
                  const SizedBox(height: 4),
                  const Text(
                    'Your workouts will appear here. Every legend starts '
                    'with a first entry.',
                    textAlign: TextAlign.center,
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

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('History', style: t.headlineSmall),
            const SizedBox(height: 12),
            _WeekChart(now: now, grants: grants),
            const SizedBox(height: 16),
            for (final day in days) ...[
              _DayHeader(day: day, grant: grants[day], count: byDay[day]!.length),
              for (final w in byDay[day]!)
                _WorkoutTile(entry: w, metric: metric),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.grant, required this.count});

  final String day;
  final DayGrant? grant;
  final int count;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final d = DateTime.parse(day);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(DateFormat('EEEE, MMM d').format(d), style: t.titleSmall),
          ),
          if (grant != null)
            Text('+${grant!.xp} XP · +${grant!.energy} energy',
                style: t.labelMedium),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        title: Text(a?.name ?? 'Unknown activity'),
        subtitle: Text(
          '${DateFormat('h:mm a').format(entry.performedAt)} · '
          '${entry.summary(metric: metric)}',
        ),
        trailing: IconButton(
          tooltip: 'Delete workout',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmDelete(context, ref),
        ),
        onTap: a == null
            ? null
            : () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => LogWorkoutScreen(activity: a, editing: entry),
                )),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete This Workout?'),
        content: const Text(
            'The entry is removed from your history and that day\'s rewards '
            'are recalculated.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep It')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
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
    final scheme = Theme.of(context).colorScheme;
    final today = startOfDay(now);
    final days = [
      for (var i = 6; i >= 0; i--) DateTime(today.year, today.month, today.day - i)
    ];
    final values = [for (final d in days) grants[dayKey(d)]?.effortMinutes ?? 0.0];
    final maxV = values.fold<double>(20, (a, b) => b > a ? b : a);
    final total = values.fold<double>(0, (a, b) => a + b);

    return Semantics(
      label: 'Last 7 days: ${total.round()} effort minutes in total',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Last 7 Days', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
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
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              height: 4 + 64 * (values[i] / maxV),
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: values[i] > 0
                                    ? scheme.primary
                                    : scheme.outlineVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('E').format(days[i]).substring(0, 1),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text('Effort minutes per day. Rest days are part of the plan.',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
