import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/game/core.dart';

void main() {
  test('every Sfx has a valid WAV file in assets/audio', () {
    for (final s in Sfx.values) {
      final f = File('assets/audio/${s.name}.wav');
      expect(f.existsSync(), isTrue, reason: '${s.name}.wav is missing');
      final bytes = f.readAsBytesSync();
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
      expect(bytes.length, greaterThan(1000));
    }
  });
}
