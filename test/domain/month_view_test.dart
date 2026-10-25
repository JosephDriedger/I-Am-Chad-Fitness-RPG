import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/domain/month_view.dart';
import 'package:i_am_chad/domain/workout.dart';

WorkoutEntry _on(int y, int m, int d, {int hour = 9, String id = 'walking', DateTime? loggedAt}) =>
    WorkoutEntry(activityId: id, performedAt: DateTime(y, m, d, hour), durationSeconds: 600, loggedAt: loggedAt);

void main() {
  group('the grid', () {
    test('weeks run Monday to Sunday and cover the whole month', () {
      final v = MonthView.of(const [], year: 2026, month: 10); // 1 Oct 2026 is a Thursday
      expect(v.weeks.length, 5);
      for (final w in v.weeks) {
        expect(w.length, 7);
        expect(w.first.date.weekday, DateTime.monday);
        expect(w.last.date.weekday, DateTime.sunday);
      }
      expect(v.weeks.first.first.date, DateTime(2026, 9, 28));
      expect(v.weeks.last.last.date, DateTime(2026, 11, 1));
      expect(v.days.length, 31, reason: 'only the days of the month itself');
      expect(v.weeks.first.take(3).every((d) => !d.inMonth), isTrue, reason: 'Mon to Wed belong to September');
      expect(v.weeks.first[3].date, DateTime(2026, 10, 1));
      expect(v.weeks.first[3].inMonth, isTrue);
    });

    test('a month can need four, five or six weeks', () {
      expect(MonthView.of(const [], year: 2021, month: 2).weeks.length, 4, reason: '1 Feb 2021 is a Monday, 28 days');
      expect(MonthView.of(const [], year: 2026, month: 10).weeks.length, 5);
      expect(MonthView.of(const [], year: 2026, month: 8).weeks.length, 6, reason: '1 Aug 2026 is a Saturday, 31 days');
    });

    test('every month of several years has the right number of days', () {
      for (var y = 2024; y <= 2029; y++) {
        for (var m = 1; m <= 12; m++) {
          final v = MonthView.of(const [], year: y, month: m);
          expect(v.days.length, DateTime(y, m + 1, 0).day, reason: '$y-$m');
          expect(v.weeks.first.first.date.weekday, DateTime.monday);
          expect(v.weeks.last.last.date.weekday, DateTime.sunday);
          // No gaps and no repeats from one cell to the next.
          final all = v.weeks.expand((w) => w).toList();
          for (var i = 1; i < all.length; i++) {
            expect(all[i].date, DateTime(all[i - 1].date.year, all[i - 1].date.month, all[i - 1].date.day + 1), reason: '$y-$m');
          }
        }
      }
    });

    test('leap years, and the turn of the year', () {
      expect(MonthView.of(const [], year: 2028, month: 2).days.length, 29);
      final dec = MonthView.of(const [], year: 2026, month: 12);
      expect(dec.weeks.last.last.date, DateTime(2027, 1, 3));
      final jan = MonthView.of(const [], year: 2027, month: 1);
      expect(jan.weeks.first.first.date, DateTime(2026, 12, 28));
    });
  });

  group('the active days', () {
    test('a day is active when anything was logged on it, however many entries', () {
      final v = MonthView.of([_on(2026, 10, 19), _on(2026, 10, 19, hour: 18), _on(2026, 10, 21)], year: 2026, month: 10);
      expect(v.activeDays, 2);
      final day = v.days.firstWhere((d) => d.date == DateTime(2026, 10, 19));
      expect(day.active, isTrue);
      expect(day.entries.length, 2);
      expect(day.entries.first.performedAt.hour, 9, reason: 'oldest first');
      expect(v.days.firstWhere((d) => d.date == DateTime(2026, 10, 20)).active, isFalse);
    });

    test('days of other months are not counted, even when they show in the first or last week', () {
      final v = MonthView.of([_on(2026, 9, 30), _on(2026, 11, 1), _on(2026, 10, 5)], year: 2026, month: 10);
      expect(v.activeDays, 1);
      final leading = v.weeks.first.firstWhere((d) => d.date == DateTime(2026, 9, 30));
      expect(leading.inMonth, isFalse);
    });

    test('a day logged late for the journal still shows, because it did happen', () {
      final v = MonthView.of([_on(2026, 10, 3, loggedAt: DateTime(2026, 10, 20, 9))], year: 2026, month: 10);
      expect(v.activeDays, 1);
    });

    test('late at night belongs to its own day', () {
      final v = MonthView.of([_on(2026, 10, 3, hour: 23), _on(2026, 10, 4, hour: 0)], year: 2026, month: 10);
      expect(v.days.firstWhere((d) => d.date == DateTime(2026, 10, 3)).entries.length, 1);
      expect(v.days.firstWhere((d) => d.date == DateTime(2026, 10, 4)).entries.length, 1);
      expect(v.activeDays, 2);
    });

    test('an empty month has none, and nothing is marked', () {
      final v = MonthView.of(const [], year: 2026, month: 10);
      expect(v.activeDays, 0);
      expect(v.days.any((d) => d.active), isFalse);
    });
  });

  test('the earliest month with anything logged', () {
    expect(MonthView.firstMonth(const []), isNull);
    expect(MonthView.firstMonth([_on(2026, 10, 3), _on(2026, 7, 28), _on(2026, 9, 1)]), (2026, 7));
  });
}
