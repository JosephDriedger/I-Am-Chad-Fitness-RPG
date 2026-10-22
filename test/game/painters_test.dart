import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/expedition.dart';
import 'package:i_am_chad/domain/items.dart';
import 'package:i_am_chad/game/art/painters.dart';
import 'package:i_am_chad/game/look.dart';

Canvas _canvas() => Canvas(PictureRecorder());

/// Poses that exercise every branch of the painters.
List<ActorState> _poses() {
  final out = <ActorState>[];
  for (final t in [0.0, 1.3, 4.1]) {
    out
      ..add(ActorState()..time = t)
      ..add(ActorState()
        ..time = t
        ..walking = true
        ..walkPhase = t * 3)
      ..add(ActorState()
        ..time = t
        ..attack = 1)
      ..add(ActorState()
        ..time = t
        ..windUp = 1
        ..guard = 1
        ..down = 1);
  }
  return out;
}

void main() {
  group('character painters', () {
    test('hero draws for every style, colour and skin without throwing', () {
      for (var style = 0; style < HeroLook.styleNames.length; style++) {
        for (var color = 0; color < HeroLook.colors.length; color++) {
          for (var skin = 0; skin < HeroLook.skins.length; skin++) {
            final look = HeroLook(style: style, color: color, skin: skin);
            for (final pose in _poses()) {
              paintHero(_canvas(), look, pose);
            }
          }
        }
      }
    });

    test('hero draws with every item equipped, alone and together', () {
      final ids = [for (final i in ItemCatalog.all) i.id];
      for (final equipped in [
        <String>{},
        ...[for (final id in ids) {id}],
        ids.toSet(),
      ]) {
        for (final pose in _poses()) {
          paintHero(_canvas(), HeroLook(style: 5, equipped: equipped), pose);
        }
      }
    });

    test('out-of-range appearance values wrap instead of crashing', () {
      paintHero(_canvas(), const HeroLook(style: 99, color: 99, skin: 99), ActorState());
      paintHeroPortrait(_canvas(), 48, const HeroLook(style: 41, color: 17, skin: 8), 0);
    });

    test('portrait draws at HUD and onboarding sizes', () {
      for (final size in [28.0, 48.0, 96.0]) {
        paintHeroPortrait(_canvas(), size, const HeroLook(style: 5), 1.2);
      }
    });

    test('Chad and Brad draw in every pose', () {
      for (final pose in _poses()) {
        paintChad(_canvas(), pose);
        paintBrad(_canvas(), pose);
      }
    });
  });

  group('enemy painters', () {
    test('every enemy in the game has art and draws in every pose', () {
      final names = [
        for (final e in [...EnemyPool.regular, ...EnemyPool.bosses]) e.name,
      ];
      expect(names.toSet().length, names.length);
      for (final name in names) {
        final painter = enemyPainter(name);
        for (final pose in _poses()) {
          painter(_canvas(), pose);
        }
      }
    });

    test('an unknown enemy falls back to a friendly blob', () {
      enemyPainter('Future Monster')(_canvas(), ActorState());
    });

    test('each enemy has its own painter (none silently falls back)', () {
      final fallback = enemyPainter('Future Monster');
      for (final e in [...EnemyPool.regular, ...EnemyPool.bosses]) {
        if (e.name == 'Snooze Slime') continue; // the slime is the fallback
        expect(enemyPainter(e.name), isNot(same(fallback)), reason: e.name);
      }
    });
  });

  group('props and icons', () {
    test('props draw', () {
      paintCampfire(_canvas(), 0.7);
      paintMerchantCart(_canvas(), 0.7);
      for (final open in [0.0, 0.5, 1.0]) {
        paintChest(_canvas(), open, open);
      }
    });
  });
}
