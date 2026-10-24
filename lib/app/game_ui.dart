/// The game's UI kit: wood and parchment panels, chunky 3D buttons, a ribbon
/// header, dialogs and page transitions. Every screen outside the Flame
/// scenes is built from these so the whole app feels like one game.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/core.dart' show Haptic, Sfx;
import 'feedback.dart';

class GameColors {
  const GameColors._();

  static const ink = Color(0xFF3A2A1C);
  static const inkSoft = Color(0xFF6B5440);
  static const woodDark = Color(0xFF3F2814);
  static const wood = Color(0xFF6B4528);
  static const woodLight = Color(0xFF8A5A33);
  static const parchment = Color(0xFFF6E8C8);
  static const parchmentDark = Color(0xFFE8D3A5);
  static const cream = Color(0xFFFFF3D6);
  static const gold = Color(0xFFF2C94C);
  static const goldDark = Color(0xFFB8860B);
  static const green = Color(0xFF4CAF50);
  static const greenDark = Color(0xFF2E7D32);
  static const red = Color(0xFFD9534F);
  static const redDark = Color(0xFF9C2B28);
  static const teal = Color(0xFF3FB8AF);
  static const blue = Color(0xFF4F8FD6);
  static const purple = Color(0xFF8E5BB5);
}

const String gameFont = 'LilitaOne';

TextStyle gameTitle(double size, {Color color = GameColors.ink, double? letterSpacing}) => TextStyle(
      fontFamily: gameFont,
      fontSize: size,
      color: color,
      letterSpacing: letterSpacing,
      height: 1.1,
    );

// ---------------------------------------------------------------------------
// Page route
// ---------------------------------------------------------------------------

/// A menu-style transition: the page rises, fades and settles. Instant when
/// the player has asked for reduced motion.
Route<T> gameRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (context, animation, secondary, child) {
        if (MediaQuery.of(context).disableAnimations) return child;
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(curved),
            child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(curved), child: child),
          ),
        );
      },
    );

// ---------------------------------------------------------------------------
// Scaffold and header
// ---------------------------------------------------------------------------

class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.showBack = true,
    this.padding,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final bool showBack;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.parchment,
      body: Stack(
        children: [
          const Positioned.fill(child: _ParchmentBackground()),
          SafeArea(
            child: Column(
              children: [
                _Ribbon(title: title, showBack: showBack, actions: actions),
                Expanded(
                  child: padding == null ? child : Padding(padding: padding!, child: child),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.title, required this.showBack, required this.actions});

  final String title;
  final bool showBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GameColors.woodLight, GameColors.wood],
        ),
        border: Border(bottom: BorderSide(color: GameColors.gold, width: 3)),
        boxShadow: [BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          if (showBack && Navigator.of(context).canPop())
            GameIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: 6),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: gameTitle(26, color: GameColors.cream).copyWith(
                  shadows: const [Shadow(color: GameColors.woodDark, offset: Offset(0, 2), blurRadius: 0)],
                ),
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _ParchmentBackground extends StatelessWidget {
  const _ParchmentBackground();

  @override
  Widget build(BuildContext context) => const RepaintBoundary(child: CustomPaint(painter: _ParchmentPainter()));
}

class _ParchmentPainter extends CustomPainter {
  const _ParchmentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = GameColors.parchment);
    // Soft vignette toward the edges.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: const [Color(0x00000000), Color(0x22A0763A)],
        ).createShader(rect),
    );
    // Faint paper fibres.
    final r = math.Random(11);
    final fibre = Paint()
      ..color = const Color(0x0F6B4528)
      ..strokeWidth = 1;
    for (var i = 0; i < size.width * size.height / 2600; i++) {
      final x = r.nextDouble() * size.width;
      final y = r.nextDouble() * size.height;
      canvas.drawLine(Offset(x, y), Offset(x + 6 + r.nextDouble() * 12, y + r.nextDouble() * 3 - 1.5), fibre);
    }
  }

  @override
  bool shouldRepaint(_ParchmentPainter old) => false;
}

// ---------------------------------------------------------------------------
// Panels
// ---------------------------------------------------------------------------

/// A parchment card with a wooden frame. [title] adds a wooden banner on top.
class GamePanel extends StatelessWidget {
  const GamePanel({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(14),
    this.color = GameColors.parchment,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;
  final Color color;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GameColors.wood, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 4), blurRadius: 0)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                color: GameColors.wood,
                child: Text(title!, style: gameTitle(18, color: GameColors.cream)),
              ),
            // Its own Material, so list tiles and switches inside a panel can
            // paint their ink on top of the panel's decoration.
            Material(
              type: MaterialType.transparency,
              child: Padding(padding: padding, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small dark badge for numbers and statuses.
class GameChip extends StatelessWidget {
  const GameChip({super.key, required this.text, this.icon, this.color = GameColors.gold});

  final String text;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: GameColors.woodDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: GameColors.woodLight, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: 5)],
              // Flexible, so a long label at a large text size wraps instead of
              // running off the edge of the screen.
              Flexible(child: Text(text, style: const TextStyle(color: GameColors.cream, fontWeight: FontWeight.w800, fontSize: 13))),
            ],
          ),
        ),
      ),
    );
  }
}

/// A heading with a gold flourish underneath.
class GameHeading extends StatelessWidget {
  const GameHeading(this.text, {super.key, this.size = 22});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(text, style: gameTitle(size))),
          const SizedBox(height: 3),
          Container(
            height: 3,
            width: 54,
            decoration: BoxDecoration(color: GameColors.gold, borderRadius: BorderRadius.circular(2)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

enum GameButtonKind { primary, positive, secondary, danger }

/// A chunky 3D button that presses down, with a sound and a buzz.
class GameButton extends ConsumerStatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = GameButtonKind.primary,
    this.expanded = true,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GameButtonKind kind;
  final bool expanded;
  final bool small;

  @override
  ConsumerState<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends ConsumerState<GameButton> {
  bool _down = false;

  (Color top, Color bottom, Color edge, Color text) get _palette => switch (widget.kind) {
        GameButtonKind.primary => (const Color(0xFFFFD95E), const Color(0xFFF0B429), GameColors.goldDark, GameColors.ink),
        GameButtonKind.positive => (const Color(0xFF6CCB70), GameColors.green, GameColors.greenDark, Colors.white),
        GameButtonKind.secondary => (GameColors.woodLight, GameColors.wood, GameColors.woodDark, GameColors.cream),
        GameButtonKind.danger => (const Color(0xFFEB7A76), GameColors.red, GameColors.redDark, Colors.white),
      };

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final (top, bottom, edge, text) = enabled
        ? _palette
        : (const Color(0xFFD8CFC0), const Color(0xFFC4B9A6), const Color(0xFFA89C86), const Color(0xFF8A7F6C));
    final h = widget.small ? 40.0 : 52.0;
    const lift = 5.0;
    final pressed = _down && enabled;

    final face = Container(
      height: h,
      padding: EdgeInsets.symmetric(horizontal: widget.small ? 14 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[Icon(widget.icon, color: text, size: widget.small ? 18 : 22), const SizedBox(width: 8)],
          Flexible(
            child: Text(
              widget.label,
              overflow: TextOverflow.ellipsis,
              style: gameTitle(widget.small ? 16 : 20, color: text).copyWith(
                shadows: text == Colors.white
                    ? const [Shadow(color: Color(0x66000000), offset: Offset(0, 1.5), blurRadius: 0)]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          onTap: enabled
              ? () {
                  final fx = ref.read(feedbackProvider);
                  fx.sfx(Sfx.tap);
                  fx.haptic(Haptic.light);
                  widget.onPressed!();
                }
              : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48),
            child: Container(
              width: widget.expanded ? double.infinity : null,
              padding: EdgeInsets.only(top: pressed ? lift : 0, bottom: pressed ? 0 : lift),
              decoration: BoxDecoration(
                color: edge,
                borderRadius: BorderRadius.circular(16),
              ),
              child: face,
            ),
          ),
        ),
      ),
    );
  }
}

/// A round wooden icon button (back arrows, settings).
class GameIconButton extends ConsumerWidget {
  const GameIconButton({super.key, required this.icon, required this.onPressed, required this.tooltip});

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkResponse(
          onTap: () {
            final fx = ref.read(feedbackProvider);
            fx.sfx(Sfx.tap);
            fx.haptic(Haptic.light);
            onPressed();
          },
          // The round face stays 46 wide; the pressable area around it is the
          // 48 that phones' accessibility guidelines ask for.
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameColors.woodDark,
                  border: Border.all(color: GameColors.gold, width: 2),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 2), blurRadius: 0)],
                ),
                child: Icon(icon, color: GameColors.cream, size: 26),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs
// ---------------------------------------------------------------------------

/// A modal in the game's style, with a title banner and big buttons.
Future<T?> showGameDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<Widget> actions,
  bool dismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'Close',
    barrierColor: const Color(0x99000000),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, _) => SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Material(
            type: MaterialType.transparency,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: GamePanel(
                  title: title,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DefaultTextStyle.merge(style: const TextStyle(color: GameColors.ink, fontSize: 15, height: 1.35), child: content),
                      const SizedBox(height: 16),
                      for (final a in actions) ...[a, const SizedBox(height: 8)],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (ctx, anim, _, child) {
      if (MediaQuery.of(ctx).disableAnimations) return child;
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(curved), child: child),
      );
    },
  );
}
