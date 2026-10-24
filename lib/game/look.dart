/// Appearance data shared by the portrait widget and the game scenes.
library;

import 'package:flutter/material.dart';

import '../domain/cosmetics.dart';

class HeroLook {
  const HeroLook({
    this.style = 0,
    this.color = 0,
    this.skin = 0,
    this.equipped = const {},
    this.cape,
    this.dye,
  });

  final int style;
  final int color;
  final int skin;

  /// Ids of equipped items; drawn on the character.
  final Set<String> equipped;

  /// A cape other than the classic one, or null. Looks only (see cosmetics.dart).
  final Cape? cape;

  /// A hair dye replacing the natural colour, or null.
  final HairDye? dye;

  Color get tunic => colors[color % colors.length];
  Color get skinColor => skins[skin % skins.length];
  Color get hairColor =>
      dye != null ? Color(dye!.color) : hairColors[style % hairColors.length];

  static const colors = <Color>[
    Color(0xFF00796B),
    Color(0xFF3949AB),
    Color(0xFFD84315),
    Color(0xFF7B1FA2),
    Color(0xFF558B2F),
    Color(0xFFC2185B),
  ];
  static const colorNames = ['Teal', 'Indigo', 'Ember', 'Violet', 'Moss', 'Rose'];

  static const skins = <Color>[
    Color(0xFFFFDBB4),
    Color(0xFFF1C27D),
    Color(0xFFE0AC69),
    Color(0xFFC68642),
    Color(0xFF8D5524),
    Color(0xFF5C3A21),
  ];
  static const skinNames = ['Light', 'Fair', 'Medium', 'Tan', 'Brown', 'Deep'];

  static const styleNames = [
    'Short',
    'Long',
    'Spiky',
    'Bun',
    'Headband',
    'Hood',
  ];
  static const hairColors = <Color>[
    Color(0xFF3B2A20),
    Color(0xFF7A4A21),
    Color(0xFFE0A93B),
    Color(0xFF1E1E1E),
    Color(0xFF8E3B2E),
    Color(0xFF3B2A20),
  ];

  HeroLook copyWith({int? style, int? color, int? skin, Set<String>? equipped}) =>
      HeroLook(
        style: style ?? this.style,
        color: color ?? this.color,
        skin: skin ?? this.skin,
        equipped: equipped ?? this.equipped,
        cape: cape,
        dye: dye,
      );

  /// Whether two looks draw the same hero, for `shouldRepaint`.
  bool sameAs(HeroLook o) =>
      style == o.style &&
      color == o.color &&
      skin == o.skin &&
      cape?.id == o.cape?.id &&
      dye?.id == o.dye?.id &&
      equipped.length == o.equipped.length &&
      equipped.containsAll(o.equipped);
}

/// Mutable per-frame state that character painters read.
class ActorState {
  /// Seconds since the scene started; drives idle motion.
  double time = 0;

  /// Walk cycle phase in radians; only used while [walking] is true.
  double walkPhase = 0;
  bool walking = false;

  /// 0..1 weapon swing / lunge strength.
  double attack = 0;

  /// 0..1 telegraph for a heavy blow (lean back, glow).
  double windUp = 0;

  /// 0..1 hold-up-a-shield pose.
  double guard = 0;

  /// 0..1 fainted pose.
  double down = 0;
}
