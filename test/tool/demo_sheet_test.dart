// Not a real test: a QA tool that draws exercise demos into contact sheets.
//
//   DEMO_SHEET=<output dir> flutter test test/tool/demo_sheet_test.dart
//   DEMO_SHEET=<dir> DEMO_IDS=lunge,burpee flutter test test/tool/demo_sheet_test.dart
//
// Each row is one demo at four moments of its loop. Rows are listed in
// sheet_N.txt next to the image, because test fonts cannot draw labels.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/game/demo/exercise_demo.dart';
import 'package:i_am_chad/game/look.dart';

const _rowsPerSheet = 10;
const _times = [0.0, 0.25, 0.5, 0.75];

void main() {
  final out = Platform.environment['DEMO_SHEET'];
  final only = Platform.environment['DEMO_IDS']?.split(',').where((s) => s.isNotEmpty).toSet();

  testWidgets('draw demo contact sheets', (tester) async {
    final rows = <(String, String?)>[
      for (final a in ActivityCatalog.all)
        if (only == null || only.contains(a.id)) ...[
          (a.id, null),
          for (final v in a.variants) (a.id, v),
        ],
    ];
    await tester.runAsync(() async {
      Directory(out!).createSync(recursive: true);
      for (var s = 0; s * _rowsPerSheet < rows.length; s++) {
        final chunk = rows.skip(s * _rowsPerSheet).take(_rowsPerSheet).toList();
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        final legend = StringBuffer();
        for (var r = 0; r < chunk.length; r++) {
          final (id, variant) = chunk[r];
          final demo = demoFor(id, variant);
          legend.writeln('row ${r + 1}: $id${variant == null ? '' : ' / $variant'}'
              '${demo == null ? '  (NO DEMO)' : ''}');
          if (demo == null) continue;
          for (var c = 0; c < _times.length; c++) {
            canvas.save();
            canvas.translate(c * demoW, r * demoH);
            canvas.clipRect(const ui.Rect.fromLTWH(0, 0, demoW, demoH));
            paintDemo(canvas, demo, _times[c], const HeroLook(style: 1, skin: 3));
            canvas.restore();
            canvas.drawRect(
              ui.Rect.fromLTWH(c * demoW, r * demoH, demoW, demoH),
              ui.Paint()
                ..style = ui.PaintingStyle.stroke
                ..strokeWidth = 1.5
                ..color = const ui.Color(0xFF3A2A1C),
            );
          }
        }
        final image = await recorder
            .endRecording()
            .toImage((demoW * _times.length).round(), (demoH * chunk.length).round());
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        File('$out/sheet_$s.png').writeAsBytesSync(Uint8List.view(bytes.buffer));
        File('$out/sheet_$s.txt').writeAsStringSync(legend.toString());
      }
    });
  }, skip: out == null);
}
