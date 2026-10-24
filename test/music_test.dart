import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/music.dart';
import 'package:i_am_chad/app/providers.dart';
import 'package:i_am_chad/domain/player_state.dart';

class _Recorder implements MusicBackend {
  final calls = <String>[];

  @override
  Future<void> play(MusicTrack track) async => calls.add('play ${track.name}');

  @override
  Future<void> stop() async => calls.add('stop');
}

class _Broken implements MusicBackend {
  @override
  Future<void> play(MusicTrack track) async => throw StateError('no audio device');

  @override
  Future<void> stop() async => throw StateError('no audio device');
}

void main() {
  late _Recorder music;
  late StreamController<AppPrefs> prefs;
  late ProviderContainer container;

  // The stream, the provider and the player each take a turn of the event loop.
  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() async {
    music = _Recorder();
    prefs = StreamController<AppPrefs>();
    container = ProviderContainer(overrides: [
      musicBackendProvider.overrideWithValue(music),
      settingsProvider.overrideWith((ref) => prefs.stream),
    ]);
    // Keep it running the way the app does from launch.
    container.listen(musicProvider, (_, _) {});
    await settle();
  });

  tearDown(() async {
    container.dispose();
    await prefs.close();
  });

  test('music is off until the player turns it on', () async {
    expect(music.calls.where((c) => c.startsWith('play')), isEmpty);
    prefs.add(const AppPrefs());
    await settle();
    expect(music.calls.where((c) => c.startsWith('play')), isEmpty);
    expect(music.calls.last, 'stop');
  });

  test('turning it on plays the hall tune, and off stops it', () async {
    prefs.add(const AppPrefs(musicOn: true));
    await settle();
    expect(music.calls.last, 'play hall');

    prefs.add(const AppPrefs(musicOn: false));
    await settle();
    expect(music.calls.last, 'stop');
  });

  test('a battle screen brings the livelier tune and hands back the hall tune', () async {
    prefs.add(const AppPrefs(musicOn: true));
    await settle();

    container.read(musicTrackProvider.notifier).set(MusicTrack.battle);
    await settle();
    expect(music.calls.last, 'play battle');

    container.read(musicTrackProvider.notifier).set(MusicTrack.hall);
    await settle();
    expect(music.calls.last, 'play hall');
  });

  test('music goes quiet when the app is in the background and returns with it', () async {
    prefs.add(const AppPrefs(musicOn: true));
    await settle();

    container.read(appActiveProvider.notifier).set(false);
    await settle();
    expect(music.calls.last, 'stop');

    container.read(appActiveProvider.notifier).set(true);
    await settle();
    expect(music.calls.last, 'play hall');
  });

  test('the background never plays music that is switched off', () async {
    prefs.add(const AppPrefs());
    await settle();
    container.read(appActiveProvider.notifier).set(false);
    container.read(appActiveProvider.notifier).set(true);
    container.read(musicTrackProvider.notifier).set(MusicTrack.battle);
    await settle();
    expect(music.calls.where((c) => c.startsWith('play')), isEmpty);
  });

  test('a music backend that fails never throws into the game', () async {
    final broken = ProviderContainer(overrides: [
      musicBackendProvider.overrideWithValue(_Broken()),
      settingsProvider.overrideWith((ref) => Stream.value(const AppPrefs(musicOn: true))),
    ]);
    addTearDown(broken.dispose);
    broken.listen(musicProvider, (_, _) {});
    await settle();
    await settle();
  });
}
