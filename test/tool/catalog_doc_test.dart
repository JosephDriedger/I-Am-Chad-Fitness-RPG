// Not a real test: writes docs/EXERCISE_CATALOG.md from the catalog data so
// the table can never drift from the code.
//
//   CATALOG_DOC=docs/EXERCISE_CATALOG.md flutter test test/tool/catalog_doc_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/activity.dart';

String _records(ActivityType a) => [
      if (a.metrics.contains(Metric.sets)) 'sets',
      if (a.metrics.contains(Metric.reps)) 'reps',
      if (a.metrics.contains(Metric.duration)) 'time',
      if (a.metrics.contains(Metric.distance)) 'distance',
      if (a.metrics.contains(Metric.load)) 'weight',
    ].join(', ');

String _tuning(ActivityType a) {
  final parts = <String>[];
  if (a.usesReps) parts.add('${a.secondsPerRep} s per rep');
  if (a.usesDuration || a.metrics.contains(Metric.distance)) {
    if (a.minutesPerKm != null && !a.usesDuration) parts.add('${a.minutesPerKm} min per km');
  }
  if (a.effortFactor != 1.0) parts.add('× ${a.effortFactor}');
  return parts.isEmpty ? 'standard' : parts.join(', ');
}

String _limits(ActivityType a) => [
      if (a.plausibleRepsPerSet != null) '${a.plausibleRepsPerSet} reps per set',
      if (a.plausibleKmh != null) '${a.plausibleKmh!.round()} km/h',
    ].join(', ');

String _cell(String s) => s.replaceAll('|', '\\|');

void main() {
  final out = Platform.environment['CATALOG_DOC'];

  test('write the exercise catalog document', () {
    final b = StringBuffer()
      ..writeln('# Exercise Catalog')
      ..writeln()
      ..writeln('Every exercise a player can log, with how it is recorded, what it needs, and how it is tuned. '
          'The table below is generated from the code (`lib/domain/activity.dart` and `lib/domain/exercises.dart`), so it '
          'cannot drift. To regenerate it:')
      ..writeln()
      ..writeln('```')
      ..writeln('CATALOG_DOC=docs/EXERCISE_CATALOG.md flutter test test/tool/catalog_doc_test.dart')
      ..writeln('```')
      ..writeln()
      ..writeln('There are **${ActivityCatalog.all.length} exercises** in '
          '${ActivityCategory.values.length} categories, and every one has an animated demonstration with '
          'step-by-step cues. ${ActivityCatalog.all.where((a) => a.equipment.atHome).length} need no gear beyond '
          'a floor, a wall or a chair.')
      ..writeln()
      ..writeln('## Reading the tables')
      ..writeln()
      ..writeln('- **Records** is what the log screen asks for.')
      ..writeln('- **Tuning** is how the exercise turns into effort minutes (see [Reward rules](REWARD_RULES.md)). '
          '"s per rep" is how long one rep really takes. A "×" multiplier is above 1 for hard cardio and below 1 for gentle '
          'work. Easier versions of an exercise earn exactly the same as harder ones.')
      ..writeln('- **Honesty limits** are the reps per set or speed above which the friendly honesty check '
          'asks the player to look again. They are deliberately generous.')
      ..writeln('- **Easier version** is shown in the log screen for anyone who needs it.')
      ..writeln();

    for (final c in ActivityCategory.values) {
      final list = ActivityCatalog.inCategory(c);
      b
        ..writeln('## ${c.label} (${list.length})')
        ..writeln()
        ..writeln('| Exercise | Records | Equipment | Tuning | Honesty limits | Easier version |')
        ..writeln('| --- | --- | --- | --- | --- | --- |');
      for (final a in list) {
        b.writeln('| **${_cell(a.name)}** (`${a.id}`) | ${_records(a)} | ${a.equipment.label} | ${_tuning(a)} | '
            '${_limits(a).isEmpty ? '–' : _limits(a)} | ${_cell(a.easierAlternative ?? '–')} |');
      }
      b.writeln();
    }

    b
      ..writeln('## Adding an exercise')
      ..writeln()
      ..writeln('1. **Describe it** in `lib/domain/exercises.dart`: a stable snake_case `id` (never rename it, because workouts '
          'store it), a Title Case `name`, the `category`, which `metrics` it records, and a short, calm, conservative `formCue`. '
          'Add an `easierAlternative` whenever there is a gentler way to do it, and an `equipment` tag.')
      ..writeln('2. **Tune it.** Set `secondsPerRep` to how long one rep really takes and an `effortFactor` that fits '
          '(1.0 is a brisk walk). Distance exercises need `minutesPerKm` and `plausibleKmh`; rep exercises need '
          '`plausibleRepsPerSet`. The catalog tests fail if these are missing or out of range.')
      ..writeln('3. **Animate it.** Write a pose with `_rig` in a file under `lib/game/demo/` (keyframes of torso, hand and '
          'foot targets, solved with the same IK as every other demo), then add an entry with its three cues to '
          '`demo_catalog.dart`. Draw props in `demo_props.dart`.')
      ..writeln('4. **Look at it.** Render a contact sheet and check every demo by eye:')
      ..writeln()
      ..writeln('   ```')
      ..writeln('   DEMO_SHEET=<folder> DEMO_IDS=your_id flutter test test/tool/demo_sheet_test.dart')
      ..writeln('   ```')
      ..writeln()
      ..writeln('5. **Run the tests.** The demo tests check that limbs never stretch, nothing sinks through the floor, '
          'the loop closes, motion is smooth, and the exercise really moves. Then regenerate this document.')
      ..writeln()
      ..writeln('## Safety and review')
      ..writeln()
      ..writeln('Cues are written to be conservative: they ask people to go at their own pace, stop if anything hurts, and use '
          'spotters or coaching for heavy lifts. The animations and cues have **not** been reviewed by a qualified trainer or '
          'physiotherapist yet, and that review is on the [roadmap](ROADMAP.md). This is a game, not medical advice.');

    File(out!).writeAsStringSync(b.toString());
  }, skip: out == null);
}
