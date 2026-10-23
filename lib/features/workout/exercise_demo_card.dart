import 'package:flutter/material.dart';

import '../../game/demo/exercise_demo.dart';
import '../../game/look.dart';

/// A looping animated demonstration of how to do an exercise, with cues that
/// follow the movement. Honours the system "reduce motion" setting by showing
/// still key poses you can step through instead.
class ExerciseDemoCard extends StatefulWidget {
  const ExerciseDemoCard({
    super.key,
    required this.activityId,
    this.variant,
    this.look = const HeroLook(),
  });

  final String activityId;
  final String? variant;
  final HeroLook look;

  @override
  State<ExerciseDemoCard> createState() => _ExerciseDemoCardState();
}

class _ExerciseDemoCardState extends State<ExerciseDemoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  DemoConfig? _config;
  bool _playing = true;
  int _step = 0;
  bool _reduce = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _configure();
  }

  @override
  void didUpdateWidget(ExerciseDemoCard old) {
    super.didUpdateWidget(old);
    if (old.activityId != widget.activityId || old.variant != widget.variant) {
      _step = 0;
      _configure();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce != _reduce) {
      _reduce = reduce;
      _syncPlayback();
    }
  }

  void _configure() {
    _config = demoFor(widget.activityId, widget.variant);
    final c = _config;
    if (c != null) {
      _ctrl.duration = Duration(milliseconds: (c.seconds * 1000).round());
    }
    _syncPlayback();
  }

  void _syncPlayback() {
    if (_config == null) return;
    if (_playing && !_reduce) {
      _ctrl.repeat();
    } else {
      _ctrl.stop();
      _ctrl.value = _config!.keyTimes[_step % _config!.keyTimes.length];
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    _syncPlayback();
  }

  void _nextStep() {
    final c = _config!;
    setState(() => _step = (_step + 1) % c.keyTimes.length);
    _ctrl.value = c.keyTimes[_step];
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    if (config == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final animated = _playing && !_reduce;

    return Semantics(
      container: true,
      label: 'How to do ${config.title}. ${config.cues.join(' ')}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.play_circle_outline, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('How to Do It: ${config.title}', style: t.titleSmall),
                  ),
                  if (_reduce)
                    TextButton.icon(
                      onPressed: _nextStep,
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Next Pose'),
                    )
                  else
                    IconButton(
                      tooltip: animated ? 'Pause Demo' : 'Play Demo',
                      onPressed: _togglePlay,
                      icon: Icon(animated ? Icons.pause_circle : Icons.play_circle),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: demoW / demoH,
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: _DemoPainter(config, _ctrl, widget.look),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        '${(_ctrl.value.clamp(0.0, 0.9999) * config.cues.length).floor() + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(config.cueAt(_ctrl.value))),
                  ],
                ),
              ),
              if (config.note != null) ...[
                const SizedBox(height: 6),
                Text(config.note!, style: t.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoPainter extends CustomPainter {
  _DemoPainter(this.config, this.ctrl, this.look) : super(repaint: ctrl);

  final DemoConfig config;
  final AnimationController ctrl;
  final HeroLook look;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / demoW, size.height / demoH);
    canvas.clipRect(const Rect.fromLTWH(0, 0, demoW, demoH));
    paintDemo(canvas, config, ctrl.value % 1.0, look);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DemoPainter old) =>
      old.config != config || old.look.style != look.style || old.look.skin != look.skin || old.look.color != look.color;
}
