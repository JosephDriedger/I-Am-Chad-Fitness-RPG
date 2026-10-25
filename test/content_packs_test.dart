import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/content_packs.dart';
import 'package:i_am_chad/domain/story.dart';
import 'package:i_am_chad/domain/story_pack.dart';

import 'helpers.dart' show publishedPacks;

final _packs = publishedPacks();

ProviderContainer _container({TestPackSource? source, PackStore? store}) {
  final c = ProviderContainer(overrides: [
    packSourceProvider.overrideWithValue(source ?? TestPackSource(packs: _packs)),
    packStoreProvider.overrideWithValue(store ?? MemoryPackStore()),
  ]);
  addTearDown(c.dispose);
  return c;
}

Future<void> _loaded(ProviderContainer c) async {
  c.read(installedPacksProvider);
  while (!c.read(installedPacksProvider).loaded) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<PackProblem?> _install(ProviderContainer c, int season, {void Function(int, int)? onProgress, PackCancel? cancel}) async {
  final notifier = c.read(installedPacksProvider.notifier);
  try {
    final entry = await notifier.offer(season);
    await notifier.install(entry, onProgress: onProgress, cancel: cancel);
    return null;
  } on PackException catch (e) {
    return e.problem;
  }
}

void main() {
  group('downloading a season', () {
    test('nothing is downloaded to begin with, and Season One never needs it', () async {
      final c = _container();
      await _loaded(c);
      final packs = c.read(installedPacksProvider);
      expect(packs.hasSeason(1), isTrue);
      expect(packs.hasSeason(2), isFalse);
      expect(packs.readable(Story.inSeason(1).first), isNotNull);
      expect(packs.readable(Story.inSeason(2).first), isNull);
    });

    test('a good download is checked, kept and readable at once', () async {
      final source = TestPackSource(packs: _packs);
      final store = MemoryPackStore();
      final c = _container(source: source, store: store);
      await _loaded(c);
      final progress = <int>[];
      expect(await _install(c, 2, onProgress: (got, total) => progress.add(got)), isNull);

      final packs = c.read(installedPacksProvider);
      expect(packs.hasSeason(2), isTrue);
      expect(packs.hasSeason(3), isFalse, reason: 'only the season asked for');
      for (final chapter in Story.inSeason(2)) {
        expect(packs.readable(chapter)!.scenes, isNotEmpty, reason: chapter.title);
        expect(packs.readable(chapter)!.title, chapter.title);
      }
      expect(store.files.keys, [2]);
      expect(progress, isNotEmpty);
    });

    test('it is kept across launches, so it is only ever downloaded once', () async {
      final store = MemoryPackStore();
      final first = _container(store: store);
      await _loaded(first);
      await _install(first, 3);

      final source = TestPackSource(packs: _packs);
      final second = _container(source: source, store: store);
      await _loaded(second);
      expect(second.read(installedPacksProvider).hasSeason(3), isTrue);
      expect(source.manifestRequests + source.fileRequests, 0, reason: 'nothing is fetched at launch');
    });

    test('a file that arrives damaged is not kept', () async {
      final source = TestPackSource(packs: _packs);
      final store = MemoryPackStore();
      final c = _container(source: source, store: store);
      await _loaded(c);
      final entry = await c.read(installedPacksProvider.notifier).offer(2);
      // The same size but different content, as a bad connection or a swapped file might give.
      source.corrupt(2, Uint8List.fromList(List.filled(entry.bytes, 65)));
      expect(await _install(c, 2), PackProblem.damaged);
      expect(c.read(installedPacksProvider).hasSeason(2), isFalse);
      expect(store.files, isEmpty);

      // A truncated file too.
      source.corrupt(2, Uint8List.fromList(utf8.encode(_packs[2]!).sublist(0, 100)));
      expect(await _install(c, 2), PackProblem.damaged);
      expect(store.files, isEmpty);
    });

    test('a pack with the right checksum that is not a real pack is still refused', () async {
      // Even a correctly signed file must be a pack this game can read.
      final bogus = jsonEncode({'format': 1, 'season': 2, 'version': 1, 'chapters': <Object?>[]});
      final c = _container(source: TestPackSource(packs: {..._packs, 2: bogus}));
      await _loaded(c);
      expect(await _install(c, 2), PackProblem.damaged);
      expect(c.read(installedPacksProvider).hasSeason(2), isFalse);
    });

    test('offline, not published yet, and a pack for a newer game each say so, and lose nothing', () async {
      final source = TestPackSource(packs: _packs, problem: PackProblem.offline);
      final c = _container(source: source);
      await _loaded(c);
      expect(await _install(c, 2), PackProblem.offline);
      source.problem = null;
      expect(await _install(c, 2), isNull, reason: 'trying again just works');

      final missing = _container(source: TestPackSource(packs: {2: _packs[2]!}));
      await _loaded(missing);
      expect(await _install(missing, 4), PackProblem.notPublished);

      final newer = _pack2WithFormat(StoryPacks.format + 1);
      final c2 = _container(source: TestPackSource(packs: {..._packs, 2: newer}));
      await _loaded(c2);
      expect(await _install(c2, 2), PackProblem.newerApp);
    });

    test('stopping a download keeps nothing', () async {
      final store = MemoryPackStore();
      final c = _container(store: store);
      await _loaded(c);
      final cancel = PackCancel()..call();
      expect(await _install(c, 2, cancel: cancel), PackProblem.cancelled);
      expect(store.files, isEmpty);
      expect(c.read(installedPacksProvider).hasSeason(2), isFalse);
    });

    test('a stored file that has gone bad is treated as not downloaded, and the rest still load', () async {
      final store = MemoryPackStore({2: '{"broken', 3: _packs[3]!});
      final c = _container(store: store);
      await _loaded(c);
      final packs = c.read(installedPacksProvider);
      expect(packs.hasSeason(2), isFalse);
      expect(packs.hasSeason(3), isTrue);
    });
  });

  group('what is asked of the network', () {
    final sources = {
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart')) f.path.replaceAll(r'\', '/'): f.readAsStringSync(),
    };
    final real = sources['lib/app/content_packs.dart']!;

    test('only the pack code opens network connections for content, and it never knows who the player is', () {
      expect([for (final e in sources.entries) if (e.value.contains('HttpClient(')) e.key], ['lib/app/content_packs.dart']);
      final imports = RegExp(r"^import '([^']+)'", multiLine: true).allMatches(real).map((m) => m.group(1)!).toList();
      for (final banned in ['providers.dart', 'repository.dart', 'database.dart', 'player_state.dart', 'hero.dart', 'workout.dart']) {
        expect(imports.any((i) => i.endsWith(banned)), isFalse, reason: 'content_packs.dart must not import $banned');
      }
    });

    test('a plain GET: no body, no cookies, no identifying header, https only outside debug builds', () {
      expect(real, contains('getUrl('));
      for (final banned in ['postUrl(', 'openUrl(', 'headers.set(', 'headers.add(', 'cookies', 'add(utf8']) {
        expect(real.contains(banned), isFalse, reason: banned);
      }
      expect(real, contains("url.scheme != 'https'"));
      expect(real, contains('kDebugMode'));
    });

    test('it runs only when asked: nothing starts a download at launch or in the background', () {
      final users = [for (final e in sources.entries) if (e.value.contains('.install(')) e.key];
      expect(users, ['lib/features/story/pack_download.dart']);
      expect(sources['lib/app/app.dart'], isNot(contains('installedPacks')));
      expect(sources['lib/main.dart'], isNot(contains('installedPacks')));
    });
  });
}

String _pack2WithFormat(int format) {
  final pack = jsonDecode(_packs[2]!) as Map<String, Object?>;
  pack['format'] = format;
  return jsonEncode(pack);
}
