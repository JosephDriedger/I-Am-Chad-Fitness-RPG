import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/game_ui.dart';
import 'title_lockup.dart';

/// The title screen shown on launch to a returning player.
class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key, required this.heroName, required this.level, required this.onContinue});

  final String heroName;
  final int level;
  final VoidCallback onContinue;

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  Timer? _auto;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    // Don't hold anyone up: carry on by itself after a moment.
    _auto = Timer(const Duration(milliseconds: 4200), _go);
  }

  void _go() {
    if (_gone) return;
    _gone = true;
    _auto?.cancel();
    widget.onContinue();
  }

  @override
  void dispose() {
    _auto?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      backgroundColor: GameColors.woodDark,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _go,
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              // Always at least the screen tall, so the content is centred on a tall phone and
              // scrolls on a short one (a phone on its side, or very large text).
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight - 40),
                child: IntrinsicHeight(
                  child: Column(
              children: [
                const Spacer(),
                TitleLockup(height: (box.maxHeight * 0.5).clamp(190.0, 340.0)),
                const Spacer(),
                Text('Welcome back, ${widget.heroName}!', style: gameTitle(26, color: GameColors.cream), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text('Level ${widget.level}', style: gameTitle(20, color: GameColors.gold)),
                const SizedBox(height: 22),
                _Pulse(
                  still: still,
                  child: GameButton(label: 'Tap to Continue', icon: Icons.touch_app_rounded, onPressed: _go),
                ),
                const SizedBox(height: 10),
                const Text(
                  'A game, not medical advice. Move at your own level.',
                  style: TextStyle(color: Color(0xFFBFA680), fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
                const SizedBox(height: 4),
              ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.child, required this.still});

  final Widget child;
  final bool still;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  // Made in initState, not on first use: with reduced motion it is never used while the
  // button is on screen, and creating it for the first time in dispose() is unsafe.
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.still) {
      _c.stop();
      return widget.child;
    }
    if (!_c.isAnimating) _c.repeat(reverse: true);
    return ScaleTransition(
      scale: Tween(begin: 0.97, end: 1.03).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

