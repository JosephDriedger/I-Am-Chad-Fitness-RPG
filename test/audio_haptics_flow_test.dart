import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/feedback.dart';
import 'package:i_am_chad/app/music.dart';
import 'package:i_am_chad/app/providers.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/player_state.dart';
import 'package:i_am_chad/domain/workout.dart';
import 'package:i_am_chad/game/core.dart';

import 'helpers.dart';

final _now = DateTime(2026, 10, 22, 10);

class _Music implements MusicBackend {
  final calls = <String>[];

  @override
  Future<void> play(MusicTrack track) async => calls.add('play ${track.name}');

  @override
  Future<void> stop() async => calls.add('stop');
}

/// The app with the real feedback pipeline, except that sounds, vibration and
/// music go into lists instead of the device.
class _Rig {
  final sounds = <Sfx>[];
  final buzzes = <Haptic>[];
  final music = _Music();
  late AppDatabase db;
  late GameRepository repo;
}

Future<_Rig> _boot(
  WidgetTester tester, {
  AppPrefs prefs = const AppPrefs(),
  List<WorkoutEntry> before = const [],
}) async {
  usePhone(tester);
  final rig = _Rig();
  rig.db = AppDatabase.forTesting(NativeDatabase.memory());
  rig.repo = GameRepository(rig.db);
  await tester.runAsync(() async {
    await rig.repo.createHero(const HeroProfile(
      name: 'Ada',
      appearanceStyle: 0,
      appearanceColor: 0,
      experience: ExperienceLevel.returning,
      preferredCategories: {ActivityCategory.cardio},
      hasDumbbells: false,
    ));
    await rig.repo.saveSettings(prefs);
    for (final e in before) {
      await rig.repo.addWorkout(e);
    }
  });
  await bootApp(tester, rig.db, now: _now, liveFeedback: true, overrides: [
    sfxPlayerProvider.overrideWithValue((s) async => rig.sounds.add(s)),
    hapticPlayerProvider.overrideWithValue((h) async => rig.buzzes.add(h)),
    musicBackendProvider.overrideWithValue(rig.music),
    // The real thing: settings come from the saved game, so a switch flipped
    // while the game is running takes effect.
    prefsProvider.overrideWith((ref) => (ref.watch(settingsProvider).value ?? prefs).copyWith(reducedMotion: true)),
    feedbackProvider.overrideWith((ref) {
      final p = ref.watch(prefsProvider);
      return GameFeedback(
        soundOn: p.soundOn,
        hapticsOn: p.hapticsOn,
        player: ref.watch(sfxPlayerProvider),
        hapticPlayer: ref.watch(hapticPlayerProvider),
      );
    }),
  ]);
  return rig;
}

Future<void> _logWalk(WidgetTester tester) async {
  await tester.tap(find.text('Train'));
  await settle(tester, frames: 30);
  await openExercise(tester, 'Walking');
  await tester.enterText(find.widgetWithText(TextField, 'Minutes'), '10');
  await tester.scrollUntilVisible(find.text('Save Workout'), 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(find.text('Save Workout'));
  await tester.pump();
  await tester.ensureVisible(find.text('Save Workout'));
  await tester.ensureVisible(find.text('Save Workout'));
  await tester.tap(find.text('Save Workout'));
  await settle(tester);
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await settle(tester, frames: 30);
}

void main() {
  testWidgets('saving a workout chimes and gives two soft pulses', (tester) async {
    final rig = await _boot(tester);
    await _logWalk(tester);
    expect(find.text('Workout Saved!'), findsOneWidget);
    expect(rig.sounds, contains(Sfx.saved));
    expect(rig.sounds, isNot(contains(Sfx.fanfare)));
    expect(rig.buzzes, contains(Haptic.success));
    await shutDown(tester, rig.db);
  });

  testWidgets('a personal best gets the fanfare instead', (tester) async {
    final rig = await _boot(tester, before: [
      WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 19, 18), durationSeconds: 300),
    ]);
    await _logWalk(tester); // ten minutes beats the earlier five
    expect(find.text('New Personal Best!'), findsOneWidget);
    expect(rig.sounds, contains(Sfx.fanfare));
    expect(rig.sounds, isNot(contains(Sfx.saved)));
    expect(rig.buzzes, contains(Haptic.success));
    await shutDown(tester, rig.db);
  });

  testWidgets('with sound and vibration off, saving is silent and still', (tester) async {
    final rig = await _boot(tester, prefs: const AppPrefs(soundOn: false, hapticsOn: false));
    await _logWalk(tester);
    expect(find.text('Workout Saved!'), findsOneWidget);
    expect(rig.sounds, isEmpty);
    expect(rig.buzzes, isEmpty);
    await shutDown(tester, rig.db);
  });

  testWidgets('switching sound on in Settings applies to the hall straight away', (tester) async {
    // The hall scene stays alive under Settings. It used to keep the switches
    // it was built with, so sound stayed off until the app was restarted.
    final rig = await _boot(tester, prefs: const AppPrefs(soundOn: false));
    await tester.runAsync(() => rig.repo.saveSettings(const AppPrefs(soundOn: true)));
    await settle(tester, frames: 10);
    rig.sounds.clear();

    await _logWalk(tester);
    await tester.tap(find.text('Nice'));
    await settle(tester, frames: 30);
    // Back out of the Train page to the hall, which pays out the gains.
    await tester.pageBack();
    await settle(tester, frames: 80);
    expect(rig.sounds, contains(Sfx.coin), reason: 'the hall pays out its gains with a coin sound');
    await shutDown(tester, rig.db);
  });

  testWidgets('turning Vibration on in Settings lets you feel it, and Sound lets you hear it', (tester) async {
    final rig = await _boot(tester, prefs: const AppPrefs(soundOn: false, hapticsOn: false));
    await _openSettings(tester);

    await tester.tap(find.text('Vibration'));
    await settle(tester, frames: 10);
    expect(rig.buzzes, [Haptic.success]);

    rig.sounds.clear();
    await tester.tap(find.text('Sound Effects'));
    await settle(tester, frames: 10);
    expect(rig.sounds, contains(Sfx.saved));

    // Turning them off again makes no noise.
    rig.sounds.clear();
    rig.buzzes.clear();
    await tester.tap(find.text('Sound Effects'));
    await tester.tap(find.text('Vibration'));
    await settle(tester, frames: 10);
    expect(rig.sounds.where((s) => s == Sfx.saved), isEmpty);
    expect(rig.buzzes.where((h) => h == Haptic.success), isEmpty);
    await shutDown(tester, rig.db);
  });

  testWidgets('Music is off by default, and its switch starts and stops the tune', (tester) async {
    final rig = await _boot(tester);
    expect(rig.music.calls.where((c) => c.startsWith('play')), isEmpty);

    await _openSettings(tester);
    expect(find.text('Music'), findsOneWidget);
    expect(find.textContaining('Off unless you want it'), findsOneWidget);

    await tester.tap(find.text('Music'));
    await _afterSave(tester);
    expect((await tester.runAsync(() => rig.repo.watchSettings().first))!.musicOn, isTrue);
    expect(rig.music.calls.last, 'play hall');

    await tester.tap(find.text('Music'));
    await _afterSave(tester);
    expect((await tester.runAsync(() => rig.repo.watchSettings().first))!.musicOn, isFalse);
    expect(rig.music.calls.last, 'stop');
    await shutDown(tester, rig.db);
  });

  testWidgets('with music on, a practice duel plays the battle tune and returns to the hall tune', (tester) async {
    final rig = await _boot(tester, prefs: const AppPrefs(musicOn: true));
    expect(rig.music.calls.last, 'play hall');

    await tester.tap(find.text('Adventure'));
    await settle(tester, frames: 30);
    await tester.scrollUntilVisible(find.text('Practice Duel'), 300, scrollable: find.byType(Scrollable).first);
    await _bringIntoView(tester, find.text('Practice Duel'));
    await tester.tap(find.text('Practice Duel'));
    await settle(tester, frames: 40);
    expect(rig.music.calls.last, 'play battle');
    await tester.pageBack();
    await settle(tester, frames: 10);
    await tester.tap(find.text('Retreat'));
    await settle(tester, frames: 40);
    expect(rig.music.calls.last, 'play hall');
    await shutDown(tester, rig.db);
  });
}

/// Saved settings travel through the real database, which needs real time.
Future<void> _afterSave(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await settle(tester, frames: 20);
}

/// Scrolls the list until [target] is inside the screen, not merely built.
Future<void> _bringIntoView(WidgetTester tester, Finder target) async {
  final height = tester.view.physicalSize.height / tester.view.devicePixelRatio;
  for (var i = 0; i < 10 && tester.getCenter(target).dy > height - 80; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await settle(tester, frames: 5);
  }
}
