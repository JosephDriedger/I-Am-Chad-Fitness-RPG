/// Downloading the later story seasons, once, the first time they are read.
/// See docs/CONTENT_PACKS.md and docs/DECISIONS.md.
///
/// What this does and does not do: it fetches one small static file per season
/// from a web address, checks it, and keeps it on the phone. It sends nothing
/// about the player (a plain GET with no account, no id and no headers of its
/// own), runs only when the player chooses to download, never in the background
/// and never at launch, and stores the file so it is only ever fetched once.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/story.dart';
import '../domain/story_pack.dart';

class ContentConfig {
  const ContentConfig._();

  /// Where the packs are published (a folder with `manifest.json` in it). Set it
  /// per build with `--dart-define=CONTENT_URL=https://...`.
  static const baseUrl = String.fromEnvironment(
    'CONTENT_URL',
    defaultValue: 'https://josephdriedger.github.io/I-Am-Chad-Fitness-RPG/packs/',
  );
}

/// Why a download did not happen. None of these loses anything: the player can
/// try again whenever they like.
enum PackProblem {
  /// No connection, or the server could not be reached.
  offline,

  /// The file arrived but is not what the manifest promised.
  damaged,

  /// The pack was made for a newer version of the game.
  newerApp,

  /// This season is not on the shelf yet.
  notPublished,

  /// The player stopped it.
  cancelled,
}

class PackException implements Exception {
  const PackException(this.problem);

  final PackProblem problem;

  @override
  String toString() => 'PackException(${problem.name})';
}

/// Lets the player stop a download in progress.
class PackCancel {
  bool cancelled = false;

  void call() => cancelled = true;
}

// ---------------------------------------------------------------------------
// Source: where the files come from
// ---------------------------------------------------------------------------

abstract class PackSource {
  Future<PackManifest> manifest();

  /// The bytes of [entry]'s file, reporting progress as they arrive.
  Future<Uint8List> fetch(PackEntry entry, {void Function(int received, int total)? onProgress, PackCancel? cancel});
}

/// Downloads over HTTPS (or plain HTTP in a debug build, for a local server).
class HttpPackSource implements PackSource {
  HttpPackSource(this.base, {this.timeout = const Duration(seconds: 20)});

  final Uri base;
  final Duration timeout;

  Future<HttpClientResponse> _get(HttpClient client, Uri url) async {
    if (url.scheme != 'https' && !(kDebugMode && url.scheme == 'http')) throw const PackException(PackProblem.offline);
    final request = await client.getUrl(url).timeout(timeout);
    // Nothing identifying goes with the request.
    request.headers.removeAll(HttpHeaders.userAgentHeader);
    final response = await request.close().timeout(timeout);
    if (response.statusCode == 404) throw const PackException(PackProblem.notPublished);
    if (response.statusCode != 200) throw const PackException(PackProblem.offline);
    return response;
  }

  Future<Uint8List> _bytes(Uri url, {void Function(int, int)? onProgress, PackCancel? cancel, required int limit}) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final response = await _get(client, url);
      final out = BytesBuilder(copy: false);
      var got = 0;
      await for (final chunk in response.timeout(timeout)) {
        if (cancel?.cancelled == true) throw const PackException(PackProblem.cancelled);
        got += chunk.length;
        if (got > limit) throw const PackException(PackProblem.damaged);
        out.add(chunk);
        onProgress?.call(got, response.contentLength);
      }
      return out.takeBytes();
    } on PackException {
      rethrow;
    } on Exception {
      // Socket, TLS, timeout and format problems all mean the same thing to a player.
      throw const PackException(PackProblem.offline);
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<PackManifest> manifest() async {
    final bytes = await _bytes(base.resolve('manifest.json'), limit: 64 * 1024);
    try {
      return PackManifest.decode(utf8.decode(bytes));
    } on PackFormatException catch (e) {
      throw PackException(e.message == 'newer-app' ? PackProblem.newerApp : PackProblem.damaged);
    } on FormatException {
      throw const PackException(PackProblem.damaged);
    }
  }

  @override
  Future<Uint8List> fetch(PackEntry entry, {void Function(int received, int total)? onProgress, PackCancel? cancel}) =>
      _bytes(base.resolve(entry.file), onProgress: onProgress, cancel: cancel, limit: StoryPacks.maxBytes);
}

/// A pretend shelf of packs, for tests and previews.
class TestPackSource implements PackSource {
  TestPackSource({Map<int, String> packs = const {}, this.problem, this.delay = Duration.zero})
      : _files = {for (final e in packs.entries) e.key: Uint8List.fromList(utf8.encode(e.value))};

  final Map<int, Uint8List> _files;

  /// If set, every request fails this way.
  PackProblem? problem;

  /// Time each request takes.
  Duration delay;

  int manifestRequests = 0;
  int fileRequests = 0;

  /// Replaces what arrives for [season] without changing what the manifest promises.
  void corrupt(int season, Uint8List bytes) => _files[season] = bytes;

  @override
  Future<PackManifest> manifest() async {
    manifestRequests++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (problem != null) throw PackException(problem!);
    return PackManifest([
      for (final e in _files.entries)
        PackEntry(
          season: e.key,
          version: 1,
          file: 'season_${e.key}.json',
          bytes: e.value.length,
          sha256: sha256.convert(e.value).toString(),
        ),
    ]);
  }

  @override
  Future<Uint8List> fetch(PackEntry entry, {void Function(int received, int total)? onProgress, PackCancel? cancel}) async {
    fileRequests++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (problem != null) throw PackException(problem!);
    if (cancel?.cancelled == true) throw const PackException(PackProblem.cancelled);
    final data = _files[entry.season] ?? (throw const PackException(PackProblem.notPublished));
    onProgress?.call(data.length, data.length);
    return data;
  }
}

// ---------------------------------------------------------------------------
// Store: where downloaded packs are kept
// ---------------------------------------------------------------------------

abstract class PackStore {
  /// Every pack kept, as season to file text.
  Future<Map<int, String>> readAll();

  Future<void> write(int season, String text);
}

/// Keeps packs in the app's private folder, written whole or not at all.
class FilePackStore implements PackStore {
  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'story_packs'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<Map<int, String>> readAll() async {
    final out = <int, String>{};
    final dir = await _dir();
    for (final f in dir.listSync().whereType<File>()) {
      final m = RegExp(r'season_(\d+)\.json$').firstMatch(p.basename(f.path));
      if (m != null) out[int.parse(m.group(1)!)] = await f.readAsString();
    }
    return out;
  }

  @override
  Future<void> write(int season, String text) async {
    final dir = await _dir();
    final target = File(p.join(dir.path, 'season_$season.json'));
    final temp = File('${target.path}.part');
    await temp.writeAsString(text, flush: true);
    await temp.rename(target.path);
  }
}

class MemoryPackStore implements PackStore {
  MemoryPackStore([Map<int, String> initial = const {}]) : files = {...initial};

  final Map<int, String> files;

  @override
  Future<Map<int, String>> readAll() async => {...files};

  @override
  Future<void> write(int season, String text) async => files[season] = text;
}

// ---------------------------------------------------------------------------
// What has been downloaded
// ---------------------------------------------------------------------------

/// The downloaded seasons' scripts, by chapter number.
class InstalledPacks {
  const InstalledPacks({this.loaded = false, this.scenes = const {}, this.versions = const {}});

  /// False until the phone's stored packs have been read.
  final bool loaded;
  final Map<int, List<StoryScene>> scenes;
  final Map<int, int> versions;

  bool hasSeason(int season) => !Story.seasonOf(season).isDownloaded || versions.containsKey(season);

  /// [chapter] with its scenes, or null if it still has to be downloaded.
  StoryChapter? readable(StoryChapter chapter) {
    if (chapter.hasScenes) return chapter;
    final scenes = this.scenes[chapter.number];
    return scenes == null ? null : chapter.withScenes(scenes);
  }
}

final packSourceProvider = Provider<PackSource>((_) => HttpPackSource(Uri.parse(ContentConfig.baseUrl)));
final packStoreProvider = Provider<PackStore>((_) => FilePackStore());

class InstalledPacksNotifier extends Notifier<InstalledPacks> {
  @override
  InstalledPacks build() {
    unawaited(_load());
    return const InstalledPacks();
  }

  Future<void> _load() async {
    var scenes = <int, List<StoryScene>>{};
    var versions = <int, int>{};
    try {
      final stored = await ref.read(packStoreProvider).readAll();
      for (final e in stored.entries) {
        try {
          final read = _read(e.key, e.value);
          scenes = {...scenes, ...read.scenes};
          versions = {...versions, e.key: read.version};
        } catch (_) {
          // A damaged file is treated as not downloaded; it will be offered again.
        }
      }
    } catch (_) {
      // Nothing readable: everything is simply "not downloaded yet".
    }
    state = InstalledPacks(loaded: true, scenes: {...state.scenes, ...scenes}, versions: {...state.versions, ...versions});
  }

  ({Map<int, List<StoryScene>> scenes, int version}) _read(int season, String text) {
    final scenes = StoryPacks.decode(text, season: season);
    final version = (jsonDecode(text) as Map)['version'];
    return (scenes: scenes, version: version is int ? version : 1);
  }

  /// What the manifest offers for [season]. Throws a [PackException] if it cannot be reached.
  Future<PackEntry> offer(int season) async {
    final manifest = await ref.read(packSourceProvider).manifest();
    return manifest.forSeason(season) ?? (throw const PackException(PackProblem.notPublished));
  }

  /// Downloads, checks and keeps [entry]. Nothing is kept unless every check passes.
  Future<void> install(PackEntry entry, {void Function(int received, int total)? onProgress, PackCancel? cancel}) async {
    final bytes = await ref.read(packSourceProvider).fetch(entry, onProgress: onProgress, cancel: cancel);
    if (bytes.length != entry.bytes || sha256.convert(bytes).toString() != entry.sha256) {
      throw const PackException(PackProblem.damaged);
    }
    final String text;
    final ({Map<int, List<StoryScene>> scenes, int version}) read;
    try {
      text = utf8.decode(bytes);
      read = _read(entry.season, text);
    } on PackFormatException catch (e) {
      throw PackException(e.message == 'newer-app' ? PackProblem.newerApp : PackProblem.damaged);
    } on FormatException {
      throw const PackException(PackProblem.damaged);
    }
    try {
      await ref.read(packStoreProvider).write(entry.season, text);
    } on Exception {
      throw const PackException(PackProblem.damaged);
    }
    state = InstalledPacks(
      loaded: true,
      scenes: {...state.scenes, ...read.scenes},
      versions: {...state.versions, entry.season: read.version},
    );
  }
}

final installedPacksProvider = NotifierProvider<InstalledPacksNotifier, InstalledPacks>(InstalledPacksNotifier.new);
