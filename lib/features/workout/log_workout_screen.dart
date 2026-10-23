import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/activity.dart';
import '../../domain/chad.dart';
import '../../domain/quests.dart';
import '../../domain/rewards.dart';
import '../../domain/workout.dart';
import '../../game/look.dart';
import 'exercise_demo_card.dart';

const _kmPerMile = 1.609344;
const _lbPerKg = 2.2046226;

/// Log a new workout, or edit [editing]. [quest] pre-fills a suggestion.
class LogWorkoutScreen extends ConsumerStatefulWidget {
  const LogWorkoutScreen({
    super.key,
    required this.activity,
    this.quest,
    this.editing,
  });

  final ActivityType activity;
  final QuestSuggestion? quest;
  final WorkoutEntry? editing;

  @override
  ConsumerState<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends ConsumerState<LogWorkoutScreen> {
  final _sets = TextEditingController();
  final _reps = TextEditingController();
  final _minutes = TextEditingController();
  final _seconds = TextEditingController();
  final _distance = TextEditingController();
  final _load = TextEditingController();
  final _notes = TextEditingController();

  String? _variant;
  int? _effort;
  late DateTime _when;
  bool _saving = false;
  bool _prefilledUnits = false;

  Timer? _ticker;
  DateTime? _timerStart;
  int _elapsed = 0;

  ActivityType get a => widget.activity;

  @override
  void initState() {
    super.initState();
    _when = widget.editing?.performedAt ?? ref.read(clockProvider)();
    final q = widget.quest;
    if (q != null) {
      _setIfPositive(_sets, q.sets);
      _setIfPositive(_reps, q.reps);
      _setDuration(q.durationSeconds);
      _variant = q.variant;
    }
  }

  /// Distance and load are stored metric; fill them once units are known.
  void _fillEditingUnits(bool metric) {
    final e = widget.editing;
    if (e == null || _prefilledUnits) return;
    _prefilledUnits = true;
    _setIfPositive(_sets, e.sets);
    _setIfPositive(_reps, e.reps);
    _setDuration(e.durationSeconds);
    if ((e.distanceMeters ?? 0) > 0) {
      final km = e.distanceMeters! / 1000;
      _distance.text = _fmt(metric ? km : km / _kmPerMile);
    }
    if ((e.loadKg ?? 0) > 0) {
      _load.text = _fmt(metric ? e.loadKg! : e.loadKg! * _lbPerKg);
    }
    _variant = e.variant;
    _effort = e.perceivedEffort;
    _notes.text = e.notes ?? '';
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  void _setIfPositive(TextEditingController c, int? v) {
    if (v != null && v > 0) c.text = '$v';
  }

  void _setDuration(int? secs) {
    if (secs == null || secs <= 0) return;
    final m = secs ~/ 60, s = secs % 60;
    if (m > 0) _minutes.text = '$m';
    if (s > 0) _seconds.text = '$s';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final c in [_sets, _reps, _minutes, _seconds, _distance, _load, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());
  double? _dbl(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  // ---- Stopwatch ----------------------------------------------------------

  void _toggleTimer() {
    if (_ticker != null) {
      _ticker!.cancel();
      _ticker = null;
      _elapsed = DateTime.now().difference(_timerStart!).inSeconds;
      _minutes.text = _elapsed >= 60 ? '${_elapsed ~/ 60}' : '';
      _seconds.text = _elapsed % 60 > 0 ? '${_elapsed % 60}' : '';
      setState(() {});
    } else {
      _elapsed = 0;
      // Measure against the wall clock so time still counts if the app is
      // backgrounded and the periodic ticks are paused.
      _timerStart = DateTime.now();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed = DateTime.now().difference(_timerStart!).inSeconds);
      });
      setState(() {});
    }
  }

  String get _elapsedLabel {
    final m = (_elapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ---- Save ---------------------------------------------------------------

  Future<void> _pickWhen() async {
    final now = ref.read(clockProvider)();
    final date = await showDatePicker(
      context: context,
      initialDate: _when.isAfter(now) ? now : _when,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (time == null) return;
    setState(() => _when =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    final metric = ref.read(prefsProvider).useMetric;
    final secs = (_int(_minutes) ?? 0) * 60 + (_int(_seconds) ?? 0);
    final dist = _dbl(_distance);
    final load = _dbl(_load);
    final entry = WorkoutEntry(
      id: widget.editing?.id,
      activityId: a.id,
      performedAt: _when,
      variant: _variant,
      sets: a.metrics.contains(Metric.sets) ? _int(_sets) : null,
      reps: a.usesReps ? _int(_reps) : null,
      durationSeconds: a.usesDuration && secs > 0 ? secs : null,
      distanceMeters: a.metrics.contains(Metric.distance) && dist != null
          ? (metric ? dist : dist * _kmPerMile) * 1000
          : null,
      loadKg: a.metrics.contains(Metric.load) && load != null
          ? (metric ? load : load / _lbPerKg)
          : null,
      perceivedEffort: _effort,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    if (!entry.hasMeasurement) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add at least a time, some reps, or a distance.'),
      ));
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(repositoryProvider);
    final firstEver = (ref.read(workoutsProvider).value ?? const []).isEmpty;
    if (entry.id == null) {
      await repo.addWorkout(entry);
    } else {
      await repo.updateWorkout(entry);
    }
    final reward = await repo.rewardForDay(entry.performedAt);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _RewardDialog(
        reward: reward,
        rules: repo.rules,
        forToday: dayKey(entry.performedAt) == dayKey(ref.read(clockProvider)()),
        chadLine: ChadDialogue.line(
          firstEver
              ? ChadContext.firstWorkout
              : reward.capReached
                  ? ChadContext.capReached
                  : ChadContext.afterWorkout,
          seed: entry.performedAt.day,
        ),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  // ---- UI -----------------------------------------------------------------

  /// The demo figure wears your hero's look.
  HeroLook _demoLook() {
    final hero = ref.read(heroProvider).value;
    if (hero == null) return const HeroLook();
    return HeroLook(
      style: hero.appearanceStyle,
      color: hero.appearanceColor,
      skin: hero.appearanceSkin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);
    _fillEditingUnits(prefs.useMetric);
    final t = Theme.of(context).textTheme;
    final editing = widget.editing != null;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit ${a.name}' : a.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ExerciseDemoCard(
              activityId: a.id,
              variant: _variant,
              look: _demoLook(),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        [a.formCue, if (a.easierAlternative != null) a.easierAlternative]
                            .join(' '),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (a.variants.isNotEmpty) ...[
              Text('Version (All Earn the Same)', style: t.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in a.variants)
                    ChoiceChip(
                      label: Text(v),
                      selected: _variant == v,
                      onSelected: (on) =>
                          setState(() => _variant = on ? v : null),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (a.metrics.contains(Metric.sets) || a.usesReps)
              Row(
                children: [
                  if (a.metrics.contains(Metric.sets))
                    Expanded(child: _intField(_sets, 'Sets', 20)),
                  if (a.metrics.contains(Metric.sets) && a.usesReps)
                    const SizedBox(width: 12),
                  if (a.usesReps)
                    Expanded(child: _intField(_reps, 'Reps per Set', 500)),
                ],
              ),
            if (a.usesDuration) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _intField(_minutes, 'Minutes', 600)),
                  const SizedBox(width: 12),
                  Expanded(child: _intField(_seconds, 'Seconds', 59)),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _toggleTimer,
                  icon: Icon(_ticker != null ? Icons.stop : Icons.timer_outlined),
                  label: Text(_ticker != null
                      ? 'Stop Timer ($_elapsedLabel)'
                      : 'Use a Timer Instead'),
                ),
              ),
            ],
            if (a.metrics.contains(Metric.distance)) ...[
              const SizedBox(height: 12),
              _decimalField(_distance, 'Distance (Optional)',
                  prefs.useMetric ? 'km' : 'mi'),
            ],
            if (a.metrics.contains(Metric.load)) ...[
              const SizedBox(height: 12),
              _decimalField(
                  _load, 'Weight (Optional)', prefs.useMetric ? 'kg' : 'lb'),
            ],
            const SizedBox(height: 20),
            Text('How Did It Feel? (Optional, Just for You)',
                style: t.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 1; i <= 5; i++)
                  ChoiceChip(
                    label: Text(['Very Easy', 'Easy', 'Okay', 'Hard', 'Very Hard'][i - 1]),
                    selected: _effort == i,
                    onSelected: (on) => setState(() => _effort = on ? i : null),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text('This never changes your rewards.', style: t.bodySmall),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (Optional)'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('When'),
              subtitle: Text(DateFormat('EEE, MMM d · h:mm a').format(_when)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickWhen,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(editing ? 'Save Changes' : 'Save Workout'),
            ),
            const SafetyNote(),
          ],
        ),
      ),
    );
  }

  Widget _intField(TextEditingController c, String label, int max) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          _MaxValueFormatter(max),
        ],
        decoration: InputDecoration(labelText: label),
      );

  Widget _decimalField(TextEditingController c, String label, String unit) =>
      TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          LengthLimitingTextInputFormatter(7),
        ],
        decoration: InputDecoration(labelText: label, suffixText: unit),
      );
}

/// Rejects integer input above [max] so fields can't hold absurd values.
class _MaxValueFormatter extends TextInputFormatter {
  _MaxValueFormatter(this.max);
  final int max;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final v = int.tryParse(next.text);
    return v != null && v > max ? old : next;
  }
}

class _RewardDialog extends StatelessWidget {
  const _RewardDialog({
    required this.reward,
    required this.rules,
    required this.forToday,
    required this.chadLine,
  });

  final DayReward reward;
  final RewardRules rules;
  final bool forToday;
  final String chadLine;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Workout Saved!'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(forToday ? 'Rewards for today' : 'Rewards for that day',
                style: t.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                StatChip(icon: Icons.star, text: '${reward.xp} XP'),
                StatChip(icon: Icons.bolt, text: '${reward.energy} Energy'),
              ],
            ),
            const SizedBox(height: 12),
            Text(rules.explain(reward), style: t.bodyMedium),
            const SizedBox(height: 16),
            ChadBubble(text: chadLine),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Nice'),
        ),
      ],
    );
  }
}
