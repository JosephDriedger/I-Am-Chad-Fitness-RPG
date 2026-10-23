import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/feedback.dart';
import '../../app/game_ui.dart';
import '../../app/providers.dart';
import '../../domain/story.dart';
import '../../game/art/story_art.dart';
import '../../game/core.dart' show Haptic, Sfx;
import '../../game/look.dart';

/// Plays one chapter: a staged scene, a name tag and a line at a time. Tap to
/// read on. Always skippable. A few choices are remembered for later chapters.
///
/// Reading to the end, or skipping, marks the chapter read. Leaving with the
/// back button does not, so it stays marked as new.
class StoryScreen extends ConsumerStatefulWidget {
  const StoryScreen({super.key, required this.chapter});

  final StoryChapter chapter;

  @override
  ConsumerState<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends ConsumerState<StoryScreen>
    with TickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();
  late AnimationController _typing;

  late Map<String, int> _choices;
  int _scene = 0;
  int _i = 0;
  late List<StoryNode> _nodes;

  bool _title = true;
  bool _done = false;

  static const _msPerChar = 20;

  StoryScene get _current => widget.chapter.scenes[_scene];
  StoryNode? get _node => _i < _nodes.length ? _nodes[_i] : null;

  @override
  void initState() {
    super.initState();
    _choices = {...?ref.read(storyChoicesProvider).value};
    _nodes = StoryText.visible(_current, _choices);
    _typing = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1),
    );
  }

  @override
  void dispose() {
    _clock.dispose();
    _typing.dispose();
    super.dispose();
  }

  bool get _still =>
      MediaQuery.of(context).disableAnimations ||
      ref.read(prefsProvider).reducedMotion;

  String get _hero => ref.read(heroProvider).value?.name ?? 'Hero';

  HeroLook get _look {
    final h = ref.read(heroProvider).value;
    if (h == null) return const HeroLook();
    final owned = ref.read(itemsProvider).value;
    final equipped = <String>{
      if (owned != null)
        for (final o in owned)
          if (o.equipped) o.itemId,
    };
    return HeroLook(
      style: h.appearanceStyle,
      color: h.appearanceColor,
      skin: h.appearanceSkin,
      equipped: equipped,
    );
  }

  /// Starts revealing the line now showing, if it is a line.
  void _begin() {
    final n = _node;
    if (n is StoryLine) {
      final text = StoryText.fill(n.text, hero: _hero);
      _typing.duration = Duration(
        milliseconds: _still ? 1 : (text.length * _msPerChar).clamp(300, 4000),
      );
      _typing.forward(from: 0);
    }
    setState(() {});
  }

  bool get _typingNow => _typing.isAnimating;

  void _tap() {
    if (_title) {
      setState(() => _title = false);
      _begin();
      return;
    }
    if (_done) return;
    final n = _node;
    if (n is StoryChoice) return; // The buttons do the work.
    if (_typingNow) {
      _typing.value = 1;
      setState(() {});
      return;
    }
    ref.read(feedbackProvider).sfx(Sfx.tap);
    _advance();
  }

  void _advance() {
    _i++;
    if (_i >= _nodes.length) {
      if (_scene + 1 < widget.chapter.scenes.length) {
        _scene++;
        _i = 0;
        _nodes = StoryText.visible(_current, _choices);
        _begin();
      } else {
        _finish();
      }
      return;
    }
    _begin();
  }

  Future<void> _pick(StoryChoice choice, int option) async {
    final fx = ref.read(feedbackProvider);
    fx.sfx(Sfx.tap);
    fx.haptic(Haptic.light);
    _choices[choice.key] = option;
    // The reply plays next, then the story carries on from after the choice.
    _nodes.insertAll(_i + 1, choice.options[option].reply);
    unawaited(ref.read(repositoryProvider).saveStoryChoice(choice.key, option));
    _advance();
  }

  Future<void> _finish() async {
    await ref
        .read(repositoryProvider)
        .markChapterRead(widget.chapter.number, at: ref.read(clockProvider)());
    if (!mounted) return;
    setState(() => _done = true);
  }

  Future<void> _skip() async {
    await ref
        .read(repositoryProvider)
        .markChapterRead(widget.chapter.number, at: ref.read(clockProvider)());
    if (mounted) Navigator.of(context).pop(true);
  }

  static Color _colorOf(StorySpeaker s) => switch (s) {
    StorySpeaker.chad => const Color(0xFFE6B83C),
    StorySpeaker.maple => const Color(0xFF26837A),
    StorySpeaker.biscuit => const Color(0xFFA6683A),
    StorySpeaker.brad => const Color(0xFFC62828),
    StorySpeaker.oakhelm => const Color(0xFF4F7D3A),
    StorySpeaker.grit => const Color(0xFF7CB342),
    StorySpeaker.murmur => const Color(0xFF8E5BB5),
    _ => GameColors.wood,
  };

  @override
  Widget build(BuildContext context) {
    final n = _node;
    final speaker = n is StoryLine ? n.speaker : null;
    return Scaffold(
      backgroundColor: const Color(0xFF1B1109),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(flex: 11, child: _stage(speaker)),
            Expanded(flex: 8, child: _panel(n)),
          ],
        ),
      ),
    );
  }

  Widget _stage(StorySpeaker? speaker) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _tap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _clock,
                builder: (context, _) {
                  final t = _still ? 0.0 : _clock.value * 60;
                  return CustomPaint(
                    painter: _StagePainter(
                      scene: _current,
                      speaker: _done ? null : speaker,
                      look: _look,
                      time: t,
                    ),
                    size: size,
                  );
                },
              ),
              if (_title) _titleCard(),
              if (_done) _doneCard(),
              // Top bar, above the cards so you can always leave.
              Positioned(
                left: 8,
                right: 8,
                top: 8,
                child: Row(
                  children: [
                    GameIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Leave the Story',
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    const Spacer(),
                    if (!_done)
                      GameButton(
                        label: 'Skip',
                        icon: Icons.skip_next_rounded,
                        kind: GameButtonKind.secondary,
                        expanded: false,
                        small: true,
                        onPressed: _skip,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _titleCard() {
    return Container(
      color: const Color(0xCC1B1109),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Semantics(
        button: true,
        label:
            '${widget.chapter.label}: ${widget.chapter.title}. Tap to begin.',
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.chapter.label,
                style: gameTitle(22, color: GameColors.gold),
              ),
              const SizedBox(height: 10),
              Text(
                widget.chapter.title,
                textAlign: TextAlign.center,
                style: gameTitle(34, color: GameColors.cream),
              ),
              const SizedBox(height: 20),
              Text(
                Story.seasonTitle,
                style: const TextStyle(
                  color: Color(0xFFCDB68C),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Tap to begin',
                style: TextStyle(color: Color(0xFFCDB68C)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _doneCard() {
    final next = StoryRules.next(ref.read(playerProvider)?.level ?? 1);
    return Container(
      color: const Color(0xE61B1109),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            color: GameColors.gold,
            size: 44,
          ),
          const SizedBox(height: 10),
          Text(
            '${widget.chapter.label} Complete',
            style: gameTitle(28, color: GameColors.cream),
          ),
          const SizedBox(height: 10),
          Text(
            widget.chapter.summary,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE9D9B8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            next == null
                ? 'That is the end of this season. More is coming.'
                : 'The next chapter opens at Level ${next.unlockLevel}. There is no rush.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFCDB68C),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          GameButton(
            label: 'Back to the Hall',
            icon: Icons.home_rounded,
            kind: GameButtonKind.positive,
            expanded: false,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  Widget _panel(StoryNode? node) {
    final theme = GameColors.woodDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: theme,
        border: const Border(top: BorderSide(color: GameColors.gold, width: 3)),
      ),
      child: _title || _done
          ? const SizedBox.shrink()
          : switch (node) {
              StoryLine() => _lineView(node),
              StoryChoice() => _choiceView(node),
              null => const SizedBox.shrink(),
            },
    );
  }

  Widget _lineView(StoryLine line) {
    final full = StoryText.fill(line.text, hero: _hero);
    final narrator = line.speaker == StorySpeaker.narrator;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      child: Semantics(
        liveRegion: true,
        label: '${narrator ? '' : '${line.speaker.label} says: '}$full',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!narrator)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _colorOf(line.speaker),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GameColors.cream, width: 1.5),
                  ),
                  child: Text(
                    line.speaker.label,
                    style: gameTitle(17, color: Colors.white),
                  ),
                ),
              if (!narrator) const SizedBox(height: 8),
              Expanded(
                child: AnimatedBuilder(
                  animation: _typing,
                  builder: (context, _) {
                    final shown = (full.length * _typing.value).round().clamp(
                      0,
                      full.length,
                    );
                    return SingleChildScrollView(
                      child: Text(
                        full.substring(0, shown),
                        style: TextStyle(
                          color: GameColors.cream,
                          fontSize: 17,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          fontStyle: narrator
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: AnimatedBuilder(
                  animation: _typing,
                  builder: (context, _) => Opacity(
                    opacity: _typing.isAnimating ? 0 : 1,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: GameColors.gold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choiceView(StoryChoice choice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(choice.prompt, style: gameTitle(19, color: GameColors.gold)),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (var i = 0; i < choice.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GameButton(
                      label: choice.options[i].label,
                      kind: GameButtonKind.secondary,
                      onPressed: () => _pick(choice, i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StagePainter extends CustomPainter {
  _StagePainter({
    required this.scene,
    required this.speaker,
    required this.look,
    required this.time,
  });

  final StoryScene scene;
  final StorySpeaker? speaker;
  final HeroLook look;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    paintStoryBackdrop(canvas, size, scene.backdrop, time);
    paintStoryCast(
      canvas,
      size,
      cast: scene.cast,
      speaking: speaker,
      look: look,
      time: time,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StagePainter old) =>
      old.scene != scene ||
      old.speaker != speaker ||
      old.time != time ||
      old.look.style != look.style;
}
