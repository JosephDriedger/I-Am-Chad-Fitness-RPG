import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// The two loops the game has: a calm one for the guild hall and a livelier
/// one for battles. The files are `assets/audio/<name>_loop.wav`, synthesized
/// by `tool/gen_music.mjs`.
enum MusicTrack {
  hall('hall_loop.wav'),
  battle('battle_loop.wav');

  const MusicTrack(this.file);
  final String file;
}

/// Where the music actually plays. Tests swap in a recorder.
abstract class MusicBackend {
  Future<void> play(MusicTrack track);
  Future<void> stop();
}

/// Plays through Flame's background-music player, quietly, and lets other
/// apps' audio carry on beneath it instead of taking over the phone.
class DeviceMusicBackend implements MusicBackend {
  static const volume = 0.3;
  static bool _configured = false;

  static Future<void> _configure() async {
    if (_configured) return;
    _configured = true;
    await AudioPlayer.global.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
  }

  /// Whether any music has been started. Until it has, there is nothing to
  /// stop, so the audio system is left alone (the game starts with music off).
  bool _started = false;

  @override
  Future<void> play(MusicTrack track) async {
    await _configure();
    _started = true;
    await FlameAudio.bgm.play(track.file, volume: volume);
  }

  @override
  Future<void> stop() async {
    if (!_started) return;
    await FlameAudio.bgm.stop();
  }
}

final musicBackendProvider = Provider<MusicBackend>((_) => DeviceMusicBackend());

/// Which loop the screen in front wants. The hall is the default; battle
/// screens ask for theirs while they are open.
class MusicTrackNotifier extends Notifier<MusicTrack> {
  @override
  MusicTrack build() => MusicTrack.hall;

  void set(MusicTrack track) => state = track;
}

final musicTrackProvider = NotifierProvider<MusicTrackNotifier, MusicTrack>(MusicTrackNotifier.new);

/// Whether the app is in the foreground. Music stops in the background.
class AppActiveNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool active) => state = active;
}

final appActiveProvider = NotifierProvider<AppActiveNotifier, bool>(AppActiveNotifier.new);

/// Keeps the music in step with the Music switch, the screen in front and
/// whether the app is showing. Read it once at launch and leave it.
final musicProvider = Provider<void>((ref) {
  final backend = ref.watch(musicBackendProvider);
  final on = ref.watch(prefsProvider.select((p) => p.musicOn));
  final track = ref.watch(musicTrackProvider);
  final active = ref.watch(appActiveProvider);

  void swallow(Object _) {}
  if (on && active) {
    unawaited(backend.play(track).catchError(swallow));
  } else {
    unawaited(backend.stop().catchError(swallow));
  }
  ref.onDispose(() => unawaited(backend.stop().catchError(swallow)));
});

/// Asks for [track] while the widget that mixes this in is on screen, then
/// hands the music back to the hall. Used by the battle screen.
mixin WantsMusic<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  MusicTrackNotifier? _musicNotifier;

  void wantMusic(MusicTrack track) {
    final notifier = ref.read(musicTrackProvider.notifier);
    _musicNotifier = notifier;
    // Not while the tree is still building.
    Future<void>(() {
      if (!mounted) return;
      try {
        notifier.set(track);
      } catch (_) {/* the app is shutting down */}
    });
  }

  @override
  void dispose() {
    final notifier = _musicNotifier;
    if (notifier != null) {
      Future<void>(() {
        try {
          notifier.set(MusicTrack.hall);
        } catch (_) {/* the app is shutting down */}
      });
    }
    super.dispose();
  }
}
