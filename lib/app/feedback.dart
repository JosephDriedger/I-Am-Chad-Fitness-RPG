import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/core.dart' show Haptic, Sfx;
import 'providers.dart';

/// Sound and haptic feedback for the game scenes, gated by the player's
/// settings. Failures are swallowed: feedback is never worth a crash.
class GameFeedback {
  GameFeedback({
    required this.soundOn,
    required this.hapticsOn,
    Future<void> Function(Sfx sfx)? player,
  }) : _player = player ?? _defaultPlayer;

  /// No sound, no haptics. Used by tests.
  GameFeedback.silent()
      : soundOn = false,
        hapticsOn = false,
        _player = _defaultPlayer;

  final bool soundOn;
  final bool hapticsOn;
  final Future<void> Function(Sfx sfx) _player;

  static Future<void> _defaultPlayer(Sfx sfx) async {
    await FlameAudio.play('${sfx.name}.wav', volume: 0.8);
  }

  void sfx(Sfx s) {
    if (!soundOn) return;
    unawaited(_player(s).catchError((Object _) {}));
  }

  void haptic(Haptic h) {
    if (!hapticsOn) return;
    final call = switch (h) {
      Haptic.light => HapticFeedback.lightImpact,
      Haptic.medium => HapticFeedback.mediumImpact,
      Haptic.heavy => HapticFeedback.heavyImpact,
    };
    unawaited(call().catchError((Object _) {}));
  }
}

final feedbackProvider = Provider<GameFeedback>((ref) {
  final prefs = ref.watch(prefsProvider);
  return GameFeedback(soundOn: prefs.soundOn, hapticsOn: prefs.hapticsOn);
});
