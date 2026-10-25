/// The files a later story season is downloaded as, and how they are read.
/// See docs/CONTENT_PACKS.md.
///
/// A pack holds only the scripts (scenes, lines and choices) of one season. What
/// the Chronicle and the unlock rules need, each chapter's place, title, level and
/// summary, is part of the app, so a pack can never change when something opens.
/// It also cannot bring new art: a scene can only use the speakers and backdrops
/// the app already knows how to draw, and a pack that names anything else is
/// refused as a whole.
library;

import 'dart:convert';

import 'story.dart';

/// Thrown when a downloaded file is not a pack this version of the game can read.
class PackFormatException implements Exception {
  const PackFormatException(this.message);

  final String message;

  @override
  String toString() => 'PackFormatException: $message';
}

/// One season's download, as listed in the manifest.
class PackEntry {
  const PackEntry({
    required this.season,
    required this.version,
    required this.file,
    required this.bytes,
    required this.sha256,
  });

  final int season;

  /// Raised whenever the wording of a published pack is corrected.
  final int version;

  /// The file name, next to the manifest.
  final String file;
  final int bytes;

  /// Lower-case hex of the file's SHA-256, checked before anything is kept.
  final String sha256;

  Map<String, Object?> toJson() => {'season': season, 'version': version, 'file': file, 'bytes': bytes, 'sha256': sha256};

  factory PackEntry.fromJson(Object? json) {
    if (json is! Map) throw const PackFormatException('A pack entry is not an object.');
    final season = json['season'], version = json['version'], file = json['file'], bytes = json['bytes'], sha = json['sha256'];
    if (season is! int || version is! int || file is! String || bytes is! int || sha is! String) {
      throw const PackFormatException('A pack entry is missing a field.');
    }
    // A file name only, so a manifest can never point anywhere else.
    if (!RegExp(r'^[a-z0-9_]+\.json$').hasMatch(file)) throw const PackFormatException('A pack file name is not allowed.');
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha)) throw const PackFormatException('A pack checksum is malformed.');
    if (bytes <= 0 || bytes > StoryPacks.maxBytes) throw const PackFormatException('A pack size is not allowed.');
    return PackEntry(season: season, version: version, file: file, bytes: bytes, sha256: sha);
  }
}

/// The list of packs on offer.
class PackManifest {
  const PackManifest(this.packs);

  final List<PackEntry> packs;

  PackEntry? forSeason(int season) {
    for (final p in packs) {
      if (p.season == season) return p;
    }
    return null;
  }

  String encode() => jsonEncode({'format': StoryPacks.format, 'packs': [for (final p in packs) p.toJson()]});

  factory PackManifest.decode(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      throw const PackFormatException('The list of packs is not readable.');
    }
    if (json is! Map) throw const PackFormatException('The list of packs is not an object.');
    final format = json['format'];
    if (format is! int) throw const PackFormatException('The list of packs has no format.');
    if (format > StoryPacks.format) throw const PackFormatException('newer-app');
    final packs = json['packs'];
    if (packs is! List) throw const PackFormatException('The list of packs has no packs.');
    return PackManifest([for (final p in packs) PackEntry.fromJson(p)]);
  }
}

class StoryPacks {
  const StoryPacks._();

  /// The pack format this game reads. A pack made for a newer one asks the
  /// player to update the game instead.
  static const format = 1;

  /// The largest pack accepted, far more than any season needs.
  static const maxBytes = 2 * 1024 * 1024;

  static const _maxScenes = 40, _maxNodes = 400, _maxOptions = 6, _maxText = 1200;

  /// Writes [chapters] (with their scenes) as one season's pack file.
  static String encode({required int season, required int version, required List<StoryChapter> chapters}) {
    return jsonEncode({
      'format': format,
      'season': season,
      'version': version,
      'chapters': [
        for (final c in chapters)
          {
            'number': c.number,
            'title': c.title,
            'scenes': [for (final s in c.scenes) _scene(s)],
          },
      ],
    });
  }

  static Map<String, Object?> _scene(StoryScene s) => {
        'backdrop': s.backdrop.name,
        'cast': [for (final c in s.cast) c.name],
        'nodes': [for (final n in s.nodes) _node(n)],
      };

  static Map<String, Object?> _node(StoryNode n) => switch (n) {
        StoryLine() => {'t': 'line', ..._line(n)},
        StoryChoice() => {
            't': 'choice',
            'key': n.key,
            'prompt': n.prompt,
            'options': [
              for (final o in n.options) {'label': o.label, 'reply': [for (final l in o.reply) _line(l)]},
            ],
            if (n.only != null) 'only': {'key': n.only!.key, 'option': n.only!.option},
          },
      };

  static Map<String, Object?> _line(StoryLine l) => {
        'speaker': l.speaker.name,
        'text': l.text,
        if (l.only != null) 'only': {'key': l.only!.key, 'option': l.only!.option},
      };

  /// Reads a pack for [season] and returns each chapter's scenes by chapter
  /// number. The pack must cover exactly the chapters the app lists for that
  /// season, with the same titles, or it is refused.
  static Map<int, List<StoryScene>> decode(String text, {required int season}) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      throw const PackFormatException('The pack is not readable.');
    }
    final root = _map(json, 'the pack');
    final fmt = root['format'];
    if (fmt is! int) throw const PackFormatException('The pack has no format.');
    if (fmt > format) throw const PackFormatException('newer-app');
    if (root['season'] != season) throw const PackFormatException('The pack is for a different season.');
    final chapters = root['chapters'];
    if (chapters is! List) throw const PackFormatException('The pack has no chapters.');
    final expected = {for (final c in Story.inSeason(season)) c.number: c};
    final out = <int, List<StoryScene>>{};
    for (final raw in chapters) {
      final c = _map(raw, 'a chapter');
      final number = c['number'];
      final known = expected[number];
      if (number is! int || known == null) throw const PackFormatException('The pack has a chapter this game does not list.');
      if (c['title'] != known.title) throw PackFormatException('Chapter $number has a different title than expected.');
      if (out.containsKey(number)) throw PackFormatException('Chapter $number appears twice.');
      final scenes = c['scenes'];
      if (scenes is! List || scenes.isEmpty || scenes.length > _maxScenes) {
        throw PackFormatException('Chapter $number has no usable scenes.');
      }
      out[number] = [for (final s in scenes) _readScene(s)];
    }
    if (out.length != expected.length) throw const PackFormatException('The pack is missing chapters.');
    return out;
  }

  static Map<dynamic, dynamic> _map(Object? v, String what) {
    if (v is! Map) throw PackFormatException('$what is not an object.');
    return v;
  }

  static T _named<T extends Enum>(List<T> values, Object? name, String what) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    throw PackFormatException('Unknown $what "$name".');
  }

  static StoryScene _readScene(Object? raw) {
    final s = _map(raw, 'a scene');
    final backdrop = _named(StoryBackdrop.values, s['backdrop'], 'backdrop');
    final castRaw = s['cast'], nodesRaw = s['nodes'];
    if (castRaw is! List || nodesRaw is! List) throw const PackFormatException('A scene is incomplete.');
    if (nodesRaw.isEmpty || nodesRaw.length > _maxNodes || castRaw.length > 8) {
      throw const PackFormatException('A scene has a size that is not allowed.');
    }
    final cast = [for (final c in castRaw) _named(StorySpeaker.values, c, 'speaker')];
    final nodes = [for (final n in nodesRaw) _readNode(n, cast)];
    return StoryScene(backdrop, cast, nodes);
  }

  static StoryCondition? _only(Map<dynamic, dynamic> m) {
    final o = m['only'];
    if (o == null) return null;
    final c = _map(o, 'a condition');
    final key = c['key'], option = c['option'];
    if (key is! String || option is! int || key.isEmpty || key.length > 40) throw const PackFormatException('A condition is malformed.');
    return StoryCondition(key, option);
  }

  static String _text(Object? v) {
    if (v is! String || v.isEmpty || v.length > _maxText) throw const PackFormatException('A line of text is missing or too long.');
    return v;
  }

  static StoryLine _readLine(Object? raw, List<StorySpeaker> cast) {
    final m = _map(raw, 'a line');
    final speaker = _named(StorySpeaker.values, m['speaker'], 'speaker');
    // Anyone who speaks must be on stage. The narrator and the hero never are.
    if (speaker != StorySpeaker.narrator && speaker != StorySpeaker.hero && !cast.contains(speaker)) {
      throw PackFormatException('${speaker.name} speaks without being in the scene.');
    }
    return StoryLine(speaker, _text(m['text']), only: _only(m));
  }

  static StoryNode _readNode(Object? raw, List<StorySpeaker> cast) {
    final m = _map(raw, 'a node');
    switch (m['t']) {
      case 'line':
        return _readLine(m, cast);
      case 'choice':
        final key = m['key'], options = m['options'];
        if (key is! String || key.isEmpty || key.length > 40 || options is! List || options.isEmpty || options.length > _maxOptions) {
          throw const PackFormatException('A choice is malformed.');
        }
        return StoryChoice(
          key,
          _text(m['prompt']),
          [
            for (final o in options)
              () {
                final om = _map(o, 'an option');
                final reply = om['reply'];
                if (reply is! List) throw const PackFormatException('An option has no reply.');
                return StoryOption(_text(om['label']), [for (final l in reply) _readLine(l, cast)]);
              }(),
          ],
          only: _only(m),
        );
      default:
        throw PackFormatException('Unknown node type "${m['t']}".');
    }
  }
}
