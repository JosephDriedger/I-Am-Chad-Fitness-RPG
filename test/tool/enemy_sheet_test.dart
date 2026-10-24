// Not a real test: draws every enemy, each region's scenery and the camp props
// into a contact sheet for review.
//
//   ENEMY_SHEET=<output dir> flutter test test/tool/enemy_sheet_test.dart
//
// Cells are listed in sheet.txt in reading order.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/difficulty.dart';
import 'package:i_am_chad/domain/expedition.dart';
import 'package:i_am_chad/game/art/enemy_art.dart';
import 'package:i_am_chad/game/art/painters.dart';
import 'package:i_am_chad/game/battle_scene.dart';
import 'package:i_am_chad/game/look.dart';

const _cellW = 240.0;
const _cellH = 220.0;
const _cols = 5;
const _ground = 170.0;

Biome _biomeOf(Terrain t) => switch (t) {
      Terrain.meadow => Biome.meadow,
      Terrain.forest => Biome.forest,
      Terrain.coast => Biome.coast,
      Terrain.cave => Biome.cave,
      Terrain.peak => Biome.peak,
      Terrain.storm => Biome.storm,
    };

void main() {
  final out = Platform.environment['ENEMY_SHEET'];

  testWidgets('draw the enemies', (tester) async {
    final cells = <(String, Biome, void Function(ui.Canvas))>[
      for (final e in EnemyPool.everyone)
        (
          '${e.boss ? 'BOSS' : 'enemy'} region ${e.tier}: ${e.name}',
          e.boss ? Biome.arena : _biomeOf(Difficulty.region(e.tier).terrains.first),
          (c) {
            c.translate(_cellW * 0.55, _ground);
            c.scale(e.boss ? 1.5 : 1.8, e.boss ? 1.5 : 1.8);
            enemyPainter(e.name)(c, ActorState()..time = 1.3);
          },
        ),
      for (final r in Difficulty.regions)
        (
          'scenery region ${r.tier}: ${r.name}',
          _biomeOf(r.terrains.first),
          (c) {
            c.translate(_cellW * 0.3, _ground);
            c.scale(1.4, 1.4);
            paintHero(c, const HeroLook(style: 1, color: 2, skin: 3), ActorState()..time = 1.0);
          },
        ),
      (
        'bard',
        Biome.night,
        (c) {
          c.translate(_cellW * 0.5, _ground);
          c.scale(1.9, 1.9);
          paintBard(c, 1.2);
        },
      ),
      (
        'spring',
        Biome.night,
        (c) {
          c.translate(_cellW * 0.5, _ground);
          c.scale(1.9, 1.9);
          paintSpring(c, 1.2);
        },
      ),
    ];
    await tester.runAsync(() async {
      Directory(out!).createSync(recursive: true);
      final rows = (cells.length / _cols).ceil();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final legend = StringBuffer();
      for (var i = 0; i < cells.length; i++) {
        final (name, biome, draw) = cells[i];
        legend.writeln('${i + 1}: $name');
        final x = (i % _cols) * _cellW, y = (i ~/ _cols) * _cellH;
        canvas.save();
        canvas.translate(x, y);
        canvas.clipRect(const ui.Rect.fromLTWH(0, 0, _cellW, _cellH));
        canvas.save();
        Backdrop(biome, _ground).render(canvas);
        canvas.restore();
        draw(canvas);
        canvas.restore();
        canvas.drawRect(
          ui.Rect.fromLTWH(x, y, _cellW, _cellH),
          ui.Paint()
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const ui.Color(0xFF3A2A1C),
        );
      }
      final image = await recorder.endRecording().toImage((_cols * _cellW).round(), (rows * _cellH).round());
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      File('$out/enemies.png').writeAsBytesSync(Uint8List.view(bytes.buffer));
      File('$out/enemies.txt').writeAsStringSync(legend.toString());
    });
  }, skip: out == null);
}
