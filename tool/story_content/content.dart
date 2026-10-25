/// The full story, with every script, and the files the later seasons are
/// downloaded as. Used by tool/build_packs.dart to write them, and by the tests,
/// which read the story through here because the app itself carries only
/// Season One's scripts. See docs/CONTENT_PACKS.md.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:i_am_chad/domain/story.dart';
import 'package:i_am_chad/domain/story_pack.dart';

import 'season_five.dart';
import 'season_six.dart';
import 'season_four.dart';
import 'season_three.dart';
import 'season_two.dart';

class StoryContent {
  const StoryContent._();

  /// Every chapter of every season, with its scenes.
  static const chapters = <StoryChapter>[...Story.seasonOne, ...seasonTwoChapters, ...seasonThreeChapters, ...seasonFourChapters, ...seasonFiveChapters, ...seasonSixChapters];

  static StoryChapter byNumber(int n) => chapters.firstWhere((c) => c.number == n);

  static List<StoryChapter> inSeason(int season) => [
        for (final c in chapters)
          if (c.season == season) c,
      ];

  /// Raised when the wording of a published pack is corrected, so phones that
  /// already have it can be offered the fix. Bump a season's number whenever
  /// its script changes after it has been published.
  static const versions = <int, int>{2: 1, 3: 1, 4: 1, 5: 1, 6: 1};

  /// The files to publish, by name: one pack per downloaded season, and the
  /// manifest that lists them.
  static Map<String, String> files() {
    final out = <String, String>{};
    final entries = <PackEntry>[];
    for (final season in Story.seasons.where((s) => s.isDownloaded)) {
      final text = StoryPacks.encode(season: season.number, version: versions[season.number]!, chapters: inSeason(season.number));
      final bytes = utf8.encode(text);
      final file = 'season_${season.number}.json';
      out[file] = text;
      entries.add(PackEntry(
        season: season.number,
        version: versions[season.number]!,
        file: file,
        bytes: bytes.length,
        sha256: sha256.convert(bytes).toString(),
      ));
    }
    out['manifest.json'] = PackManifest(entries).encode();
    return out;
  }
}
