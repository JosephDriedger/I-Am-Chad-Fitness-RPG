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

  test('a failing sound player never throws into the game', () async {
    final fx = GameFeedback(
      soundOn: true,
      hapticsOn: false,
      player: (_) async => throw StateError('no audio device'),
    );
    fx.sfx(Sfx.levelUp);
    await Future<void>.delayed(Duration.zero);
  });

  test('silent feedback does nothing', () {
    GameFeedback.silent()
      ..sfx(Sfx.hit)
      ..haptic(Haptic.heavy);
  });
}
