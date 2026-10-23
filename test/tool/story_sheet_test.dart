// Not a real test: draws every story scene into a contact sheet for review.
//
//   STORY_SHEET=<output dir> flutter test test/tool/story_sheet_test.dart
//
// Each cell is one scene, with its first speaker in front. Scenes are listed
// in sheet.txt in reading order.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/story.dart';
import 'package:i_am_chad/game/art/story_art.dart';
import 'package:i_am_chad/game/look.dart';

const _cellW = 300.0;
const _cellH = 340.0;
const _cols = 4;

void main() {
  final out = Platform.environment['STORY_SHEET'];

  testWidgets('draw the story scenes', (tester) async {
    final cells = <(String, StoryScene)>[
      for (final c in Story.chapters)
        for (var i = 0; i < c.scenes.length; i++) ('${c.label} scene ${i + 1}: ${c.scenes[i].backdrop.name}', c.scenes[i]),
    ];
    await tester.runAsync(() async {
      Directory(out!).createSync(recursive: true);
      final rows = (cells.length / _cols).ceil();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final legend = StringBuffer();
      for (var i = 0; i < cells.length; i++) {
        final (name, scene) = cells[i];
        legend.writeln('${i + 1}: $name  cast: ${scene.cast.map((s) => s.name).join(', ')}');
        final x = (i % _cols) * _cellW, y = (i ~/ _cols) * _cellH;
        canvas.save();
        canvas.translate(x, y);
        canvas.clipRect(const ui.Rect.fromLTWH(0, 0, _cellW, _cellH));
        paintStoryBackdrop(canvas, const ui.Size(_cellW, _cellH), scene.backdrop, 1.0);
        final speaker = scene.nodes.whereType<StoryLine>().map((l) => l.speaker).firstWhere(
              (s) => s != StorySpeaker.narrator,
              orElse: () => scene.cast.first,
            );
        paintStoryCast(
          canvas,
          const ui.Size(_cellW, _cellH),
          cast: scene.cast,
          speaking: speaker,
          look: const HeroLook(style: 1, color: 2, skin: 3),
          time: 1.0,
        );
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
      File('$out/story.png').writeAsBytesSync(Uint8List.view(bytes.buffer));
      File('$out/story.txt').writeAsStringSync(legend.toString());
    });
  }, skip: out == null);
}
