import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/content_packs.dart';
import '../../app/game_ui.dart';
import '../../domain/story.dart';
import '../../domain/story_pack.dart';

/// Makes sure the script of [chapter] is on the phone, offering to download its
/// season if it is not. Returns the chapter with its scenes, or null if the
/// player chose not to (or could not) download it, which is always fine: the
/// chapter simply stays unread until they are ready.
Future<StoryChapter?> readableChapter(BuildContext context, StoryChapter chapter) async {
  final container = ProviderScope.containerOf(context);
  await untilPacksLoaded(container);
  final have = container.read(installedPacksProvider).readable(chapter);
  if (have != null) return have;
  if (!context.mounted) return null;
  final downloaded = await showPackDownload(context, chapter.season);
  if (downloaded != true) return null;
  return container.read(installedPacksProvider).readable(chapter);
}

/// The phone's stored packs are read a moment after launch; wait for that so a
/// season that is already downloaded is never offered again.
Future<void> untilPacksLoaded(ProviderContainer container) async {
  if (container.read(installedPacksProvider).loaded) return;
  final done = Completer<void>();
  final sub = container.listen(installedPacksProvider, (_, s) {
    if (s.loaded && !done.isCompleted) done.complete();
  });
  try {
    await done.future.timeout(const Duration(seconds: 3), onTimeout: () {});
  } finally {
    sub.close();
  }
}

/// Asks to download [season]'s chapters and does it. True once it is on the phone.
Future<bool?> showPackDownload(BuildContext context, int season) {
  final container = ProviderScope.containerOf(context);
  final download = _PackDownload(container, season);
  final navigator = Navigator.of(context, rootNavigator: true);
  download.onDone = () {
    if (navigator.mounted) navigator.pop(true);
  };
  unawaited(download.check());
  return showGameDialog<bool>(
    context: context,
    title: 'Download ${Story.seasonOf(season).name}?',
    dismissible: false,
    content: ListenableBuilder(listenable: download, builder: (_, _) => _Body(download)),
    actions: [
      ListenableBuilder(
        listenable: download,
        builder: (ctx, _) => _Actions(download, close: () => Navigator.of(ctx).pop(false)),
      ),
    ],
  ).whenComplete(download.stop);
}

enum _Phase { checking, ready, downloading, failed, done }

class _PackDownload extends ChangeNotifier {
  _PackDownload(this._container, this.season);

  final ProviderContainer _container;
  final int season;

  _Phase phase = _Phase.checking;
  PackProblem? problem;
  PackEntry? entry;
  double? progress;
  PackCancel _cancel = PackCancel();
  bool _stopped = false;
  void Function()? onDone;

  InstalledPacksNotifier get _packs => _container.read(installedPacksProvider.notifier);

  void _set(_Phase p, {PackProblem? because}) {
    if (_stopped) return;
    phase = p;
    problem = because;
    notifyListeners();
  }

  Future<void> check() async {
    _set(_Phase.checking);
    try {
      entry = await _packs.offer(season);
      _set(_Phase.ready);
    } on PackException catch (e) {
      _set(_Phase.failed, because: e.problem);
    } catch (_) {
      _set(_Phase.failed, because: PackProblem.offline);
    }
  }

  Future<void> start() async {
    final offered = entry;
    if (offered == null) return check();
    _cancel = PackCancel();
    progress = null;
    _set(_Phase.downloading);
    try {
      await _packs.install(
        offered,
        cancel: _cancel,
        onProgress: (got, total) {
          if (_stopped) return;
          progress = total > 0 ? (got / total).clamp(0.0, 1.0) : null;
          notifyListeners();
        },
      );
      _set(_Phase.done);
      if (!_stopped) onDone?.call();
    } on PackException catch (e) {
      // Stopping on purpose is not a failure to apologise for.
      if (e.problem == PackProblem.cancelled) {
        _set(_Phase.ready);
      } else {
        _set(_Phase.failed, because: e.problem);
      }
    } catch (_) {
      _set(_Phase.failed, because: PackProblem.damaged);
    }
  }

  void stopDownload() => _cancel();

  /// The dialog has gone: abandon whatever is in flight.
  void stop() {
    _stopped = true;
    _cancel();
  }
}

String _size(int bytes) => bytes < 1024 ? '$bytes bytes' : '${(bytes / 1024).ceil()} KB';

String _words(PackProblem p) => switch (p) {
      PackProblem.offline => 'The story shelf could not be reached. You might be offline. Nothing is lost, and you can try again whenever you like.',
      PackProblem.damaged => 'That download did not arrive in one piece, so it was not kept. Nothing is lost. Try again in a moment.',
      PackProblem.newerApp => 'These chapters need a newer version of the game. Update it from the store whenever you like, and they will be waiting.',
      PackProblem.notPublished => 'These chapters are not on the shelf yet. Nothing is lost. Check back another time.',
      PackProblem.cancelled => '',
    };

class _Body extends StatelessWidget {
  const _Body(this.d);

  final _PackDownload d;

  @override
  Widget build(BuildContext context) {
    final s = Story.seasonOf(d.season);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.title, style: gameTitle(20)),
        const SizedBox(height: 8),
        switch (d.phase) {
          _Phase.checking => const Row(children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
              SizedBox(width: 12),
              Expanded(child: Text('Looking for these chapters...', key: Key('pack_status'))),
            ]),
          _Phase.ready => Text(
              'These chapters come as a small download the first time you read them, about ${_size(d.entry!.bytes)}. '
              'They stay on your phone, so you only do this once. Nothing about you is sent.',
              key: const Key('pack_status'),
            ),
          _Phase.downloading || _Phase.done => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Downloading...', key: Key('pack_status')),
                const SizedBox(height: 10),
                LinearProgressIndicator(key: const Key('pack_progress'), value: d.progress, minHeight: 8, borderRadius: BorderRadius.circular(4)),
              ],
            ),
          _Phase.failed => Text(_words(d.problem ?? PackProblem.offline), key: const Key('pack_status')),
        },
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions(this.d, {required this.close});

  final _PackDownload d;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) {
    final notNow = GameButton(
      key: const Key('pack_not_now'),
      label: 'Not Now',
      kind: GameButtonKind.secondary,
      onPressed: close,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (d.phase) {
        _Phase.ready => [
            GameButton(
              key: const Key('pack_download'),
              label: 'Download',
              icon: Icons.download_rounded,
              kind: GameButtonKind.positive,
              onPressed: d.start,
            ),
            const SizedBox(height: 8),
            notNow,
          ],
        _Phase.downloading || _Phase.done => [
            GameButton(key: const Key('pack_stop'), label: 'Stop', kind: GameButtonKind.secondary, onPressed: d.stopDownload),
          ],
        _Phase.failed => [
            if (d.problem != PackProblem.newerApp && d.problem != PackProblem.notPublished) ...[
              GameButton(
                key: const Key('pack_retry'),
                label: 'Try Again',
                icon: Icons.refresh_rounded,
                kind: GameButtonKind.positive,
                onPressed: d.check,
              ),
              const SizedBox(height: 8),
            ],
            notNow,
          ],
        _Phase.checking => [notNow],
      },
    );
  }
}
