import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminders.dart';
import 'reminders.dart';

/// The real reminder delivery, on Android and iOS. This is the only file that
/// talks to the notification plugin (test/reminders_promise_test.dart checks), so
/// the rest of the game only ever sees [ReminderGateway].
///
/// What it deliberately does not do: ask for permission when the app starts (only
/// when the player turns reminders on), use exact alarms (a reminder a few minutes
/// late is fine, and exact alarms need a special permission), show a notification
/// while the game is already open, or attach anything to a notification beyond a
/// line of text.
class LocalReminderGateway implements ReminderGateway {
  LocalReminderGateway({FlutterLocalNotificationsPlugin? plugin}) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _ready;

  static const _channelId = 'gentle_reminders';
  static const _channelName = 'Gentle Reminders';
  static const _channelDescription = 'Optional, occasional nudges you choose in Settings.';

  /// Whether this platform can schedule notifications at all.
  static bool get platformCanNotify =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  bool get isSupported => platformCanNotify;

  Future<void> _init() => _ready ??= _initOnce();

  Future<void> _initOnce() async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // Leave the zone as UTC. Every time we schedule is a real instant converted
      // from the phone's own clock, so it still arrives at the right moment.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Nothing is asked at start-up; permission is requested when the player
          // turns reminders on.
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
          // No banner or sound while the game is open: a nudge to come in is
          // pointless once they are here.
          defaultPresentAlert: false,
          defaultPresentSound: false,
          defaultPresentBadge: false,
          defaultPresentBanner: false,
          defaultPresentList: false,
        ),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    await _init();
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        // Before Android 13 there is nothing to ask, and this reports whether they are switched on.
        final asked = await android?.requestNotificationsPermission();
        return asked ?? await android?.areNotificationsEnabled() ?? false;
      case TargetPlatform.iOS:
        final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        return await ios?.requestPermissions(alert: true, sound: true) ?? false;
      default:
        return false;
    }
  }

  /// Whether the phone currently lets us notify. Checked before scheduling, so a
  /// player who later switched notifications off in the phone's settings is left
  /// alone rather than queued up.
  Future<bool> _allowed() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await android?.areNotificationsEnabled() ?? false;
      case TargetPlatform.iOS:
        final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final p = await ios?.checkPermissions();
        return p?.isEnabled ?? false;
      default:
        return false;
    }
  }

  @override
  Future<void> replaceAll(List<Reminder> reminders) async {
    if (!isSupported) return;
    await _init();
    await _plugin.cancelAllPendingNotifications();
    if (reminders.isEmpty || !await _allowed()) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(presentAlert: false, presentSound: false, presentBadge: false),
    );
    for (final r in reminders) {
      try {
        await _plugin.zonedSchedule(
          id: idFor(r.at),
          title: ReminderCopy.title,
          body: r.text,
          scheduledDate: tz.TZDateTime.from(r.at, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {
        // One that cannot be scheduled (for example it just passed) must not stop the rest.
      }
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!isSupported) return;
    await _init();
    await _plugin.cancelAllPendingNotifications();
  }

  /// One stable id per calendar day (20261023), since there is at most one a day.
  @visibleForTesting
  static int idFor(DateTime at) => at.year * 10000 + at.month * 100 + at.day;
}
