import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/story.dart';
import '../../tool/story_content/content.dart';

/// Every line in a chapter, including the replies to choices.
Iterable<StoryLine> _lines(StoryChapter c) sync* {
  for (final scene in c.scenes) {
    for (final n in scene.nodes) {
      switch (n) {
        case StoryLine():
          yield n;
        case StoryChoice():
          for (final o in n.options) {
            yield* o.reply;
          }
      }
    }
  }
}

Iterable<StoryChoice> _choices(StoryChapter c) sync* {
  for (final scene in c.scenes) {
    for (final n in scene.nodes) {
      if (n is StoryChoice) yield n;
    }
  }
}

void main() {
  final chapters = StoryContent.chapters;

  test('each season is a prologue and seven chapters, numbered in order across the whole story', () {
    expect(Story.seasons.map((s) => s.number), [1, 2, 3, 4]);
    expect(chapters.length, 32);
    expect([for (final c in chapters) c.number], [for (var i = 0; i < 32; i++) i]);
    expect([for (final c in StoryContent.inSeason(3)) c.number], [16, 17, 18, 19, 20, 21, 22, 23]);
    expect([for (final c in StoryContent.inSeason(4)) c.number], [24, 25, 26, 27, 28, 29, 30, 31]);
    expect([for (final s in Story.seasons) s.name], ['Season One', 'Season Two', 'Season Three', 'Season Four']);
    expect([for (final c in StoryContent.inSeason(1)) c.number], [0, 1, 2, 3, 4, 5, 6, 7]);
    expect([for (final c in StoryContent.inSeason(2)) c.number], [8, 9, 10, 11, 12, 13, 14, 15]);
    for (final season in Story.seasons) {
      expect(StoryContent.inSeason(season.number).first.number, season.firstChapter);
      expect(StoryContent.inSeason(season.number).first.label, 'Prologue');
      expect(season.title.trim(), isNotEmpty);
      expect(season.blurb.trim(), isNotEmpty);
    }
    expect(chapters[3].label, 'Chapter 3');
    expect(chapters[11].label, 'Chapter 3', reason: 'Season Two counts from its own prologue');
    expect(chapters[15].label, 'Chapter 7');
    for (final c in chapters) {
      expect(Story.byNumber(c.number)!.title, c.title);
    }
    expect(Story.byNumber(99), isNull);
  });

  test('chapters open at rising levels, starting with the prologue at level 1', () {
    expect(chapters.first.unlockLevel, 1);
    for (var i = 1; i < chapters.length; i++) {
      expect(chapters[i].unlockLevel, greaterThan(chapters[i - 1].unlockLevel), reason: chapters[i].title);
    }
    // Early chapters come quickly; the last is a few months of regular use away.
    expect(chapters[1].unlockLevel, lessThanOrEqualTo(3));
    expect(StoryContent.inSeason(1).last.unlockLevel, inInclusiveRange(12, 25));
    // Season Two starts after Season One is done and goes further up the curve.
    expect(StoryContent.inSeason(2).first.unlockLevel, greaterThan(StoryContent.inSeason(1).last.unlockLevel));
    expect(StoryContent.inSeason(2).last.unlockLevel, inInclusiveRange(30, 60));
    // Season Three starts after Season Two and reaches higher still.
    expect(StoryContent.inSeason(3).first.unlockLevel, greaterThan(StoryContent.inSeason(2).last.unlockLevel));
    expect(StoryContent.inSeason(3).last.unlockLevel, inInclusiveRange(55, 90));
    // Season Four starts after Season Three and ends by the level cap.
    expect(StoryContent.inSeason(4).first.unlockLevel, greaterThan(StoryContent.inSeason(3).last.unlockLevel));
    expect(StoryContent.inSeason(4).last.unlockLevel, inInclusiveRange(80, 99));
  });

  test('what is open depends only on level, and never shrinks as the hero levels up', () {
    expect(StoryRules.unlocked(1).map((c) => c.number), [0]);
    expect(StoryRules.unlocked(2).map((c) => c.number), [0, 1]);
    expect(StoryRules.unlocked(6).map((c) => c.number), [0, 1, 2, 3]);
    expect(StoryRules.unlocked(99).length, chapters.length);
    var last = 0;
    for (var level = 1; level <= 40; level++) {
      final n = StoryRules.unlocked(level).length;
      expect(n, greaterThanOrEqualTo(last));
      last = n;
    }
    expect(StoryRules.next(1)!.number, 1);
    expect(StoryRules.next(15)!.number, 7);
    expect(StoryRules.next(16)!.number, 8, reason: 'Season Two opens once Season One is done');
    expect(StoryRules.next(42)!.number, 16, reason: 'Season Three opens once Season Two is done');
    expect(StoryRules.next(StoryContent.inSeason(3).last.unlockLevel)!.number, 24, reason: 'Season Four opens once Season Three is done');
    expect(StoryRules.next(StoryContent.chapters.last.unlockLevel), isNull);
  });

  test('every chapter has a title, a summary and scenes with something in them', () {
    for (final c in chapters) {
      expect(c.title.trim(), isNotEmpty);
      expect(c.summary.trim(), isNotEmpty);
      expect(c.summary.length, lessThan(160), reason: '${c.title} summary is for a list');
      expect(c.scenes, isNotEmpty, reason: c.title);
      for (final s in c.scenes) {
        expect(s.nodes.whereType<StoryLine>().length, greaterThanOrEqualTo(3), reason: c.title);
        expect(s.cast, isNotEmpty);
        expect(s.cast.toSet().length, s.cast.length, reason: 'a character twice in ${c.title}');
        expect(s.cast.length, lessThanOrEqualTo(5));
      }
    }
  });

  test('titles are in Title Case', () {
    const small = {'a', 'the', 'and', 'of', 'to', 'for', 'with', 'from', 'in', 'at', 'on'};
    for (final c in chapters) {
      final words = c.title.split(' ');
      for (var i = 0; i < words.length; i++) {
        final w = words[i];
        if (i > 0 && small.contains(w)) continue;
        expect(w[0], w[0].toUpperCase(), reason: '"${c.title}"');
      }
    }
  });

  test('everyone who speaks is on stage in that scene', () {
    for (final c in chapters) {
      for (final s in c.scenes) {
        final onStage = {...s.cast, StorySpeaker.narrator, StorySpeaker.hero};
        for (final n in s.nodes) {
          final spoken = switch (n) {
            StoryLine() => [n],
            StoryChoice() => [for (final o in n.options) ...o.reply],
          };
          for (final l in spoken) {
            expect(onStage, contains(l.speaker), reason: '${c.title}: ${l.speaker} says "${l.text}" but is not in the cast');
          }
        }
      }
    }
  });

  test('every line is short enough to read at a glance and says something', () {
    for (final c in chapters) {
      for (final l in _lines(c)) {
        expect(l.text.trim(), isNotEmpty, reason: c.title);
        expect(l.text.length, lessThan(260), reason: '${c.title}: "${l.text}"');
      }
    }
  });

  test('the story is kind: nothing shames, pressures or talks about bodies', () {
    const banned = [
      'lazy', 'fat ', 'ugly', 'pathetic', 'weak', 'failure', 'failed', 'loser', 'excuse', 'no pain',
      'don\'t break', 'streak', 'hurry up', 'you must do', 'you have to', 'overdue', 'behind schedule',
      'weight', 'skinny', 'burn off', 'in shape', 'out of shape', 'deadline is',
    ];
    for (final c in chapters) {
      final all = [
        c.title,
        c.summary,
        for (final l in _lines(c)) l.text,
        for (final ch in _choices(c)) ...[ch.prompt, for (final o in ch.options) o.label],
      ];
      for (final t in all) {
        final lower = t.toLowerCase();
        for (final w in banned) {
          expect(lower.contains(w), isFalse, reason: '"$w" in "$t" (${c.title})');
        }
      }
    }
  });

  test('the story says rest and gentle pace are welcome, and that it never has a deadline', () {
    final all = [for (final c in chapters) for (final l in _lines(c)) l.text.toLowerCase()].join(' ');
    // (Checked with isTrue so a failure does not print the whole script.)
    expect(all.contains('rest is training'), isTrue);
    expect(all.contains('at your own pace'), isTrue);
    expect(all.contains('nothing here has a deadline'), isTrue);
  });

  test('placeholders are well formed, and the hero is named in the first chapter', () {
    for (final c in chapters) {
      for (final l in _lines(c)) {
        final open = '{'.allMatches(l.text).length;
        final close = '}'.allMatches(l.text).length;
        expect(open, close, reason: l.text);
        // The only placeholder is the hero's name.
        final stripped = l.text.replaceAll(StoryText.heroToken, '');
        expect(stripped.contains('{'), isFalse, reason: 'unknown placeholder in "${l.text}"');
      }
    }
    expect(StoryText.fill('Hello, {hero}! Bye, {hero}.', hero: 'Ada'), 'Hello, Ada! Bye, Ada.');
    expect(_lines(chapters.first).any((l) => l.text.contains(StoryText.heroToken)), isTrue);
  });

  test('every choice has at least two options and every option replies', () {
    var count = 0;
    for (final c in chapters) {
      for (final ch in _choices(c)) {
        count++;
        expect(ch.options.length, inInclusiveRange(2, 3), reason: ch.key);
        expect(ch.prompt.trim(), isNotEmpty);
        for (final o in ch.options) {
          expect(o.label.trim(), isNotEmpty);
          expect(o.label.length, lessThan(60), reason: 'button text: ${o.label}');
          expect(o.reply, isNotEmpty, reason: '${ch.key}: ${o.label}');
        }
      }
    }
    expect(count, greaterThanOrEqualTo(6), reason: 'the story should give the player a say');
  });

  test('choice keys are unique across the season', () {
    final keys = [for (final c in chapters) for (final ch in _choices(c)) ch.key];
    expect(keys.toSet().length, keys.length);
  });

  test('a line that depends on a choice refers to a real, earlier choice and option', () {
    final seen = <String, int>{};
    for (final c in chapters) {
      for (final s in c.scenes) {
        for (final n in s.nodes) {
          final only = n.only;
          if (only != null) {
            expect(seen.containsKey(only.key), isTrue, reason: '${c.title} refers to "${only.key}" before it is asked');
            expect(only.option, inInclusiveRange(0, seen[only.key]! - 1), reason: only.key);
          }
          if (n is StoryChoice) seen[n.key] = n.options.length;
        }
      }
    }
  });

  test('a choice-dependent line has an answer for every option, so nobody gets a gap', () {
    // Each season's final scene has a farewell that depends on the first choice; every option must be covered.
    final first = chapters.first.scenes.expand((s) => s.nodes).whereType<StoryChoice>().first;
    expect(first.key, 'motivation');
    for (final season in Story.seasons) {
      final last = StoryContent.inSeason(season.number).last.scenes.last;
      final conditional = [for (final n in last.nodes) if (n.only != null) n.only!];
      expect({for (final c in conditional) c.option}, {for (var i = 0; i < first.options.length; i++) i}, reason: season.title);
    }
  });

  test('visible() filters lines by earlier choices, and shows plain lines to everyone', () {
    for (final season in Story.seasons) {
      final last = StoryContent.inSeason(season.number).last.scenes.last;
      for (var option = 0; option < 3; option++) {
        final shown = StoryText.visible(last, {'motivation': option});
        final farewells = shown.whereType<StoryLine>().where((l) => l.text.startsWith('Come by when you like')).toList();
        expect(farewells, hasLength(1), reason: '${season.title}: exactly one farewell for option $option');
      }
      // Without a recorded choice, the plain lines still show.
      final none = StoryText.visible(last, const {});
      expect(none.whereType<StoryLine>().where((l) => l.text.startsWith('Come by when you like')), isEmpty);
      expect(none.length, greaterThan(5));
    }
  });

  test('the cast is used: everyone introduced in the season actually speaks', () {
    final speakers = {for (final c in chapters) for (final l in _lines(c)) l.speaker};
    for (final s in StorySpeaker.values) {
      if (s == StorySpeaker.hero) continue; // the player speaks through choices
      expect(speakers, contains(s), reason: '$s is never given a line');
    }
  });

  test('Chad\'s old joke gets its true answer', () {
    final lines = [for (final c in chapters) for (final l in _lines(c)) l.text].join('\n');
    expect(lines, contains('I started at Level 2'));
    expect(lines, contains('I started at Level 1, like everyone'));
    expect(chapters.firstWhere((c) => c.title == 'The Night Before the Bell').unlockLevel,
        greaterThan(chapters.first.unlockLevel));
  });

  test('the story is a decent length: rich, but each chapter is a few minutes', () {
    final total = chapters.fold(0, (a, c) => a + _lines(c).length);
    expect(total, inInclusiveRange(120, 1100));
    for (final c in chapters) {
      expect(_lines(c).length, inInclusiveRange(10, 60), reason: c.title);
    }
  });

  group('Season Two, The Lantern Coast', () {
    final two = StoryContent.inSeason(2);

    test('it picks up where Season One ends and goes west to the coast', () {
      final seasonOneEnd = [for (final l in _lines(StoryContent.inSeason(1).last)) l.text].join(' ');
      expect(seasonOneEnd, contains('lantern'));
      expect(seasonOneEnd, contains('west'));
      final all = [for (final c in two) for (final l in _lines(c)) l.text].join(' ');
      expect(all, contains('lighthouse'));
      expect(all, contains('Gullhaven'));
    });

    test('it brings in three new characters and every one of them speaks', () {
      final speakers = {for (final c in two) for (final l in _lines(c)) l.speaker};
      expect(speakers, containsAll([StorySpeaker.pip, StorySpeaker.wren, StorySpeaker.sedge]));
    });

    test('it remembers choices from Season One', () {
      final keysUsed = {
        for (final c in two) for (final s in c.scenes) for (final n in s.nodes) if (n.only != null) n.only!.key,
      };
      expect(keysUsed, containsAll(['brad', 'gremlin', 'murmur', 'oak', 'motivation']));
    });

    test('it asks its own questions, with fresh keys', () {
      final seasonOneKeys = {for (final c in StoryContent.inSeason(1)) for (final ch in _choices(c)) ch.key};
      final keys = [for (final c in two) for (final ch in _choices(c)) ch.key];
      expect(keys.length, greaterThanOrEqualTo(6));
      expect(keys.toSet().intersection(seasonOneKeys), isEmpty);
    });

    test('it says the same kind things as Season One: rest, its own pace, no deadline', () {
      final all = [for (final c in two) for (final l in _lines(c)) l.text.toLowerCase()].join(' ');
      expect(all.contains('rest is training'), isTrue);
      expect(all.contains('at your own pace'), isTrue);
      expect(all.contains('nothing here has a deadline'), isTrue);
    });

    test('the coast has its own places', () {
      final used = {for (final c in two) for (final s in c.scenes) s.backdrop};
      expect(
        used,
        containsAll([
          StoryBackdrop.coastRoad,
          StoryBackdrop.estuary,
          StoryBackdrop.harbour,
          StoryBackdrop.tidePools,
          StoryBackdrop.lighthouse,
          StoryBackdrop.lighthouseNight,
        ]),
      );
    });
  });

  group('Season Three, The Weather Chime', () {
    final three = StoryContent.inSeason(3);

    test('it picks up from the bell and the lamp and goes up into the mountains', () {
      final seasonTwoEnd = [for (final l in _lines(StoryContent.inSeason(2).last)) l.text].join(' ');
      expect(seasonTwoEnd, contains('Dawn Bell'));
      final all = [for (final c in three) for (final l in _lines(c)) l.text].join(' ');
      expect(all, contains('Thunder Heights'));
      expect(all, contains('Weather Chime'));
      expect(all, contains('Dawn Bell'));
    });

    test('it brings in four new characters and every one of them speaks', () {
      final speakers = {for (final c in three) for (final l in _lines(c)) l.speaker};
      expect(speakers, containsAll([StorySpeaker.fennel, StorySpeaker.hush, StorySpeaker.tamsin, StorySpeaker.skarn]));
    });

    test('it remembers choices from the seasons before', () {
      final keysUsed = {
        for (final c in three) for (final s in c.scenes) for (final n in s.nodes) if (n.only != null) n.only!.key,
      };
      expect(keysUsed, containsAll(['light', 'pip', 'motivation']));
    });

    test('it asks its own questions, with fresh keys', () {
      final earlier = {for (final c in [...StoryContent.inSeason(1), ...StoryContent.inSeason(2)]) for (final ch in _choices(c)) ch.key};
      final keys = [for (final c in three) for (final ch in _choices(c)) ch.key];
      expect(keys.length, greaterThanOrEqualTo(6));
      expect(keys.toSet().intersection(earlier), isEmpty);
    });

    test('it says the same kind things as the others: rest, its own pace, no deadline', () {
      final all = [for (final c in three) for (final l in _lines(c)) l.text.toLowerCase()].join(' ');
      expect(all.contains('rest is training'), isTrue);
      expect(all.contains('at your own pace'), isTrue);
      expect(all.contains('nothing here has a deadline'), isTrue);
    });

    test('the mountain has its own places', () {
      final used = {for (final c in three) for (final s in c.scenes) s.backdrop};
      expect(
        used,
        containsAll([
          StoryBackdrop.snowRoad,
          StoryBackdrop.passHut,
          StoryBackdrop.iceCave,
          StoryBackdrop.observatory,
          StoryBackdrop.stormTop,
          StoryBackdrop.highCamp,
          StoryBackdrop.summit,
        ]),
      );
    });

    test('its theme is coming back: stopping is welcome and starting again is small', () {
      final all = [for (final c in three) for (final l in _lines(c)) l.text.toLowerCase()].join(' ');
      expect(all.contains('stop here'), isTrue, reason: 'the hut with the one rule');
      expect(all.contains('one counts'), isTrue);
      expect(all.contains('picking up where'), isTrue);
    });
  });

  group('Season Four, The Long Table', () {
    final four = StoryContent.inSeason(4);

    test('it brings back the people the story has met, and the table is the point', () {
      final speakers = {for (final c in four) for (final l in _lines(c)) l.speaker};
      // Nearly everyone returns: the valley, the coast, the mountain and the desert.
      expect(
        speakers,
        containsAll([
          StorySpeaker.chad, StorySpeaker.maple, StorySpeaker.pip, StorySpeaker.wren, StorySpeaker.sedge,
          StorySpeaker.hush, StorySpeaker.tamsin, StorySpeaker.skarn, StorySpeaker.fennel, StorySpeaker.oakhelm,
          StorySpeaker.grit, StorySpeaker.murmur, StorySpeaker.brad,
        ]),
      );
      final all = [for (final c in four) for (final l in _lines(c)) l.text].join(' ');
      expect(all, contains('table'));
      expect(all, contains('chair'));
      expect(all, contains('feast'));
    });

    test('it brings in three new characters and every one of them speaks', () {
      final speakers = {for (final c in four) for (final l in _lines(c)) l.speaker};
      expect(speakers, containsAll([StorySpeaker.bertram, StorySpeaker.sphinx, StorySpeaker.worm]));
    });

    test('it remembers choices from the seasons before', () {
      final keysUsed = {
        for (final c in four) for (final s in c.scenes) for (final n in s.nodes) if (n.only != null) n.only!.key,
      };
      expect(keysUsed, containsAll(['pip', 'light', 'stair', 'chime', 'motivation']));
    });

    test('it asks its own questions, with fresh keys', () {
      final earlier = {for (final c in [...StoryContent.inSeason(1), ...StoryContent.inSeason(2), ...StoryContent.inSeason(3)]) for (final ch in _choices(c)) ch.key};
      final keys = [for (final c in four) for (final ch in _choices(c)) ch.key];
      expect(keys.length, greaterThanOrEqualTo(7));
      expect(keys.toSet().intersection(earlier), isEmpty);
    });

    test('it says the same kind things as the others: rest, its own pace, no deadline', () {
      final all = [for (final c in four) for (final l in _lines(c)) l.text.toLowerCase()].join(' ');
      expect(all.contains('rest is training'), isTrue);
      expect(all.contains('at your own pace'), isTrue);
      expect(all.contains('nothing here has a deadline'), isTrue);
    });

    test('it has its own places, and the feast comes last', () {
      final used = {for (final c in four) for (final s in c.scenes) s.backdrop};
      expect(used, containsAll([StoryBackdrop.courtyard, StoryBackdrop.dunes, StoryBackdrop.feast]));
      expect(four.last.scenes.last.backdrop, StoryBackdrop.feast);
    });

    test('its newcomer is an older beginner, treated as a delight and never as a problem', () {
      final bertram = [for (final c in four) for (final l in _lines(c)) if (l.speaker == StorySpeaker.bertram) l.text].join(' ');
      expect(bertram, contains('eighty-three'));
      expect(bertram.toLowerCase(), contains('begin'));
      final others = [for (final c in four) for (final l in _lines(c)) if (l.speaker != StorySpeaker.bertram) l.text.toLowerCase()].join(' ');
      for (final w in ['too old', 'past it', 'at your age', 'at his age', 'frail', 'elderly']) {
        expect(others.contains(w), isFalse, reason: '"$w" about Bertram');
      }
    });

    test('it ends at the level cap or just short of it, so the story finishes before the game does', () {
      expect(four.last.unlockLevel, lessThanOrEqualTo(99));
      expect(four.first.unlockLevel, greaterThan(StoryContent.inSeason(3).last.unlockLevel));
    });
  });
}
