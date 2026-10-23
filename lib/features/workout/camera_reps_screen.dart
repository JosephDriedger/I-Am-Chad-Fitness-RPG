import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/feedback.dart';
import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../domain/activity.dart';
import '../../domain/hero.dart';
import '../../domain/pose.dart';
import '../../domain/rep_counter.dart';
import '../../game/core.dart' show Haptic, Sfx;
import '../../game/look.dart';
import 'camera_setup_guide.dart';
import 'pose_camera.dart';

/// What the camera counted: reps for each set the player finished.
class CameraRepResult {
  const CameraRepResult(this.sets);

  final List<int> sets;

  int get total => sets.fold(0, (a, b) => a + b);
}

enum _Stage { intro, starting, running, problem }

class _Live {
  const _Live(this.pose, this.update);

  final BodyPose? pose;
  final RepUpdate update;
}

/// Counts reps with the phone camera. Frames are processed on the device and
/// thrown away; see docs/ROADMAP.md ("Camera rep checking") for the thinking.
class CameraRepsScreen extends ConsumerStatefulWidget {
  const CameraRepsScreen({super.key, required this.activity, this.variant});

  final ActivityType activity;
  final String? variant;

  @override
  ConsumerState<CameraRepsScreen> createState() => _CameraRepsScreenState();
}

class _CameraRepsScreenState extends ConsumerState<CameraRepsScreen> {
  _Stage _stage = _Stage.intro;
  PoseCameraStatus? _problem;
  PoseCamera? _camera;
  StreamSubscription<PoseSample>? _sub;
  late RepCounter _counter;
  final _live = ValueNotifier<_Live?>(null);
  final _sets = <int>[];

  @override
  void initState() {
    super.initState();
    final level = ref.read(heroProvider).value?.experience ?? ExperienceLevel.returning;
    _counter = RepCounter(RepProfile.forActivity(
      widget.activity.id,
      variant: widget.variant,
      leniency: RepLeniency.forExperience(level),
    )!);
    // The camera maths assumes an upright phone.
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const []);
    unawaited(_sub?.cancel());
    unawaited(_camera?.dispose());
    _live.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final make = ref.read(poseCameraFactoryProvider);
    if (make == null) {
      setState(() {
        _problem = PoseCameraStatus.noCamera;
        _stage = _Stage.problem;
      });
      return;
    }
    setState(() => _stage = _Stage.starting);
    final camera = make();
    _camera = camera;
    final status = await camera.start();
    if (!mounted) return;
    if (status != PoseCameraStatus.ready) {
      setState(() {
        _problem = status;
        _stage = _Stage.problem;
      });
      return;
    }
    _sub = camera.poses.listen(_onSample);
    setState(() => _stage = _Stage.running);
  }

  void _onSample(PoseSample s) {
    final update = _counter.update(s.pose, s.millis);
    if (update.counted) {
      final fx = ref.read(feedbackProvider);
      fx.sfx(Sfx.tap);
      fx.haptic(Haptic.medium);
    }
    _live.value = _Live(s.pose, update);
  }

  int get _current => _counter.count;
  int get _total => _sets.fold(0, (a, b) => a + b) + _current;

  void _setDone() {
    if (_current == 0) return;
    setState(() => _sets.add(_current));
    _counter.reset();
    _live.value = null;
  }

  void _finish() {
    final sets = [..._sets, if (_current > 0) _current];
    Navigator.of(context).pop(sets.isEmpty ? null : CameraRepResult(sets));
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Count Your Reps',
      child: switch (_stage) {
        _Stage.intro => _intro(context),
        _Stage.starting => const Center(child: CircularProgressIndicator()),
        _Stage.running => _running(context),
        _Stage.problem => _problemView(context),
      },
    );
  }

  // ---- Intro --------------------------------------------------------------

  HeroLook _look() {
    final hero = ref.read(heroProvider).value;
    if (hero == null) return const HeroLook();
    return HeroLook(style: hero.appearanceStyle, color: hero.appearanceColor, skin: hero.appearanceSkin);
  }

  CameraSetupGuide _guide({bool diagram = true}) => CameraSetupGuide(
        activity: widget.activity,
        variant: widget.variant,
        look: _look(),
        metric: ref.read(prefsProvider).useMetric,
        showDiagram: diagram,
      );

  Future<void> _showSetupHelp() {
    final maxHeight = MediaQuery.of(context).size.height * 0.6;
    return showGameDialog<void>(
      context: context,
      title: 'How to Set Up',
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(child: _guide()),
      ),
      actions: [
        Builder(
          builder: (ctx) => GameButton(
            label: 'Got It',
            icon: Icons.thumb_up_rounded,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ),
      ],
    );
  }

  Widget _intro(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        GamePanel(title: 'Set Up Your Phone', child: _guide()),
        const SizedBox(height: 16),
        GamePanel(
          title: 'What It Does',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bullet(Icons.favorite_rounded,
                  'Go at your own pace. A smaller range of motion still counts, so there is no need to rush or strain.'),
              _bullet(Icons.info_outline_rounded,
                  'The camera only counts your reps. It does not grade your form.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GamePanel(
          title: 'Your Privacy',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.lock_rounded, color: GameColors.goldDark),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Everything happens on your phone. Nothing is recorded, saved or sent anywhere, '
                  'and the camera switches off when you leave this screen.',
                  style: TextStyle(color: GameColors.ink, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GameButton(
          label: 'Start Camera',
          icon: Icons.videocam_rounded,
          kind: GameButtonKind.positive,
          onPressed: _start,
        ),
        const SizedBox(height: 10),
        const Text(
          'Prefer not to use the camera? Just type your reps in. They earn exactly the same.',
          textAlign: TextAlign.center,
          style: TextStyle(color: GameColors.inkSoft),
        ),
      ],
    );
  }

  Widget _bullet(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: GameColors.goldDark),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: const TextStyle(color: GameColors.ink, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  // ---- Problems -----------------------------------------------------------

  Widget _problemView(BuildContext context) {
    final message = switch (_problem) {
      PoseCameraStatus.permissionDenied =>
        'The camera is switched off for I Am Chad. You can allow it in your phone\'s settings, '
            'or just type your reps in.',
      PoseCameraStatus.noCamera => 'There is no camera I can use here. Type your reps in instead.',
      _ => 'The camera would not start. You can try again, or type your reps in instead.',
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        GamePanel(
          title: 'No Camera Today',
          child: Text(message, style: const TextStyle(color: GameColors.ink, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        if (_problem == PoseCameraStatus.failed) ...[
          GameButton(label: 'Try Again', icon: Icons.refresh_rounded, onPressed: _start),
          const SizedBox(height: 10),
        ],
        GameButton(
          label: 'Back to Logging',
          icon: Icons.arrow_back_rounded,
          kind: GameButtonKind.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // ---- Running ------------------------------------------------------------

  String _cueText(RepCue cue) => switch (cue) {
        RepCue.showWholeBody => 'Step back a little so I can see all of you.',
        RepCue.getInPosition => widget.activity.id == 'squat'
            ? 'Stand tall to start.'
            : 'Get into your starting position, arms straight.',
        RepCue.goLower => 'A little lower and it counts!',
        RepCue.steady => 'Nice and steady, one rep at a time.',
        RepCue.none => 'Go at your own pace. I am counting.',
      };

  Widget _running(BuildContext context) {
    final camera = _camera!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: camera.previewAspect,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      camera.buildPreview(context),
                      ValueListenableBuilder<_Live?>(
                        valueListenable: _live,
                        builder: (context, live, _) => CustomPaint(
                          painter: _SkeletonPainter(
                            pose: live?.pose,
                            phase: live?.update.phase ?? RepPhase.searching,
                            mirrored: camera.mirrored,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: ValueListenableBuilder<_Live?>(
                          valueListenable: _live,
                          builder: (context, live, _) => _CountBadge(
                            count: live?.update.count ?? _counter.count,
                            set: _sets.length + 1,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        bottom: 10,
                        child: ValueListenableBuilder<_Live?>(
                          valueListenable: _live,
                          builder: (context, live, _) => _DepthGauge(depth: live?.update.depth ?? 0),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Row(
                          children: [
                            GameIconButton(
                              icon: Icons.help_outline_rounded,
                              tooltip: 'How to Set Up',
                              onPressed: _showSetupHelp,
                            ),
                            if (camera.canFlip) ...[
                              const SizedBox(width: 8),
                              GameIconButton(
                                icon: Icons.cameraswitch_rounded,
                                tooltip: 'Switch Camera',
                                onPressed: () async {
                                  await camera.flip();
                                  if (mounted) setState(() {});
                                },
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
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<_Live?>(
            valueListenable: _live,
            builder: (context, live, _) {
              final firstRep = _sets.isEmpty && _counter.count == 0;
              final phase = live?.update.phase;
              final seen = (live?.pose?.visibleMainJoints(minConfidence: 0.4) ?? 0) >= 8;
              final ready = phase == RepPhase.ready || phase == RepPhase.down;
              return Column(
                children: [
                  if (firstRep) ...[
                    Row(
                      children: [
                        Expanded(child: _SetupCheck(label: 'Whole Body in View', ok: seen)),
                        const SizedBox(width: 8),
                        Expanded(child: _SetupCheck(label: 'Ready Position', ok: ready)),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  ChadBubble(text: _cueText(live?.update.cue ?? RepCue.showWholeBody)),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<_Live?>(
                  valueListenable: _live,
                  builder: (context, live, _) => GameButton(
                    label: 'Set Done',
                    icon: Icons.flag_rounded,
                    kind: GameButtonKind.secondary,
                    onPressed: _counter.count > 0 ? _setDone : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ValueListenableBuilder<_Live?>(
                  valueListenable: _live,
                  builder: (context, live, _) => GameButton(
                    label: 'Finish',
                    icon: Icons.check_circle,
                    kind: GameButtonKind.positive,
                    onPressed: _total > 0 ? _finish : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One tick in the set-up check: green once the camera has what it needs.
class _SetupCheck extends StatelessWidget {
  const _SetupCheck({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? const Color(0xFF3E9B52) : GameColors.inkSoft;
    return Semantics(
      label: '$label: ${ok ? 'done' : 'not yet'}',
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: ok ? const Color(0xFFDDF3E1) : const Color(0xFFF3E7CC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: color, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The big rep counter.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.set});

  final int count;
  final int set;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Reps counted: $count, set $set',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: GameColors.woodDark.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GameColors.gold, width: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Text('$count', key: ValueKey(count), style: gameTitle(44, color: GameColors.cream)),
              ),
              Text('Set $set', style: const TextStyle(color: GameColors.gold, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fills as you get deeper; turns green once the rep would count.
class _DepthGauge extends StatelessWidget {
  const _DepthGauge({required this.depth});

  final double depth;

  @override
  Widget build(BuildContext context) {
    final reached = depth >= 1;
    return Container(
      width: 16,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white70, width: 2),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: FractionallySizedBox(
          heightFactor: depth.clamp(0.04, 1.0),
          widthFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: reached ? const Color(0xFF58C46B) : GameColors.gold,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the detected skeleton over the preview, so the player can see that
/// the camera has found them.
class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter({required this.pose, required this.phase, required this.mirrored});

  final BodyPose? pose;
  final RepPhase phase;
  final bool mirrored;

  static const _bones = [
    (Joint.leftShoulder, Joint.rightShoulder),
    (Joint.leftShoulder, Joint.leftElbow),
    (Joint.leftElbow, Joint.leftWrist),
    (Joint.rightShoulder, Joint.rightElbow),
    (Joint.rightElbow, Joint.rightWrist),
    (Joint.leftShoulder, Joint.leftHip),
    (Joint.rightShoulder, Joint.rightHip),
    (Joint.leftHip, Joint.rightHip),
    (Joint.leftHip, Joint.leftKnee),
    (Joint.leftKnee, Joint.leftAnkle),
    (Joint.rightHip, Joint.rightKnee),
    (Joint.rightKnee, Joint.rightAnkle),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final p = pose;
    if (p == null || p.width <= 0 || p.height <= 0) return;
    final color = switch (phase) {
      RepPhase.down => const Color(0xFF58C46B),
      RepPhase.ready => GameColors.gold,
      _ => Colors.white,
    };
    Offset? at(Joint j) {
      final jp = p[j];
      if (jp == null || jp.confidence < 0.45) return null;
      final x = jp.x / p.width * size.width;
      return Offset(mirrored ? size.width - x : x, jp.y / p.height * size.height);
    }

    final line = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in _bones) {
      final pa = at(a), pb = at(b);
      if (pa != null && pb != null) canvas.drawLine(pa, pb, line);
    }
    final dot = Paint()..color = color;
    final rim = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final j in Joint.values) {
      final o = at(j);
      if (o == null) continue;
      canvas.drawCircle(o, 7, dot);
      canvas.drawCircle(o, 7, rim);
    }
  }

  @override
  bool shouldRepaint(_SkeletonPainter old) =>
      old.pose != pose || old.phase != phase || old.mirrored != mirrored;
}
