import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart'
    show TextPainter, TextSpan, TextStyle, FontWeight, TextDirection;

import '../game/art/painters.dart';
import '../game/core.dart';
import '../game/look.dart';

/// Every character on one sheet, for checking the art. Dev preview only.
class CastScene extends GameScene {
  CastScene() : super(designWidth: 360, designHeight: 640);

  @override
  Color backgroundColor() => const Color(0xFFEFE2C4);

  @override
  Future<void> onLoad() async {
    final items = <(String, ActorPainter, double)>[
      ('Hero (Short, Teal)', (c, s) => paintHero(c, const HeroLook(), s), 1.5),
      ('Hero (Hood, Ember, Brown)', (c, s) => paintHero(c, const HeroLook(style: 5, color: 2, skin: 4), s), 1.5),
      ('Hero + gear', (c, s) => paintHero(c, const HeroLook(style: 2, color: 1, skin: 2, equipped: {'iron_blade', 'wayfarer_cap', 'trail_vest', 'stopwatch_charm'}), s), 1.5),
      ('Chad', paintChad, 1.3),
      ('Snooze Slime', paintSlime, 1.4),
      ('Fog Imp', paintImp, 1.4),
      ('Rusty Gear Golem', paintGolem, 1.4),
      ('Cobweb Wisp', paintCobwebWisp, 1.4),
      ('Pebble Gremlin', paintGremlin, 1.4),
      ('Mist Wisp', paintMistWisp, 1.4),
      ('Grumbling Treant', paintTreant, 0.95),
      ('Brad', paintBrad, 1.3),
    ];
    for (var i = 0; i < items.length; i++) {
      final col = i % 3, row = i ~/ 3;
      final x = 60.0 + col * 120;
      final y = 138.0 + row * 150;
      world.add(ActorComponent(
        painter: items[i].$2,
        position: Vector2(x, y),
        scaleFactor: items[i].$3,
      ));
      world.add(_Caption(items[i].$1, Vector2(x, y + 14)));
    }
  }
}

class _Caption extends PositionComponent {
  _Caption(String text, Vector2 p) : super(position: p) {
    _tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4A2F1A),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 110);
  }

  late final TextPainter _tp;

  @override
  void render(Canvas canvas) => _tp.paint(canvas, Offset(-_tp.width / 2, 0));
}
