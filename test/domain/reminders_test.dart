import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/reminders.dart';

// Wednesday 21 Oct 2026, 10:00.
final _now = DateTime(2026, 10, 21, 10);

const _on = ReminderPrefs(enabled: true);

List<Reminder> _plan(ReminderPrefs p, {DateTime? now, bool moved = false, bool goalMet = false}) =>
    ReminderPlanner.plan(prefs: p, now: now ?? _now, movedToday: moved, goalMetThisWeek: goalMet);

void main() {
  group('the choices', () {
    test('everything is off until the player turns it on, and sensible when they do', () {
      const p = ReminderPrefs();
      expect(p.enabled, isFalse);
      expect(p.hour, inInclusiveRange(ReminderPrefs.earliestHour, ReminderPrefs.latestHour));
      expect(p.days.length, lessThanOrEqualTo(3), reason: 'a few days, not every day');
      expect(p.days, isNotEmpty);
      expect(_plan(p), isEmpty, reason: 'off means nothing is scheduled');
    });

    test('days are stored as one number and come back the same', () {
      for (var bits = 0; bits < 128; bits++) {
        expect(ReminderPrefs(days: ReminderPrefs.daysFromBits(bits)).daysBits, bits);
      }
      expect(const ReminderPrefs(days: {1, 3, 5}).daysBits, 21);
      expect(ReminderPrefs.daysFromBits(127), {1, 2, 3, 4, 5, 6, 7});
    });

    test('the hour stays within daytime, however it is set', () {
      expect(_on.copyWith(hour: 3).hour, ReminderPrefs.earliestHour);
      expect(_on.copyWith(hour: 23).hour, ReminderPrefs.latestHour);
      expect(_on.copyWith(hour: 12).hour, 12);
      expect(ReminderPrefs.earliestHour, greaterThanOrEqualTo(7));
      expect(ReminderPrefs.latestHour, lessThanOrEqualTo(21));
    });

    test('equal choices are equal', () {
      expect(
        const ReminderPrefs(enabled: true, hour: 9, days: {1, 2}),
        const ReminderPrefs(enabled: true, hour: 9, days: {2, 1}),
      );
      expect(const ReminderPrefs(enabled: true), isNot(const ReminderPrefs()));
    });
  });

  group('the plan', () {
    test('it covers the picked days over the next fortnight, one a day, in order', () {
      final r = _plan(_on); // Mon, Wed, Fri from Wed 21 Oct at 10:00
      expect({for (final x in r) x.at.weekday}.difference({1, 3, 5}), isEmpty);
      expect(r.map((x) => x.at.hour).toSet(), {18});
      expect({for (final x in r) DateTime(x.at.year, x.at.month, x.at.day)}.length, r.length, reason: 'at most one a day');
      for (var i = 1; i < r.length; i++) {
        expect(r[i].at.isAfter(r[i - 1].at), isTrue);
      }
      expect(r.first.at, DateTime(2026, 10, 21, 18), reason: 'today, because it is still before six');
      expect(r.length, 6, reason: 'Wed Fri Mon Wed Fri Mon in fourteen days');
    });

    test('it only looks a fortnight ahead, so if the game is not opened again the reminders run out', () {
      final r = _plan(_on.copyWith(days: {1, 2, 3, 4, 5, 6, 7}));
      expect(r.length, lessThanOrEqualTo(ReminderPlanner.horizonDays));
      expect(r.last.at.isBefore(_now.add(const Duration(days: ReminderPlanner.horizonDays + 1))), isTrue);
    });

    test('a time that has already passed today is not sent, and the next one is', () {
      final late = _plan(_on, now: DateTime(2026, 10, 21, 19));
      expect(late.first.at, DateTime(2026, 10, 23, 18));
      final exactly = _plan(_on, now: DateTime(2026, 10, 21, 18));
      expect(exactly.first.at, DateTime(2026, 10, 23, 18), reason: 'strictly after now');
    });

    test('nothing is sent on a day they have already moved', () {
      final r = _plan(_on, moved: true);
      expect(r.first.at, DateTime(2026, 10, 23, 18), reason: 'today is skipped');
      // Moving today does not silence the days after it.
      expect(r.length, 5);
    });

    test('a week whose goal is already met is left alone, and the next week resumes on Monday', () {
      final r = _plan(_on, goalMet: true);
      expect(r.first.at, DateTime(2026, 10, 26, 18), reason: 'Monday, the first day of next week');
      for (final x in r) {
        expect(x.at.isBefore(DateTime(2026, 10, 26)), isFalse);
      }
    });

    test('with no days picked, or while off, nothing is planned', () {
      expect(_plan(_on.copyWith(days: <int>{})), isEmpty);
      expect(_plan(const ReminderPrefs(enabled: false, days: {1, 2, 3})), isEmpty);
    });

    test('every reminder is at the chosen local hour, even across a clock change', () {
      final r = _plan(_on.copyWith(hour: 9, days: {1, 2, 3, 4, 5, 6, 7}), now: DateTime(2026, 10, 30, 12));
      expect(r.every((x) => x.at.hour == 9 && x.at.minute == 0), isTrue);
    });

    test('the same day always gets the same words, and different days vary', () {
      expect(ReminderCopy.lineFor(DateTime(2026, 10, 21)), ReminderCopy.lineFor(DateTime(2026, 10, 21, 23)));
      final seen = {for (var d = 0; d < 30; d++) ReminderCopy.lineFor(DateTime(2026, 10, 1 + d))};
      expect(seen.length, greaterThan(5));
      final r = _plan(_on);
      expect(r.first.text, ReminderCopy.lineFor(DateTime(2026, 10, 21)));
    });
  });

  group('the words', () {
    test('they are kind: no pressure, no guilt, no streaks, no counting, nothing about bodies', () {
      const banned = [
        'streak', 'missed', 'haven\'t', 'have not', 'yet?', 'again?', 'lazy', 'weak', 'failure', 'failed',
        'excuse', 'weight', 'in shape', 'burn', 'hurry', 'must ', 'you have to', 'don\'t forget', 'do not forget',
        'last chance', 'today only', 'limited', 'now!', 'days', 'in a row', 'goal', 'level',
      ];
      for (final line in ReminderCopy.lines) {
        final lower = line.toLowerCase();
        for (final b in banned) {
          expect(lower.contains(b), isFalse, reason: '"$b" in: $line');
        }
      }
    });

    test('each is a short, finished sentence that fits a notification, and none repeats', () {
      expect(ReminderCopy.lines.toSet().length, ReminderCopy.lines.length);
      for (final line in ReminderCopy.lines) {
        expect(line.length, inInclusiveRange(20, 110), reason: line);
        expect(RegExp(r'[.!]$').hasMatch(line), isTrue, reason: line);
      }
      expect(ReminderCopy.lines.length, greaterThanOrEqualTo(10));
      expect(ReminderCopy.title.length, lessThan(30));
    });

    test('some of them say that resting and taking it slowly are fine', () {
      final all = ReminderCopy.lines.join(' ').toLowerCase();
      expect(all, contains('rest'));
      expect(all, contains('no rush'));
    });
  });
}
