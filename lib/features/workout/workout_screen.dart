import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/feedback.dart';
import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/activity.dart';
import '../../game/core.dart' show Haptic, Sfx;
import '../../game/demo/exercise_demo.dart';
import '../../game/look.dart';
import 'log_workout_screen.dart';

/// The training yard: pick an exercise card. Every card shows the exercise
/// itself, and free-form logging is always available (quests from the hall
/// just pre-fill the same form). With a large catalog you can search, filter
/// by category, or show only what you can do at home.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  final _search = TextEditingController();
  ActivityCategory? _category;
  bool _atHomeOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _filtering =>
      _search.text.trim().isNotEmpty || _category != null || _atHomeOnly;

  List<ActivityType> _matches() {
    final q = _search.text.trim().toLowerCase();
    return [
      for (final a in ActivityCatalog.all)
        if ((_category == null || a.category == _category) &&
            (!_atHomeOnly || a.equipment.atHome) &&
            (q.isEmpty ||
                a.name.toLowerCase().contains(q) ||
                a.category.label.toLowerCase().contains(q) ||
                a.equipment.label.toLowerCase().contains(q)))
          a,
    ];
  }

  void _clear() => setState(() {
    _search.clear();
    _category = null;
    _atHomeOnly = false;
  });

  @override
  Widget build(BuildContext context) {
    final hero = ref.watch(heroProvider).value;
    final look = hero == null
        ? const HeroLook()
        : HeroLook(
            style: hero.appearanceStyle,
            color: hero.appearanceColor,
            skin: hero.appearanceSkin,
          );
    final matches = _matches();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const ChadBubble(
          text:
              'Pick what you did. Any version counts, and you can edit or delete it later.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search Exercises',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear Search',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(_search.clear),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip(
                'All',
                _category == null,
                () => setState(() => _category = null),
              ),
              for (final c in ActivityCategory.values)
                _chip(
                  c.label,
                  _category == c,
                  () => setState(() => _category = _category == c ? null : c),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // A Wrap, so the count drops to a second line when text is large.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            FilterChip(
              label: const Text('At Home Only'),
              avatar: const Icon(Icons.home_rounded, size: 18),
              selected: _atHomeOnly,
              onSelected: (v) => setState(() => _atHomeOnly = v),
            ),
            Text(
              '${matches.length} ${matches.length == 1 ? 'Exercise' : 'Exercises'}',
              style: const TextStyle(
                color: GameColors.inkSoft,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        if (matches.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: GamePanel(
              title: 'No Exercises Match',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Try a different word, or clear the filters. You can also log something the list does not have '
                    'with Light Mobility or Stretching.',
                    style: TextStyle(
                      color: GameColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GameButton(
                    label: 'Clear Filters',
                    icon: Icons.filter_alt_off_rounded,
                    onPressed: _clear,
                  ),
                ],
              ),
            ),
          )
        else
          for (final c in ActivityCategory.values)
            ..._section(c, matches, look),
        const SafetyNote(),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );

  List<Widget> _section(
    ActivityCategory c,
    List<ActivityType> matches,
    HeroLook look,
  ) {
    final inCategory = matches.where((a) => a.category == c).toList();
    if (inCategory.isEmpty) return const [];
    return [
      const SizedBox(height: 8),
      GameHeading(_filtering ? '${c.label} (${inCategory.length})' : c.label),
      for (var i = 0; i < inCategory.length; i += 2)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ExerciseCard(activity: inCategory[i], look: look),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < inCategory.length
                      ? _ExerciseCard(activity: inCategory[i + 1], look: look)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
    ];
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({required this.activity, required this.look});

  final ActivityType activity;
  final HeroLook look;

  static String _metrics(ActivityType a) {
    final names = <String>[
      if (a.metrics.contains(Metric.sets)) 'sets',
      if (a.metrics.contains(Metric.reps)) 'reps',
      if (a.metrics.contains(Metric.duration)) 'time',
      if (a.metrics.contains(Metric.distance)) 'distance',
      if (a.metrics.contains(Metric.load)) 'weight',
    ];
    return names.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = demoFor(activity.id);
    final gear = activity.equipment == Equipment.none
        ? null
        : activity.equipment.label;
    return Semantics(
      button: true,
      label:
          '${activity.name}. ${gear == null ? '' : 'Needs ${gear.toLowerCase()}. '}Record ${_metrics(activity)}.',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: () {
            final fx = ref.read(feedbackProvider);
            fx.sfx(Sfx.tap);
            fx.haptic(Haptic.light);
            Navigator.of(
              context,
            ).push(gameRoute(LogWorkoutScreen(activity: activity)));
          },
          child: GamePanel(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (demo != null)
                  AspectRatio(
                    aspectRatio: demoW / demoH,
                    child: CustomPaint(painter: _ThumbPainter(demo, look)),
                  ),
                Container(height: 3, color: GameColors.wood),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.name,
                        style: gameTitle(17),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _metrics(activity),
                        style: const TextStyle(
                          color: GameColors.inkSoft,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (gear != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.handyman_rounded,
                              size: 13,
                              color: GameColors.goldDark,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                gear,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: GameColors.goldDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A still frame of the exercise, mid-movement.
class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.config, this.look);

  final DemoConfig config;
  final HeroLook look;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / demoW, size.height / demoH);
    canvas.clipRect(const Rect.fromLTWH(0, 0, demoW, demoH));
    paintDemo(canvas, config, config.keyTimes.last, look);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ThumbPainter old) =>
      old.config != config ||
      old.look.style != look.style ||
      old.look.color != look.color ||
      old.look.skin != look.skin;
}
