import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/hero.dart' show Progression;
import 'package:i_am_chad/domain/story.dart';
import 'package:i_am_chad/domain/story_pack.dart';

import '../../tool/story_content/content.dart';

Map<String, Object?> _pack(int season) => jsonDecode(StoryContent.files()['season_$season.json']!) as Map<String, Object?>;

String _text(Map<String, Object?> pack) => jsonEncode(pack);

/// Changes the first scene of the first chapter of season 2's pack.
String _tweaked(void Function(Map<String, dynamic> firstScene) change) {
  final pack = _pack(2);
  final scene = ((pack['chapters'] as List).first as Map)['scenes'].first as Map<String, dynamic>;
  change(scene);
  return _text(pack);
}

void main() {
  group('what stays in the app and what is downloaded', () {
    test('Season One is part of the app and the later seasons are not', () {
      expect(Story.seasons.first.isDownloaded, isFalse);
      for (final c in Story.inSeason(1)) {
        expect(c.hasScenes, isTrue, reason: c.title);
      }
      for (final season in Story.seasons.skip(1)) {
        expect(season.isDownloaded, isTrue);
        for (final c in Story.inSeason(season.number)) {
          expect(c.hasScenes, isFalse, reason: '${c.title} is downloaded, not carried');
        }
      }
    });

    test('the catalog the app carries matches the scripts: same place, title, level and summary', () {
      expect(Story.chapters.length, StoryContent.chapters.length);
      for (var i = 0; i < Story.chapters.length; i++) {
        final app = Story.chapters[i], script = StoryContent.chapters[i];
        expect(app.number, script.number);
        expect(app.season, script.season, reason: script.title);
        expect(app.title, script.title);
        expect(app.unlockLevel, script.unlockLevel, reason: script.title);
        expect(app.summary, script.summary, reason: script.title);
      }
    });

    test('opening a chapter never depends on a download: levels and numbers come from the app', () {
      expect(StoryRules.unlocked(Progression.maxLevel).length, StoryContent.chapters.length);
      expect(StoryRules.next(16)!.number, 8);
      expect(Story.byNumber(24)!.title, StoryContent.byNumber(24).title);
    });
  });

  group('the published files', () {
    test('docs/packs is up to date with the scripts (run: dart run tool/build_packs.dart)', () {
      for (final e in StoryContent.files().entries) {
        final file = File('docs/packs/${e.key}');
        expect(file.existsSync(), isTrue, reason: '${e.key} is missing');
        expect(utf8.decode(file.readAsBytesSync()), e.value, reason: '${e.key} is out of date');
      }
      final published = Directory('docs/packs').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(published, StoryContent.files().keys.toSet(), reason: 'nothing stray is published');
    });

    test('the manifest lists every downloaded season, with sizes and checksums that are true', () {
      final files = StoryContent.files();
      final manifest = PackManifest.decode(files['manifest.json']!);
      expect({for (final p in manifest.packs) p.season}, {for (final s in Story.seasons.where((s) => s.isDownloaded)) s.number});
      for (final p in manifest.packs) {
        final bytes = utf8.encode(files[p.file]!);
        expect(p.bytes, bytes.length);
        expect(p.sha256, sha256.convert(bytes).toString());
        expect(p.bytes, lessThan(StoryPacks.maxBytes ~/ 4), reason: 'a season is a small download');
        expect(StoryContent.versions[p.season], p.version);
      }
    });

    test('every pack reads back to exactly the script it was made from', () {
      for (final season in [2, 3, 4]) {
        final text = StoryContent.files()['season_$season.json']!;
        final scenes = StoryPacks.decode(text, season: season);
        final rebuilt = StoryPacks.encode(
          season: season,
          version: StoryContent.versions[season]!,
          chapters: [for (final c in Story.inSeason(season)) c.withScenes(scenes[c.number]!)],
        );
        expect(rebuilt, text, reason: 'season $season');
        expect(scenes.keys.toList(), [for (final c in Story.inSeason(season)) c.number]);
      }
    });
  });

  group('a pack that is not right is refused whole', () {
    final good = StoryContent.files()['season_2.json']!;

    PackFormatException refusal(String text, {int season = 2}) {
      try {
        StoryPacks.decode(text, season: season);
      } on PackFormatException catch (e) {
        return e;
      }
      fail('expected the pack to be refused');
    }

    test('the real one is accepted', () => expect(StoryPacks.decode(good, season: 2), isNotEmpty));

    test('text that is not a pack', () {
      refusal('not json');
      refusal('[]');
      refusal('{}');
    });

    test('a pack for another season, or for a newer game', () {
      refusal(good, season: 3);
      final newer = _pack(2)..['format'] = StoryPacks.format + 1;
      expect(refusal(_text(newer)).message, 'newer-app');
    });

    test('a speaker or a backdrop this game cannot draw', () {
      expect(refusal(_tweaked((s) => s['backdrop'] = 'spaceStation')).message, contains('spaceStation'));
      expect(refusal(_tweaked((s) => (s['cast'] as List)[0] = 'dragon')).message, contains('dragon'));
    });

    test('someone speaking who is not in the scene', () {
      expect(
        refusal(_tweaked((s) {
          s['cast'] = <String>['chad'];
          ((s['nodes'] as List).firstWhere((n) => n['t'] == 'line' && n['speaker'] != 'narrator') as Map)['speaker'] = 'wren';
        })).message,
        contains('without being in the scene'),
      );
    });

    test('a chapter the app does not list, a missing chapter, or a changed title', () {
      final extra = _pack(2);
      ((extra['chapters'] as List).first as Map)['number'] = 99;
      refusal(_text(extra));

      final fewer = _pack(2);
      (fewer['chapters'] as List).removeLast();
      expect(refusal(_text(fewer)).message, contains('missing'));

      final renamed = _pack(2);
      ((renamed['chapters'] as List).first as Map)['title'] = 'Something Else';
      expect(refusal(_text(renamed)).message, contains('title'));
    });

    test('nodes, text and conditions that are malformed or far too big', () {
      refusal(_tweaked((s) => (s['nodes'] as List).add({'t': 'explosion'})));
      refusal(_tweaked((s) => (s['nodes'] as List).add({'t': 'line', 'speaker': 'narrator', 'text': 'x' * 5000})));
      refusal(_tweaked((s) => (s['nodes'] as List).add({'t': 'line', 'speaker': 'narrator', 'text': ''})));
      refusal(_tweaked((s) => (s['nodes'] as List).add({'t': 'line', 'speaker': 'narrator', 'text': 'Hi.', 'only': {'key': 5, 'option': 'a'}})));
      refusal(_tweaked((s) => s['nodes'] = <Object?>[]));
    });
  });

  group('the manifest', () {
    String manifest(Map<String, Object?> entry) => jsonEncode({
          'format': 1,
          'packs': [entry],
        });
    final sha = sha256.convert([1, 2, 3]).toString();
    Map<String, Object?> entry({Object? file = 'season_2.json', Object? hash, Object? bytes = 100}) =>
        {'season': 2, 'version': 1, 'file': file, 'bytes': bytes, 'sha256': hash ?? sha};

    test('a well-formed entry is read', () {
      final m = PackManifest.decode(manifest(entry()));
      expect(m.forSeason(2)!.bytes, 100);
      expect(m.forSeason(3), isNull);
    });

    test('a file name can only be a plain name next to the manifest', () {
      for (final bad in ['../season_2.json', 'a/b.json', 'https://evil.example/x.json', 'season_2.exe', 'Season 2.json', '']) {
        expect(() => PackManifest.decode(manifest(entry(file: bad))), throwsA(isA<PackFormatException>()), reason: bad);
      }
    });

    test('a checksum or size that cannot be right', () {
      expect(() => PackManifest.decode(manifest(entry(hash: 'abc'))), throwsA(isA<PackFormatException>()));
      expect(() => PackManifest.decode(manifest(entry(hash: sha.toUpperCase()))), throwsA(isA<PackFormatException>()));
      expect(() => PackManifest.decode(manifest(entry(bytes: 0))), throwsA(isA<PackFormatException>()));
      expect(() => PackManifest.decode(manifest(entry(bytes: StoryPacks.maxBytes + 1))), throwsA(isA<PackFormatException>()));
      expect(() => PackManifest.decode('nonsense'), throwsA(isA<PackFormatException>()));
    });

    test('a manifest from a newer game asks for an update', () {
      try {
        PackManifest.decode(jsonEncode({'format': 2, 'packs': <Object?>[]}));
        fail('expected a refusal');
      } on PackFormatException catch (e) {
        expect(e.message, 'newer-app');
      }
    });
  });
}
