import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/reminders.dart';
import 'package:i_am_chad/app/providers.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/activity.dart';
import 'package:i_am_chad/domain/hero.dart';
import 'package:i_am_chad/domain/player_state.dart';
import 'package:i_am_chad/domain/reminders.dart';
import 'package:i_am_chad/domain/workout.dart';

import 'helpers.dart';

// Thursday 22 Oct 2026, 10:00.
final _now = DateTime(2026, 10, 22, 10);

class _Rig {
  late AppDatabase db;
  late GameRepository repo;
}

Future<_Rig> _boot(
  WidgetTester tester, {
  ReminderGateway? gateway,
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
  await bootApp(tester, rig.db, now: _now, liveFeedback: true, reminders: gateway, overrides: [
    // Settings come from the saved game, so a switch flipped while the game runs takes effect.
    prefsProvider.overrideWith((ref) => (ref.watch(settingsProvider).value ?? prefs).copyWith(reducedMotion: true)),
  ]);
  return rig;
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await settle(tester, frames: 30);
}

Future<void> _reveal(WidgetTester tester, Finder f) async {
  // The list builds lazily, so scroll down until the control exists, then bring it fully on screen.
  await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(f);
  await settle(tester, frames: 4);
}

void main() {
  testWidgets('where the phone cannot send reminders, Settings does not offer them', (tester) async {
    final rig = await _boot(tester); // the default gateway sends nothing
    await _openSettings(tester);
    expect(find.text('Gentle Reminders'), findsNothing);
    expect(find.byKey(const Key('reminders_switch')), findsNothing);
    await shutDown(tester, rig.db);
  });

  testWidgets('it is off to begin with, and nothing is asked or scheduled until the player turns it on', (tester) async {
    final gateway = TestReminderGateway();
    final rig = await _boot(tester, gateway: gateway);
    await _openSettings(tester);
    await _reveal(tester, find.byKey(const Key('reminders_switch')));
    expect(find.text('Gentle Reminders'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('reminders_switch'))).value, isFalse);
    expect(find.byKey(const Key('reminders_hour')), findsNothing, reason: 'choices appear only once it is on');
    expect(gateway.permissionAsks, 0);
    expect(gateway.scheduled, isEmpty);
    await shutDown(tester, rig.db);
  });

  testWidgets('turning it on asks once, then plans the next fortnight; turning it off removes them', (tester) async {
    final gateway = TestReminderGateway();
    final rig = await _boot(tester, gateway: gateway);
    await _openSettings(tester);
    await _reveal(tester, find.byKey(const Key('reminders_switch')));

    await tester.tap(find.byKey(const Key('reminders_switch')));
    await settle(tester, frames: 20);
    expect(gateway.permissionAsks, 1);
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('reminders_switch'))).value, isTrue);
    expect(find.byKey(const Key('reminders_hour')), findsOneWidget);
    for (var d = 1; d <= 7; d++) {
      expect(find.byKey(Key('reminders_day_$d')), findsOneWidget);
    }
    expect(gateway.scheduled, isNotEmpty);
    expect(gateway.scheduled.first.at, DateTime(2026, 10, 23, 18), reason: 'Friday evening, the next of Mon/Wed/Fri');
    for (final r in gateway.scheduled) {
      expect({1, 3, 5}.contains(r.at.weekday), isTrue);
      expect(ReminderCopy.lines, contains(r.text));
    }

    // Saved, so it is still on after a restart.
    final saved = await tester.runAsync(() => rig.repo.watchSettings().first);
    expect(saved!.reminders.enabled, isTrue);

    await tester.tap(find.byKey(const Key('reminders_switch')));
    await settle(tester, frames: 20);
    expect(gateway.scheduled, isEmpty);
    expect(gateway.cancelled, greaterThan(0));
    expect(find.byKey(const Key('reminders_hour')), findsNothing);
    await shutDown(tester, rig.db);
  });

  testWidgets('choosing days replans, and the last day cannot be switched off', (tester) async {
    final gateway = TestReminderGateway();
    final rig = await _boot(tester, gateway: gateway, prefs: const AppPrefs(reminders: ReminderPrefs(enabled: true)));
    await _openSettings(tester);
    await _reveal(tester, find.byKey(const Key('reminders_day_2')));

    await tester.tap(find.byKey(const Key('reminders_day_2'))); // add Tuesday
    await settle(tester, frames: 20);
    expect(gateway.scheduled.map((r) => r.at.weekday).toSet(), {1, 2, 3, 5});

    // Take everything off except Friday.
    for (final d in [1, 2, 3]) {
      await tester.tap(find.byKey(Key('reminders_day_$d')));
      await settle(tester, frames: 12);
    }
    expect(gateway.scheduled.map((r) => r.at.weekday).toSet(), {5});
    await tester.tap(find.byKey(const Key('reminders_day_5')));
    await settle(tester, frames: 12);
    expect(gateway.scheduled.map((r) => r.at.weekday).toSet(), {5}, reason: 'at least one day stays picked');
    await shutDown(tester, rig.db);
  });

  testWidgets('moving today leaves today alone', (tester) async {
    final gateway = TestReminderGateway();
    final rig = await _boot(
      tester,
      gateway: gateway,
      prefs: const AppPrefs(reminders: ReminderPrefs(enabled: true, days: {4, 5})),
      before: [WorkoutEntry(activityId: 'walking', performedAt: DateTime(2026, 10, 22, 8), durationSeconds: 600)],
    );
    expect(gateway.scheduled, isNotEmpty);
    expect(gateway.scheduled.first.at, DateTime(2026, 10, 23, 18), reason: 'Thursday is skipped; they have moved');
    await shutDown(tester, rig.db);
  });

  testWidgets('if the phone says no, reminders stay off and the player is told kindly', (tester) async {
    final gateway = TestReminderGateway(grants: false);
    final rig = await _boot(tester, gateway: gateway);
    await _openSettings(tester);
    await _reveal(tester, find.byKey(const Key('reminders_switch')));
    await tester.tap(find.byKey(const Key('reminders_switch')));
    await settle(tester, frames: 20);
    expect(gateway.permissionAsks, 1);
    expect(find.byKey(const Key('reminders_note')), findsOneWidget);
    expect(find.textContaining('That is fine'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('reminders_switch'))).value, isFalse);
    expect(gateway.scheduled, isEmpty);
    await shutDown(tester, rig.db);
  });

  testWidgets('the panel fits a small phone at large text', (tester) async {
    final gateway = TestReminderGateway();
    final rig = await _boot(tester, gateway: gateway, prefs: const AppPrefs(reminders: ReminderPrefs(enabled: true)));
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await settle(tester, frames: 10);
    await _openSettings(tester);
    await _reveal(tester, find.byKey(const Key('reminders_day_7')));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('reminders_hour')), findsOneWidget);
    await shutDown(tester, rig.db);
  });
}
