import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/local_reminders.dart';

/// Every .dart file under lib/, as path -> text.
Map<String, String> _sources() => {
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart')) f.path.replaceAll(r'\', '/'): f.readAsStringSync(),
    };

void main() {
  final sources = _sources();
  final real = sources['lib/app/local_reminders.dart']!;

  test('only one file talks to the notification plugin', () {
    final users = [for (final e in sources.entries) if (e.value.contains('flutter_local_notifications')) e.key];
    expect(users..sort(), ['lib/app/local_reminders.dart']);
  });

  test('the real gateway is installed in exactly one place, at start-up', () {
    final users = [for (final e in sources.entries) if (e.value.contains('LocalReminderGateway(')) e.key];
    expect(users..sort(), ['lib/app/local_reminders.dart', 'lib/main.dart']);
  });

  test('it asks for permission only when the player turns reminders on, never when the game starts', () {
    expect(real, contains('requestAlertPermission: false'));
    expect(real, contains('requestSoundPermission: false'));
    expect(real, contains('requestBadgePermission: false'));
    // The only calls that can show a permission prompt live inside requestPermission().
    final ask = real.indexOf('Future<bool> requestPermission()');
    final next = real.indexOf('Future<bool> _allowed()');
    for (final call in ['requestNotificationsPermission(', 'requestPermissions(']) {
      final at = real.indexOf(call);
      expect(at, greaterThan(ask), reason: call);
      expect(at, lessThan(next), reason: call);
      expect(real.indexOf(call, at + 1), -1, reason: '$call only once');
    }
  });

  test('it never uses exact alarms, repeats, attachments or sounds, and never shows while the game is open', () {
    for (final banned in [
      'AndroidScheduleMode.exact',
      'AndroidScheduleMode.alarmClock',
      'requestExactAlarmsPermission',
      'matchDateTimeComponents',
      'fullScreenIntent',
      'payload:',
      'attachments',
      'badgeNumber',
      'AndroidNotificationSound',
    ]) {
      expect(real.contains(banned), isFalse, reason: banned);
    }
    expect(real, contains('AndroidScheduleMode.inexactAllowWhileIdle'));
    expect(real, contains('defaultPresentAlert: false'));
    expect(real, contains('defaultPresentBanner: false'));
  });

  test('the Android manifest asks only for what scheduling needs', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('RECEIVE_BOOT_COMPLETED'));
    for (final banned in ['SCHEDULE_EXACT_ALARM', 'USE_EXACT_ALARM', 'USE_FULL_SCREEN_INTENT', 'ACCESS_NOTIFICATION_POLICY']) {
      expect(manifest.contains(banned), isFalse, reason: banned);
    }
  });

  test('one id per calendar day, so a day can only ever have one reminder', () {
    expect(LocalReminderGateway.idFor(DateTime(2026, 10, 23, 18)), 20261023);
    expect(LocalReminderGateway.idFor(DateTime(2026, 10, 23, 8)), LocalReminderGateway.idFor(DateTime(2026, 10, 23, 21)));
    expect(LocalReminderGateway.idFor(DateTime(2026, 10, 24, 18)), isNot(20261023));
  });

  test('on a test machine the real gateway reports what the platform allows without touching the plugin', () {
    // flutter_test pretends to be Android, so this must not throw or need a device.
    expect(LocalReminderGateway.platformCanNotify, isTrue);
  });
}
