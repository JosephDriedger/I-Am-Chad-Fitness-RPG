import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/core.dart' show Haptic, Sfx;
import 'providers.dart';

/// Sound and haptic feedback for the game scenes and screens, gated by the
/// player's settings. Failures are swallowed: feedback is never worth a crash.
class GameFeedback {
  GameFeedback({
    required this.soundOn,
    required this.hapticsOn,
    Future<void> Function(Sfx sfx)? player,
    Future<void> Function(Haptic h)? hapticPlayer,
  })  : _player = player ?? _defaultPlayer,
        _hapticPlayer = hapticPlayer ?? _defaultHaptic;

  /// No sound, no haptics. Used by tests.
  GameFeedback.silent()
      : soundOn = false,
        hapticsOn = false,
        _player = _defaultPlayer,
        _hapticPlayer = _defaultHaptic;

  final bool soundOn;
  final bool hapticsOn;
  final Future<void> Function(Sfx sfx) _player;
  final Future<void> Function(Haptic h) _hapticPlayer;

  static Future<void> _defaultPlayer(Sfx sfx) async {
    await FlameAudio.play('${sfx.name}.wav', volume: 0.8);
  }

  static Future<void> _defaultHaptic(Haptic h) async {
    switch (h) {
      case Haptic.light:
        await HapticFeedback.lightImpact();
      case Haptic.medium:
        await HapticFeedback.mediumImpact();
      case Haptic.heavy:
        await HapticFeedback.heavyImpact();
      case Haptic.select:
        await HapticFeedback.selectionClick();
      case Haptic.success:
        // Two pulses, a firm one then a soft one: "got it".
        await HapticFeedback.mediumImpact();
        await Future<void>.delayed(const Duration(milliseconds: 110));
        await HapticFeedback.lightImpact();
    }
  }

  void sfx(Sfx s) {
    if (!soundOn) return;
    unawaited(_player(s).catchError((Object _) {}));
  }

  void haptic(Haptic h) {
    if (!hapticsOn) return;
    unawaited(_hapticPlayer(h).catchError((Object _) {}));
  }

  /// A sound and a haptic together, for moments like saving a workout.
  void both(Sfx s, Haptic h) {
    sfx(s);
    haptic(h);
  }
}

/// Where sounds and vibration actually go. Null means the device; tests swap
/// in recorders so they can check what the game asked for.
final sfxPlayerProvider = Provider<Future<void> Function(Sfx sfx)?>((_) => null);
final hapticPlayerProvider = Provider<Future<void> Function(Haptic h)?>((_) => null);

final feedbackProvider = Provider<GameFeedback>((ref) {
  final prefs = ref.watch(prefsProvider);
  return GameFeedback(
    soundOn: prefs.soundOn,
    hapticsOn: prefs.hapticsOn,
    player: ref.watch(sfxPlayerProvider),
    hapticPlayer: ref.watch(hapticPlayerProvider),
  );
});
