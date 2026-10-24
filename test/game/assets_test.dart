import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/music.dart';
import 'package:i_am_chad/game/core.dart';

/// The samples of a 16-bit mono WAV written by the generator scripts.
List<int> _samples(Uint8List bytes) {
  final data = ByteData.sublistView(bytes, 44);
  return [for (var i = 0; i < data.lengthInBytes ~/ 2; i++) data.getInt16(i * 2, Endian.little)];
}

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

  group('music loops', () {
    for (final track in MusicTrack.values) {
      test('${track.name} is a valid, long, not-too-loud WAV that loops without a click', () {
        final f = File('assets/audio/${track.file}');
        expect(f.existsSync(), isTrue, reason: '${track.file} is missing');
        final bytes = f.readAsBytesSync();
        expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');

        final s = _samples(bytes);
        final rate = ByteData.sublistView(bytes).getUint32(24, Endian.little);
        final seconds = s.length / rate;
        expect(seconds, inInclusiveRange(10, 40), reason: 'a loop should last a while but stay small');
        expect(bytes.length, lessThan(1500 * 1024));

        // Never clips, and is never silent.
        final peak = s.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);
        expect(peak, lessThan(32767 * 0.9));
        expect(peak, greaterThan(32767 * 0.2));

        // The jump from the last sample back to the first is no bigger than the
        // jumps inside the music itself, so the loop point cannot be heard.
        var biggestStep = 0;
        for (var i = 1; i < s.length; i++) {
          final d = (s[i] - s[i - 1]).abs();
          if (d > biggestStep) biggestStep = d;
        }
        expect((s.first - s.last).abs(), lessThanOrEqualTo(biggestStep));
      });
    }
  });
}
