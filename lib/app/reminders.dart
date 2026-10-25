import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/quests.dart';
import '../domain/reminders.dart';
import '../domain/workout.dart';
import 'providers.dart';

/// The edge between the game and the phone's notifications. The game decides what
/// to say and when (lib/domain/reminders.dart); a gateway only delivers it.
///
/// Nothing is scheduled unless the player has turned reminders on, and a gateway
/// that cannot send notifications says so with [isSupported], which hides the
/// switch from Settings entirely, so the game never offers what it cannot do.
abstract class ReminderGateway {
  /// Whether this platform can send them. When false, Settings does not show the
  /// reminders switch at all.
  bool get isSupported;

  /// Asks the platform for permission to notify. Only called when the player
  /// turns the switch on. Returns false if they decline.
  Future<bool> requestPermission();

  /// Makes [reminders] the only ones scheduled, replacing any earlier plan.
  Future<void> replaceAll(List<Reminder> reminders);

  /// Removes every scheduled reminder.
  Future<void> cancelAll();
}

/// Used where nothing can be sent. It offers nothing and does nothing.
class NoReminderGateway implements ReminderGateway {
  const NoReminderGateway();

  @override
  bool get isSupported => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> replaceAll(List<Reminder> reminders) async {}

  @override
  Future<void> cancelAll() async {}
}

/// A pretend notification service, for tests and previews. It remembers what it
/// was asked to schedule.
class TestReminderGateway implements ReminderGateway {
  TestReminderGateway({this.supported = true, this.grants = true});

  final bool supported;

  /// Whether the pretend platform says yes when asked for permission.
  final bool grants;

  final List<Reminder> scheduled = [];
  int permissionAsks = 0;
  int replaced = 0;
  int cancelled = 0;

  @override
  bool get isSupported => supported;

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    return grants;
  }

  @override
  Future<void> replaceAll(List<Reminder> reminders) async {
    replaced++;
    scheduled
      ..clear()
      ..addAll(reminders);
  }

  @override
  Future<void> cancelAll() async {
    cancelled++;
    scheduled.clear();
  }
}

/// The real service. Overridden at startup where the platform can notify.
final reminderGatewayProvider = Provider<ReminderGateway>((_) => const NoReminderGateway());

/// Keeps the scheduled reminders matched to the player's settings and to what they
/// have done today and this week. Read it once at launch and leave it: it plans a
/// fortnight ahead each time the game opens or something relevant changes, so if
/// the game is not opened again the reminders run out by themselves.
final reminderSyncProvider = Provider<void>((ref) {
  final gateway = ref.watch(reminderGatewayProvider);
  if (!gateway.isSupported) return;
  final prefs = ref.watch(prefsProvider).reminders;
  final workouts = ref.watch(workoutsProvider).value ?? const <WorkoutEntry>[];
  final player = ref.watch(playerProvider);
  final now = ref.watch(clockProvider)();

  void swallow(Object _) {}
  if (!prefs.enabled || player == null) {
    unawaited(gateway.cancelAll().catchError(swallow));
    return;
  }
  final today = dayKey(now);
  final movedToday = workouts.any((w) => w.countsForRewards && dayKey(w.performedAt) == today);
  final goal = QuestBoard.weeklyGoal(
    level: player.hero.experience,
    now: now,
    entries: workouts,
    target: QuestBoard.goalTarget(hero: player.hero, now: now, entries: workouts),
  );
  final plan = ReminderPlanner.plan(prefs: prefs, now: now, movedToday: movedToday, goalMetThisWeek: goal.met);
  unawaited(gateway.replaceAll(plan).catchError(swallow));
});
