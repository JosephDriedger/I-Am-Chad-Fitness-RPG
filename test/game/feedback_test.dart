import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/feedback.dart';
import 'package:i_am_chad/game/core.dart';

void main() {
  test('sound plays only when enabled', () async {
    final played = <Sfx>[];
    final on = GameFeedback(soundOn: true, hapticsOn: false, player: (s) async => played.add(s));
    final off = GameFeedback(soundOn: false, hapticsOn: false, player: (s) async => played.add(s));

    on.sfx(Sfx.hit);
    off.sfx(Sfx.coin);
    await Future<void>.delayed(Duration.zero);

    expect(played, [Sfx.hit]);
  });

  test('haptics play only when enabled', () async {
    final felt = <Haptic>[];
    final on = GameFeedback(soundOn: false, hapticsOn: true, hapticPlayer: (h) async => felt.add(h));
    final off = GameFeedback(soundOn: false, hapticsOn: false, hapticPlayer: (h) async => felt.add(h));

    on.haptic(Haptic.success);
    off.haptic(Haptic.heavy);
    await Future<void>.delayed(Duration.zero);

    expect(felt, [Haptic.success]);
  });

  test('both plays a sound and a haptic, each by its own switch', () async {
    final played = <Sfx>[];
    final felt = <Haptic>[];
    GameFeedback fx(bool sound, bool haptics) => GameFeedback(
          soundOn: sound,
          hapticsOn: haptics,
          player: (s) async => played.add(s),
          hapticPlayer: (h) async => felt.add(h),
        );

    fx(true, true).both(Sfx.saved, Haptic.success);
    fx(true, false).both(Sfx.fanfare, Haptic.success);
    fx(false, true).both(Sfx.rep, Haptic.medium);
    await Future<void>.delayed(Duration.zero);

    expect(played, [Sfx.saved, Sfx.fanfare]);
    expect(felt, [Haptic.success, Haptic.medium]);
  });

  test('a failing sound player never throws into the game', () async {
    final fx = GameFeedback(
      soundOn: true,
      hapticsOn: false,
      player: (_) async => throw StateError('no audio device'),
    );
    fx.sfx(Sfx.levelUp);
    await Future<void>.delayed(Duration.zero);
  });

  test('a failing haptic motor never throws into the game', () async {
    final fx = GameFeedback(
      soundOn: false,
      hapticsOn: true,
      hapticPlayer: (_) async => throw StateError('no vibration motor'),
    );
    fx.haptic(Haptic.select);
    await Future<void>.delayed(Duration.zero);
  });

  test('silent feedback does nothing', () {
    GameFeedback.silent()
      ..sfx(Sfx.hit)
      ..haptic(Haptic.heavy)
      ..both(Sfx.saved, Haptic.success);
  });
}
