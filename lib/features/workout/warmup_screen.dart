import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/activity.dart';
import '../../domain/warmup.dart';
import '../../game/look.dart';
import 'exercise_demo_card.dart';

enum _Phase { intro, moving, done }

/// Chad's one-minute warm-up: an optional guided stretch with an animated
/// demonstration of each move. It pays nothing and saves nothing, can be paused
/// or skipped at any time, and nothing here is timed against the player: the
/// countdown only moves the guide along.
class WarmUpScreen extends ConsumerStatefulWidget {
  const WarmUpScreen({super.key});

  @override
  ConsumerState<WarmUpScreen> createState() => _WarmUpScreenState();
}

class _WarmUpScreenState extends ConsumerState<WarmUpScreen> {
  _Phase _phase = _Phase.intro;
  int _index = 0;
  int _left = 0;
  bool _paused = false;
  Timer? _timer;

  WarmUpStep get _step => WarmUp.steps[_index];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _begin() {
    setState(() {
      _phase = _Phase.moving;
      _index = 0;
      _left = _step.seconds;
      _paused = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_paused || _phase != _Phase.moving) return;
    if (_left > 1) {
      setState(() => _left--);
    } else {
      _next();
    }
  }

  void _next() {
    if (_index + 1 >= WarmUp.steps.length) {
      _timer?.cancel();
      setState(() => _phase = _Phase.done);
    } else {
      setState(() {
        _index++;
        _left = _step.seconds;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hero = ref.watch(heroProvider).value;
    final look = ref.watch(heroLookProvider) ??
        (hero == null
            ? const HeroLook()
            : HeroLook(style: hero.appearanceStyle, color: hero.appearanceColor, skin: hero.appearanceSkin));
    return GameScaffold(
      title: WarmUp.title,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: switch (_phase) {
          _Phase.intro => _intro(),
          _Phase.moving => _moving(look),
          _Phase.done => _done(),
        },
      ),
    );
  }

  List<Widget> _intro() => [
        const ChadBubble(text: WarmUp.intro),
        const SizedBox(height: 14),
        GamePanel(
          title: 'The Four Moves',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < WarmUp.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    '${i + 1}. ${ActivityCatalog.byId(WarmUp.steps[i].activityId)?.name ?? WarmUp.steps[i].activityId}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: 6),
              const Text(WarmUp.note, style: TextStyle(color: GameColors.inkSoft)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GameButton(label: 'Begin', icon: Icons.play_arrow_rounded, onPressed: _begin),
      ];

  List<Widget> _moving(HeroLook look) {
    final last = _index + 1 >= WarmUp.steps.length;
    final name = ActivityCatalog.byId(_step.activityId)?.name ?? '';
    return [
      Text('Move ${_index + 1} of ${WarmUp.steps.length}: $name', style: gameTitle(22)),
      const SizedBox(height: 8),
      ChadBubble(text: _step.chadLine),
      const SizedBox(height: 10),
      ExerciseDemoCard(activityId: _step.activityId, look: look),
      const SizedBox(height: 10),
      Semantics(
        label: _paused ? 'Paused' : '$_left seconds left on this move',
        child: ExcludeSemantics(
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: 1 - (_left - 1) / _step.seconds,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(_paused ? 'Paused' : '$_left s', style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: GameButton(
              label: _paused ? 'Resume' : 'Pause',
              icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              kind: GameButtonKind.secondary,
              onPressed: () => setState(() => _paused = !_paused),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GameButton(
              label: last ? 'Finish' : 'Next Move',
              icon: last ? Icons.check_rounded : Icons.skip_next_rounded,
              onPressed: _next,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _done() => [
        const ChadBubble(text: WarmUp.finish),
        const SizedBox(height: 16),
        GameButton(
          label: 'Back to the Yard',
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ];
}
