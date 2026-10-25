import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/feedback.dart';
import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/activity.dart';
import '../../domain/first_steps.dart';
import '../../domain/chad.dart';
import '../../domain/honesty.dart';
import '../../domain/quests.dart';
import '../../domain/records.dart';
import '../../domain/rep_counter.dart';
import '../../domain/rewards.dart';
import '../../domain/streaks.dart';
import '../../domain/workout.dart';
import '../../game/core.dart' show Haptic, Sfx;
import '../../game/look.dart';
import '../history/past_marks.dart';
import 'camera_reps_screen.dart';
import 'exercise_demo_card.dart';
import 'pose_camera.dart';

const _kmPerMile = 1.609344;
const _lbPerKg = 2.2046226;

/// Log a new workout, or edit [editing]. [quest] pre-fills a suggestion.
class LogWorkoutScreen extends ConsumerStatefulWidget {
  const LogWorkoutScreen({
    super.key,
    required this.activity,
    this.quest,
    this.editing,
    this.repeatOf,
  });

  final ActivityType activity;
  final QuestSuggestion? quest;
  final WorkoutEntry? editing;

  /// Start from this earlier entry's numbers (a "do it again" from the Train screen).
  final WorkoutEntry? repeatOf;

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

  /// What the camera counted, if it did. The entry only counts as
  /// camera-counted while the fields still match it.
  int? _camSets;
  int? _camReps;

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
    final again = widget.repeatOf;
    if (again != null && widget.editing == null) _fillFrom(again, ref.read(prefsProvider).useMetric);
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
    if (e.cameraCounted) {
      _camSets = e.sets;
      _camReps = e.reps;
    }
  }

  /// Fills the numbers from the last time this was done, so someone who repeats
  /// the same session does not retype it. Notes, effort and the camera mark are
  /// not copied, because they belong to that day; the date stays today's.
  void _useLast(WorkoutEntry last, bool metric) => setState(() => _fillFrom(last, metric));

  void _fillFrom(WorkoutEntry last, bool metric) {
    for (final c in [_sets, _reps, _minutes, _seconds, _distance, _load]) {
      c.clear();
    }
    _setIfPositive(_sets, last.sets);
    _setIfPositive(_reps, last.reps);
    _setDuration(last.durationSeconds);
    if ((last.distanceMeters ?? 0) > 0) {
      final km = last.distanceMeters! / 1000;
      _distance.text = _fmt(metric ? km : km / _kmPerMile);
    }
    if ((last.loadKg ?? 0) > 0) {
      _load.text = _fmt(metric ? last.loadKg! : last.loadKg! * _lbPerKg);
    }
    _variant = last.variant;
    _camSets = null;
    _camReps = null;
  }

  bool get _cameraCounted =>
      _camSets != null && _camReps != null && _int(_sets) == _camSets && _int(_reps) == _camReps;

  Future<void> _countWithCamera() async {
    final result = await Navigator.of(context).push<CameraRepResult>(
      gameRoute(CameraRepsScreen(activity: a, variant: _variant)),
    );
    if (result == null || !mounted) return;
    final sets = result.sets;
    final reps = (result.total / sets.length).round();
    setState(() {
      _sets.text = '${sets.length}';
      _reps.text = '$reps';
      _camSets = sets.length;
      _camReps = reps;
      // Uneven sets are averaged, so keep what was really counted.
      if (_notes.text.trim().isEmpty && sets.toSet().length > 1) {
        _notes.text = 'Camera counted: ${sets.join(', ')}';
      }
    });
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
    if (time == null || !mounted) return;
    // A time later today has not happened yet; settle on now instead.
    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => _when = picked.isAfter(now) ? now : picked);
  }

  /// The entry as the fields currently describe it.
  WorkoutEntry _buildEntry(bool metric) {
    final secs = (_int(_minutes) ?? 0) * 60 + (_int(_seconds) ?? 0);
    final dist = _dbl(_distance);
    final load = _dbl(_load);
    return WorkoutEntry(
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
      cameraCounted: _cameraCounted,
      // Entered now; an entry being edited keeps the time it was first logged.
      loggedAt: widget.editing == null ? ref.read(clockProvider)() : widget.editing!.loggedAt,
    );
  }

  /// Whether this workout, dated as it is now, would earn rewards. A workout
  /// moved to an earlier day is back-dated: journal only.
  bool get _earnsRewards {
    final e = widget.editing;
    final logged = e == null ? ref.read(clockProvider)() : (e.loggedAt ?? e.performedAt);
    return WorkoutEntry(activityId: a.id, performedAt: _when, loggedAt: logged).countsForRewards;
  }

  /// Anything about [entry] that looks unlikely to be real. Never blocks.
  /// Reps the camera counted need no second opinion.
  List<HonestyNote> _honestyNotes(WorkoutEntry entry, bool metric) {
    if (!entry.hasMeasurement || entry.cameraCounted) return const [];
    final day = dayKey(entry.performedAt);
    final sameDay = (ref.read(workoutsProvider).value ?? const <WorkoutEntry>[])
        .where((w) => dayKey(w.performedAt) == day);
    return const HonestyCheck().review(entry, sameDay: sameDay, metric: metric);
  }

  Future<void> _save() async {
    final metric = ref.read(prefsProvider).useMetric;
    final entry = _buildEntry(metric);

    if (!entry.hasMeasurement) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add at least a time, some reps, or a distance.'),
      ));
      return;
    }

    final concerns = _honestyNotes(entry, metric);
    if (concerns.isNotEmpty) {
      // A soft tap to get attention, nothing alarming: it is only a question.
      ref.read(feedbackProvider).haptic(Haptic.light);
      final accurate = await showGameDialog<bool>(
        context: context,
        title: 'Quick Honesty Check',
        content: _HonestyContent(notes: concerns),
        actions: [
          Builder(
            builder: (ctx) => GameButton(
              label: 'Let Me Fix It',
              icon: Icons.edit_rounded,
              kind: GameButtonKind.secondary,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ),
          Builder(
            builder: (ctx) => GameButton(
              label: 'It\'s Accurate',
              icon: Icons.check_circle,
              kind: GameButtonKind.positive,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ),
        ],
      );
      if (accurate != true || !mounted) return;
    }

    setState(() => _saving = true);
    final repo = ref.read(repositoryProvider);
    final journal = ref.read(workoutsProvider).value ?? const <WorkoutEntry>[];
    final firstEver = journal.isEmpty;
    final bests = PersonalBests.brokenBy(entry, journal);
    // Read what depends on the screen before the first wait: the player can
    // leave while it saves, and a screen that is gone cannot be asked anything.
    final today = ref.read(clockProvider)();
    final earns = _earnsRewards;
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (entry.id == null) {
        await repo.addWorkout(entry);
      } else {
        await repo.updateWorkout(entry);
      }
    } catch (_) {
      // Nothing was saved, so let them try again instead of leaving Save dead.
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(const SnackBar(content: Text('That could not be saved. Please try again.')));
      return;
    }
    if (!earns) {
      // Back-dated: saved for the journal, nothing to pay.
      if (!mounted) return;
      ref.read(feedbackProvider).both(Sfx.tap, Haptic.light);
      await showGameDialog<void>(
        context: context,
        title: 'Saved to Your Journal',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This workout was from an earlier day, so it is in your journal but earns no rewards. '
              'Rewards are for workouts you log on the day you do them.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            ChadBubble(text: ChadDialogue.line(ChadContext.backDated, seed: entry.performedAt.day)),
          ],
        ),
        actions: [
          Builder(
            builder: (ctx) => GameButton(
              label: 'Got It',
              icon: Icons.check_circle,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      );
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final reward = await repo.rewardForDay(entry.performedAt);
    // Pay any streak milestone this workout has reached. Never takes anything away.
    final streakPaid = await repo.claimStreakRewards(today: today);
    final streak = await repo.streakStatus(today: today);
    if (!mounted) return;
    // A chime and two soft pulses for a saved workout, and the fanfare when it
    // also set a personal best or reached a streak reward.
    ref.read(feedbackProvider).both(
          bests.isNotEmpty || streakPaid.isNotEmpty ? Sfx.fanfare : Sfx.saved,
          Haptic.success,
        );
    await showGameDialog<void>(
      context: context,
      title: 'Workout Saved!',
      content: _RewardContent(
        reward: reward,
        rules: repo.rules,
        forToday: dayKey(entry.performedAt) == dayKey(today),
        streakPaid: streakPaid,
        streak: streak,
        bests: bests,
        metric: metric,
        chadLine: ChadDialogue.line(
          firstEver
              ? ChadContext.firstWorkout
              : streakPaid.isNotEmpty
                  ? ChadContext.streakReward
                  : streak.startedFresh
                      ? ChadContext.freshStart
                      : reward.capReached
                          ? ChadContext.capReached
                          : ChadContext.afterWorkout,
          seed: entry.performedAt.day,
        ),
      ),
      actions: [
        Builder(
          builder: (ctx) => GameButton(
            label: 'Nice',
            icon: Icons.thumb_up_rounded,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ),
      ],
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

    return GameScaffold(
      title: editing ? 'Edit ${a.name}' : a.name,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          ExerciseDemoCard(
            activityId: a.id,
            variant: _variant,
            look: _demoLook(),
          ),
          const SizedBox(height: 12),
          GamePanel(
            color: const Color(0xFFFFF1CC),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates, color: GameColors.goldDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    [a.formCue, if (a.easierAlternative != null) a.easierAlternative].join(' '),
                    style: const TextStyle(color: GameColors.ink, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // An exercise they have done before shows their own marks, so they can see where they are.
          if (ref.watch(workoutsProvider).value case final journal? when journal.isNotEmpty) ...[
            const SizedBox(height: 10),
            Builder(builder: (context) {
              final recap = ExerciseRecap.of(journal, a.id, excludingId: widget.editing?.id);
              return PastMarks(
                recap: recap,
                entries: journal,
                metric: prefs.useMetric,
                // Repeating a session should not mean retyping it; editing has its own numbers already.
                onUseLast: editing || !recap.hasHistory ? null : () => _useLast(recap.last!, prefs.useMetric),
              );
            }),
          ],
          if (!editing && (ref.watch(workoutsProvider).value?.isEmpty ?? false)) ...[
            const SizedBox(height: 10),
            Semantics(
              container: true,
              label: '${FirstSteps.logTitle}. ${FirstSteps.logIntro} ${[for (final s in FirstSteps.logSteps) '${s.title}. ${s.text}'].join(' ')}',
              child: ExcludeSemantics(
                child: GamePanel(
                  key: const Key('first_log_panel'),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(FirstSteps.logTitle, style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        [for (var i = 0; i < FirstSteps.logSteps.length; i++) '${i + 1}. ${FirstSteps.logSteps[i].title}'].join('   '),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      const Text(FirstSteps.logIntro),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          GamePanel(
            title: 'Your Effort',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          onSelected: (on) {
                            ref.read(feedbackProvider).haptic(Haptic.select);
                            setState(() => _variant = on ? v : null);
                          },
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
                      if (a.metrics.contains(Metric.sets) && a.usesReps) const SizedBox(width: 12),
                      if (a.usesReps) Expanded(child: _intField(_reps, 'Reps per Set', 500)),
                    ],
                  ),
                if (RepProfile.supports(a.id) && ref.watch(poseCameraFactoryProvider) != null) ...[
                  const SizedBox(height: 12),
                  GameButton(
                    label: 'Count My Reps With the Camera',
                    icon: Icons.videocam_rounded,
                    kind: GameButtonKind.secondary,
                    onPressed: _countWithCamera,
                  ),
                  ListenableBuilder(
                    listenable: Listenable.merge([_sets, _reps]),
                    builder: (context, _) => !_cameraCounted
                        ? const SizedBox.shrink()
                        : const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(Icons.videocam_rounded, size: 18, color: GameColors.goldDark),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Counted by the camera. Change the numbers any time.',
                                    style: TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
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
                    child: GameButton(
                      label: _ticker != null ? 'Stop Timer ($_elapsedLabel)' : 'Use a Timer Instead',
                      icon: _ticker != null ? Icons.stop : Icons.timer_outlined,
                      kind: GameButtonKind.secondary,
                      expanded: false,
                      small: true,
                      onPressed: _toggleTimer,
                    ),
                  ),
                ],
                if (a.metrics.contains(Metric.distance)) ...[
                  const SizedBox(height: 12),
                  _decimalField(_distance, 'Distance (Optional)', prefs.useMetric ? 'km' : 'mi'),
                ],
                if (a.metrics.contains(Metric.load)) ...[
                  const SizedBox(height: 12),
                  _decimalField(_load, 'Weight (Optional)', prefs.useMetric ? 'kg' : 'lb'),
                ],
              ],
            ),
          ),
          ListenableBuilder(
            listenable: Listenable.merge([_sets, _reps, _minutes, _seconds, _distance]),
            builder: (context, _) {
              final notes = _honestyNotes(_buildEntry(prefs.useMetric), prefs.useMetric);
              if (notes.isEmpty) return const SizedBox(height: 16);
              return Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 16),
                child: GamePanel(
                  color: const Color(0xFFFFE3B8),
                  child: _HonestyContent(notes: notes, compact: true),
                ),
              );
            },
          ),
          GamePanel(
            title: 'Journal Entry',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How Did It Feel? (Optional, Just for You)', style: t.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      ChoiceChip(
                        label: Text(['Very Easy', 'Easy', 'Okay', 'Hard', 'Very Hard'][i - 1]),
                        selected: _effort == i,
                        onSelected: (on) {
                          ref.read(feedbackProvider).haptic(Haptic.select);
                          setState(() => _effort = on ? i : null);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('This never changes your rewards.', style: t.bodySmall),
                const SizedBox(height: 14),
                TextField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: const Text('When'),
                  subtitle: Text(DateFormat('EEE, MMM d · h:mm a').format(_when)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickWhen,
                ),
                if (!_earnsRewards)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE3B8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GameColors.goldDark, width: 2),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, color: GameColors.goldDark),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Back-dated: this goes in your journal but earns no rewards. '
                            'Rewards are for workouts you log on the day you do them.',
                            style: TextStyle(fontWeight: FontWeight.w700, color: GameColors.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GameButton(
            label: editing ? 'Save Changes' : 'Save Workout',
            icon: Icons.check_circle,
            kind: GameButtonKind.positive,
            onPressed: _saving ? null : _save,
          ),
          const SafetyNote(),
        ],
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

/// What looks off about an entry, and a reminder that only the player knows.
/// Shown live under the fields ([compact]) and again when saving.
class _HonestyContent extends StatelessWidget {
  const _HonestyContent({required this.notes, this.compact = false});

  final List<HonestyNote> notes;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: GameColors.ink, fontWeight: FontWeight.w600);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.visibility_rounded, color: GameColors.goldDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                compact ? 'Does This Look Right?' : 'This Looks Unusual',
                style: gameTitle(18, color: GameColors.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final n in notes) ...[
          Text(n.text, style: style),
          const SizedBox(height: 8),
        ],
        Text(
          'Nobody checks but you. The game only works if your log is true, '
          'and your real progress is the whole point. A typo is fine; nothing '
          'bad happens either way.',
          style: TextStyle(color: GameColors.inkSoft, fontSize: compact ? 13 : 14),
        ),
      ],
    );
  }
}

/// The reward summary shown in the "Workout Saved!" dialog.
class _RewardContent extends StatelessWidget {
  const _RewardContent({
    required this.reward,
    required this.rules,
    required this.forToday,
    required this.chadLine,
    required this.streakPaid,
    required this.streak,
    this.bests = const [],
    this.metric = true,
  });

  /// Marks this workout beat, if any. Just a pat on the back: never a reward.
  final List<PersonalBest> bests;
  final bool metric;
  final DayReward reward;
  final RewardRules rules;
  final bool forToday;
  final String chadLine;

  /// Streak milestones paid by this save (usually none).
  final List<StreakMilestone> streakPaid;
  final StreakStatus streak;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(forToday ? 'Rewards for today' : 'Rewards for that day',
            style: const TextStyle(fontWeight: FontWeight.w800, color: GameColors.inkSoft)),
        const SizedBox(height: 10),
        // A Wrap, so the two badges stack when text is large and the screen small.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 10,
          children: [
            _RewardBadge(icon: Icons.star_rounded, text: '${reward.xp} XP', color: GameColors.gold, delay: 0),
            _RewardBadge(icon: Icons.bolt_rounded, text: '${reward.energy} Energy', color: GameColors.teal, delay: 160),
          ],
        ),
        const SizedBox(height: 14),
        Text(rules.explain(reward)),
        if (bests.isNotEmpty) ...[
          const SizedBox(height: 14),
          _PersonalBestCard(bests: bests, metric: metric),
        ],
        for (final m in streakPaid) ...[
          const SizedBox(height: 14),
          _StreakRewardCard(milestone: m),
        ],
        if (streak.hasStreak && streakPaid.isEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF7043), size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${streak.current} active ${streak.current == 1 ? 'day' : 'days'} in a row. '
                  'Next reward at ${streak.next!.days}.',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: GameColors.inkSoft),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        ChadBubble(text: chadLine),
      ],
      ),
    );
  }
}

/// Shown when a workout beats one of the player's own marks. It is a note of
/// congratulation only: personal bests never change what a workout earns.
class _PersonalBestCard extends StatelessWidget {
  const _PersonalBestCard({required this.bests, required this.metric});

  final List<PersonalBest> bests;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    final lines = [for (final b in bests) '${b.kind.label}: ${b.describe(metric: metric)}'];
    return Semantics(
      label: 'New personal ${bests.length == 1 ? 'best' : 'bests'}. ${lines.join('. ')}',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFDFF3EE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GameColors.teal, width: 2.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: GameColors.teal),
                  const SizedBox(width: 6),
                  Expanded(child: Text(bests.length == 1 ? 'New Personal Best!' : 'New Personal Bests!', style: gameTitle(19))),
                ],
              ),
              const SizedBox(height: 4),
              for (final l in lines)
                Text(l, style: const TextStyle(fontWeight: FontWeight.w800, color: GameColors.ink)),
              const SizedBox(height: 4),
              const Text(
                'Your own marks, just for you to enjoy. They never change what you earn.',
                style: TextStyle(fontWeight: FontWeight.w600, color: GameColors.inkSoft, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The golden card shown when a workout reaches a streak milestone.
class _StreakRewardCard extends StatelessWidget {
  const _StreakRewardCard({required this.milestone});

  final StreakMilestone milestone;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Streak reward: ${milestone.title}. ${milestone.days} active days in a row. '
          'Plus ${milestone.coins} coins and ${milestone.xp} XP.',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE3B8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GameColors.gold, width: 2.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF7043)),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Streak Reward!', style: gameTitle(19))),
                ],
              ),
              const SizedBox(height: 4),
              Text('${milestone.title}: ${milestone.days} active days in a row',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: GameColors.ink)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.monetization_on, color: GameColors.goldDark, size: 20),
                    const SizedBox(width: 4),
                    Flexible(child: Text('+${milestone.coins} Coins', style: gameTitle(17))),
                  ]),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded, color: GameColors.goldDark, size: 20),
                    const SizedBox(width: 4),
                    Flexible(child: Text('+${milestone.xp} XP', style: gameTitle(17))),
                  ]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A reward tile that pops in with a bounce.
class _RewardBadge extends StatelessWidget {
  const _RewardBadge({required this.icon, required this.text, required this.color, required this.delay});

  final IconData icon;
  final String text;
  final Color color;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: GameColors.woodDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(height: 2),
          Text(text, style: gameTitle(20, color: GameColors.cream)),
        ],
      ),
    );
    if (still) return tile;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 700 + delay),
      curve: Interval(delay / (700 + delay), 1, curve: Curves.elasticOut),
      builder: (context, v, child) => Transform.scale(scale: v.clamp(0.0, 1.4), child: child),
      child: tile,
    );
  }
}
