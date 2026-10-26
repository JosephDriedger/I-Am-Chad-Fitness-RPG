import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/calm.dart';

enum _Stage { intro, breathing, done }

/// Chad's calm minute: a circle that swells and settles at a slow pace, with a
/// word for each part of the breath. It pays nothing and saves nothing, can be
/// paused or ended at any time, and the circle only sets a pace: nothing is
/// measured, and nothing here asks for a particular depth of breath.
class CalmScreen extends ConsumerStatefulWidget {
  const CalmScreen({super.key});

  @override
  ConsumerState<CalmScreen> createState() => _CalmScreenState();
}

class _CalmScreenState extends ConsumerState<CalmScreen> {
  _Stage _stage = _Stage.intro;
  int _elapsed = 0;
  bool _paused = false;

  /// The circle starts small, then swells on the first frame, so the first breath is seen.
  bool _primed = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _begin() {
    setState(() {
      _stage = _Stage.breathing;
      _elapsed = 0;
      _paused = false;
      _primed = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _primed = true);
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_paused || _stage != _Stage.breathing) return;
    if (_elapsed + 1 >= Calm.totalSeconds) {
      _finish();
    } else {
      setState(() => _elapsed++);
    }
  }

  void _finish() {
    _timer?.cancel();
    setState(() => _stage = _Stage.done);
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: Calm.title,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: switch (_stage) {
          _Stage.intro => _intro(),
          _Stage.breathing => _breathing(),
          _Stage.done => _done(),
        },
      ),
    );
  }

  List<Widget> _intro() => [
        const ChadBubble(text: Calm.intro),
        const SizedBox(height: 14),
        GamePanel(
          title: 'The Pace',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final p in CalmPhase.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text('${p.label}: ${p.seconds} seconds', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              const SizedBox(height: 6),
              const Text(Calm.note, style: TextStyle(color: GameColors.inkSoft)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GameButton(key: const Key('calm_begin'), label: 'Begin', icon: Icons.play_arrow_rounded, onPressed: _begin),
      ];

  List<Widget> _breathing() {
    final now = Calm.at(_elapsed) ?? (breath: Calm.breaths - 1, phase: CalmPhase.exhale, left: 1);
    final reduced = ref.watch(prefsProvider.select((p) => p.reducedMotion));
    // The circle's size at the end of this part of the breath. It is set once, when the part
    // begins, and animates there over the part's own length, so it slows down with the breath.
    final big = _primed && now.phase != CalmPhase.exhale;
    final size = big ? 190.0 : 110.0;
    return [
      Text('Breath ${now.breath + 1} of ${Calm.breaths}', style: gameTitle(22)),
      const SizedBox(height: 8),
      ChadBubble(text: Calm.cues[now.breath.clamp(0, Calm.cues.length - 1)]),
      const SizedBox(height: 14),
      Semantics(
        liveRegion: true,
        label: _paused ? 'Paused' : '${now.phase.label}, ${now.left} seconds',
        child: ExcludeSemantics(
          child: SizedBox(
            height: 210,
            child: Center(
              child: AnimatedContainer(
                key: const Key('calm_circle'),
                duration: reduced || _paused ? Duration.zero : Duration(seconds: now.phase.seconds),
                curve: Curves.easeInOut,
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(colors: [GameColors.cream, GameColors.gold]),
                  border: Border.all(color: GameColors.wood, width: 3),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _paused ? 'Paused' : now.phase.label,
                      key: const Key('calm_phase'),
                      textAlign: TextAlign.center,
                      style: gameTitle(20),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
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
              key: const Key('calm_finish'),
              label: 'Finish',
              icon: Icons.check_rounded,
              onPressed: _finish,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _done() => [
        const ChadBubble(text: Calm.finish),
        const SizedBox(height: 16),
        GameButton(
          key: const Key('calm_back'),
          label: 'Back to the Yard',
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ];
}
