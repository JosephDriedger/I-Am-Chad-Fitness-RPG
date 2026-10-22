import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/widgets.dart';
import '../../domain/activity.dart';
import 'log_workout_screen.dart';

/// Pick an activity to log. Free-form logging is always available; quests
/// from the Guild just pre-fill the same form.
class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Log a workout', style: t.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Pick what you did. Any version counts, and you can edit or delete '
          'it later.',
          style: t.bodyMedium,
        ),
        const SizedBox(height: 16),
        for (final c in ActivityCategory.values) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(c.label, style: t.titleMedium),
          ),
          for (final a in ActivityCatalog.inCategory(c))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  title: Text(a.name),
                  subtitle: Text(_metricsLabel(a)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => LogWorkoutScreen(activity: a),
                  )),
                ),
              ),
            ),
        ],
        const SafetyNote(),
      ],
    );
  }

  static String _metricsLabel(ActivityType a) {
    final names = <String>[
      if (a.metrics.contains(Metric.sets)) 'sets',
      if (a.metrics.contains(Metric.reps)) 'reps',
      if (a.metrics.contains(Metric.duration)) 'time',
      if (a.metrics.contains(Metric.distance)) 'distance',
      if (a.metrics.contains(Metric.load)) 'weight',
    ];
    return 'Record: ${names.join(', ')}';
  }
}
